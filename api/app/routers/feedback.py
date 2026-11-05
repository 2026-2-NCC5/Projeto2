from fastapi import APIRouter, Depends, HTTPException, status, Request
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import get_current_user
from app.models.user import User
from app.models.chat import ChatMessage, Conversation
from app.models.feedback import MessageFeedback
from app.models.audit import AuditLog
from app.schemas.feedback import FeedbackCreateRequest, FeedbackResponse

router = APIRouter(prefix="/feedback", tags=["Feedback de Mensagens (RF17)"])


@router.post("", response_model=FeedbackResponse)
def submit_feedback(
    feedback_data: FeedbackCreateRequest,
    request: Request,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Registra avaliação de utilidade da resposta do agente (Útil / Não Útil) (RF17).
    """
    # Verifica se a mensagem existe
    message = db.query(ChatMessage).filter(ChatMessage.id == feedback_data.message_id).first()
    if not message:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Mensagem não encontrada para registrar feedback.",
        )

    # Verifica se a conversa pertence ao usuário
    conversation = db.query(Conversation).filter(
        Conversation.id == message.conversation_id,
        Conversation.user_id == current_user.id,
    ).first()
    if not conversation:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Não autorizado a avaliar mensagens de outro estudante.",
        )

    # Cria ou atualiza feedback existente
    existing_feedback = db.query(MessageFeedback).filter(
        MessageFeedback.message_id == feedback_data.message_id,
        MessageFeedback.user_id == current_user.id,
    ).first()

    if existing_feedback:
        existing_feedback.is_helpful = feedback_data.is_helpful
        existing_feedback.comment = feedback_data.comment
        db.add(existing_feedback)
        db.commit()
        db.refresh(existing_feedback)
        saved_feedback = existing_feedback
    else:
        new_feedback = MessageFeedback(
            message_id=feedback_data.message_id,
            user_id=current_user.id,
            is_helpful=feedback_data.is_helpful,
            comment=feedback_data.comment,
        )
        db.add(new_feedback)
        db.commit()
        db.refresh(new_feedback)
        saved_feedback = new_feedback

    # Auditoria (RF10)
    audit = AuditLog(
        user_id=current_user.id,
        action="MESSAGE_FEEDBACK",
        details={
            "message_id": feedback_data.message_id,
            "is_helpful": feedback_data.is_helpful,
            "has_comment": bool(feedback_data.comment),
        },
        ip_address=request.client.host if request.client else None,
    )
    db.add(audit)
    db.commit()

    return saved_feedback
