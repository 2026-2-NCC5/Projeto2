import enum
from datetime import datetime, timezone
from sqlalchemy import Column, Integer, String, DateTime, Enum, ForeignKey, Text
from sqlalchemy.orm import relationship
from app.core.database import Base


class EscalationStatus(str, enum.Enum):
    PENDENTE = "PENDENTE"
    EM_ATENDIMENTO = "EM_ATENDIMENTO"
    RESOLVIDO = "RESOLVIDO"
    CANCELADO = "CANCELADO"


class EscalationPriority(str, enum.Enum):
    BAIXA = "BAIXA"
    MEDIA = "MEDIA"
    ALTA = "ALTA"
    URGENTE = "URGENTE"


class EscalationCase(Base):
    __tablename__ = "escalation_cases"

    id = Column(Integer, primary_key=True, index=True)
    conversation_id = Column(String(36), ForeignKey("conversations.id", ondelete="CASCADE"), nullable=False, unique=True)
    student_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    assigned_attendant_id = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True)

    reason = Column(String(255), nullable=False)  # Motivo do escalonamento (ex: "Abstenção do Agente")
    user_notes = Column(Text, nullable=True)  # Observações ou dúvida adicional enviada pelo estudante
    priority = Column(Enum(EscalationPriority), default=EscalationPriority.MEDIA, nullable=False)
    status = Column(Enum(EscalationStatus), default=EscalationStatus.PENDENTE, nullable=False)
    
    # Justificativa/resolução do atendente (RF08)
    resolution_notes = Column(Text, nullable=True)
    
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc), nullable=False)
    resolved_at = Column(DateTime, nullable=True)

    # Relacionamentos
    conversation = relationship("Conversation", back_populates="escalation_case")
    student = relationship("User", foreign_keys=[student_id], back_populates="escalated_cases")
    assigned_attendant = relationship("User", foreign_keys=[assigned_attendant_id], back_populates="attended_cases")
