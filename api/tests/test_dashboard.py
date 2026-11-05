import pytest
from httpx import ASGITransport, AsyncClient
from app.main import app
from app.core.config import settings


@pytest.mark.asyncio
async def test_dashboard_stats_attendant_authorized():
    """Valida acesso às métricas do dashboard pelo perfil de Atendente (RF11)."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        # 1. Login como Atendente
        login_resp = await client.post(
            f"{settings.API_V1_PREFIX}/auth/login",
            json={"ra_or_email": "atendente@fecap.br", "password": "senha123"},
        )
        token = login_resp.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        # 2. Consulta de métricas
        stats_resp = await client.get(
            f"{settings.API_V1_PREFIX}/dashboard/stats",
            headers=headers,
        )
        assert stats_resp.status_code == 200
        data = stats_resp.json()
        assert "total_conversations" in data
        assert "abstention_rate" in data
        assert "feedback" in data
        assert "satisfaction_rate" in data["feedback"]
        assert len(data["top_categories"]) > 0


@pytest.mark.asyncio
async def test_dashboard_stats_student_forbidden():
    """
    Validação de Segurança / RBAC:
    Garante que um Estudante NÃO possui permissão para acessar as métricas do painel gerencial (403 Forbidden).
    """
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        # 1. Login como Estudante
        login_resp = await client.post(
            f"{settings.API_V1_PREFIX}/auth/login",
            json={"ra_or_email": "123456", "password": "senha123"},
        )
        token = login_resp.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        # 2. Tentativa de acesso negada
        stats_resp = await client.get(
            f"{settings.API_V1_PREFIX}/dashboard/stats",
            headers=headers,
        )
        assert stats_resp.status_code == 403
        assert "Acesso negado" in stats_resp.json()["detail"]


@pytest.mark.asyncio
async def test_audit_logs_attendant_access():
    """Valida retorno da trilha de auditoria para perfil autorizado (RF10)."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        login_resp = await client.post(
            f"{settings.API_V1_PREFIX}/auth/login",
            json={"ra_or_email": "atendente@fecap.br", "password": "senha123"},
        )
        token = login_resp.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        logs_resp = await client.get(
            f"{settings.API_V1_PREFIX}/dashboard/audit-logs",
            headers=headers,
        )
        assert logs_resp.status_code == 200
        logs = logs_resp.json()
        assert isinstance(logs, list)
