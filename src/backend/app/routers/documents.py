import os
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import get_current_user, require_profiles
from app.models.user import User, ProfileType
from app.models.document import KnowledgeDocument
from app.models.audit import AuditLog
from app.schemas.document import (
    DocumentResponse,
    DocumentToggleActiveRequest,
)
from app.agent.retriever import retriever

router = APIRouter(prefix="/documents", tags=["Base de Conhecimento e Documentos"])


@router.get("", response_model=List[DocumentResponse])
def list_documents(
    active_only: bool = False,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Lista todos os documentos institucionais da base de conhecimento (RF03, RF16).
    """
    query = db.query(KnowledgeDocument)
    if active_only:
        query = query.filter(KnowledgeDocument.is_active == True)
    docs = query.order_by(KnowledgeDocument.category, KnowledgeDocument.title).all()
    return docs


@router.get("/{slug}")
def get_document_by_slug(
    slug: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Retorna o conteúdo completo e metadados de um documento específico pelo slug.
    """
    doc = db.query(KnowledgeDocument).filter(KnowledgeDocument.slug == slug).first()
    if not doc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Documento institucional com slug '{slug}' não encontrado.",
        )

    content = ""
    if os.path.exists(doc.file_path):
        with open(doc.file_path, "r", encoding="utf-8") as f:
            content = f.read()

    return {
        "id": doc.id,
        "slug": doc.slug,
        "title": doc.title,
        "category": doc.category,
        "official_source": doc.official_source,
        "section": doc.section,
        "version": doc.version,
        "is_active": doc.is_active,
        "updated_at": doc.updated_at,
        "content": content,
    }


@router.post("/reindex")
def reindex_knowledge_base(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_profiles([ProfileType.ATENDENTE_ASA, ProfileType.ADMINISTRADOR])),
):
    """
    Recarrega e indexa todos os documentos da pasta knowledge_base no banco vetorial (RF03).
    Apenas Atendentes e Administradores.
    """
    total_chunks = retriever.build_index(db=db)
    
    # Auditoria (RF10)
    audit = AuditLog(
        user_id=current_user.id,
        action="KNOWLEDGE_BASE_REINDEX",
        details={"total_chunks": total_chunks, "docs_count": retriever.indexed_docs_count},
    )
    db.add(audit)
    db.commit()

    return {
        "message": f"Indexação concluída com sucesso. {retriever.indexed_docs_count} documentos e {total_chunks} trechos processados.",
        "total_documents": retriever.indexed_docs_count,
        "total_chunks": total_chunks,
    }


@router.patch("/{doc_id}/toggle-active", response_model=DocumentResponse)
def toggle_document_active_status(
    doc_id: int,
    toggle_req: DocumentToggleActiveRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_profiles([ProfileType.ATENDENTE_ASA, ProfileType.ADMINISTRADOR])),
):
    """
    Ativa ou desativa um documento institucional da base de conhecimento (RF16).
    Quando desativado, o RAG ignora este documento nas buscas.
    """
    doc = db.query(KnowledgeDocument).filter(KnowledgeDocument.id == doc_id).first()
    if not doc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Documento não encontrado.",
        )

    doc.is_active = toggle_req.is_active
    db.add(doc)
    db.commit()
    db.refresh(doc)

    # Atualiza o índice vetorial em memória
    retriever.build_index(db=db)

    # Auditoria (RF10)
    audit = AuditLog(
        user_id=current_user.id,
        action="DOC_STATUS_TOGGLED",
        details={"doc_id": doc.id, "slug": doc.slug, "is_active": doc.is_active},
    )
    db.add(audit)
    db.commit()

    return doc
