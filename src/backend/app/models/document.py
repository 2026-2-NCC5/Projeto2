from datetime import datetime, timezone
from sqlalchemy import Column, Integer, String, Boolean, DateTime, Text
from app.core.database import Base


class KnowledgeDocument(Base):
    __tablename__ = "knowledge_documents"

    id = Column(Integer, primary_key=True, index=True)
    slug = Column(String(100), unique=True, index=True, nullable=False)
    title = Column(String(200), nullable=False)
    category = Column(String(100), index=True, nullable=False)  # Acadêmico, Financeiro, Estágio, etc.
    file_path = Column(String(255), nullable=False)
    official_source = Column(String(200), nullable=False)  # Ex: "Secretaria Geral / Manual do Aluno 2024"
    section = Column(String(150), nullable=False)  # Ex: "Capítulo 4 - Emissão de Documentos"
    version = Column(String(50), default="v1.0", nullable=False)
    content_hash = Column(String(64), nullable=True)  # Hash SHA-256 para controle de versão
    summary = Column(Text, nullable=True)
    is_active = Column(Boolean, default=True, nullable=False)  # RF16 - Ativar/desativar documento

    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc), nullable=False)
