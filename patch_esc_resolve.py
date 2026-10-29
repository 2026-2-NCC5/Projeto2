path = r'src\backend\app\routers\escalations.py'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Fix current_user.profile -> current_user.profile_type
content = content.replace("current_user.profile == ProfileType.ALUNO", "current_user.profile_type == ProfileType.ALUNO")

# In resolve_escalation, add a system ChatMessage into the conversation
old_resolve_body = """    case.status = resolve_req.status
    case.resolution_notes = resolve_req.resolution_notes
    case.resolved_at = datetime.now(timezone.utc)
    case.assigned_attendant_id = current_user.id
    db.commit()
    db.refresh(case)"""

new_resolve_body = """    case.status = resolve_req.status
    case.resolution_notes = resolve_req.resolution_notes
    case.resolved_at = datetime.now(timezone.utc)
    case.assigned_attendant_id = current_user.id

    # Envia mensagem do sistema/atendente no chat notificando que o atendimento foi encerrado
    closure_text = f"🔒 O atendimento com o atendente ASA ({current_user.full_name}) foi finalizado.\\nResolução: {resolve_req.resolution_notes or 'Chamado resolvido com sucesso.'}"
    sys_msg = ChatMessage(
        conversation_id=case.conversation_id,
        sender=MessageSender.ATTENDANT,
        content=closure_text,
        created_at=datetime.now(timezone.utc),
    )
    db.add(sys_msg)
    db.commit()
    db.refresh(case)"""

content = content.replace(old_resolve_body, new_resolve_body)

# Add endpoint GET /escalations/by-conversation/{conversation_id}
by_conv_endpoint = """
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
"""

content += by_conv_endpoint

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Updated escalations.py successfully with resolve notice, fix profile_type, and by-conversation endpoint')
