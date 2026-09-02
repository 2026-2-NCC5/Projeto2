import os
import re
import yaml
from typing import List, Dict, Any, Optional
from sqlalchemy.orm import Session

from app.core.config import settings
from app.agent.embeddings import TextVectorizer
from app.models.document import KnowledgeDocument


class Chunk:
    def __init__(
        self,
        document_slug: str,
        document_title: str,
        official_source: str,
        section: str,
        version: str,
        updated_at: str,
        category: str,
        content: str,
        file_path: str,
    ):
        self.document_slug = document_slug
        self.document_title = document_title
        self.official_source = official_source
        self.section = section
        self.version = version
        self.updated_at = updated_at
        self.category = category
        self.content = content
        self.file_path = file_path

    def to_dict(self) -> Dict[str, Any]:
        return {
            "document_slug": self.document_slug,
            "document_title": self.document_title,
            "official_source": self.official_source,
            "section": self.section,
            "version": self.version,
            "updated_at": self.updated_at,
            "category": self.category,
            "content": self.content,
            "file_path": self.file_path,
        }


class KnowledgeRetriever:
    """
    Gerenciador da Base de Conhecimento e Indexação Vetorial do ASA Connect.
    """
    def __init__(self, kb_dir: Optional[str] = None):
        self.kb_dir = kb_dir or settings.KNOWLEDGE_BASE_DIR
        self.vectorizer = TextVectorizer()
        self.chunks: List[Chunk] = []
        self.chunk_vectors = None
        self.indexed_docs_count = 0
        # Inicializa o índice automaticamente
        self.build_index()

    def parse_markdown_file(self, file_path: str) -> List[Chunk]:
        """Lê um arquivo Markdown com frontmatter YAML e divide em seções semânticas."""
        with open(file_path, "r", encoding="utf-8") as f:
            raw_content = f.read()

        frontmatter = {}
        body = raw_content

        # Extrai frontmatter YAML entre --- e ---
        match = re.match(r"^---\s*\n(.*?)\n---\s*\n(.*)$", raw_content, re.DOTALL)
        if match:
            fm_text, body = match.groups()
            try:
                frontmatter = yaml.safe_load(fm_text) or {}
            except Exception:
                frontmatter = {}

        slug = frontmatter.get("slug", os.path.splitext(os.path.basename(file_path))[0])
        title = frontmatter.get("title", slug.replace("_", " ").title())
        source = frontmatter.get("official_source", "Secretaria Geral / Manual do Aluno")
        default_section = frontmatter.get("section", "Procedimento Geral")
        version = str(frontmatter.get("version", "v1.0"))
        updated_at = str(frontmatter.get("updated_at", "2024-10-15"))
        category = frontmatter.get("category", "Geral")

        # Divide o corpo em seções por títulos (# e ##)
        section_pattern = r"(^|\n)(#{1,3}\s+[^\n]+)"
        splits = re.split(section_pattern, body)

        chunks: List[Chunk] = []
        current_section = default_section
        current_text = ""

        for part in splits:
            part = part.strip()
            if not part:
                continue
            if part.startswith("#"):
                if current_text:
                    chunks.append(
                        Chunk(
                            document_slug=slug,
                            document_title=title,
                            official_source=source,
                            section=current_section,
                            version=version,
                            updated_at=updated_at,
                            category=category,
                            content=current_text,
                            file_path=file_path,
                        )
                    )
                    current_text = ""
                current_section = part.lstrip("#").strip()
            else:
                if current_text:
                    current_text += "\n\n" + part
                else:
                    current_text = part

        if current_text:
            chunks.append(
                Chunk(
                    document_slug=slug,
                    document_title=title,
                    official_source=source,
                    section=current_section,
                    version=version,
                    updated_at=updated_at,
                    category=category,
                    content=current_text,
                    file_path=file_path,
                )
            )

        return chunks

    def build_index(self, db: Optional[Session] = None) -> int:
        """
        Carrega todos os arquivos .md da base de conhecimento,
        filtra documentos inativos do banco de dados e cria os vetores.
        """
        all_chunks: List[Chunk] = []
        if not os.path.exists(self.kb_dir):
            return 0

        # Lista de slugs inativos se db estiver disponível (RF16)
        inactive_slugs = set()
        if db:
            inactive_docs = db.query(KnowledgeDocument).filter(KnowledgeDocument.is_active == False).all()
            inactive_slugs = {doc.slug for doc in inactive_docs}

        md_files = [f for f in os.listdir(self.kb_dir) if f.endswith(".md") and f != "README.md"]

        for filename in md_files:
            file_path = os.path.join(self.kb_dir, filename)
            file_chunks = self.parse_markdown_file(file_path)
            
            # Sincroniza metadados no banco se houver sessão
            if db and file_chunks:
                first_chunk = file_chunks[0]
                existing_doc = db.query(KnowledgeDocument).filter(KnowledgeDocument.slug == first_chunk.document_slug).first()
                if not existing_doc:
                    db_doc = KnowledgeDocument(
                        slug=first_chunk.document_slug,
                        title=first_chunk.document_title,
                        category=first_chunk.category,
                        file_path=file_path,
                        official_source=first_chunk.official_source,
                        section=first_chunk.section,
                        version=first_chunk.version,
                        is_active=True,
                    )
                    db.add(db_doc)
            
            for chunk in file_chunks:
                if chunk.document_slug not in inactive_slugs:
                    all_chunks.append(chunk)

        if db:
            db.commit()

        self.chunks = all_chunks
        self.indexed_docs_count = len(md_files)

        if all_chunks:
            # Constrói texto representativo para cada chunk (título + seção + conteúdo)
            corpus = [f"{c.document_title} - {c.section}\n{c.content}" for c in all_chunks]
            self.chunk_vectors = self.vectorizer.fit_transform(corpus)

        return len(all_chunks)

    def retrieve(self, query: str, top_k: int = 3) -> List[Dict[str, Any]]:
        """
        Busca os top-k chunks mais similares à pergunta do usuário,
        calculando score de similaridade de cosseno e cobertura de termos.
        """
        if not self.chunks or self.chunk_vectors is None or self.chunk_vectors.shape[0] == 0:
            return []

        query_vec = self.vectorizer.transform([query])
        similarities = self.vectorizer.compute_similarity(query, query_vec, self.chunk_vectors)

        # Ordena por similaridade decrescente
        top_indices = similarities.argsort()[::-1][:top_k]

        results = []
        for idx in top_indices:
            score = float(similarities[idx])
            chunk = self.chunks[idx]
            results.append({
                "chunk": chunk.to_dict(),
                "similarity": round(score, 4),
            })

        return results


# Instância singleton do Retriever
retriever = KnowledgeRetriever()
