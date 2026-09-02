import pytest
from httpx import ASGITransport, AsyncClient
from app.main import app
from app.core.config import settings
from app.agent.retriever import retriever
from app.agent.rag_pipeline import rag_pipeline
from app.agent.abstention import should_abstain
from app.core.database import SessionLocal


def test_retriever_indexing():
    """Valida a indexação dos documentos oficiais em Markdown."""
    db = SessionLocal()
    try:
        chunks_count = retriever.build_index(db=db)
        assert retriever.indexed_docs_count >= 8
        assert chunks_count > 0
        assert len(retriever.chunks) == chunks_count
    finally:
        db.close()


def test_rag_semantic_retrieval_atestado():
    """Valida recuperação do atestado de matrícula para pergunta típica de aluno."""
    results = retriever.retrieve("Como faço para solicitar meu atestado de matrícula no portal?", top_k=3)
    assert len(results) > 0
    top = results[0]
    assert top["chunk"]["document_slug"] == "atestado_matricula"
    assert top["similarity"] >= 0.50


def test_rag_pipeline_answer_and_citation():
    """Valida resposta do pipeline com formato exato do chip de fonte."""
    ans = rag_pipeline.answer_query("Como solicitar atestado de matrícula?")
    assert ans["is_abstained"] is False
    assert "Fonte: Atestado de Matrícula" in ans["source_citation"]
    assert "atualizado em" in ans["source_citation"]
    assert ans["confidence_score"] >= 0.60
    assert "Secretaria" in ans["suggested_action"]


def test_rag_abstention_on_out_of_scope_query():
    """
    Validação de Equidade e Não-Alucinação:
    Uma pergunta fora do escopo institucional regulamentado (ex: cardápio de restaurante)
    deve acionar o estado de abstenção (is_abstained=True).
    """
    ans = rag_pipeline.answer_query("Qual o preço do pastel de carne na feira do bairro?")
    assert ans["is_abstained"] is True
    assert ans["confidence_score"] < 0.60
    assert "Não encontrei uma informação oficial" in ans["content"]
    assert "atendente" in ans["content"]


@pytest.mark.asyncio
async def test_documents_api_endpoints():
    """Valida os endpoints REST de listagem e detalhe de documentos (RF03, RF16)."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        # Login como aluno
        login_resp = await client.post(
            f"{settings.API_V1_PREFIX}/auth/login",
            json={"ra_or_email": "123456", "password": "senha123"},
        )
        token = login_resp.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        # 1. Listar documentos
        docs_resp = await client.get(f"{settings.API_V1_PREFIX}/documents", headers=headers)
        assert docs_resp.status_code == 200
        docs_list = docs_resp.json()
        assert len(docs_list) >= 8

        # 2. Obter detalhe do atestado
        detail_resp = await client.get(
            f"{settings.API_V1_PREFIX}/documents/atestado_matricula",
            headers=headers,
        )
        assert detail_resp.status_code == 200
        data = detail_resp.json()
        assert data["slug"] == "atestado_matricula"
        assert "QR Code" in data["content"]
