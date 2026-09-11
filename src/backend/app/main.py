import time
import os
from contextlib import asynccontextmanager
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse

from app.core.config import settings
from app.core.logging import logger
from app.core.database import init_db, SessionLocal
from app.models.user import User, ProfileType
from app.core.security import get_password_hash
from app.agent.retriever import retriever
from app.routers import auth, profile, documents, chat, feedback, escalations, dashboard


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Ciclo de vida da aplicação FastAPI: startup e shutdown."""
    logger.info("Iniciando ASA Connect API...", extra={"extra_data": {"version": settings.APP_VERSION}})
    
    # Inicializa tabelas do banco
    init_db()
    
    db = SessionLocal()
    try:
        # 1. Seed automático de usuários se o banco estiver vazio
        user_count = db.query(User).count()
        if user_count == 0:
            logger.info("Banco vazio detectado. Executando seed inicial de usuários fictícios...")
            initial_users = [
                User(
                    ra_or_email="123456",
                    email="aluno@fecap.br",
                    full_name="Lucas Alvarista Silva",
                    hashed_password=get_password_hash("senha123"),
                    profile_type=ProfileType.ALUNO,
                    ra="123456",
                    course="Ciência da Computação",
                    semester=5,
                    campus="Campus Liberdade",
                ),
                User(
                    ra_or_email="atendente@fecap.br",
                    email="atendente@fecap.br",
                    full_name="Mariana Atendente ASA",
                    hashed_password=get_password_hash("senha123"),
                    profile_type=ProfileType.ATENDENTE_ASA,
                    ra="AT9901",
                    course="Área de Sucesso Alvarista",
                    campus="Campus Liberdade",
                ),
                User(
                    ra_or_email="admin@fecap.br",
                    email="admin@fecap.br",
                    full_name="Coordenação Geral ASA",
                    hashed_password=get_password_hash("senha123"),
                    profile_type=ProfileType.ADMINISTRADOR,
                    ra="ADM001",
                    course="Diretoria Acadêmica",
                    campus="Campus Liberdade",
                ),
            ]
            db.add_all(initial_users)
            db.commit()

        # 2. Constrói e indexa a Base de Conhecimento vetorial RAG
        total_chunks = retriever.build_index(db=db)
        logger.info(
            f"Base de conhecimento RAG indexada com sucesso ({total_chunks} trechos em {retriever.indexed_docs_count} documentos).",
            extra={"extra_data": {"total_chunks": total_chunks, "docs": retriever.indexed_docs_count}},
        )
    except Exception as e:
        logger.error(f"Erro na inicialização: {str(e)}")
    finally:
        db.close()

    yield
    logger.info("Encerrando ASA Connect API...")


app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description="API do Projeto Interdisciplinar FECAP — ASA Connect+ (Agente para o Estudante)",
    openapi_url=f"{settings.API_V1_PREFIX}/openapi.json",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan,
)

# Configuração de CORS para permitir acesso do Flutter / Web
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.middleware("http")
async def log_requests(request: Request, call_next):
    """Middleware de observabilidade para métricas de latência e auditoria de requisições."""
    start_time = time.time()
    response = await call_next(request)
    duration_ms = round((time.time() - start_time) * 1000, 2)
    
    if not request.url.path.startswith(("/docs", "/openapi.json", "/redoc", "/health", "/static")):
        logger.info(
            "HTTP Request processada",
            extra={
                "extra_data": {
                    "method": request.method,
                    "path": request.url.path,
                    "status_code": response.status_code,
                    "duration_ms": duration_ms,
                    "client_ip": request.client.host if request.client else None,
                }
            },
        )
    return response


# Registro de Rotas da API v1
app.include_router(auth.router, prefix=settings.API_V1_PREFIX)
app.include_router(profile.router, prefix=settings.API_V1_PREFIX)
app.include_router(documents.router, prefix=settings.API_V1_PREFIX)
app.include_router(chat.router, prefix=settings.API_V1_PREFIX)
app.include_router(feedback.router, prefix=settings.API_V1_PREFIX)
app.include_router(escalations.router, prefix=settings.API_V1_PREFIX)
app.include_router(dashboard.router, prefix=settings.API_V1_PREFIX)

@app.get("/health", tags=["Sistema"])
async def health_check():
    """Healthcheck simples para monitoramento e docker healthcheck."""
    return {
        "status": "healthy",
        "app": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "environment": settings.ENVIRONMENT,
        "rag_docs_indexed": retriever.indexed_docs_count,
        "rag_chunks_indexed": len(retriever.chunks),
    }


# Monta arquivos e diretórios estáticos do Flutter Web
static_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "static")
if os.path.exists(static_dir):
    app.mount("/static", StaticFiles(directory=static_dir), name="static")
    
    assets_dir = os.path.join(static_dir, "assets")
    if os.path.exists(assets_dir):
        app.mount("/assets", StaticFiles(directory=assets_dir), name="assets")
        
    canvaskit_dir = os.path.join(static_dir, "canvaskit")
    if os.path.exists(canvaskit_dir):
        app.mount("/canvaskit", StaticFiles(directory=canvaskit_dir), name="canvaskit")

    icons_dir = os.path.join(static_dir, "icons")
    if os.path.exists(icons_dir):
        app.mount("/icons", StaticFiles(directory=icons_dir), name="icons")

    @app.get("/{file_name}.js", tags=["Flutter Web"])
    async def serve_root_js(file_name: str):
        target = os.path.join(static_dir, f"{file_name}.js")
        if os.path.exists(target):
            return FileResponse(target, media_type="application/javascript")
        return FileResponse(os.path.join(static_dir, "index.html"))

    @app.get("/{file_name}.json", tags=["Flutter Web"])
    async def serve_root_json(file_name: str):
        target = os.path.join(static_dir, f"{file_name}.json")
        if os.path.exists(target):
            return FileResponse(target, media_type="application/json")
        return FileResponse(os.path.join(static_dir, "index.html"))

    @app.get("/favicon.png", tags=["Flutter Web"])
    async def serve_favicon():
        fav = os.path.join(static_dir, "favicon.png")
        if os.path.exists(fav):
            return FileResponse(fav)
        return FileResponse(os.path.join(static_dir, "index.html"))

    @app.get("/app", tags=["Flutter Web"])
    @app.get("/", tags=["Flutter Web"])
    async def serve_flutter_app():
        """Serve o aplicativo oficial Flutter Web."""
        return FileResponse(os.path.join(static_dir, "index.html"))


