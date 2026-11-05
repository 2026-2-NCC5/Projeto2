import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.core.database import Base
from app.models import (
    User,
    ProfileType,
    KnowledgeDocument,
    Conversation,
    ChatMessage,
    MessageSender,
    MessageFeedback,
    EscalationCase,
    EscalationStatus,
    EscalationPriority,
    AuditLog,
)

# Test in-memory SQLite database
TEST_SQLALCHEMY_DATABASE_URL = "sqlite:///:memory:"


@pytest.fixture
def db_session():
    engine = create_engine(TEST_SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})
    Base.metadata.create_all(bind=engine)
    TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    session = TestingSessionLocal()
    try:
        yield session
    finally:
        session.close()
        Base.metadata.drop_all(bind=engine)


def test_create_user_and_profile(db_session):
    user = User(
        ra_or_email="123456",
        email="aluno@fecap.br",
        full_name="Aluno Teste Alvarista",
        hashed_password="hashed_secret_test",
        profile_type=ProfileType.ALUNO,
        ra="123456",
        course="Ciência da Computação",
        semester=5,
    )
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)

    assert user.id is not None
    assert user.profile_type == ProfileType.ALUNO
    assert user.is_active is True


def test_conversation_and_messages_with_rag_metadata(db_session):
    user = User(
        ra_or_email="aluno@fecap.br",
        full_name="Aluno Teste",
        hashed_password="hash",
        profile_type=ProfileType.ALUNO,
    )
    db_session.add(user)
    db_session.commit()

    conversation = Conversation(user_id=user.id, title="Atestado de Matrícula")
    db_session.add(conversation)
    db_session.commit()

    user_msg = ChatMessage(
        conversation_id=conversation.id,
        sender=MessageSender.USER,
        content="Como solicitar atestado de matrícula?",
    )
    agent_msg = ChatMessage(
        conversation_id=conversation.id,
        sender=MessageSender.AGENT,
        content="Para solicitar seu atestado, acesse o Portal no menu Secretaria.",
        is_abstained=False,
        confidence_score=0.88,
        threshold_used=0.60,
        source_citation="Fonte: Manual do Aluno 2024 · Cap. 4 · atualizado em 15/10/2024",
        retrieved_chunks=[{"doc": "atestado_matricula.md", "similarity": 0.88}],
        agent_version="asa-rag-v1.0",
    )
    db_session.add_all([user_msg, agent_msg])
    db_session.commit()

    # Verifica feedbacks
    feedback = MessageFeedback(
        message_id=agent_msg.id,
        user_id=user.id,
        is_helpful=True,
        comment="Resposta clara e rápida!",
    )
    db_session.add(feedback)
    db_session.commit()

    # Verifica escalonamento
    escalation = EscalationCase(
        conversation_id=conversation.id,
        student_id=user.id,
        reason="Dúvida pontual",
        status=EscalationStatus.PENDENTE,
        priority=EscalationPriority.MEDIA,
    )
    db_session.add(escalation)
    db_session.commit()

    # Validações dos relacionamentos
    db_session.refresh(conversation)
    assert len(conversation.messages) == 2
    assert conversation.messages[1].feedback.is_helpful is True
    assert conversation.escalation_case.status == EscalationStatus.PENDENTE
