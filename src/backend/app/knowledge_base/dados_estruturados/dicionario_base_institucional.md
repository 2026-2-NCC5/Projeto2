# Dicionário de Dados - Base Institucional Integrada ASA FECAP

Este documento consolida a estrutura oficial e o esquema técnico dos dados institucionais da FECAP, abrangendo os 5 domínios da vida acadêmica do estudante: Contato, Matrículas, Histórico Escolar, Financeiro e Relacionamentos/Sucesso do Aluno.

---

## 1. Tabela `contato` (Dados Cadastrais e Demográficos)
- **id_aluno** (TEXT, PK): Identificador institucional único do estudante (RA).
- **idade** (INTEGER): Idade do aluno.
- **bairro** (TEXT): Bairro de residência do aluno.
- **cidade** (TEXT): Município de residência (ex: São Paulo, Santo André, Mogi das Cruzes, etc.).
- **estado** (TEXT): Unidade Federativa (UF).
- **estado_civil** (TEXT): Estado civil (Solteiro, Casado, Divorciado).
- **sexo** (TEXT): Gênero autodeclarado (Feminino, Masculino).

## 2. Tabela `matriculas` (Situação Acadêmica e Risco de Evasão)
- **id_aluno** (TEXT, FK): RA do estudante.
- **periodo_letivo_atual** (TEXT): Ciclo letivo vigente (ex: 2023-1, 2023-2).
- **forma_ingresso** (TEXT): Canal de ingresso (Vestibular, ENEM, Transferência, Segunda Graduação).
- **curso** (TEXT): Nome do curso de graduação ou pós-graduação.
- **grau_academico** (TEXT): Nível de ensino (Graduação, Especialização, Mestrado).
- **turno** (TEXT): Período das aulas (Matutino, Noturno, Integral).
- **periodo_ingresso** (TEXT): Ano/semestre de ingresso do aluno na instituição.
- **risco_evasao** (INTEGER): Indicador preditivo de risco de abandono/evasão (0 = baixo risco, 1 = alto risco / sob monitoramento do ASA).
- **status_academico** (TEXT): Status formal da matrícula (Ativo, Trancado, Formado, Desistente, Cancelado).

## 3. Tabela `historico` (Desempenho, Notas e Assiduidade)
- **id_aluno** (TEXT, FK): RA do estudante.
- **ano_semestre** (TEXT): Semestre da disciplina cursada (ex: 2022/1).
- **periodo_oferta** (TEXT): Semestre ideal da disciplina na grade curricular.
- **perc_assiduidade** (REAL): Percentual de presença nas aulas (frequência mínima institucional = 75%).
- **perc_faltas** (REAL): Percentual de ausência acumulado no período letivo.
- **perc_nota** (REAL): Aproveitamento percentual na disciplina.
- **aulas_ministradas** (REAL): Carga horária em aulas executadas no semestre.
- **disciplina** (TEXT): Denominação da unidade curricular.
- **situacao** (TEXT): Resultado final (Aprovado, Reprovado por Nota, Reprovado por Frequência, Cursando, Dispensa).
- **nota_obtida** (REAL): Média final obtida pelo estudante (escala 0.0 a 10.0; média mínima de aprovação = 6.0).
- **faltas_lancadas** (REAL): Total de faltas em horas ou aulas registradas no diário.

## 4. Tabela `financeiro` (Mensalidades, Parcelas e Bolsas)
- **id_aluno** (TEXT, FK): RA do estudante.
- **unidade** (TEXT): Unidade gestora (GRA = Graduação, POS = Pós-Graduação).
- **periodo_letivo** (TEXT): Semestre financeiro correspondente.
- **curso** (TEXT): Curso do contrato financeiro.
- **parcela** (TEXT): Número da parcela da anuidade (1 = Rematrícula, 2 a 6 = Mensalidades do semestre).
- **servico_parcela** (TEXT): Natureza da cobrança (REMATRICULA, MENSALIDADE, TAXA_SERVICO, ACORDO).
- **bolsa_aluno** (TEXT): Programa de bolsa ou benefício associado (ex: Bolsa FIDELIDADE 25%, Bolsa Mérito, Convênio Empresa, ProUni, FIES, Pagamento Integral).
- **valor_original** (REAL): Valor facial do lançamento financeiro em Reais (R$).
- **status_lancamento** (TEXT): Estado de liquidação do título (Baixado = quitado, Aberto = pendente, Cancelado = anulado).
- **data_vencimento** (TEXT): Data limite de pagamento sem acréscimos.
- **data_baixa** (TEXT): Data efetiva da quitação bancária.

## 5. Tabela `relacionamentos` (Chamados, Atendimentos e Permanência ASA)
- **id_aluno** (TEXT, FK): RA do estudante atendido.
- **codigo** (TEXT): Protocolo único do ticket de atendimento no sistema ASA.
- **tema_relacionamento** (TEXT): Macrocategoria do atendimento (Sucesso Acadêmico, Dúvidas Financeiras, Apoio Psicológico, Rematrícula, Bolsas, Documentos).
- **motivo_contato** (TEXT): Descrição sintética da solicitação do aluno.
- **motivo_evasao** (TEXT): Causa raiz identificada em casos de intenção de trancamento/cancelamento.
- **alternativa_permanencia** (TEXT): Medida proposta pela equipe ASA para retenção e permanência (Plano de Pagamento, Reopção de Curso, Mentoria Acadêmica, Apoio Psicopedagógico).
- **data_criacao** (TEXT): Timestamp do registro do chamado.
