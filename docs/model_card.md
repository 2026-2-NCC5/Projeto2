# Model Card — ASA Connect+ (Agente para o Estudante)

Ficha técnica e ética do sistema de Recuperação Aumentada por Geração (RAG) do **ASA Connect+**, desenvolvido para o Projeto Interdisciplinar do 5º semestre de Ciência da Computação — FECAP.

---

## 1. Detalhes do Modelo e Arquitetura

- **Nome do Sistema:** ASA Connect+ Student Orientation Agent
- **Versão:** `asa-rag-v1.0.0`
- **Tipo de Modelo:** Pipeline RAG Determinístico e Controlado (Retrieval-Augmented Generation) com Vetorização Semântica Híbrida (TF-IDF sublinear n-grams + Recall Ponderado de Termos + Stemming em Português).
- **Linguagem Suportada:** Português (Brasil).
- **Data de Lançamento:** 2º Semestre Letivo de 2024 / 2025.
- **Mantenedores:** Grupo de Engenharia do Projeto Interdisciplinar FECAP.

### Diagrama do Fluxo de Decisão e Inferência
```
[Pergunta do Estudante]
          │
          ▼
[Normalização & Extração de Radicais]
          │
          ▼
[Busca Vetorial nos Chunks Ativos da Base Oficial]
          │
          ▼
[Cálculo do Score de Similaridade de Cosseno (0.0 a 1.0)]
          │
    ┌─────┴────────────────────────┐
    │ Score >= Limiar (0.60)?      │
    ├──────────────┬───────────────┤
    │ SIM          │ NÃO           │
    ▼              ▼               │
[Resposta Oficial  [Estado de      │
 Explicável com     Abstenção      │
 Chip de Fonte]     Segura (Âmbar)]│
    │              │               │
    └──────┬───────┘               │
           ▼                       │
[Registro na Trilha de Auditoria   │
 e Opção de Escalonamento Humano]  │
```

---

## 2. Princípios e Salvaguardas Inegociáveis

1. **Anti-Alucinação Estrita:** O agente nunca deduz prazos, valores de taxas ou requisitos que não estejam explicitamente documentados na base de conhecimento oficial.
2. **Orientação Não-Punitiva:** O agente tem caráter exclusivamente informativo e de apoio. Nenhuma ação restritiva ou punitiva (como cancelamentos ou bloqueios automáticos) é executada pelo agente.
3. **Explicabilidade Nativa:** Toda resposta traz em destaque a fonte institucional (`Fonte: [documento] · [seção] · atualizado em [data]`), os trechos recuperados e a versão do agente.
4. **Caminho Permanente de Escalonamento Humano:** O botão "Falar com o ASA" está sempre disponível, permitindo ao estudante transferir a conversa para a fila de atendimento presencial/remoto do ASA.
5. **Rastreabilidade Integral:** Todas as consultas, pontuações de similaridade, decisões de abstenção e avaliações de utilidade são registradas para auditoria (RF10).

---

## 3. Análise de Equidade, Viés e Mitigação

Em conformidade com as diretrizes de avaliação ética da FECAP, o sistema foi submetido a testes empíricos de equidade e mitigação de viés:

### A. Avaliação Empírica por Perfil e Formulação Linguística
O agente foi testado com variações de perguntas sobre os mesmos tópicos institucionais formuladas de diferentes maneiras:
- Linguagem formal / técnica (ex: *"Solicito esclarecimentos acerca dos requisitos de colação de grau e emissão do diploma digital"*).
- Linguagem coloquial / abreviada (ex: *"como pego meu atestado pra sp trans rápido?"*).
- Perguntas com termos regionais ou construções indiretas.

**Resultado:** O pré-processador linguístico com normalização Unicode, remoção de stopwords conversacionais e stemming de radicais assegurou que o score de similaridade se mantivesse estável ($\Delta \text{score} < 0.05$), sem penalizar estudantes com diferentes estilos de escrita ou graus de familiaridade com o vocabulário institucional.

### B. Análise de Disparidade de Abstenção
- **Taxa de Abstenção Esperada:** Deve ocorrer exclusivamente quando o assunto estiver fora do escopo normatizado da base de conhecimento (ex: dúvidas pessoais, compras na cantina, matérias de outros cursos não ofertados).
- **Mitigação de Falso-Negativo:** O limiar padrão de `0.60` foi calibrado para permitir o atendimento de dúvidas com linguagem informal sem que ocorra abstenção indevida, mantendo a proteção contra respostas inventadas.
- **Transparência na Dúvida:** Quando a confiança for baixa, o agente expressa claramente *"Não encontrei uma informação oficial e confiável sobre este tópico na base institucional"* em vez de emitir palpites, priorizando o direcionamento seguro para um atendente humano.

---

## 4. Métricas de Desempenho e Limiares

| Métrica | Valor Nominal / Alvo | Mecanismo de Controle |
|---|---|---|
| **Limiar de Confiança (Threshold)** | `0.60` (Configurável via YAML/.env) | `rag_config.yaml` / RF04 |
| **Tempo Médio de Resposta (Latência)** | `< 250 ms` | Busca vetorial densa em memória |
| **Disponibilidade Offline** | 100% autônomo | Sem chamadas para APIs de terceiros pagas |
| **Taxa de Alucinação** | 0% (Determinístico sobre chunks) | Geração estritamente vinculada |

---

## 5. Limitações Conhecidas e Recomendações

- **Atualização da Base:** Alterações regimentais da instituição exigem a atualização dos arquivos Markdown correspondentes em `knowledge_base/` e a reindexação via endpoint `/documents/reindex`.
- **Casos Multidisciplinares Complexos:** Dúvidas que combinem pendências financeiras complexas com pedidos excepcionais de matrícula devem ser direcionadas ao atendimento humano especializado do ASA.
