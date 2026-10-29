from typing import List, Optional, Dict, Any
from datetime import datetime, timezone, time
import zoneinfo
from fastapi import APIRouter, Depends, HTTPException, status, Request
from sqlalchemy.orm import Session
from sqlalchemy import desc, func

from app.core.database import get_db
from app.core.security import get_current_user, require_profiles
from app.models.user import User, ProfileType
from app.models.chat import Conversation, ChatMessage, MessageSender
from app.models.escalation import EscalationCase, EscalationStatus, EscalationPriority
from app.models.audit import AuditLog
from app.schemas.escalation import (
    EscalationCreateRequest,
    EscalationResolveRequest,
    EscalationResponse,
    EscalationRateRequest,
    AttendantMessageRequest,
)

router = APIRouter(prefix="/escalations", tags=["Fila de Escalonamento Humano e Senhas (RF08, RF09)"])


def check_asa_operating_hours() -> Dict[str, Any]:
    """
    Verifica se a ouvidoria/balcão do ASA está aberta no horário de Brasília:
    - Seg a Sex: 09h00 às 21h00
    - Sábado: 09h00 às 12h30
    - Domingo / Feriado: Fechado
    """
    from datetime import timedelta
    tz_brasilia = timezone(timedelta(hours=-3))
    now = datetime.now(timezone.utc).astimezone(tz_brasilia)
    weekday = now.weekday()  # 0=Segunda, ..., 5=Sábado, 6=Domingo
    current_time = now.time()

    is_open = False
    message = "O atendimento humano do ASA encerrou por hoje."
    next_opening = "Segunda-feira às 09h00"

    if weekday in range(0, 5):  # Segunda a Sexta
        if time(9, 0) <= current_time <= time(21, 0):
            is_open = True
            message = "Atendimento do ASA aberto até às 21h00."
        elif current_time < time(9, 0):
            message = "Atendimento do ASA abre hoje às 09h00."
            next_opening = "Hoje às 09h00"
        else:
            if weekday == 4:  # Sexta após 21h
                next_opening = "Amanhã (Sábado) às 09h00"
            else:
                next_opening = "Amanhã às 09h00"
    elif weekday == 5:  # Sábado
        if time(9, 0) <= current_time <= time(12, 30):
            is_open = True
            message = "Atendimento do ASA aberto até às 12h30."
        elif current_time < time(9, 0):
            message = "Atendimento do ASA abre hoje às 09h00."
            next_opening = "Hoje às 09h00"
        else:
            next_opening = "Segunda-feira às 09h00"
    else:  # Domingo
        message = "O ASA não funciona aos domingos."
        next_opening = "Segunda-feira às 09h00"

    return {
        "is_open": is_open,
        "message": message,
        "next_opening": next_opening,
        "schedule": "Seg-Sex: 09h00 às 21h00 | Sáb: 09h00 às 12h30",
        "current_time_str": now.strftime("%H:%M"),
    }


def generate_ticket_number(db: Session, modality: str, priority: EscalationPriority) -> str:
    """
    Gera a sequência diária de senhas:
    P = Presencial, O = Online
    PRI = Prioritário
    Ex: P001, O001, PRI001
    """
    prefix = "P" if modality == "PRESENCIAL" else "O"
    if priority in [EscalationPriority.ALTA, EscalationPriority.URGENTE]:
        prefix = "PRI"

    count = db.query(func.count(EscalationCase.id)).filter(
        EscalationCase.ticket_number.like(f"{prefix}%")
    ).scalar() or 0

    return f"{prefix}{(count + 1):03d}"


@router.get("/status-hours")
def get_operating_status():
    """Retorna o status de abertura do ASA e previsão."""
    return check_asa_operating_hours()


@router.post("", response_model=EscalationResponse)
def create_escalation(
    escalation_req: EscalationCreateRequest,
    request: Request,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Solicita escalonamento e emite senha para atendimento (Presencial ou Online).
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

    # Regra: cada pessoa pode ter apenas 1 senha/chamado ativo por vez (por student_id)
    existing = db.query(EscalationCase).filter(
        EscalationCase.student_id == current_user.id,
        EscalationCase.status.in_([EscalationStatus.PENDENTE, EscalationStatus.EM_ATENDIMENTO]),
    ).first()

    if existing:
        return EscalationResponse(
            id=existing.id,
            ticket_number=existing.ticket_number or "A001",
            modality=existing.modality or "ONLINE",
            conversation_id=existing.conversation_id,
            student_id=existing.student_id,
            student_name=current_user.full_name,
            student_ra=current_user.ra,
            student_email=current_user.email,
            student_course=current_user.course,
            student_semester=current_user.semester,
            student_campus=current_user.campus,
            reason=existing.reason,
            user_notes=existing.user_notes,
            priority=existing.priority,
            status=existing.status,
            resolution_notes=existing.resolution_notes,
            created_at=existing.created_at,
            updated_at=existing.updated_at,
            resolved_at=existing.resolved_at,
        )

    ticket_number = generate_ticket_number(db, escalation_req.modality, escalation_req.priority)

    new_case = EscalationCase(
        conversation_id=conversation.id,
        student_id=current_user.id,
        ticket_number=ticket_number,
        modality=escalation_req.modality,
        reason=escalation_req.reason,
        user_notes=escalation_req.user_notes,
        priority=escalation_req.priority,
        status=EscalationStatus.PENDENTE,
    )
    db.add(new_case)
    db.commit()
    db.refresh(new_case)

    # Auditoria
    audit = AuditLog(
        user_id=current_user.id,
        action="ESCALATION_REQUESTED",
        details={
            "case_id": new_case.id,
            "ticket_number": ticket_number,
            "modality": escalation_req.modality,
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
        ticket_number=new_case.ticket_number,
        modality=new_case.modality,
        conversation_id=new_case.conversation_id,
        student_id=new_case.student_id,
        student_name=current_user.full_name,
        student_ra=current_user.ra,
        student_email=current_user.email,
        student_course=current_user.course,
        student_semester=current_user.semester,
        student_campus=current_user.campus,
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
    today_only: bool = False,
    current_user: User = Depends(require_profiles([ProfileType.ATENDENTE_ASA, ProfileType.ADMINISTRADOR])),
    db: Session = Depends(get_db),
):
    """
    Fila de casos com dados cadastrais completos do estudante (Nome, RA, Email, Curso, Semestre, Campus, Modalidade).
    Filtro 'today_only=True' isola apenas os chamados abertos no dia de hoje (horário de Brasília) para manter a tela limpa.
    """
    from datetime import timedelta
    query = db.query(EscalationCase)
    if status_filter:
        query = query.filter(EscalationCase.status == status_filter)
    
    if today_only:
        tz_brasilia = timezone(timedelta(hours=-3))
        now_br = datetime.now(timezone.utc).astimezone(tz_brasilia)
        start_of_day_br = datetime(now_br.year, now_br.month, now_br.day, 0, 0, 0, tzinfo=tz_brasilia)
        # Convert to UTC naive/aware comparison
        query = query.filter(EscalationCase.created_at >= start_of_day_br.astimezone(timezone.utc).replace(tzinfo=None))
    
    cases = query.order_by(EscalationCase.status, EscalationCase.created_at.desc()).limit(200).all()

    user_ids = {c.student_id for c in cases} | {c.assigned_attendant_id for c in cases if c.assigned_attendant_id}
    users_by_id = {}
    if user_ids:
        users = db.query(User).filter(User.id.in_(user_ids)).all()
        users_by_id = {u.id: u for u in users}

    results = []
    for c in cases:
        student = users_by_id.get(c.student_id)
        attendant = users_by_id.get(c.assigned_attendant_id) if c.assigned_attendant_id else None
        
        results.append(
            EscalationResponse(
                id=c.id,
                ticket_number=c.ticket_number or f"#{c.id:03d}",
                modality=c.modality or "ONLINE",
                conversation_id=c.conversation_id,
                student_id=c.student_id,
                student_name=student.full_name if student else "Aluno",
                student_ra=student.ra if student else None,
                student_email=student.email if student else None,
                student_course=student.course if student else "Ciência da Computação",
                student_semester=student.semester if student else 1,
                student_campus=student.campus if student else "Campus Liberdade",
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
                service_rating=c.service_rating,
                service_rating_comment=c.service_rating_comment,
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
    case = db.query(EscalationCase).filter(EscalationCase.id == case_id).first()
    if not case:
        raise HTTPException(status_code=404, detail="Caso de escalonamento não encontrado.")

    case.status = resolve_req.status
    case.resolution_notes = resolve_req.resolution_notes
    case.resolved_at = datetime.now(timezone.utc)
    case.assigned_attendant_id = current_user.id

    # Envia mensagem do sistema/atendente no chat notificando que o atendimento foi encerrado
    closure_text = f"🔒 O atendimento com o atendente ASA ({current_user.full_name}) foi finalizado.\nResolução: {resolve_req.resolution_notes or 'Chamado resolvido com sucesso.'}"
    sys_msg = ChatMessage(
        conversation_id=case.conversation_id,
        sender=MessageSender.ATTENDANT,
        content=closure_text,
        created_at=datetime.now(timezone.utc),
    )
    db.add(sys_msg)
    db.commit()
    db.refresh(case)

    student = db.query(User).filter(User.id == case.student_id).first()

    return EscalationResponse(
        id=case.id,
        ticket_number=case.ticket_number or f"#{case.id:03d}",
        modality=case.modality or "ONLINE",
        conversation_id=case.conversation_id,
        student_id=case.student_id,
        student_name=student.full_name if student else "Aluno",
        student_ra=student.ra if student else None,
        student_email=student.email if student else None,
        student_course=student.course if student else None,
        student_semester=student.semester if student else None,
        student_campus=student.campus if student else None,
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
        service_rating=case.service_rating,
        service_rating_comment=case.service_rating_comment,
    )


@router.patch("/{case_id}/start", response_model=EscalationResponse)
def start_escalation_attendance(
    case_id: int,
    current_user: User = Depends(require_profiles([ProfileType.ATENDENTE_ASA, ProfileType.ADMINISTRADOR])),
    db: Session = Depends(get_db),
):
    case = db.query(EscalationCase).filter(EscalationCase.id == case_id).first()
    if not case:
        raise HTTPException(status_code=404, detail="Caso de escalonamento não encontrado.")

    case.status = EscalationStatus.EM_ATENDIMENTO
    case.assigned_attendant_id = current_user.id
    db.commit()
    db.refresh(case)

    student = db.query(User).filter(User.id == case.student_id).first()
    return EscalationResponse(
        id=case.id,
        ticket_number=case.ticket_number or f"#{case.id:03d}",
        modality=case.modality or "ONLINE",
        conversation_id=case.conversation_id,
        student_id=case.student_id,
        student_name=student.full_name if student else "Aluno",
        student_ra=student.ra if student else None,
        student_email=student.email if student else None,
        student_course=student.course if student else None,
        student_semester=student.semester if student else None,
        student_campus=student.campus if student else None,
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
        service_rating=case.service_rating,
        service_rating_comment=case.service_rating_comment,
    )


@router.get("/{case_id}/messages")
def get_escalation_messages(
    case_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    case = db.query(EscalationCase).filter(EscalationCase.id == case_id).first()
    if not case:
        raise HTTPException(status_code=404, detail="Caso de escalonamento não encontrado.")

    messages = (
        db.query(ChatMessage)
        .filter(ChatMessage.conversation_id == case.conversation_id)
        .order_by(ChatMessage.created_at.asc())
        .all()
    )

    return [
        {
            "id": m.id,
            "conversation_id": m.conversation_id,
            "sender": m.sender.value,
            "content": m.content,
            "created_at": m.created_at.isoformat(),
        }
        for m in messages
    ]


@router.post("/{case_id}/messages")
def send_attendant_message(
    case_id: int,
    msg_req: AttendantMessageRequest,
    current_user: User = Depends(require_profiles([ProfileType.ATENDENTE_ASA, ProfileType.ADMINISTRADOR])),
    db: Session = Depends(get_db),
):
    case = db.query(EscalationCase).filter(EscalationCase.id == case_id).first()
    if not case:
        raise HTTPException(status_code=404, detail="Caso de escalonamento não encontrado.")

    if case.status == EscalationStatus.PENDENTE:
        case.status = EscalationStatus.EM_ATENDIMENTO
        case.assigned_attendant_id = current_user.id

    msg = ChatMessage(
        conversation_id=case.conversation_id,
        sender=MessageSender.ATTENDANT,
        content=msg_req.content,
        created_at=datetime.now(timezone.utc),
    )
    db.add(msg)
    db.commit()
    db.refresh(msg)

    return {
        "id": msg.id,
        "conversation_id": msg.conversation_id,
        "sender": msg.sender.value,
        "content": msg.content,
        "created_at": msg.created_at.isoformat(),
    }


@router.post("/{case_id}/rate")
def rate_escalation(
    case_id: int,
    rate_req: EscalationRateRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    case = db.query(EscalationCase).filter(EscalationCase.id == case_id).first()
    if not case:
        raise HTTPException(status_code=404, detail="Caso de escalonamento não encontrado.")

    if current_user.profile_type == ProfileType.ALUNO and case.student_id != current_user.id:
        raise HTTPException(status_code=403, detail="Apenas o estudante deste atendimento pode avaliá-lo.")

    if rate_req.rating < 1 or rate_req.rating > 5:
        raise HTTPException(status_code=400, detail="A nota deve ser entre 1 e 5 estrelas.")

    case.service_rating = rate_req.rating
    case.service_rating_comment = rate_req.comment
    db.commit()
    db.refresh(case)

    return {
        "message": "Avaliação registrada com sucesso! Obrigado pelo feedback.",
        "rating": case.service_rating,
        "comment": case.service_rating_comment,
    }


@router.get("/stats/satisfaction")
def get_satisfaction_stats(
    current_user: User = Depends(require_profiles([ProfileType.ADMINISTRADOR, ProfileType.ADMINISTRADOR, ProfileType.ATENDENTE_ASA])),
    db: Session = Depends(get_db),
):
    rated_cases = db.query(EscalationCase).filter(EscalationCase.service_rating.isnot(None)).all()
    total_rated = len(rated_cases)
    
    if total_rated == 0:
        return {
            "average_rating": 0.0,
            "total_rated": 0,
            "distribution": {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
            "csat_percent": 0.0,
        }

    sum_rating = sum(c.service_rating for c in rated_cases)
    avg_rating = round(sum_rating / total_rated, 2)

    distribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0}
    for c in rated_cases:
        if c.service_rating in distribution:
            distribution[c.service_rating] += 1

    satisfied_count = distribution[4] + distribution[5]
    csat_percent = round((satisfied_count / total_rated) * 100, 1)

    return {
        "average_rating": avg_rating,
        "total_rated": total_rated,
        "distribution": distribution,
        "csat_percent": csat_percent,
    }

@router.get("/by-conversation/{conversation_id}", response_model=Optional[EscalationResponse])
def get_escalation_by_conversation(
    conversation_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    case = db.query(EscalationCase).filter(EscalationCase.conversation_id == conversation_id).first()
    if not case:
        return None

    student = db.query(User).filter(User.id == case.student_id).first()
    attendant = db.query(User).filter(User.id == case.assigned_attendant_id).first() if case.assigned_attendant_id else None

    return EscalationResponse(
        id=case.id,
        ticket_number=case.ticket_number or f"#{case.id:03d}",
        modality=case.modality or "ONLINE",
        conversation_id=case.conversation_id,
        student_id=case.student_id,
        student_name=student.full_name if student else "Aluno",
        student_ra=student.ra if student else None,
        student_email=student.email if student else None,
        student_course=student.course if student else None,
        student_semester=student.semester if student else None,
        student_campus=student.campus if student else None,
        assigned_attendant_id=case.assigned_attendant_id,
        assigned_attendant_name=attendant.full_name if attendant else None,
        reason=case.reason,
        user_notes=case.user_notes,
        priority=case.priority,
        status=case.status,
        resolution_notes=case.resolution_notes,
        created_at=case.created_at,
        updated_at=case.updated_at,
        resolved_at=case.resolved_at,
        service_rating=case.service_rating,
        service_rating_comment=case.service_rating_comment,
    )

@router.get("/active-mine", response_model=Optional[EscalationResponse])
def get_my_active_escalation(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    case = db.query(EscalationCase).filter(
        EscalationCase.student_id == current_user.id,
        EscalationCase.status.in_([EscalationStatus.PENDENTE, EscalationStatus.EM_ATENDIMENTO]),
    ).first()
    if not case:
        return None

    student = db.query(User).filter(User.id == case.student_id).first()
    attendant = db.query(User).filter(User.id == case.assigned_attendant_id).first() if case.assigned_attendant_id else None

    return EscalationResponse(
        id=case.id,
        ticket_number=case.ticket_number or f"#{case.id:03d}",
        modality=case.modality or "ONLINE",
        conversation_id=case.conversation_id,
        student_id=case.student_id,
        student_name=student.full_name if student else "Aluno",
        student_ra=student.ra if student else None,
        student_email=student.email if student else None,
        student_course=student.course if student else None,
        student_semester=student.semester if student else None,
        student_campus=student.campus if student else None,
        assigned_attendant_id=case.assigned_attendant_id,
        assigned_attendant_name=attendant.full_name if attendant else None,
        reason=case.reason,
        user_notes=case.user_notes,
        priority=case.priority,
        status=case.status,
        resolution_notes=case.resolution_notes,
        created_at=case.created_at,
        updated_at=case.updated_at,
        resolved_at=case.resolved_at,
        service_rating=case.service_rating,
        service_rating_comment=case.service_rating_comment,
    )
