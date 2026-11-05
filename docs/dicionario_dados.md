# Dicionário de Dados e Classificação LGPD — ASA Connect+

Dicionário completo das tabelas e atributos relacionais do sistema **ASA Connect+**, com marcação explícita de privacidade, minimização de dados e enquadramento na **Lei Geral de Proteção de Dados (Lei nº 13.709/2018 - LGPD)**.

---

## 1. Política de Privacidade e Minimização de Dados (LGPD)

- **Princípio da Finalidade e Necessidade (Art. 6º, I e III):** Apenas dados estritamente necessários para identificação acadêmica e prestação do serviço de orientação do estudante são processados.
- **Base Legal (Art. 7º, V):** Execução de contrato educacional e procedimentos preliminares a requerimentos solicitados pelo titular.
- **Ambiente Fictício e Anonimizado:** Todos os registros utilizados em desenvolvimento e homologação acadêmica são estritamente fictícios.
- **Direito à Explicabilidade e Informação (Art. 6º, VI):** O titular tem acesso transparente à fonte oficial utilizada pelo agente e aos seus logs de interação.

---

## 2. Tabelas e Atributos

### Tabela `users` (Usuários e Perfis)
Armazena as contas institucionais e permissões de acesso ao sistema (RBAC).

| Coluna | Tipo | Nulo? | Classificação LGPD | Justificativa de Coleta / Minimização |
|---|---|---|---|---|
| `id` | `INTEGER` (PK) | Não | Dado Técnico | Identificador interno do registro. |
| `ra_or_email` | `VARCHAR(100)` | Não | Identificador Acadêmico | Credencial primária para login e autenticação. |
| `email` | `VARCHAR(150)` | Sim | Dado Pessoal | Envio de avisos de atendimento e recuperação de senha. |
| `full_name` | `VARCHAR(150)` | Não | Dado Pessoal | Identificação do estudante/atendente na interface. |
| `hashed_password` | `VARCHAR(255)` | Não | Dado Técnico | Hash criptográfico seguro (Bcrypt); senha original nunca armazenada. |
| `profile_type` | `ENUM` | Não | Dado Técnico | Papel RBAC (`ALUNO`, `ATENDENTE_ASA`, `ADMINISTRADOR`, etc.). |
| `is_active` | `BOOLEAN` | Não | Dado Técnico | Controle de acesso ativo/inativo. |
| `ra` | `VARCHAR(20)` | Sim | Identificador Acadêmico | Matrícula acadêmica para personalização de serviços. |
| `course` | `VARCHAR(150)` | Sim | Dado Acadêmico | Curso do aluno para direcionamento de diretrizes de estágio/AAC. |
| `semester` | `INTEGER` | Sim | Dado Acadêmico | Semestre letivo para verificação de elegibilidade de requerimentos. |
| `campus` | `VARCHAR(100)` | Sim | Dado Acadêmico | Unidade física de referência (ex: Campus Liberdade). |
| `font_size_factor` | `VARCHAR(20)` | Não | Dado de Acessibilidade | Preferência de tamanho de texto para adaptação visual do app. |
| `high_contrast` | `BOOLEAN` | Não | Dado de Acessibilidade | Preferência de alto contraste para conformidade WCAG AA. |
| `notifications_enabled` | `BOOLEAN` | Não | Dado Técnico | Preferência de recebimento de notificações. |
| `created_at` / `updated_at` | `DATETIME` | Não | Dado Técnico | Auditoria temporal do registro. |

---

### Tabela `knowledge_documents` (Documentos da Base de Conhecimento RAG)
Metadados dos regulamentos e manuais institucionais oficiais.

| Coluna | Tipo | Nulo? | Classificação LGPD | Descrição |
|---|---|---|---|---|
| `id` | `INTEGER` (PK) | Não | Dado Institucional | Identificador do documento. |
| `slug` | `VARCHAR(100)` | Não | Dado Institucional | Identificador amigável e único do arquivo. |
| `title` | `VARCHAR(200)` | Não | Dado Institucional | Título normativo oficial. |
| `category` | `VARCHAR(100)` | Não | Dado Institucional | Categoria (Acadêmico, Financeiro, Estágio, etc.). |
| `file_path` | `VARCHAR(255)` | Não | Dado Técnico | Caminho do arquivo `.md` indexado. |
| `official_source` | `VARCHAR(200)` | Não | Dado Institucional | Órgão emissor (ex: Secretaria Geral). |
| `section` | `VARCHAR(150)` | Não | Dado Institucional | Capítulo ou seção do regulamento. |
| `version` | `VARCHAR(50)` | Não | Dado Técnico | Versão normativa do conteúdo. |
| `is_active` | `BOOLEAN` | Não | Dado Técnico | Flag de ativação no índice RAG (RF16). |
| `created_at` / `updated_at` | `DATETIME` | Não | Dado Técnico | Controle de atualização da norma. |

---

### Tabela `conversations` (Conversas)
Sessões de diálogo iniciadas pelos estudantes com o assistente virtual.

| Coluna | Tipo | Nulo? | Classificação LGPD | Justificativa / Descrição |
|---|---|---|---|---|
| `id` | `VARCHAR(36)` (PK) | Não | Dado Técnico | UUID identificador da sessão de chat. |
| `user_id` | `INTEGER` (FK) | Não | Identificador Acadêmico | Vinculação à conta do estudante (segurança multi-tenant). |
| `title` | `VARCHAR(200)` | Não | Dado de Conteúdo | Resumo do tópico da conversa gerado pelo início da pergunta. |
| `created_at` / `updated_at` | `DATETIME` | Não | Dado Técnico | Registro cronológico. |

---

### Tabela `chat_messages` (Mensagens e Explicabilidade RAG)
Registro detalhado das perguntas dos alunos e respostas fundamentadas do agente.

| Coluna | Tipo | Nulo? | Classificação LGPD | Justificativa / Descrição |
|---|---|---|---|---|
| `id` | `VARCHAR(36)` (PK) | Não | Dado Técnico | UUID da mensagem. |
| `conversation_id` | `VARCHAR(36)` (FK)| Não | Dado Técnico | Vínculo com a conversa correspondente. |
| `sender` | `ENUM` | Não | Dado Técnico | Remetente (`USER`, `AGENT`, `ATTENDANT`). |
| `content` | `TEXT` | Não | Dado de Conteúdo | Texto da pergunta ou resposta oficial. |
| `is_abstained` | `BOOLEAN` | Não | Dado de Auditoria | Indica se a resposta foi uma abstenção segura (RF04). |
| `confidence_score` | `FLOAT` | Sim | Dado de Auditoria | Similaridade de cosseno máxima obtida pelo RAG. |
| `threshold_used` | `FLOAT` | Sim | Dado de Auditoria | Limiar de corte vigente na consulta. |
| `retrieved_chunks` | `JSON` | Sim | Dado de Explicabilidade | Trechos e metadados recuperados na base oficial (RF06). |
| `source_citation` | `VARCHAR(255)` | Sim | Dado de Explicabilidade | Citação oficial formatada exibida na interface. |
| `suggested_action` | `VARCHAR(255)` | Sim | Dado de Orientação | Próxima ação recomendada ao estudante (RF07). |
| `agent_version` | `VARCHAR(50)` | Não | Dado Técnico | Versão do pipeline (`asa-rag-v1.0.0`). |
| `created_at` | `DATETIME` | Não | Dado Técnico | Timestamp com fuso horário UTC. |

---

### Tabela `message_feedbacks` (Avaliações de Qualidade - RF17)
Armazena a percepção do estudante sobre a utilidade da resposta.

| Coluna | Tipo | Nulo? | Classificação LGPD | Descrição |
|---|---|---|---|---|
| `id` | `INTEGER` (PK) | Não | Dado Técnico | Identificador da avaliação. |
| `message_id` | `VARCHAR(36)` (FK)| Não | Dado Técnico | Mensagem avaliada. |
| `user_id` | `INTEGER` (FK) | Não | Identificador Acadêmico | Estudante que avaliou. |
| `is_helpful` | `BOOLEAN` | Não | Métrica de Qualidade | `True` = Útil, `False` = Não útil. |
| `comment` | `TEXT` | Sim | Opinião / Feedback | Comentário espontâneo para melhoria contínua. |
| `created_at` | `DATETIME` | Não | Dado Técnico | Data da avaliação. |

---

### Tabela `escalation_cases` (Fila de Atendimento Humano - RF08, RF09)
Casos transferidos para atendimento presencial ou remoto pelo setor do ASA.

| Coluna | Tipo | Nulo? | Classificação LGPD | Descrição |
|---|---|---|---|---|
| `id` | `INTEGER` (PK) | Não | Dado Técnico | Número de protocolo do caso. |
| `conversation_id` | `VARCHAR(36)` (FK)| Não | Dado Técnico | Conversa escalonada. |
| `student_id` | `INTEGER` (FK) | Não | Identificador Acadêmico | Estudante solicitante. |
| `assigned_attendant_id`| `INTEGER` (FK)| Sim | Identificador Profissional | Atendente responsável pelo caso. |
| `reason` | `VARCHAR(255)` | Não | Dado de Suporte | Motivo do escalonamento (abstenção ou solicitação). |
| `user_notes` | `TEXT` | Sim | Dado de Conteúdo | Dúvida complementar informada pelo aluno. |
| `priority` | `ENUM` | Não | Dado Operacional | Prioridade (`BAIXA`, `MEDIA`, `ALTA`, `URGENTE`). |
| `status` | `ENUM` | Não | Dado Operacional | `PENDENTE`, `EM_ATENDIMENTO`, `RESOLVIDO`. |
| `resolution_notes` | `TEXT` | Sim | Dado Operacional | Justificativa e orientação registrada pelo atendente (RF08). |
| `created_at` / `resolved_at` | `DATETIME` | Não/Sim | Dado Técnico | Prazos de SLA e tempo de atendimento. |

---

### Tabela `audit_logs` (Trilha de Auditoria e Rastreabilidade - RF10)
Registro imutável de eventos institucionais para governança e segurança.

| Coluna | Tipo | Nulo? | Classificação LGPD | Descrição |
|---|---|---|---|---|
| `id` | `INTEGER` (PK) | Não | Dado Técnico | Identificador sequencial do log. |
| `user_id` | `INTEGER` (FK) | Sim | Identificador Acadêmico | Usuário que executou a ação. |
| `action` | `VARCHAR(100)` | Não | Dado de Auditoria | Ação (`LOGIN`, `CHAT_QUERY`, `ABSTENTION`, `ESCALATION_RESOLVED`, etc.). |
| `details` | `JSON` | Não | Dado de Auditoria | Contexto estruturado (query, score, versão, ip). |
| `ip_address` | `VARCHAR(50)` | Sim | Dado Técnico / Segurança | Endereço IP do cliente para prevenção de abusos. |
| `created_at` | `DATETIME` | Não | Dado Técnico | Timestamp do evento em UTC. |
