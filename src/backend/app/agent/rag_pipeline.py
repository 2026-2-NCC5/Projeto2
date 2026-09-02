from typing import Dict, Any, List, Optional
from app.agent.retriever import retriever
from app.agent.abstention import should_abstain, load_rag_config
from app.core.config import settings


class RAGPipeline:
    """
    Pipeline RAG do ASA Connect:
    Recupera conteúdo oficial, valida confiança, aplica abstenção e formata respostas explicáveis.
    """
    def __init__(self):
        self.config = load_rag_config()
        self.agent_version = self.config.get("agent", {}).get("version", "asa-rag-v1.0.0")

    def answer_query(self, query: str, top_k: int = 3) -> Dict[str, Any]:
        """
        Processa uma pergunta do estudante e gera a resposta fundamentada com rastreabilidade total.
        """
        # 1. Recuperação Vetorial
        retrieved_results = retriever.retrieve(query, top_k=top_k)
        
        if not retrieved_results:
            # Nenhum documento indexado ou correspondente
            threshold = self.config.get("rag", {}).get("confidence_threshold", settings.RAG_CONFIDENCE_THRESHOLD)
            return {
                "content": self.config.get("abstention", {}).get("message"),
                "is_abstained": True,
                "confidence_score": 0.0,
                "threshold_used": threshold,
                "retrieved_chunks": [],
                "source_citation": None,
                "suggested_action": "Falar com um atendente do ASA para orientação personalizada.",
                "agent_version": self.agent_version,
            }

        top_match = retrieved_results[0]
        max_similarity = top_match["similarity"]
        top_chunk = top_match["chunk"]
        
        threshold = self.config.get("rag", {}).get("confidence_threshold", settings.RAG_CONFIDENCE_THRESHOLD)
        is_abstained, reason = should_abstain(max_similarity, custom_threshold=threshold)

        # Prepara lista de chunks recuperados para auditoria e explicabilidade
        formatted_chunks = []
        for r in retrieved_results:
            c = r["chunk"]
            formatted_chunks.append({
                "document_slug": c["document_slug"],
                "document_title": c["document_title"],
                "official_source": c["official_source"],
                "section": c["section"],
                "updated_at": c["updated_at"],
                "snippet": c["content"][:300] + ("..." if len(c["content"]) > 300 else ""),
                "similarity": r["similarity"],
            })

        if is_abstained:
            return {
                "content": self.config.get("abstention", {}).get("message"),
                "is_abstained": True,
                "confidence_score": max_similarity,
                "threshold_used": threshold,
                "retrieved_chunks": formatted_chunks,
                "source_citation": f"Fonte com baixa aderência ({max_similarity:.2f}) · Limiar mínimo {threshold:.2f}",
                "suggested_action": "Solicitar atendimento com a equipe do ASA.",
                "agent_version": self.agent_version,
            }

        # 2. Formatação da Resposta Fundamentada
        doc_title = top_chunk["document_title"]
        section = top_chunk["section"]
        updated_at = top_chunk["updated_at"]
        source_name = top_chunk["official_source"]

        # Chip de fonte no formato exato solicitado na seção 5 do briefing e no Figma
        source_citation = f"Fonte: {doc_title} · {section} · atualizado em {updated_at}"

        # Monta resposta concisa e direta baseada nos trechos recuperados
        answer_text = top_chunk["content"].strip()
        
        # Sugestão de próxima ação (RF07)
        suggested_action = f"Acesse o Portal do Aluno na seção '{top_chunk.get('category', 'Serviços')}' para prosseguir."
        if "atestado" in query.lower() or "matricula" in top_chunk["document_slug"]:
            suggested_action = "Acesse o Portal do Aluno > Secretaria > Emissão de Documentos."
        elif "boleto" in query.lower() or "financeiro" in top_chunk["document_slug"]:
            suggested_action = "Acesse o Portal do Aluno > Financeiro > Boletos e Pagamentos."
        elif "estagio" in query.lower():
            suggested_action = "Envie o TCE assinado via Portal do Aluno > Documentos > Estágio."

        return {
            "content": answer_text,
            "is_abstained": False,
            "confidence_score": max_similarity,
            "threshold_used": threshold,
            "retrieved_chunks": formatted_chunks,
            "source_citation": source_citation,
            "suggested_action": suggested_action,
            "agent_version": self.agent_version,
        }


# Instância global do pipeline RAG
rag_pipeline = RAGPipeline()
