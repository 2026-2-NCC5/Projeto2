import pytest
from httpx import ASGITransport, AsyncClient
from app.main import app
from app.core.config import settings
from app.models.user import ProfileType
from app.core.security import require_profiles


# Endpoint de teste protegido por RBAC (Apenas Atendente e Administrador)
@app.get(f"{settings.API_V1_PREFIX}/test-attendant-only", tags=["Testes RBAC"])
def attendant_only_endpoint(user=pytest.importorskip("fastapi").Depends(require_profiles([ProfileType.ATENDENTE_ASA, ProfileType.ADMINISTRADOR]))):
    return {"message": "Acesso concedido ao painel de atendimento", "user": user.full_name}


@pytest.mark.asyncio
async def test_login_success_with_ra():
    """Valida login de estudante utilizando RA."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.post(
            f"{settings.API_V1_PREFIX}/auth/login",
            json={"ra_or_email": "123456", "password": "senha123"},
        )
        assert response.status_code == 200
        data = response.json()
        assert "access_token" in data
        assert data["token_type"] == "bearer"
        assert data["user"]["full_name"] == "Lucas Alvarista Silva"
        assert data["user"]["profile_type"] == "ALUNO"


@pytest.mark.asyncio
async def test_login_success_with_email():
    """Valida login de estudante utilizando E-mail institucional."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.post(
            f"{settings.API_V1_PREFIX}/auth/login",
            json={"ra_or_email": "aluno@fecap.br", "password": "senha123"},
        )
        assert response.status_code == 200
        data = response.json()
        assert data["user"]["ra"] == "123456"


@pytest.mark.asyncio
async def test_login_invalid_password():
    """Valida rejeição de senha incorreta (401 Unauthorized)."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.post(
            f"{settings.API_V1_PREFIX}/auth/login",
            json={"ra_or_email": "123456", "password": "senha_errada"},
        )
        assert response.status_code == 401
        assert "incorretos" in response.json()["detail"]


@pytest.mark.asyncio
async def test_login_nonexistent_user():
    """Valida rejeição de usuário inexistente."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.post(
            f"{settings.API_V1_PREFIX}/auth/login",
            json={"ra_or_email": "999999", "password": "senha123"},
        )
        assert response.status_code == 401


@pytest.mark.asyncio
async def test_auth_me_and_profile():
    """Valida rota /auth/me e /profile com token válido."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        # 1. Login
        login_resp = await client.post(
            f"{settings.API_V1_PREFIX}/auth/login",
            json={"ra_or_email": "123456", "password": "senha123"},
        )
        token = login_resp.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        # 2. /auth/me
        me_resp = await client.get(f"{settings.API_V1_PREFIX}/auth/me", headers=headers)
        assert me_resp.status_code == 200
        assert me_resp.json()["ra"] == "123456"

        # 3. /profile
        profile_resp = await client.get(f"{settings.API_V1_PREFIX}/profile", headers=headers)
        assert profile_resp.status_code == 200
        assert profile_resp.json()["course"] == "Ciência da Computação"


@pytest.mark.asyncio
async def test_update_profile_accessibility_preferences():
    """Valida atualização das configurações de acessibilidade no perfil (RF02)."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        login_resp = await client.post(
            f"{settings.API_V1_PREFIX}/auth/login",
            json={"ra_or_email": "123456", "password": "senha123"},
        )
        token = login_resp.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        # Atualiza para tamanho de fonte 'large' e alto contraste 'True'
        patch_resp = await client.patch(
            f"{settings.API_V1_PREFIX}/profile",
            headers=headers,
            json={"font_size_factor": "large", "high_contrast": True},
        )
        assert patch_resp.status_code == 200
        data = patch_resp.json()
        assert data["font_size_factor"] == "large"
        assert data["high_contrast"] is True


@pytest.mark.asyncio
async def test_rbac_authorization_restrictions():
    """
    Validação de Segurança / RBAC:
    Garante que um Aluno NÃO consegue acessar rotas exclusivas de Atendente/Admin (403 Forbidden),
    enquanto um Atendente autenticado consegue acessar normalmente (200 OK).
    """
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        # 1. Login como ALUNO
        student_login = await client.post(
            f"{settings.API_V1_PREFIX}/auth/login",
            json={"ra_or_email": "123456", "password": "senha123"},
        )
        student_token = student_login.json()["access_token"]
        student_headers = {"Authorization": f"Bearer {student_token}"}

        # 2. Aluno tenta acessar recurso de atendente -> 403 Forbidden
        denied_resp = await client.get(
            f"{settings.API_V1_PREFIX}/test-attendant-only",
            headers=student_headers,
        )
        assert denied_resp.status_code == 403
        assert "Acesso negado" in denied_resp.json()["detail"]

        # 3. Login como ATENDENTE
        attendant_login = await client.post(
            f"{settings.API_V1_PREFIX}/auth/login",
            json={"ra_or_email": "atendente@fecap.br", "password": "senha123"},
        )
        attendant_token = attendant_login.json()["access_token"]
        attendant_headers = {"Authorization": f"Bearer {attendant_token}"}

        # 4. Atendente acessa recurso de atendente -> 200 OK
        allowed_resp = await client.get(
            f"{settings.API_V1_PREFIX}/test-attendant-only",
            headers=attendant_headers,
        )
        assert allowed_resp.status_code == 200
        assert "Acesso concedido" in allowed_resp.json()["message"]
