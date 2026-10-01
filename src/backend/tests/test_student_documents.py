import io
import pytest
from httpx import ASGITransport, AsyncClient
from app.main import app
from app.core.config import settings
from app.core.database import init_db


@pytest.fixture(autouse=True, scope="module")
def ensure_db_tables():
    init_db()


@pytest.mark.asyncio
async def test_student_document_upload_pdf_success():
    """
    Testa o upload de um arquivo PDF válido por um estudante autenticado.
    Verifica persistência, metadados gerados, feedback inteligente e status 200.
    """
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        # Login como Estudante (RA 123456)
        login_resp = await client.post(
            f"{settings.API_V1_PREFIX}/auth/login",
            json={"ra_or_email": "123456", "password": "senha123"},
        )
        assert login_resp.status_code == 200
        token = login_resp.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        # Simula arquivo PDF de Comprovante de Matrícula
        pdf_content = b"%PDF-1.4 ... Fake PDF Content for Matricula FECAP ..."
        files = {
            "file": ("Comprovante_Matricula_2024.pdf", io.BytesIO(pdf_content), "application/pdf")
        }
        data = {"category": "Matrícula"}

        upload_resp = await client.post(
            f"{settings.API_V1_PREFIX}/documents/upload",
            headers=headers,
            files=files,
            data=data,
        )
        assert upload_resp.status_code == 200
        resp_json = upload_resp.json()
        assert "document" in resp_json
        assert resp_json["document"]["original_filename"] == "Comprovante_Matricula_2024.pdf"
        assert resp_json["document"]["category"] == "Matrícula"
        assert resp_json["document"]["status"] == "RECEBIDO"
        assert "Comprovante institucional identificado" in resp_json["ai_feedback"]

        doc_id = resp_json["document"]["id"]

        # Verifica se o documento agora aparece em /my-documents
        my_docs_resp = await client.get(
            f"{settings.API_V1_PREFIX}/documents/my-documents",
            headers=headers,
        )
        assert my_docs_resp.status_code == 200
        docs_list = my_docs_resp.json()
        assert any(d["id"] == doc_id for d in docs_list)

        # Testa download do documento
        dl_resp = await client.get(
            f"{settings.API_V1_PREFIX}/documents/download/{doc_id}",
            headers=headers,
        )
        assert dl_resp.status_code == 200
        assert dl_resp.content == pdf_content


@pytest.mark.asyncio
async def test_student_document_upload_image_success():
    """
    Testa o upload de uma imagem (PNG/JPG) válida por um estudante.
    """
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        login_resp = await client.post(
            f"{settings.API_V1_PREFIX}/auth/login",
            json={"ra_or_email": "123456", "password": "senha123"},
        )
        token = login_resp.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        img_content = b"\x89PNG\r\n\x1a\nFake PNG Bytes"
        files = {
            "file": ("foto_documento_rg.png", io.BytesIO(img_content), "image/png")
        }
        data = {"category": "Documentos"}

        upload_resp = await client.post(
            f"{settings.API_V1_PREFIX}/documents/upload",
            headers=headers,
            files=files,
            data=data,
        )
        assert upload_resp.status_code == 200
        resp_json = upload_resp.json()
        assert resp_json["document"]["original_filename"] == "foto_documento_rg.png"
        assert resp_json["document"]["mime_type"] == "image/png"


@pytest.mark.asyncio
async def test_student_document_upload_invalid_extension():
    """
    Valida a rejeição imediata (HTTP 400) de formatos executáveis ou não suportados.
    """
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        login_resp = await client.post(
            f"{settings.API_V1_PREFIX}/auth/login",
            json={"ra_or_email": "123456", "password": "senha123"},
        )
        token = login_resp.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        files = {
            "file": ("malware_script.exe", io.BytesIO(b"MZ executable bytes"), "application/x-msdownload")
        }
        upload_resp = await client.post(
            f"{settings.API_V1_PREFIX}/documents/upload",
            headers=headers,
            files=files,
            data={"category": "Geral"},
        )
        assert upload_resp.status_code == 400
        assert "Formato de arquivo '.exe' não suportado" in upload_resp.json()["detail"]


@pytest.mark.asyncio
async def test_student_document_upload_exceeds_size_limit():
    """
    Valida a rejeição de arquivos que ultrapassam o limite de 10 MB.
    """
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        login_resp = await client.post(
            f"{settings.API_V1_PREFIX}/auth/login",
            json={"ra_or_email": "123456", "password": "senha123"},
        )
        token = login_resp.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        # 11 MB de conteúdo
        large_content = b"0" * (11 * 1024 * 1024)
        files = {
            "file": ("arquivo_gigante.pdf", io.BytesIO(large_content), "application/pdf")
        }
        upload_resp = await client.post(
            f"{settings.API_V1_PREFIX}/documents/upload",
            headers=headers,
            files=files,
        )
        assert upload_resp.status_code == 400
        assert "excede o limite máximo" in upload_resp.json()["detail"]


@pytest.mark.asyncio
async def test_student_documents_data_isolation():
    """
    Garante o isolamento de dados: o estudante B não pode visualizar ou baixar
    os documentos confidenciais enviados pelo estudante A.
    """
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        # Login Estudante A (123456)
        login_a = await client.post(
            f"{settings.API_V1_PREFIX}/auth/login",
            json={"ra_or_email": "123456", "password": "senha123"},
        )
        token_a = login_a.json()["access_token"]
        headers_a = {"Authorization": f"Bearer {token_a}"}

        # Estudante A faz upload
        files = {"file": ("doc_aluno_a.pdf", io.BytesIO(b"Dados Confidenciais A"), "application/pdf")}
        up_a = await client.post(
            f"{settings.API_V1_PREFIX}/documents/upload",
            headers=headers_a,
            files=files,
        )
        doc_id_a = up_a.json()["document"]["id"]

        # Login Atendente (para teste de acesso autorizado)
        login_att = await client.post(
            f"{settings.API_V1_PREFIX}/auth/login",
            json={"ra_or_email": "atendente@fecap.br", "password": "senha123"},
        )
        token_att = login_att.json()["access_token"]
        headers_att = {"Authorization": f"Bearer {token_att}"}

        # Atendente do ASA tem permissão para baixar o documento do aluno
        dl_att = await client.get(
            f"{settings.API_V1_PREFIX}/documents/download/{doc_id_a}",
            headers=headers_att,
        )
        assert dl_att.status_code == 200
        assert dl_att.content == b"Dados Confidenciais A"
