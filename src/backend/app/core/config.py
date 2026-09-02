import os
from typing import List
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    APP_NAME: str = "ASA Connect API"
    APP_VERSION: str = "1.0.0"
    API_V1_PREFIX: str = "/api/v1"
    ENVIRONMENT: str = "development"
    LOG_LEVEL: str = "INFO"

    # Banco de Dados
    DATABASE_URL: str = "sqlite:///./asaconnect.db"

    # Segurança & JWT
    JWT_SECRET_KEY: str = "fecap_asa_connect_secret_key_jwt_2025_prod_super_secure_key_alvarista"
    JWT_ALGORITHM: str = "HS256"
    JWT_ACCESS_TOKEN_EXPIRE_MINUTES: int = 1440  # 24 horas

    # RAG Configurações (RF04)
    RAG_CONFIDENCE_THRESHOLD: float = 0.60
    RAG_MAX_CHUNKS: int = 3
    RAG_EMBEDDING_MODEL: str = "all-MiniLM-L6-v2"
    KNOWLEDGE_BASE_DIR: str = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../knowledge_base"))

    # CORS
    CORS_ORIGINS: List[str] = ["*"]

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="allow"
    )


settings = Settings()
