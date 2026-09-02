import pytest
from httpx import ASGITransport, AsyncClient
from app.main import app
from app.core.config import settings


@pytest.mark.asyncio
async def test_health_check_endpoint():
    """Verifica se o endpoint de healthcheck responde com status 200 e json esperado."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"
        assert data["app"] == settings.APP_NAME
        assert data["version"] == settings.APP_VERSION


@pytest.mark.asyncio
async def test_root_endpoint():
    """Verifica se o endpoint raiz responde com boas-vindas e links."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/")
        assert response.status_code == 200
        data = response.json()
        assert "ASA Connect+" in data["message"]
        assert data["docs"] == "/docs"
