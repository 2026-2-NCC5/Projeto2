from typing import List, Optional
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, status, Request
from sqlalchemy.orm import Session
from sqlalchemy import desc

from app.core.database import get_db
from app.core.security import get_current_user, require_profiles
from app.models.user import User, ProfileType
from app.models.chat import Conversation
from app.models.escalation import EscalationCase, EscalationStatus, EscalationPriority
from app.models.audit import AuditLog
from app.schemas.escalation import (
    EscalationCreateRequest,
    EscalationResolveRequest,
    EscalationResponse,
)

router = APIRouter(prefix="/escalations", tags=["Fila de Escalonamento Humano (RF08, RF09)"])


@router.post("", response_model=EscalationResponse)
def create_escalation(
    escalation_req: EscalationCreateRequest,
    request: Request,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Solicita escalonamento da conversa para atendimento humano no ASA ("Falar com o ASA").
    """
    conversation = db.query(Conversation).filter(
        Conversation.id == escalation_req.conversation_id,
        Conversation.user_id == current_user.id,
    ).first()

    if not conversation:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Conversa não encontrada para escalonamento.",
        )

    # Verifica se já existe escalonamento ativo para esta conversa
    existing = db.query(EscalationCase).filter(
        EscalationCase.conversation_id == escalation_req.conversation_id,
        EscalationCase.status.in_([EscalationStatus.PENDENTE, EscalationStatus.EM_ATENDIMENTO]),
    ).first()

    if existing:
        return EscalationResponse(
            id=existing.id,
            conversation_id=existing.conversation_id,
            student_id=existing.student_id,
            student_name=current_user.full_name,
            student_ra=current_user.ra,
            reason=existing.reason,
            user_notes=existing.user_notes,
            priority=existing.priority,
            status=existing.status,
            resolution_notes=existing.resolution_notes,
            created_at=existing.created_at,
            updated_at=existing.updated_at,
            resolved_at=existing.resolved_at,
        )

    new_case = EscalationCase(
        conversation_id=conversation.id,
        student_id=current_user.id,
        reason=escalation_req.reason,
        user_notes=escalation_req.user_notes,
        priority=escalation_req.priority,
        status=EscalationStatus.PENDENTE,
    )
    db.add(new_case)
    db.commit()
    db.refresh(new_case)

    # Auditoria (RF10)
    audit = AuditLog(
        user_id=current_user.id,
        action="ESCALATION_REQUESTED",
        details={
            "case_id": new_case.id,
            "conversation_id": conversation.id,
            "reason": new_case.reason,
            "priority": new_case.priority.value,
        },
        ip_address=request.client.host if request.client else None,
    )
    db.add(audit)
    db.commit()

    return EscalationResponse(
        id=new_case.id,
        conversation_id=new_case.conversation_id,
        student_id=new_case.student_id,
        student_name=current_user.full_name,
        student_ra=current_user.ra,
        reason=new_case.reason,
        user_notes=new_case.user_notes,
        priority=new_case.priority,
        status=new_case.status,
        resolution_notes=new_case.resolution_notes,
        created_at=new_case.created_at,
        updated_at=new_case.updated_at,
        resolved_at=new_case.resolved_at,
    )


@router.get("", response_model=List[EscalationResponse])
def list_escalations(
    status_filter: Optional[EscalationStatus] = None,
    current_user: User = Depends(require_profiles([ProfileType.ATENDENTE_ASA, ProfileType.ADMINISTRADOR])),
    db: Session = Depends(get_db),
):
    """
    Fila de casos escalonados para atendimento humano (RF09).
    Apenas Atendentes do ASA e Administradores.
    """
    query = db.query(EscalationCase)
    if status_filter:
        query = query.filter(EscalationCase.status == status_filter)
    
    # Ordena por prioridade e data de criação
    cases = query.order_by(EscalationCase.status, EscalationCase.created_at.asc()).all()

    results = []
    for c in cases:
        student = db.query(User).filter(User.id == c.student_id).first()
        attendant = db.query(User).filter(User.id == c.assigned_attendant_id).first() if c.assigned_attendant_id else None
        
        results.append(
            EscalationResponse(
                id=c.id,
                conversation_id=c.conversation_id,
                student_id=c.student_id,
                student_name=student.full_name if student else "Aluno",
                student_ra=student.ra if student else None,
                assigned_attendant_id=c.assigned_attendant_id,
                assigned_attendant_name=attendant.full_name if attendant else None,
                reason=c.reason,
                user_notes=c.user_notes,
                priority=c.priority,
                status=c.status,
                resolution_notes=c.resolution_notes,
                created_at=c.created_at,
                updated_at=c.updated_at,
                resolved_at=c.resolved_at,
            )
        )

    return results


@router.patch("/{case_id}/resolve", response_model=EscalationResponse)
def resolve_escalation(
    case_id: int,
    resolve_req: EscalationResolveRequest,
    request: Request,
    current_user: User = Depends(require_profiles([ProfileType.ATENDENTE_ASA, ProfileType.ADMINISTRADOR])),
    db: Session = Depends(get_db),
):
    """
    Atendente resolve um caso escalonado registrando a justificativa de atendimento (RF08).
    """
    case = db.query(EscalationCase).filter(EscalationCase.id == case_id).first()
    if not case:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Caso de escalonamento não encontrado.",
        )

    if not resolve_req.resolution_notes or not resolve_req.resolution_notes.strip():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="É obrigatório informar a justificativa/orientação da resolução (RF08).",
        )

    case.status = resolve_req.status
    case.resolution_notes = resolve_req.resolution_notes.strip()
    case.assigned_attendant_id = current_user.id
    case.resolved_at = datetime.now(timezone.utc)
    case.updated_at = datetime.now(timezone.utc)

    db.add(case)
    db.commit()
    db.refresh(case)

    # Auditoria (RF10)
    audit = AuditLog(
        user_id=current_user.id,
        action="ESCALATION_RESOLVED",
        details={
            "case_id": case.id,
            "conversation_id": case.conversation_id,
            "status": case.status.value,
            "resolution_notes": case.resolution_notes,
            "resolved_by": current_user.full_name,
        },
        ip_address=request.client.host if request.client else None,
    )
    db.add(audit)
    db.commit()

    student = db.query(User).filter(User.id == case.student_id).first()

    return EscalationResponse(
        id=case.id,
        conversation_id=case.conversation_id,
        student_id=case.student_id,
        student_name=student.full_name if student else "Aluno",
        student_ra=student.ra if student else None,
        assigned_attendant_id=case.assigned_attendant_id,
        assigned_attendant_name=current_user.full_name,
        reason=case.reason,
        user_notes=case.user_notes,
        priority=case.priority,
        status=case.status,
        resolution_notes=case.resolution_notes,
        created_at=case.created_at,
        updated_at=case.updated_at,
        resolved_at=case.resolved_at,
    )
