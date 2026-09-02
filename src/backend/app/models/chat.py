import enum
import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, Integer, String, Boolean, Float, DateTime, Enum, ForeignKey, Text, JSON
from sqlalchemy.orm import relationship
from app.core.database import Base


class MessageSender(str, enum.Enum):
    USER = "USER"
    AGENT = "AGENT"
    ATTENDANT = "ATTENDANT"


class Conversation(Base):
    __tablename__ = "conversations"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    title = Column(String(200), default="Nova Conversa", nullable=False)
    
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc), nullable=False)

    # Relacionamentos
    user = relationship("User", back_populates="conversations")
    messages = relationship("ChatMessage", back_populates="conversation", cascade="all, delete-orphan", order_by="ChatMessage.created_at")
    escalation_case = relationship("EscalationCase", back_populates="conversation", uselist=False)


class ChatMessage(Base):
    __tablename__ = "chat_messages"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    conversation_id = Column(String(36), ForeignKey("conversations.id", ondelete="CASCADE"), nullable=False)
    sender = Column(Enum(MessageSender), nullable=False)
    content = Column(Text, nullable=False)

    # Campos de Explicabilidade & RAG (RF06, RF10)
    is_abstained = Column(Boolean, default=False, nullable=False)
    confidence_score = Column(Float, nullable=True)  # Similaridade de cosseno máxima
    threshold_used = Column(Float, nullable=True)   # Limiar de confiança do RAG
    retrieved_chunks = Column(JSON, nullable=True)   # Trechos recuperados e metadados
    source_citation = Column(String(255), nullable=True)  # "Fonte: Manual do Aluno 2024 · Cap. 4..."
    suggested_action = Column(String(255), nullable=True)  # RF07: sugestão de próxima ação
    agent_version = Column(String(50), default="asa-rag-v1.0", nullable=False)

    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)

    # Relacionamentos
    conversation = relationship("Conversation", back_populates="messages")
    feedback = relationship("MessageFeedback", back_populates="message", uselist=False, cascade="all, delete-orphan")
