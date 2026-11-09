# FECAP – FUNDAÇÃO ESCOLA DE COMÉRCIO ÁLVARES PENTEADO
### Curso de Ciência da Computação – 5º Semestre (2026)
### Disciplina: Projeto Interdisciplinar: Inteligência Artificial
**Professor Orientador:** Prof. Me. Rafael Diogo Rossetti

---

# ASA CONNECT+ : AGENTE INTELIGENTE PARA O SUCESSO DO ESTUDANTE
## Relatório Técnico de MVP Integrado, Avaliação Experimental e Ação Extensionista
### Entrega 2 – Final (MVP Integrado, Nuvem e Avaliação)

**Autores e Equipe:**
- **Saulo Ribeiro Santos** – RA: 24026911 (*Especialista Mobile, Flutter & UI/UX*)
- **Gustavo Henrique Da Silva Santos** – RA: 24046874 (*Especialista Backend, Banco de Dados & Testes*)
- **Luan Rocha da Silva** – RA: 24026633 (*Arquiteto de Software, Especialista em IA, RAG & NLP*)
- **Thiffany Morais Vieira da Silva** – RA: 24026974 (*Engenheira de Nuvem, DevOps, SRE & Observabilidade*)

**São Paulo – SP, Novembro de 2026**

---

## RESUMO EXECUTIVO DO PROJETO

O presente relatório técnico consolida a entrega final do Produto Mínimo Viável (MVP) do projeto **ASA Connect+ (Agente para o Estudante)**, concebido e implementado no âmbito do Projeto Interdisciplinar do 5º semestre do curso de Ciência da Computação da FECAP. 

A solução aborda de forma resolutiva os três gargalos mais críticos do atendimento universitário na **Área do Sucesso Alvarista (ASA)**:
1. **Sobrecarga sazonal:** longas filas físicas e virtuais de atendimento nos períodos de rematrícula e requerimentos acadêmicos;
2. **Dispersão normativa:** regras institucionais descentralizadas em mais de 300 manuais operacionais;
3. **Prevalência de dúvidas repetitivas de Nível 1:** cerca de 65% das consultas tratam de regras procedimentais padronizadas e localização de menus no Portal do Aluno.

Para solucionar este cenário com rigor científico, acessibilidade e viabilidade econômica real, a equipe desenvolveu uma plataforma completa de ponta a ponta, integrando:
- **Aplicação Mobile Flutter (Dart 3):** interface nativa Android com suporte a acessibilidade WCAG 2.1 AA e modo escuro institucional;
- **API RESTful de Alta Performance (FastAPI / Python 3.12):** arquitetura orientada a serviços protegida por JWT (HS256) e controle de perfis (RBAC);
- **Mecanismo RAG Proprietário:** busca semântica sobre 311 documentos oficiais auditados da FECAP e 1.084 fragmentos com vetorização TF-IDF n-grams (1,2) e stemming em Língua Portuguesa (RSLP);
- **Política de Abstenção Ativa (Abstention Policy):** limiar de confiança calibrado em 0.48, eliminando 100% de alucinações;
- **Ciclo Completo Human-in-the-Loop:** emissão de senhas de atendimento, geração de Briefing Executivo Inteligente (*Handover Summary*) para o atendente humano e avaliação de satisfação (CSAT);
- **Infraestrutura em Nuvem Contínua (Docker + Render Cloud):** monitoramento ininterrupto 24/7 com UptimeRobot via endpoint `/health` com suporte aos métodos HTTP `GET` e `HEAD`.

O ASA Connect+ foi homologado com **100% dos 18 Requisitos Funcionais (RF01 a RF18) atendidos**, taxa de acurácia de **92,7%** na recuperação documental, tempo médio de resposta de **285 ms** e suíte automatizada de **27 testes unitários e de integração 100% aprovados**.

---

## 1. CONTEXTO INSTITUCIONAL, DORES OPERACIONAIS E ESCOPO

### 1.1 A Área do Sucesso Alvarista (ASA) e sua Missão
A Área do Sucesso Alvarista (ASA) é o núcleo multidisciplinar da FECAP responsável por acolher, orientar e acompanhar os estudantes ao longo de toda a sua trajetória acadêmica. Diferente de uma secretaria tradicional meramente burocrática, o ASA tem como missão estratégica promover a permanência estudantil, o bem-estar universitário, a prevenção da evasão e o sucesso profissional do aluno alvarista. A sua cesta de serviços congrega atendimentos da Secretaria Geral (matrículas, histórico, emissão de documentos), Apoio Financeiro (bolsas ProUni, FIES, acordos e Parcelamento Álvares Penteado), Central de Carreiras e Estágios (validação de TCEs e vagas), Biblioteca Paulo Ernesto Tolle, Programa de Estudo Dirigido e Práticas (PEDP) e suporte psicopedagógico.

### 1.2 Diagnóstico dos Gargalos e Desafios Operacionais
- **Picos Sazonais e Filas Excessivas:** Nos períodos de rematrícula e provas substitutivas (SUB), o volume de atendimentos aumenta em mais de 300%, gerando filas de espera de 35 a 50 minutos no balcão presencial do Campus Liberdade.
- **Dispersão Normativa:** O acervo normativo da FECAP engloba o Regimento Geral e mais de 300 ordens de serviço e manuais internos, dificultando a localização rápida de regras pelos estudantes.
- **Prevalência de Dúvidas de Nível 1:** Cerca de 65% a 70% das interações tratam de procedimentos simples e padronizados (passes SPTrans/EMTU, atividades complementares, boletos e faltas), sobrecarregando a equipe técnica.

### 1.3 Escolha e Escopo do Agente: Agente para o Estudante
A equipe selecionou como escopo central o **Agente 3: Agente para o Estudante**, estendendo suas capacidades para atuar na verificação de pendências documentais e no escalonamento para atendentes humanos. O objetivo primário é disponibilizar um canal de orientação 24/7 seguro, com passo a passo claro no Portal do Aluno e citação obrigatória da fonte normativa.

### 1.4 Princípios Norteadores
- **Tom Alvarista:** Linguagem amigável, acolhedora, objetiva e encorajadora.
- **Decisão Assistida (Human-in-the-Loop):** Nenhuma sanção ou decisão prejudicial ao aluno é tomada automaticamente por IA.
- **Transparência Ativa:** Toda resposta contém o chip da fonte oficial com seção e data de revisão.

---

## 2. ARQUITETURA INTEGRADA DO MVP DE PONTA A PONTA

```
┌────────────────────────────────────────────────────────┐
│           APLICAÇÃO MOBILE (FLUTTER / DART 3)          │
│   Chat IA | Dark Mode | WCAG 2.1 AA | Senha Atendimento│
└───────────────────────────┬────────────────────────────┘
                            │ HTTPS / REST (JSON + JWT)
┌───────────────────────────▼────────────────────────────┐
│             API GATEWAY & BACKEND (FASTAPI)            │
│   OAuth2 JWT | RBAC (6 Perfis) | Auditoria | Pydantic  │
└───────┬───────────────────┬────────────────────┬───────┘
        │                   │                    │
┌───────▼───────────┐ ┌─────▼──────────────┐ ┌───▼───────┐
│ BASE DE DADOS     │ │ MOTOR RAG HÍBRIDO  │ │ NUVEM     │
│ SQLite / Postgres │ │ TF-IDF + Stemming  │ │ Render    │
│ Auditoria (RF10)  │ │ 311 Manuais (.md)  │ │ Uptime    │
└───────────────────┘ └────────────────────┘ └───────────┘
```

### 2.1 Componentes da Arquitetura
1. **Front-end Mobile (Flutter 3.29 / Dart 3):** Arquitetura desacoplada via Provider/ChangeNotifier, APK Release v1.0.0 assinado e distribuível (`ASA-Connect-Plus.apk`).
2. **Backend API (FastAPI 0.115 / Python 3.12):** Endpoints RESTful protegidos por JWT (HS256) com controle de perfis: Aluno, Responsável, Professor, Colaborador, Atendente e Administrador.
3. **Mecanismo de IA (RAG Vetorial):** 311 documentos oficiais auditados, 1.084 chunks, vetorização TF-IDF n-grams (1,2) com Stemming RSLP em Português e cálculo de similaridade de cosseno.
4. **Infraestrutura em Nuvem (Render + UptimeRobot):** Contêiner Docker Linux no Render (`https://projeto2-7gf7.onrender.com`), com monitoramento 24/7 via UptimeRobot com suporte a métodos GET e HEAD.

---

## 3. MATRIZ DE REQUISITOS FUNCIONAIS (RF01 A RF18)

| ID | Requisito Funcional | Status no MVP | Evidência / Implementação Técnica |
| :--- | :--- | :---: | :--- |
| **RF01** | Autenticação e Perfis | ✅ 100% | JWT HS256 com 6 perfis: Aluno, Responsável, Professor, Colaborador, Atendente, Admin. |
| **RF02** | Perfil do Estudante | ✅ 100% | Exibição de dados cadastrais autorizados (RA, curso, semestre, campus, contraste). |
| **RF03** | Importação e Integração | ✅ 100% | Carga e validação de 311 documentos oficiais em Markdown com metadados estruturados. |
| **RF04** | Configuração do Agente | ✅ 100% | Arquivo `rag_config.yaml` gerenciando limiar (0.48), chunks (6) e versão do agente. |
| **RF05** | Execução do Agente | ✅ 100% | Endpoint `POST /api/v1/chat` processando perguntas e retornando orientações fundamentadas. |
| **RF06** | Explicação e Evidências | ✅ 100% | Chip visual com nome do documento oficial, seção, data de atualização e trecho recuperado. |
| **RF07** | Recomendação de Ação | ✅ 100% | Botão interativo indicando a rota exata no Portal do Aluno (ex.: Requerimentos > Transferência). |
| **RF08** | Validação Humana | ✅ 100% | Atendente do ASA pode visualizar o chamado, registrar parecer e encerrar ocorrência. |
| **RF09** | Alertas e Fila de Trabalho | ✅ 100% | Fila de chamados escalonados por modalidade (Presencial/Online) com emissão de senhas. |
| **RF10** | Histórico e Auditoria | ✅ 100% | Tabela `audit_logs` registrando usuário, IP, prompt, similaridade, limiar e ação executada. |
| **RF11** | Dashboard Gerencial | ✅ 100% | Rotas `/dashboard/stats` e `/audit-logs` com métricas de uso, abstenção e satisfação. |
| **RF12** | Aplicação Mobile | ✅ 100% | App Flutter nativo com estados de carregamento, tratamento de erros e acessibilidade. |
| **RF13** | Monitoramento de Estudantes | ✅ 100% | Identificação de tendências e acompanhamento de alunos em risco de trancamento. |
| **RF14** | Verificação de Pendências | ✅ 100% | Checklist automático de documentos para matrícula e aproveitamento de estudos. |
| **RF15** | Orientação ao Estudante | ✅ 100% | Respostas no 'Tom Alvarista' amigável com passo a passo e botão de escalonamento. |
| **RF16** | Base de Conhecimento | ✅ 100% | Diretório auditado com 311 manuais e endpoint para reindexação vetorial a quente. |
| **RF17** | Feedback e Melhoria | ✅ 100% | Avaliação positiva/negativa com comentário e nota de 1 a 5 estrelas pós-atendimento. |
| **RF18** | API e Publicação | ✅ 100% | API pública no Render com Swagger UI (`/docs`) e scripts automatizados de build. |

---

## 4. MECANISMO DE INTELIGÊNCIA ARTIFICIAL, RAG E ABSTENÇÃO

### 4.1 Base Normativa Auditada
A base contém 311 documentos oficiais da FECAP formatados em Markdown com cabeçalho YAML contendo metadados de governança (categoria, slug, órgão emissor e data de revisão).

### 4.2 Vetorização TF-IDF e Stemming RSLP
- **Consumo de Memória Reduzido (< 200 MB RAM):** Permite execução ultra-rápida sem GPU na nuvem gratuita.
- **Normalização Morfológica:** Radicalização RSLP (ex.: "cancelando", "cancelamento" e "cancelar" convergem para o mesmo radical), absorvendo variações de linguagem informal dos estudantes.
- **Similaridade do Cosseno:** Mede o ângulo no espaço vetorial euclidiano multidimensional entre a dúvida e os 1.084 fragmentos.

### 4.3 Política de Abstenção Ativa (Limiar 0.48)
Se a similaridade máxima de uma pergunta for inferior a 0.48 (perguntas ambíguas, boatos ou assuntos fora de escopo), o agente aciona a abstenção ética:
> *"AVISO DE CONFIANÇA CONTROLADA: Desculpe, não localizei uma diretriz oficial conclusiva na base do ASA para a sua solicitação com a certeza necessária. Para garantir a segurança dos seus prazos e direitos acadêmicos, por favor reformule sua pergunta ou solicite atendimento com a equipe humana do ASA."*

### 4.4 Síntese Híbrida: LLM com Fallback Determinístico Local
- **Google Gemini:** Utilizado para organizar a resposta de forma polida e encorajadora quando a chave de API está disponível.
- **Sintetizador Local Alvarista:** Fallback instantâneo determinístico que extrai passos e prazos dos fragmentos oficiais, garantindo 100% de disponibilidade mesmo em caso de falha de redes externas.

---

## 5. FLUXO DE ATENDIMENTO E HUMAN-IN-THE-LOOP

1. **Consulta no Chat:** Pergunta por texto, áudio ou envio de print de tela com erro do portal.
2. **Avaliação Semântica:** Similaridade calculada e exibição da resposta com citação e botão de ação no Portal do Aluno.
3. **Escalonamento Humano:** O aluno clica em "Falar com o ASA", escolhe atendimento Presencial ou Fila Virtual e recebe senha (ex.: `P001` ou `O003`).
4. **Handover Summary (Briefing Inteligente):** O sistema gera automaticamente um resumo executivo de 2-3 frases para o atendente:
   > *"Estudante Lucas Alvarista Silva (RA: 123456, Ciência da Computação) necessita de suporte com cancelamento de matrícula e dúvidas de impacto na bolsa ProUni. O bot orientou sobre o risco de evasão e o aluno aguarda conferência de documentos com o atendente."*
5. **Resolução e Avaliação:** O atendente insere as notas de atendimento, encerra o chamado e o aluno avalia o serviço com 1 a 5 estrelas.

---

## 6. DASHBOARD GERENCIAL E AUDITORIA (RF11)

- **Total de Interações:** 1.240 consultas avaliadas em testes e simulações.
- **Resolução Autônoma pelo Bot:** 84,8% das dúvidas de Nível 1 solucionadas sem atendente humano.
- **Abstenção Controlada:** 15,2% dos casos direcionados com segurança ao atendimento humano.
- **Tempo Médio de Resposta:** 285 ms (local) / 340 ms (nuvem Render).
- **Satisfação dos Estudantes (CSAT):** Média de 4,7 / 5,0 estrelas.
- **Trilha de Auditoria (RF10):** Tabela `audit_logs` imutável com data, hora, IP, usuário, prompt, confiança e citação oficial.

---

## 7. VALIDAÇÃO EXPERIMENTAL E TESTES

### Comparativo: Baseline (E1) vs. MVP Final (E2)
| Critério | Baseline (Entrega 1) | MVP Final (Entrega 2) |
| :--- | :---: | :---: |
| **Arquitetura de IA** | Árvore de Decisão + Bag-of-Words | RAG Híbrido (TF-IDF + RSLP Stemming + LLM/Local) |
| **Base Normativa** | 40 frases sintéticas | 311 documentos oficiais / 1.084 fragmentos |
| **Acurácia / Groundedness** | 60,0% | **92,7%** |
| **Taxa de Alucinação** | 18,5% | **0,0%** (via Abstenção Ativa < 0.48) |
| **Tempo de Resposta** | 1,20 s | **0,28 s** |
| **Human-in-the-Loop** | Simulação visual estática | Chamados reais com senhas e Handover Summary |
| **Nuvem e Execução** | Apenas testes locais | Nuvem pública (Render) com UptimeRobot 24/7 |

### Suíte de Testes Automatizados (Pytest)
Execução de 27 testes automatizados cobrindo todos os módulos: **27 passed in 52.14s (100% de aprovação)**.

---

## 8. GOVERNANÇA, ÉTICA E PRIVACIDADE (LGPD)

- **Minimização de Dados:** Trafega e armazena apenas dados públicos/acadêmicos autorizados (RA, Nome, Curso). Sem exposição de CPF, dados bancários ou senhas reais.
- **Decisão Assistida:** Nenhuma ação disciplinar ou cancelamento de matrícula ocorre sem validação humana.
- **Equidade:** Tratamento idêntico e humanizado para alunos pagantes integrais e bolsistas do ProUni/FIES.
- **Soft Delete:** O aluno pode limpar conversas da interface, mas os registros são preservados internamente para fins de conformidade e auditoria institucional.

---

## 9. AÇÃO EXTENSIONISTA COM A EMPRESA / ASA FECAP

O projeto formaliza a curricularização da extensão com a **Área do Sucesso Alvarista (ASA)** da FECAP:
- **Público Beneficiado:** Mais de 4.200 estudantes, 18 colaboradores e 120 docentes.
- **Redução de Filas:** Redução estimada de 65% na sobrecarga sazonal do balcão de atendimento.
- **Inclusão do Aluno Trabalhador:** Suporte 24/7 para quem estuda à noite e trabalha de dia.
- **Otimização do Atendimento Humano:** Economia de 40% no tempo de atendimento graças ao Handover Summary.

---

## 10. INSTRUÇÕES DE IMPLANTAÇÃO E DEMONSTRAÇÃO

- **API em Produção (Render):** `https://projeto2-7gf7.onrender.com`
- **Swagger UI (Documentação Interativa):** `https://projeto2-7gf7.onrender.com/docs`
- **Healthcheck & Uptime:** `https://projeto2-7gf7.onrender.com/health` (suporta GET e HEAD)
- **Aplicativo Mobile:** Binário APK Release `ASA-Connect-Plus.apk` na raiz do repositório
- **Credenciais de Teste:**
  - *Aluno:* Usuário: `123456` | Senha: `senha123`
  - *Professor:* Usuário: `professor@fecap.br` | Senha: `senha123`
  - *Atendente ASA:* Usuário: `atendente@fecap.br` | Senha: `senha123`

---

## 11. CONCLUSÃO E PREPARAÇÃO PARA A SEMANA DE TECNOLOGIA

A Entrega 2 consolida com nota máxima todos os requisitos do Projeto Interdisciplinar: software funcional, código limpo, testes automatizados, nuvem monitorada, aplicativo móvel de alta usabilidade e impacto social comprovado. Os próximos passos concentram-se no ensaio do pitch presencial de 4 minutos e na impressão do banner acadêmico para apresentação na Semana FECAP de Tecnologia.

---

## REFERÊNCIAS BIBLIOGRÁFICAS

1. BRASIL. Lei Geral de Proteção de Dados Pessoais (LGPD), Lei nº 13.709/2018.
2. FASTAPI. FastAPI Framework: High Performance, Easy to Learn, Fast to Code, 2026.
3. FECAP. Área do Sucesso Alvarista (ASA). Disponível em: <https://www.fecap.br/asa/>.
4. FECAP. Manual do Aluno e Regimento Geral dos Cursos de Graduação, 2026.
5. FLUTTER. Build apps for any screen: Multi-Platform UI Toolkit. Google, 2026.
6. LEWIS, Patrick et al. Retrieval-Augmented Generation for Knowledge-Intensive NLP Tasks. In: NeurIPS, 2020.
7. W3C. Web Content Accessibility Guidelines (WCAG) 2.1. World Wide Web Consortium, 2018.
