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


class AttendanceModality(str, enum.Enum):
    PRESENCIAL = "PRESENCIAL"
    ONLINE = "ONLINE"


class EscalationPriority(str, enum.Enum):
    BAIXA = "BAIXA"
    MEDIA = "MEDIA"
    ALTA = "ALTA"
    URGENTE = "URGENTE"


class EscalationCase(Base):
    __tablename__ = "escalation_cases"

    id = Column(Integer, primary_key=True, index=True)
    ticket_number = Column(String(20), nullable=True, index=True)  # ex: P001 ou O002
    modality = Column(String(20), default="ONLINE", nullable=False)  # PRESENCIAL ou ONLINE
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
    service_rating = Column(Integer, nullable=True)  # Avaliacao de 1 a 5 estrelas
    service_rating_comment = Column(Text, nullable=True)  # Feedback opcional do aluno

    # Relacionamentos
    conversation = relationship("Conversation", back_populates="escalation_case")
    student = relationship("User", foreign_keys=[student_id], back_populates="escalated_cases")
    assigned_attendant = relationship("User", foreign_keys=[assigned_attendant_id], back_populates="attended_cases")
