import pytest
import base64
from fastapi.testclient import TestClient
from app.main import app
from app.agent.vision_analyzer import vision_analyzer
from app.core.database import SessionLocal, init_db
from app.models.user import User

client = TestClient(app)

@pytest.fixture(scope="module", autouse=True)
def setup_db():
    init_db()


def get_auth_token(ra_or_email="123456", password="senha123"):
    resp = client.post("/api/v1/auth/login", json={"ra_or_email": ra_or_email, "password": password})
    return resp.json()["access_token"]


def test_vision_analyzer_heuristic_rematricula():
    fake_png = b"\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR"
    res = vision_analyzer.analyze_image(
        image_bytes=fake_png,
        user_comment="Não estou conseguindo avançar na rematrícula com a grade",
        filename="print_erro_rematricula.png",
    )
    assert "Rematrícula" in res["screen_title"]
    assert "rematricula" in res["search_query"].lower()
    assert res["confidence"] >= 0.8


def test_vision_analyzer_heuristic_financeiro():
    fake_png = b"\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR"
    res = vision_analyzer.analyze_image(
        image_bytes=fake_png,
        user_comment="Apareceu esse aviso de pendência no boleto",
        filename="erro_boleto_mensalidade.png",
    )
    assert "Financeiro" in res["screen_title"]
    assert "boleto" in res["search_query"].lower()
    assert res["confidence"] >= 0.8


def test_chat_with_image_attachment():
    token = get_auth_token()
    fake_png_b64 = base64.b64encode(b"\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDRfake_image_bytes").decode("utf-8")

    payload = {
        "query": "Estou com esse erro na tela, o que eu faço?",
        "image_base64": fake_png_b64,
        "image_filename": "erro_portal_rematricula.png",
    }

    resp = client.post(
        "/api/v1/chat",
        json=payload,
        headers={"Authorization": f"Bearer {token}"},
    )

    assert resp.status_code == 200
    data = resp.json()
    assert "content" in data
    # Verifica que o agente reconheceu visualmente e não entrou em abstenção indevida
    assert "Análise da Imagem" in data["content"]
    assert "Rematrícula" in data["content"] or "Portal" in data["content"]
    assert data["is_abstained"] is False

    # Valida que a mensagem do usuário gravou a imagem
    conv_id = data["conversation_id"]
    conv_resp = client.get(
        f"/api/v1/chat/conversations/{conv_id}",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert conv_resp.status_code == 200
    conv_data = conv_resp.json()
    user_msgs = [m for m in conv_data["messages"] if m["sender"] == "USER"]
    assert len(user_msgs) > 0
    assert user_msgs[0]["image_url"] is not None
