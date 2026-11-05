# Contexto Completo do ASA Connect (Handover de Arquitetura)

Este arquivo foi gerado para contextualizar qualquer desenvolvedor ou assistente de IA (como o **Antigravity**) sobre a arquitetura, implementações e decisões tomadas no projeto.

---

## 1. Repositório e Branches

* **Repositório GitHub Oficial:** `https://github.com/2026-2-NCC5/Projeto2.git`
* **Branch Padrão:** `main`
* **Último Commit Integrado:** `4917e60`
* **Mensagem:** `feat(mobile): integrar design system oficial e layout visual do asa connect`
* **Autor:** `LuanRoccha13 <luanroccha13@gmail.com>`

---

## 2. Estrutura de Arquivos no Repositório

```text
Projeto2/
├── .gitignore                   # Configurado para rastrear src/mobile/lib/
├── README.md
└── src/
    ├── backend/                 # API FastAPI (Python 3.12)
    │   ├── app/
    │   │   ├── api/v1/          # Rotas de auth, chat, docs, tickets
    │   │   ├── core/            # Configurações e segurança (JWT)
    │   │   ├── models/          # Modelos SQLAlchemy / SQLite
    │   │   ├── services/        # Lógica de RAG, embeddings e IA
    │   │   └── main.py          # Ponto de entrada FastAPI
    │   ├── requirements.txt
    │   └── asaconnect.db        # Banco de dados SQLite
    │
    ├── mobile/                  # Frontend Flutter
    │   ├── android/             # Projeto nativo Android
    │   │   ├── app/src/main/AndroidManifest.xml  # Permissão de internet + cleartext
    │   │   ├── build.gradle.kts                  # compileSdk = 36 injetado
    │   │   └── gradle.properties                 # kotlin.incremental=false
    │   ├── assets/              # Logos SVG/PNG e avatares de personas
    │   ├── lib/
    │   │   ├── core/            # constants.dart (tokens de cores e tamanhos), theme.dart
    │   │   ├── models/          # user, chat_message, conversation, escalation, knowledge_doc
    │   │   ├── services/        # api_client, auth_service, chat_service, document_service
    │   │   ├── state/           # auth_provider, chat_provider, accessibility_provider
    │   │   ├── widgets/         # app_header, brand_header, chat bubbles
    │   │   ├── screens/         # splash, profile_selection, auth, home, academic_services, documents, chat
    │   │   └── main.dart
    │   └── pubspec.yaml
    │
    └── notebooks/               # Análises e protótipos de dados
```

---

## 3. Design System & Identidade Visual Implementada

* **Cores Institucionais:**
  * Verde Primário: `#02845E`
  * Verde Profundo: `#006C4C`
  * Verde Ação: `#03A576`
  * Verde Médio: `#128760`
  * Roxo Inteligência / IA: `#845EF2` (escuro: `#653CD2`)
  * Amarelo / Dourado de Destaque: `#FFDE34` / `#C3930C`
  * Fundo da Aplicação: `#F4FBF7`
* **Tokens de Componentes:**
  * `BorderRadius`: 16px arredondado padrão em cartões, botões e campos de texto.
  * `AppHeader`: Cabeçalho padrão com logo institucional, variante de perfil/login flutuante e cabeçalho de chat com indicador online verde pulsante.
  * `ProfileSelectionScreen`: Carrossel limpo horizontal com suporte a swipe (gestos), sem botões inferiores e sem setas laterais `<` `>`, com toque direto nos avatares das personas.
  * `HomeScreen`: TabBar inferior estilizada com 4 abas (Início, Conversas, Serviços, Perfil).

---

## 4. Integração Backend (FastAPI)

* **Porta:** 8000
* **Autenticação:** `/api/v1/auth/login` (retorna `access_token` JWT e payload do usuário).
* **Base de Conhecimento:** `/api/v1/documents` e busca vetorial RAG para respostas no chat acadêmico.
* **Execução:**
  ```powershell
  cd src/backend
  python -m venv .venv
  .venv\Scripts\Activate.ps1
  pip install -r requirements.txt
  uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
  ```
