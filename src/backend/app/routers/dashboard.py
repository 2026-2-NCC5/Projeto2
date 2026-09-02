from datetime import datetime, timedelta, timezone
from typing import List
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import func

from app.core.database import get_db
from app.core.security import require_profiles
from app.models.user import User, ProfileType
from app.models.chat import Conversation, ChatMessage, MessageSender
from app.models.feedback import MessageFeedback
from app.models.escalation import EscalationCase, EscalationStatus
from app.models.document import KnowledgeDocument
from app.models.audit import AuditLog
from app.schemas.dashboard import (
    DashboardStatsResponse,
    FeedbackSummary,
    CategoryStat,
    DailyMetric,
)

router = APIRouter(prefix="/dashboard", tags=["Dashboard Gerencial & Observabilidade (RF11)"])


@router.get("/stats", response_model=DashboardStatsResponse)
def get_dashboard_stats(
    current_user: User = Depends(require_profiles([ProfileType.ATENDENTE_ASA, ProfileType.ADMINISTRADOR])),
    db: Session = Depends(get_db),
):
    """
    Retorna indicadores agregados de uso, abstenção e qualidade do agente (RF11).
    Acesso restrito a Atendentes do ASA e Administradores.
    """
    # 1. Métricas de Conversas e Mensagens
    total_conversations = db.query(Conversation).count()
    total_messages = db.query(ChatMessage).count()
    total_agent_messages = db.query(ChatMessage).filter(ChatMessage.sender == MessageSender.AGENT).count()
    total_abstentions = db.query(ChatMessage).filter(
        ChatMessage.sender == MessageSender.AGENT,
        ChatMessage.is_abstained == True,
    ).count()

    abstention_rate = (
        round((total_abstentions / total_agent_messages) * 100, 2)
        if total_agent_messages > 0
        else 0.0
    )

    # 2. Métricas de Escalonamento Humano (RF08, RF09)
    total_escalations = db.query(EscalationCase).count()
    pending_escalations = db.query(EscalationCase).filter(
        EscalationCase.status == EscalationStatus.PENDENTE
    ).count()
    resolved_escalations = db.query(EscalationCase).filter(
        EscalationCase.status == EscalationStatus.RESOLVIDO
    ).count()

    # 3. Métricas de Feedback Útil / Não Útil (RF17)
    total_feedbacks = db.query(MessageFeedback).count()
    helpful_count = db.query(MessageFeedback).filter(MessageFeedback.is_helpful == True).count()
    unhelpful_count = db.query(MessageFeedback).filter(MessageFeedback.is_helpful == False).count()

    satisfaction_rate = (
        round((helpful_count / total_feedbacks) * 100, 2)
        if total_feedbacks > 0
        else 100.0
    )

    feedback_summary = FeedbackSummary(
        total_feedbacks=total_feedbacks,
        helpful_count=helpful_count,
        unhelpful_count=unhelpful_count,
        satisfaction_rate=satisfaction_rate,
    )

    # 4. Distribuição por Categorias da Base de Conhecimento
    doc_categories = db.query(
        KnowledgeDocument.category,
        func.count(KnowledgeDocument.id),
    ).group_by(KnowledgeDocument.category).all()

    total_docs = sum(c[1] for c in doc_categories) if doc_categories else 1
    top_categories = [
        CategoryStat(
            category=cat_name,
            count=count,
            percentage=round((count / total_docs) * 100, 1),
        )
        for cat_name, count in doc_categories
    ]

    # 5. Métricas Diárias dos últimos 7 dias
    daily_metrics = []
    now = datetime.now(timezone.utc)
    for i in range(6, -1, -1):
        day_date = (now - timedelta(days=i)).date()
        day_str = day_date.strftime("%d/%m")
        
        # Filtra mensagens do dia
        day_msgs = db.query(ChatMessage).filter(
            func.date(ChatMessage.created_at) == day_date
        ).count()
        
        day_absts = db.query(ChatMessage).filter(
            func.date(ChatMessage.created_at) == day_date,
            ChatMessage.is_abstained == True,
        ).count()

        daily_metrics.append(
            DailyMetric(
                date=day_str,
                total_messages=day_msgs,
                abstentions=day_absts,
            )
        )

    return DashboardStatsResponse(
        total_conversations=total_conversations,
        total_messages=total_messages,
        total_abstentions=total_abstentions,
        abstention_rate=abstention_rate,
        total_escalations=total_escalations,
        pending_escalations=pending_escalations,
        resolved_escalations=resolved_escalations,
        feedback=feedback_summary,
        top_categories=top_categories,
        daily_metrics=daily_metrics,
    )


@router.get("/audit-logs")
def list_audit_logs(
    limit: int = 50,
    current_user: User = Depends(require_profiles([ProfileType.ATENDENTE_ASA, ProfileType.ADMINISTRADOR])),
    db: Session = Depends(get_db),
):
    """
    Retorna os registros mais recentes de auditoria do sistema (RF10).
    """
    logs = (
        db.query(AuditLog)
        .order_by(AuditLog.created_at.desc())
        .limit(limit)
        .all()
    )

    results = []
    for log in logs:
        user_name = log.user.full_name if log.user else "Sistema"
        results.append({
            "id": log.id,
            "user_id": log.user_id,
            "user_name": user_name,
            "action": log.action,
            "details": log.details,
            "ip_address": log.ip_address,
            "created_at": log.created_at,
        })

    return results
