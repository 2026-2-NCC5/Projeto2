# Sistemas Operacionais e Computação em Nuvem — Entrega 2  
## ASA Connect+ — Deploy, Observabilidade, Segurança e Desempenho

**Curso:** Ciência da Computação — FECAP  
**Projeto:** ASA Connect+ (Área de Sucesso Alvarista)  
**Entrega:** 2 — Final (4,0 pontos) | Prazo: 06/11/2026  
**Repositório:** `src/backend/` — ASA Connect API (FastAPI + PostgreSQL)

---

## 1. Visão Geral da Solução

O ASA Connect+ é um agente conversacional inteligente para suporte acadêmico da FECAP, composto por:

| Componente | Tecnologia | Função |
|---|---|---|
| **API FastAPI** | Python 3.12 + Uvicorn | Backend REST + RAG |
| **Banco de Dados** | PostgreSQL 16 | Persistência de dados |
| **Frontend** | Flutter Web (via `/static`) | Interface do aluno |
| **Agente RAG** | scikit-learn + Gemini | Respostas contextuais |
| **Monitoramento** | Prometheus + Grafana | Métricas e alertas |

---

## 2. Empacotamento Docker — Multi-stage Build

### 2.1 Dockerfile (`src/backend/Dockerfile`)

A imagem foi refatorada com **build multi-stage** para reduzir o tamanho final e melhorar a segurança:

```dockerfile
# Stage 1: Builder — compila dependências (psycopg2, numpy, scikit-learn)
FROM python:3.12-slim AS builder
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# Stage 2: Production — imagem mínima com usuário não-root
FROM python:3.12-slim AS production
COPY --from=builder /install /usr/local
USER appuser          # nunca roda como root
EXPOSE 8080
HEALTHCHECK CMD curl -f http://localhost:8080/health || exit 1
```

**Benefícios:**
- Imagem final ~60% menor (sem compiladores)
- Usuário `appuser` (não-root) → menor superfície de ataque
- `HEALTHCHECK` integrado → Docker reinicia automaticamente se falhar

### 2.2 Variáveis de Ambiente

Todas as configurações sensíveis são gerenciadas por variáveis de ambiente, **nunca hardcoded**:

| Variável | Descrição | Fonte |
|---|---|---|
| `DATABASE_URL` | String de conexão PostgreSQL | `.env.prod` |
| `JWT_SECRET_KEY` | Chave de assinatura JWT (32+ bytes) | Secret seguro |
| `GEMINI_API_KEY` | Chave da API Google Gemini | Secret seguro |
| `POSTGRES_PASSWORD` | Senha do banco | `.env.prod` |
| `ENABLE_METRICS` | Habilita endpoint `/metrics` | `.env.prod` |

> **Gestão de Segredos em Produção (Fly.io):**  
> `fly secrets set JWT_SECRET_KEY=... GEMINI_API_KEY=...`  
> Os segredos são criptografados em repouso e jamais aparecem em logs.

---

## 3. Infraestrutura de Deploy

### 3.1 Docker Compose de Produção (`docker-compose.prod.yml`)

Stack completa com 4 serviços:

```
┌─────────────────────────────────────────────────────────┐
│                    Rede: asaconnect_net                 │
│  172.20.0.0/24 — isolada, sem exposição desnecessária   │
│                                                         │
│  ┌──────────┐    ┌────────────┐    ┌──────────────────┐ │
│  │ postgres │◄───│    api     │───►│   prometheus     │ │
│  │  :5432   │    │  :8080     │    │     :9090        │ │
│  └──────────┘    └────────────┘    └────────┬─────────┘ │
│                                             │           │
│                                    ┌────────▼─────────┐ │
│                                    │     grafana      │ │
│                                    │     :3000        │ │
│                                    └──────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

**Pontos de acesso controlado:**

| Serviço | Porta | Acesso |
|---|---|---|
| API | `:8080` | Público (HTTPS via Fly.io) |
| Prometheus | `:9090` | Interno (somente rede Docker) |
| Grafana | `:3000` | Restrito (admin/senha) |
| PostgreSQL | — | Interno apenas |

### 3.2 Deploy em Nuvem — Fly.io (São Paulo - GRU)

Plataforma de deploy escolhida: **Fly.io** — região `gru` (São Paulo), zero cold start.

**Comandos de deploy:**
```bash
# 1. Configurar segredos (uma vez)
fly secrets set JWT_SECRET_KEY=$(openssl rand -hex 32)
fly secrets set GEMINI_API_KEY=<sua-chave>

# 2. Deploy
fly deploy --dockerfile src/backend/Dockerfile

# 3. Verificar status
fly status
fly logs
```

**Endereço de acesso:**  
`https://asa-connect-api.fly.dev`  
- API Docs: `https://asa-connect-api.fly.dev/docs`  
- Health: `https://asa-connect-api.fly.dev/health`  
- Métricas: `https://asa-connect-api.fly.dev/metrics`  
- App Web: `https://asa-connect-api.fly.dev/app`

---

## 4. Observabilidade — Logs, Métricas e Painel

### 4.1 Logs Estruturados (JSON)

A API emite logs em formato **JSON estruturado** via `app/core/logging.py`:

```json
{
  "timestamp": "2026-11-04T21:30:00.123Z",
  "level": "INFO",
  "logger": "app.main",
  "message": "HTTP Request processada",
  "environment": "production",
  "method": "POST",
  "path": "/api/v1/chat/message",
  "status_code": 200,
  "duration_ms": 342.7,
  "client_ip": "187.45.102.33"
}
```

Campos monitorados em cada requisição:
- `duration_ms` → latência
- `status_code` → taxa de erros
- `path` → endpoint mais utilizado
- `client_ip` → origem do tráfego

### 4.2 Métricas Prometheus (`/metrics`)

A biblioteca `prometheus-fastapi-instrumentator` expõe automaticamente:

| Métrica | Tipo | Descrição |
|---|---|---|
| `http_requests_total` | Counter | Total de requisições por método, path e status |
| `http_request_duration_seconds` | Histogram | Latência (P50/P95/P99) |
| `http_requests_inprogress` | Gauge | Requisições simultâneas em andamento |
| `up` | Gauge | Disponibilidade do serviço (1=online) |

### 4.3 Painel Grafana

Dashboard provisionado automaticamente em `monitoring/grafana/dashboards/asaconnect_api.json`:

**Painéis disponíveis:**

| Painel | Métrica | Alerta |
|---|---|---|
| API Status | `up{job="asaconnect_api"}` | Crítico se offline > 1min |
| Requisições/s | `rate(http_requests_total[5m])` | Aviso se > 100 req/s |
| Latência P95 | `histogram_quantile(0.95, ...)` | Aviso se > 2s |
| Taxa de Erros | `rate(5xx) / rate(total)` | Crítico se > 5% |
| Histórico de Requisições por Status | Gráfico de série temporal | — |
| Latência P50/P95/P99 | Gráfico comparativo | — |

### 4.4 Regras de Alerta Prometheus

Definidas em `monitoring/alert_rules.yml`:

```yaml
- alert: APIDown          # Crítico — API offline > 1 minuto
- alert: HighErrorRate    # Crítico — erros 5xx > 5% por 2 minutos
- alert: HighLatencyP95   # Aviso  — P95 > 2 segundos por 5 minutos
```

---

## 5. Teste de Carga e Análise de Desempenho

### 5.1 Ferramenta: Locust

Arquivo: `tests/load_test.py`

**Perfis de usuário simulados:**

| Perfil | Peso | Comportamento |
|---|---|---|
| `StudentUser` | 70% | Login → Chat RAG (3x) → Perfil (2x) → Health (1x) |
| `AdminUser` | 30% | Login → Dashboard stats (2x) → Escalações (1x) |

**Comando de execução:**
```bash
# Instalar
pip install locust

# Executar (headless, 50 usuários, 2 minutos)
locust -f tests/load_test.py \
       --host http://localhost:8080 \
       --users 50 --spawn-rate 5 \
       --run-time 2m --headless

# Interface Web (abre em http://localhost:8089)
locust -f tests/load_test.py --host http://localhost:8080
```

### 5.2 Resultados Esperados (SLAs Definidos)

| Endpoint | P95 Alvo | Erros Máximos |
|---|---|---|
| `POST /api/v1/auth/login` | < 500ms | < 1% |
| `GET /api/v1/profile/me` | < 200ms | < 1% |
| `POST /api/v1/chat/message` | < 3000ms | < 2% |
| `GET /api/v1/dashboard/stats` | < 500ms | < 1% |
| `GET /health` | < 50ms | 0% |

### 5.3 Gargalos Identificados e Ajustes

| Gargalo | Causa | Ajuste Aplicado |
|---|---|---|
| Latência do chat | Geração LLM + embedding | Cache de embeddings no retriever |
| Inicialização lenta | Indexação RAG no startup | Build de índice assíncrono |
| Concorrência | Workers únicos | `--workers 2` no Uvicorn |
| Memória | numpy/scikit-learn | Limite de 1GB no compose |

---

## 6. Segurança

### 6.1 Autenticação e Autorização

- **JWT Bearer Token** (HS256, expiração 24h) em todos os endpoints protegidos
- **bcrypt** para hash de senhas (`passlib[bcrypt]`)
- **RBAC** via `require_profiles()`: 6 perfis (Aluno, Responsável, Professor, Colaborador, Atendente, Admin)
- **Auditoria**: `AuditLog` registra ações sensíveis no banco

### 6.2 Controle de Acesso por Endpoint

| Endpoint | Perfis Autorizados |
|---|---|
| `POST /auth/login` | Público |
| `GET /profile/me` | Todos autenticados |
| `POST /chat/message` | Aluno, Responsável, Professor, Colaborador |
| `GET /dashboard/stats` | Atendente, Admin |
| `POST /documents/` | Atendente, Admin |

### 6.3 Gestão de Segredos

```
Desenvolvimento  → .env local (nunca commitado)
Docker Compose   → .env.prod (nunca commitado, .gitignore)
Fly.io Produção  → fly secrets (criptografados, auditados)
```

Arquivo `.gitignore` garante que arquivos sensíveis não sejam versionados:
```
.env
.env.prod
*.db
```

### 6.4 Segurança de Rede

- PostgreSQL: **sem porta exposta** externamente no docker-compose.prod.yml
- Prometheus: acesso somente na rede interna `asaconnect_net`
- API: HTTPS forçado no Fly.io (`force_https = true`)
- Usuário Docker não-root (`appuser`)

---

## 7. Backup e Recuperação

### 7.1 Estratégia de Backup

| Aspecto | Configuração |
|---|---|
| Frequência sugerida | Diário às 02:00 (cron no host) |
| Formato | PostgreSQL dump comprimido (`.sql.gz`) |
| Retenção | 7 dias (remoção automática) |
| Destino | Volume Docker `postgres_backups:/backups` |

### 7.2 Executar Backup

```bash
# Backup manual
docker compose -f docker-compose.prod.yml \
  --profile backup --env-file .env.prod \
  run --rm backup

# Exemplo de saída:
# OK Backup criado: /backups/asaconnect_20261104_020000.sql.gz (2.1M)
# OK Backups com mais de 7 dias removidos.
```

### 7.3 Restaurar Backup

```bash
docker compose -f docker-compose.prod.yml run --rm backup \
  sh /restore.sh /backups/asaconnect_20261104_020000.sql.gz
```

### 7.4 RTO e RPO

| Métrica | Valor | Explicação |
|---|---|---|
| **RPO** (Ponto de Recuperação) | ≤ 24 horas | Perda máxima = 1 dia de dados (backup diário) |
| **RTO** (Tempo de Recuperação) | ≤ 15 minutos | Tempo para restaurar backup + reiniciar containers |

---

## 8. Estrutura Final de Arquivos (Entrega 2)

```
src/backend/
├── app/
│   ├── core/
│   │   ├── logging.py          ← Logs JSON estruturados
│   │   ├── security.py         ← JWT + bcrypt + RBAC
│   │   └── config.py           ← Variáveis de ambiente
│   ├── agent/                  ← Pipeline RAG
│   ├── routers/
│   │   └── dashboard.py        ← Métricas de negócio (RF11)
│   └── main.py                 ← Prometheus instrumentator + middlewares
├── monitoring/
│   ├── prometheus.yml          ← Coleta de métricas
│   ├── alert_rules.yml         ← Regras de alerta
│   └── grafana/
│       ├── provisioning/       ← Auto-configuração datasource + dashboards
│       └── dashboards/
│           └── asaconnect_api.json  ← Painel visual
├── scripts/
│   ├── backup.sh               ← Backup automático PostgreSQL
│   ├── restore.sh              ← Restauração de backup
│   └── init_db.sql             ← Inicialização do banco
├── tests/
│   └── load_test.py            ← Teste de carga Locust
├── Dockerfile                  ← Multi-stage, usuário não-root
├── docker-compose.prod.yml     ← Stack completa de produção
├── .env.prod.example           ← Template de variáveis (sem valores reais)
├── fly.toml                    ← Deploy Fly.io (São Paulo - GRU)
└── requirements.txt            ← + prometheus-fastapi-instrumentator + locust
```

---

## 9. Comandos de Operação

### Subir stack completa localmente
```bash
cd src/backend
cp .env.prod.example .env.prod
# Preencha os valores em .env.prod
docker compose -f docker-compose.prod.yml --env-file .env.prod up -d --build
```

### Verificar saúde dos serviços
```bash
docker compose -f docker-compose.prod.yml ps
curl http://localhost:8080/health
curl http://localhost:8080/metrics
```

### Ver logs estruturados
```bash
docker logs asaconnect_api --follow
```

### Acessar painéis
- **API Docs:** http://localhost:8080/docs  
- **Prometheus:** http://localhost:9090  
- **Grafana:** http://localhost:3000 (admin / senha configurada)  
- **App Web:** http://localhost:8080/app  

### Executar teste de carga
```bash
pip install locust
locust -f tests/load_test.py --host http://localhost:8080 \
       --users 50 --spawn-rate 5 --run-time 2m --headless
```

---

## 10. Evidências de Funcionamento

| Evidência | Arquivo / Endpoint | Descrição |
|---|---|---|
| Healthcheck | `GET /health` | Retorna status, versão, RAG indexado |
| Logs estruturados | `docker logs asaconnect_api` | JSON com timestamp, método, path, status, latência |
| Métricas Prometheus | `GET /metrics` | Contadores, histogramas, gauges |
| Painel Grafana | `:3000` → Dashboard "ASA Connect+" | Visualização em tempo real |
| Teste de carga | Locust report (stdout/HTML) | P95, throughput, taxa de erros |
| Backup | Volume `postgres_backups` | Arquivo `.sql.gz` datado |
| Deploy nuvem | `https://asa-connect-api.fly.dev` | HTTPS, região São Paulo |

---

*Documento — ASA Connect+ — FECAP*

