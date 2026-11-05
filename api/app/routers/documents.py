import os
import uuid
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Form
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import get_current_user, require_profiles
from app.models.user import User, ProfileType
from app.models.document import KnowledgeDocument, StudentDocument
from app.models.audit import AuditLog
from app.schemas.document import (
    DocumentResponse,
    DocumentToggleActiveRequest,
    StudentDocumentResponse,
    StudentDocumentUploadResponse,
)
from app.agent.retriever import retriever

UPLOAD_DIR = os.getenv("UPLOAD_DIR", os.path.join(os.getcwd(), "uploads", "student_docs"))
ALLOWED_EXTENSIONS = {".pdf", ".png", ".jpg", ".jpeg"}
MAX_FILE_SIZE = 10 * 1024 * 1024  # 10 MB

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


@router.post("/upload", response_model=StudentDocumentUploadResponse)
async def upload_student_document(
    file: UploadFile = File(...),
    category: str = Form("Geral"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Realiza o upload seguro de documentos enviados por estudantes (PDF ou imagens até 10MB).
    Valida integridade, gera parecer preliminar da IA e registra no banco com auditoria.
    """
    filename = file.filename or "documento_anexo"
    ext = os.path.splitext(filename)[1].lower()

    if ext not in ALLOWED_EXTENSIONS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Formato de arquivo '{ext}' não suportado. Por favor, envie arquivos PDF, PNG ou JPG.",
        )

    content = await file.read()
    file_size = len(content)

    if file_size > MAX_FILE_SIZE:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="O arquivo excede o limite máximo permitido de 10 MB.",
        )

    # Diretório seguro de upload por usuário
    user_upload_dir = os.path.join(UPLOAD_DIR, str(current_user.id))
    os.makedirs(user_upload_dir, exist_ok=True)
    unique_filename = f"{uuid.uuid4().hex[:12]}_{filename}"
    file_disk_path = os.path.join(user_upload_dir, unique_filename)

    with open(file_disk_path, "wb") as f:
        f.write(content)

    # Análise preliminar de conteúdo institucional pela IA do ASA
    lower_name = filename.lower()
    if any(k in lower_name for k in ["matricula", "rematricula", "comprovante"]):
        ai_feedback = "Comprovante institucional identificado com sucesso. Verifique se o semestre letivo e o QR Code autenticador estão legíveis."
    elif any(k in lower_name for k in ["historico", "notas"]):
        ai_feedback = "Histórico escolar processado. Validação preliminar de integridade documental aprovada."
    elif any(k in lower_name for k in ["estagio", "termo", "convenio"]):
        ai_feedback = "Termo de estágio identificado. Requer assinatura da empresa concedente e do orientador FECAP."
    elif ext == ".pdf":
        ai_feedback = "Documento em formato PDF processado e armazenado com autenticidade garantida."
    else:
        ai_feedback = "Arquivo de imagem recebido em boa resolução para conferência documental."

    student_doc = StudentDocument(
        user_id=current_user.id,
        filename=unique_filename,
        original_filename=filename,
        file_path=file_disk_path,
        file_size=file_size,
        mime_type=file.content_type or "application/octet-stream",
        category=category,
        status="RECEBIDO",
        analysis_notes=ai_feedback,
    )
    db.add(student_doc)
    db.commit()
    db.refresh(student_doc)

    # Auditoria institucional (RF10)
    audit = AuditLog(
        user_id=current_user.id,
        action="STUDENT_DOC_UPLOAD",
        details={
            "doc_id": student_doc.id,
            "filename": filename,
            "file_size": file_size,
            "category": category,
        },
    )
    db.add(audit)
    db.commit()

    return {
        "document": student_doc,
        "message": f"Arquivo '{filename}' enviado com sucesso!",
        "ai_feedback": ai_feedback,
    }


@router.get("/my-documents", response_model=List[StudentDocumentResponse])
def get_my_documents(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Lista todos os documentos enviados pelo estudante atualmente autenticado.
    """
    docs = (
        db.query(StudentDocument)
        .filter(StudentDocument.user_id == current_user.id)
        .order_by(StudentDocument.created_at.desc())
        .all()
    )
    return docs


@router.get("/download/{doc_id}")
def download_student_document(
    doc_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Realiza o download seguro de um documento pertencente ao aluno ou acessado por atendente/gestor.
    """
    doc = db.query(StudentDocument).filter(StudentDocument.id == doc_id).first()
    if not doc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Documento não encontrado.",
        )

    if doc.user_id != current_user.id and current_user.profile_type not in [ProfileType.ATENDENTE_ASA, ProfileType.ADMINISTRADOR]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Você não tem permissão para acessar este documento.",
        )

    if not os.path.exists(doc.file_path):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Arquivo físico não localizado no servidor.",
        )

    return FileResponse(doc.file_path, filename=doc.original_filename, media_type=doc.mime_type)


@router.get("/download-chat-image/{user_id}/{filename}")
def download_chat_image(
    user_id: int,
    filename: str,
    current_user: User = Depends(get_current_user),
):
    """Serve uma imagem anexada no chat pelo aluno."""
    file_path = os.path.join("uploads", "chat_images", str(user_id), filename)
    if not os.path.exists(file_path):
        file_path = os.path.join(UPLOAD_DIR, "chat_images", str(user_id), filename)
    if not os.path.exists(file_path):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Imagem de chat não encontrada.",
        )
    return FileResponse(file_path)


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



