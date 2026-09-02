import enum
from datetime import datetime, timezone
from sqlalchemy import Column, Integer, String, Boolean, DateTime, Enum, ForeignKey
from sqlalchemy.orm import relationship
from app.core.database import Base


class ProfileType(str, enum.Enum):
    ALUNO = "ALUNO"
    ATENDENTE_ASA = "ATENDENTE_ASA"
    ADMINISTRADOR = "ADMINISTRADOR"
    PROFESSOR = "PROFESSOR"
    RESPONSAVEL = "RESPONSAVEL"
    COLABORADOR = "COLABORADOR"


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    ra_or_email = Column(String(100), unique=True, index=True, nullable=False)
    email = Column(String(150), unique=True, index=True, nullable=True)
    full_name = Column(String(150), nullable=False)
    hashed_password = Column(String(255), nullable=False)
    profile_type = Column(Enum(ProfileType), default=ProfileType.ALUNO, nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
    
    # Dados acadêmicos específicos (para estudantes)
    ra = Column(String(20), index=True, nullable=True)
    course = Column(String(150), nullable=True, default="Ciência da Computação")
    semester = Column(Integer, nullable=True, default=5)
    campus = Column(String(100), nullable=True, default="Campus Liberdade")
    
    # Preferências do app (acessibilidade / UI)
    font_size_factor = Column(String(20), default="normal", nullable=False)  # small, normal, medium, large
    high_contrast = Column(Boolean, default=False, nullable=False)
    notifications_enabled = Column(Boolean, default=True, nullable=False)

    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc), nullable=False)

    # Relacionamentos
    conversations = relationship("Conversation", back_populates="user", cascade="all, delete-orphan")
    feedbacks = relationship("MessageFeedback", back_populates="user", cascade="all, delete-orphan")
    escalated_cases = relationship("EscalationCase", foreign_keys="[EscalationCase.student_id]", back_populates="student")
    attended_cases = relationship("EscalationCase", foreign_keys="[EscalationCase.assigned_attendant_id]", back_populates="assigned_attendant")
    audit_logs = relationship("AuditLog", back_populates="user")
