from typing import Generator
from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker, Session
from app.core.config import settings

# Configura o connect_args se for SQLite
connect_args = {}
if settings.DATABASE_URL.startswith("sqlite"):
    connect_args = {"check_same_thread": False}

engine = create_engine(
    settings.DATABASE_URL,
    connect_args=connect_args,
    pool_pre_ping=True,
    echo=False,
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()


def get_db() -> Generator[Session, None, None]:
    """Dependency do FastAPI para injeção de sessão do banco de dados."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def init_db() -> None:
    """Cria todas as tabelas no banco de dados se não existirem e aplica migrações leves."""
    import app.models  # Garante o registro de todos os modelos
    Base.metadata.create_all(bind=engine)

    from sqlalchemy import text
    migrations = [
        "ALTER TABLE chat_messages ADD COLUMN image_url VARCHAR(500);",
        "ALTER TABLE conversations ADD COLUMN is_deleted_by_user BOOLEAN DEFAULT 0;",
        "ALTER TABLE escalation_cases ADD COLUMN ticket_number VARCHAR(20);",
        "ALTER TABLE escalation_cases ADD COLUMN modality VARCHAR(20) DEFAULT 'ONLINE';",
        "ALTER TABLE escalation_cases ADD COLUMN service_rating INTEGER;",
        "ALTER TABLE escalation_cases ADD COLUMN service_rating_comment TEXT;",
    ]
    with engine.connect() as conn:
        for sql in migrations:
            try:
                conn.execute(text(sql))
                conn.commit()
            except Exception:
                pass
