# Catálogo Institucional de Fontes Oficiais — ASA Connect+

Este catálogo relaciona todas as fontes normativas e regulatórias autorizadas para indexação na Base de Conhecimento do agente RAG do **ASA Connect+**.

---

## 1. Documentos Ativos e Metadados Institucionais

| Slug do Documento | Título Oficial | Setor Responsável | Capítulo / Seção | Versão | Última Atualização |
|---|---|---|---|---|---|
| `atestado_matricula` | Atestado de Matrícula e Comprovante de Vínculo | Secretaria Geral | Cap. 4 - Emissão de Documentos | v2024.2 | 15/10/2024 |
| `rematricula_prazos_regras` | Regras, Prazos e Procedimentos de Rematrícula | Coordenação Acadêmica | Cap. 2 - Calendário e Renovação | v2024.2 | 20/11/2024 |
| `segunda_via_boleto` | Emissão de 2ª Via de Boleto e Política Financeira | Tesouraria e Financeiro | Regulamento Financeiro - Arts 12-18 | v2024.1 | 30/09/2024 |
| `trancamento_disciplinas` | Trancamento de Matrícula e Ajuste de Grade | Regimento Geral | Cap. 5 - Regime Escolar | v2024.2 | 25/08/2024 |
| `atividades_complementares`| Normas e Envio de Horas Complementares (AAC) | Coordenação de Extensão | Manual de Atividades Complementares | v2024.1 | 12/09/2024 |
| `estagio_obrigatorio` | Diretrizes de Estágio e Termo de Compromisso | Central de Carreiras | Manual de Estágio e Convênios | v2024.2 | 01/10/2024 |
| `solicitacao_diploma` | Emissão de Diploma Digital e Colação de Grau | Secretaria de Registros | Portaria MEC 554/2019 e Normativa | v2024.1 | 10/08/2024 |
| `aproveitamento_estudos` | Aproveitamento de Estudos e Dispensa de Matérias | Coordenação de Curso | Regimento Geral - Equivalência | v2024.1 | 20/07/2024 |

---

## 2. Ciclo de Vida e Governança de Conteúdo (RF16)

1. **Autoria e Homologação:** Todo documento indexado na pasta `knowledge_base/` deve ser homologado formalmente pelo setor competente (Secretaria Geral, Tesouraria, Coordenação Acadêmica ou Central de Carreiras).
2. **Controle de Versão:** Cada documento inclui cabeçalho YAML obrigatório com `version`, `updated_at`, `category` e `official_source`.
3. **Desativação em Tempo Real (RF16):** Atendentes e Administradores podem suspender temporariamente um documento obsoleto através do endpoint `PATCH /api/v1/documents/{id}/toggle-active` ou pelo Painel Gerencial do aplicativo mobile, sem necessidade de reimplantação (redeploy) do servidor.
4. **Reindexação Automática:** A inclusão de novas portarias ou circulares é sincronizada na base vetorial via endpoint `POST /api/v1/documents/reindex`.
