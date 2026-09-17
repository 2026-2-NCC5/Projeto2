import os
import sqlite3

DB_PATH = r"D:\projetos\ASA-PI\Projeto2\src\backend\app\data\base_institucional\institutional_data.db"
KB_DIR = r"D:\projetos\ASA-PI\Projeto2\src\backend\app\knowledge_base\dados_estruturados"
os.makedirs(KB_DIR, exist_ok=True)

conn = sqlite3.connect(DB_PATH)
cur = conn.cursor()

# 1. Dicionário de Dados
doc_dicionario = """# Dicionário de Dados - Base Institucional Integrada ASA FECAP

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
"""

with open(os.path.join(KB_DIR, "dicionario_base_institucional.md"), "w", encoding="utf-8") as f:
    f.write(doc_dicionario)

# 2. Estatísticas Agregadas
cur.execute("SELECT COUNT(DISTINCT id_aluno) FROM matriculas;")
total_alunos_mat = cur.fetchone()[0]

cur.execute("SELECT COUNT(*) FROM matriculas WHERE risco_evasao = 1;")
total_risco_evasao = cur.fetchone()[0]

cur.execute("SELECT curso, COUNT(*) as qtd FROM matriculas GROUP BY curso ORDER BY qtd DESC LIMIT 8;")
top_cursos = cur.fetchall()

cur.execute("SELECT status_lancamento, COUNT(*), ROUND(SUM(valor_original), 2) FROM financeiro GROUP BY status_lancamento;")
stats_fin = cur.fetchall()

cur.execute("SELECT bolsa_aluno, COUNT(*) as qtd FROM financeiro WHERE bolsa_aluno IS NOT NULL AND bolsa_aluno != '' GROUP BY bolsa_aluno ORDER BY qtd DESC LIMIT 8;")
top_bolsas = cur.fetchall()

cur.execute("SELECT tema_relacionamento, COUNT(*) as qtd FROM relacionamentos WHERE tema_relacionamento IS NOT NULL AND tema_relacionamento != '' GROUP BY tema_relacionamento ORDER BY qtd DESC LIMIT 8;")
top_temas = cur.fetchall()

cur.execute("SELECT situacao, COUNT(*) as qtd FROM historico WHERE situacao IS NOT NULL AND situacao != '' GROUP BY situacao ORDER BY qtd DESC LIMIT 6;")
top_situacoes = cur.fetchall()

doc_estatisticas = f"""# Indicadores e Estatísticas Institucionais da Base Alvarista (FECAP)

Este documento consolida os principais indicadores numéricos agregados calculados a partir da base histórica institucional para subsidiar as respostas e a inteligência do Agente ASA Connect+.

---

## 1. Volume Geral de Alunos e Matrículas
- **Total de Alunos Únicos Monitorados:** {total_alunos_mat:,} estudantes.
- **Alunos em Risco de Evasão (Score Ativo):** {total_risco_evasao:,} estudantes ({round(total_risco_evasao / total_alunos_mat * 100, 1) if total_alunos_mat else 0}% da base).
- **Alunos em Situação Regular / Estável:** {total_alunos_mat - total_risco_evasao:,} estudantes.

### Cursos com Maior Contingente de Alunos:
"""
for curso, qtd in top_cursos:
    doc_estatisticas += f"- **{curso}:** {qtd:,} matrículas históricas/ativas\n"

doc_estatisticas += f"""
---

## 2. Cenário Financeiro e Políticas de Benefício
### Distribuição dos Lançamentos Financeiros:
"""
for status, qtd, total_val in stats_fin:
    val_num = total_val if total_val is not None else 0.0
    doc_estatisticas += f"- **{status or 'Indefinido'}:** {qtd:,} títulos emitidos (R$ {val_num:,.2f})\n"

doc_estatisticas += f"""
### Principais Modalidades de Bolsa & Convênios Registrados:
"""
for bolsa, qtd in top_bolsas:
    doc_estatisticas += f"- **{bolsa}:** {qtd:,} concessões registradas\n"

doc_estatisticas += f"""
---

## 3. Atendimentos do Sucesso Alvarista (ASA) e Retenção
### Principais Temas de Relacionamento e Chamados:
"""
for tema, qtd in top_temas:
    doc_estatisticas += f"- **{tema}:** {qtd:,} atendimentos documentados\n"

doc_estatisticas += f"""
---

## 4. Desempenho e Histórico Acadêmico
### Resultados em Disciplinas Cursadas:
"""
for sit, qtd in top_situacoes:
    doc_estatisticas += f"- **{sit}:** {qtd:,} registros de notas e avaliações\n"

with open(os.path.join(KB_DIR, "estatisticas_academicas_fecap.md"), "w", encoding="utf-8") as f:
    f.write(doc_estatisticas)

# 3. Regras de Negócio e Diretrizes Institucionais Extraídas
doc_regras = """# Regras de Negócio e Diretrizes Institucionais da Base Integrada FECAP

O Agente ASA Connect+ deve aplicar rigorosamente as regras institucionais consolidadas da FECAP em suas orientações aos alunos, professores e atendentes:

---

## 1. Diretrizes Acadêmicas e Avaliação
- **Média Mínima para Aprovação:** 6,0 (seis inteiros) na escala decimal de 0,0 a 10,0.
- **Frequência Mínima Obrigatória:** 75% da carga horária da disciplina ministrada (máximo permitido de faltas: 25%).
- **Reprovação por Frequência:** Alunos com mais de 25% de faltas são automaticamente reprovados na disciplina, independentemente da nota obtida.
- **Abono de Faltas:** Não existe abono por faltas ordinárias, exceto nos casos resguardados por legislação federal (licença maternidade, afastamento médico prolongado comprovado via perícia, serviço militar obrigatório).

## 2. Diretrizes Financeiras e de Bolsas
- **Ciclo de Mensalidades:** O semestre letivo é composto por 6 parcelas (Parcela 1 = Rematrícula/Matrícula inicial; Parcelas 2 a 6 = Mensalidades do semestre).
- **Vencimento Padrão:** Geralmente no 5º dia útil ou data estipulada em contrato. Pagamentos até a data de vencimento garantem descontos de pontualidade vigentes.
- **Bolsas e Convênios:** Bolsas (como Bolsa Fidelidade, Bolsa Mérito, Convênios Corporativos) incidem sobre as parcelas mensais de acordo com o percentual contratado e exigem assiduidade mínima e ausência de reprovações para renovação automática.
- **Inadimplência e Negociação:** Alunos com parcelas em aberto podem solicitar Acordo e Negociação de Mensalidades diretamente pelo portal ou com o suporte financeiro do ASA para desbloqueio da rematrícula.

## 3. Diretrizes de Permanência e Atendimento ASA
- **Atendimento Preventivo de Evasão:** Estudantes sinalizados com Risco de Evasão têm prioridade no suporte da equipe do ASA para mediação acadêmica, renegociação facilitada ou reorientação vocacional.
- **Alternativas de Permanência:** Os protocolos institucionais incentivam medidas ativas antes de qualquer desistência formal:
  1. Revisão de grade horária (adaptação entre manhã/noite).
  2. Plano de apoio psicopedagógico para dificuldades em disciplinas exatas/quantitativas.
  3. Readequação de plano financeiro e busca de novas bolsas de estudo.
"""

with open(os.path.join(KB_DIR, "regras_negocio_e_indicadores.md"), "w", encoding="utf-8") as f:
    f.write(doc_regras)

conn.close()
print("Documentos da Base de Conhecimento gerados com sucesso!")
