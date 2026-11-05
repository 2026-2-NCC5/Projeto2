# =============================================================================
# ASA Connect+ — Dockerfile Multi-stage (Entrega 2)
# Stage 1: builder  — compila dependências pesadas
# Stage 2: production — imagem mínima de runtime com usuário não-root
# =============================================================================

# ── Stage 1: Builder ──────────────────────────────────────────────────────────
FROM python:3.12-slim AS builder

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /build

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt


# ── Stage 2: Production ───────────────────────────────────────────────────────
FROM python:3.12-slim AS production

LABEL maintainer="ASA Connect FECAP <asa@fecap.br>" \
      version="2.0.0" \
      description="ASA Connect+ API — Agente para o Estudante FECAP"

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app \
    PORT=8080 \
    ENABLE_METRICS=true

# Dependências de runtime (libpq + curl para healthcheck)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && addgroup --system appgroup \
    && adduser --system --ingroup appgroup --home /app appuser

WORKDIR /app

# Copia pacotes do builder (evita re-compilação na imagem final)
COPY --from=builder /install /usr/local

# Copia código-fonte
COPY --chown=appuser:appgroup . /app

# Cria diretórios necessários
RUN mkdir -p /app/logs /app/knowledge_base \
    && chown -R appuser:appgroup /app

# Usuário não-root (segurança)
USER appuser

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:${PORT:-8080}/health || exit 1

CMD ["sh", "-c", "exec uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8080} --workers 2 --log-config /dev/null"]
