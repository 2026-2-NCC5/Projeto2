import pytest
from httpx import ASGITransport, AsyncClient
from app.main import app
from app.core.config import settings


@pytest.mark.asyncio
async def test_full_chat_flow_with_rag_and_citation():
    """
    Valida o fluxo completo de chat com o Agente ASA:
    - Envio de pergunta sobre atestado de matrícula
    - Resposta oficial com chip de citação e explicabilidade
    - Listagem no histórico de conversas do estudante
    """
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        # Login como Estudante
        login_resp = await client.post(
            f"{settings.API_V1_PREFIX}/auth/login",
            json={"ra_or_email": "123456", "password": "senha123"},
        )
        token = login_resp.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        # 1. Envia pergunta para o chat
        chat_resp = await client.post(
            f"{settings.API_V1_PREFIX}/chat",
            headers=headers,
            json={"query": "Como posso emitir meu atestado de matrícula?"},
        )
        assert chat_resp.status_code == 200
        msg_data = chat_resp.json()
        
        assert msg_data["sender"] == "AGENT"
        assert msg_data["is_abstained"] is False
        assert "Fonte: Atestado de Matrícula" in msg_data["source_citation"]
        assert len(msg_data["retrieved_chunks"]) > 0
        conv_id = msg_data["conversation_id"]
        msg_id = msg_data["id"]

        # 2. Registra feedback útil (RF17)
        fb_resp = await client.post(
            f"{settings.API_V1_PREFIX}/feedback",
            headers=headers,
            json={"message_id": msg_id, "is_helpful": True, "comment": "Muito bem explicado!"},
        )
        assert fb_resp.status_code == 200
        assert fb_resp.json()["is_helpful"] is True

        # 3. Lista histórico de conversas
        conv_list_resp = await client.get(
            f"{settings.API_V1_PREFIX}/chat/conversations",
            headers=headers,
        )
        assert conv_list_resp.status_code == 200
        convs = conv_list_resp.json()
        assert any(c["id"] == conv_id for c in convs)

        # 4. Detalhe da conversa
        conv_detail_resp = await client.get(
            f"{settings.API_V1_PREFIX}/chat/conversations/{conv_id}",
            headers=headers,
        )
        assert conv_detail_resp.status_code == 200
        detail = conv_detail_resp.json()
        assert len(detail["messages"]) == 2  # Pergunta do usuário + Resposta do agente
        assert detail["messages"][1]["feedback"]["is_helpful"] is True


@pytest.mark.asyncio
async def test_student_data_isolation():
    """
    Teste de Segurança e Privacidade (LGPD / Multi-tenancy):
    Garante que o Estudante B NÃO consegue visualizar as conversas do Estudante A.
    """
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        # Estudante A cria conversa
        login_a = await client.post(
            f"{settings.API_V1_PREFIX}/auth/login",
            json={"ra_or_email": "123456", "password": "senha123"},
        )
        headers_a = {"Authorization": f"Bearer {login_a.json()['access_token']}"}
        chat_a = await client.post(
            f"{settings.API_V1_PREFIX}/chat",
            headers=headers_a,
            json={"query": "Segunda via do boleto de mensalidade"},
        )
        conv_a_id = chat_a.json()["conversation_id"]

        # Estudante B faz login
        login_b = await client.post(
            f"{settings.API_V1_PREFIX}/auth/login",
            json={"ra_or_email": "234567", "password": "senha123"},
        )
        headers_b = {"Authorization": f"Bearer {login_b.json()['access_token']}"}

        # Estudante B tenta acessar a conversa do Estudante A -> Deve ser negado (404/403)
        access_resp = await client.get(
            f"{settings.API_V1_PREFIX}/chat/conversations/{conv_a_id}",
            headers=headers_b,
        )
        assert access_resp.status_code == 404


@pytest.mark.asyncio
async def test_human_escalation_and_attendant_resolution():
    """
    Validação do fluxo de escalonamento humano (RF08, RF09):
    1. Estudante solicita atendimento humano no ASA
    2. Atendente visualiza caso na fila
    3. Atendente atende e resolve registrando justificativa obrigatória
    """
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        # 1. Aluno cria pergunta e escalona
        student_login = await client.post(
            f"{settings.API_V1_PREFIX}/auth/login",
            json={"ra_or_email": "123456", "password": "senha123"},
        )
        student_headers = {"Authorization": f"Bearer {student_login.json()['access_token']}"}
        
        chat_resp = await client.post(
            f"{settings.API_V1_PREFIX}/chat",
            headers=student_headers,
            json={"query": "Dúvida sobre aproveitamento de disciplinas de outra faculdade"},
        )
        conv_id = chat_resp.json()["conversation_id"]

        # Escalonamento para o ASA
        escalate_resp = await client.post(
            f"{settings.API_V1_PREFIX}/escalations",
            headers=student_headers,
            json={
                "conversation_id": conv_id,
                "reason": "Dúvida sobre validação de ementa antiga",
                "user_notes": "Cursei cálculo 1 em 2019 e preciso de análise especial.",
            },
        )
        assert escalate_resp.status_code == 200
        case_data = escalate_resp.json()
        assert case_data["status"] == "PENDENTE"
        case_id = case_data["id"]

        # 2. Atendente faz login e consulta fila (RF09)
        attendant_login = await client.post(
            f"{settings.API_V1_PREFIX}/auth/login",
            json={"ra_or_email": "atendente@fecap.br", "password": "senha123"},
        )
        attendant_headers = {"Authorization": f"Bearer {attendant_login.json()['access_token']}"}

        queue_resp = await client.get(
            f"{settings.API_V1_PREFIX}/escalations",
            headers=attendant_headers,
        )
        assert queue_resp.status_code == 200
        cases = queue_resp.json()
        assert any(c["id"] == case_id for c in cases)

        # 3. Atendente resolve caso com justificativa (RF08)
        resolve_resp = await client.patch(
            f"{settings.API_V1_PREFIX}/escalations/{case_id}/resolve",
            headers=attendant_headers,
            json={
                "status": "RESOLVIDO",
                "resolution_notes": "Orientado o estudante a protocolar o requerimento de aproveitamento de estudos com anexo das ementas originais até o 15º dia de aula.",
            },
        )
        assert resolve_resp.status_code == 200
        resolved_case = resolve_resp.json()
        assert resolved_case["status"] == "RESOLVIDO"
        assert resolved_case["assigned_attendant_name"] == "Mariana Atendente ASA"
        assert "requerimento de aproveitamento" in resolved_case["resolution_notes"]
