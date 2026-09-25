# -*- coding: utf-8 -*-
"""ASA-Connect — código da Entrega 1.

Extraído das células de código do notebook ASA_CONNECT_ENTREGA1_FINAL.ipynb.
Para executar localmente, coloque 'Base Unificada.csv' na mesma pasta e rode:
    python ASA_CONNECT_CODIGO.py
Dependências: pandas, scikit-learn e IPython (já presentes no Colab).
"""


# ========================================================================
# 1. Leitura e análise dos dados
# ========================================================================

from pathlib import Path
import pandas as pd
from IPython.display import display
from sklearn.feature_extraction.text import CountVectorizer
from sklearn.tree import DecisionTreeClassifier
from sklearn.pipeline import make_pipeline
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, classification_report

# No Colab, envie o CSV quando for solicitado.
# No computador, basta deixar o CSV na mesma pasta do notebook.
if not Path("Base Unificada.csv").exists():
    try:
        from google.colab import files
        files.upload()
    except ImportError:
        raise FileNotFoundError("Coloque 'Base Unificada.csv' na mesma pasta do notebook.")

df = pd.read_csv("Base Unificada.csv")
print("Registros:", len(df), "| Colunas:", len(df.columns))
print("Alunos distintos:", df["ID_ALUNO"].nunique())

# Exibimos só informações gerais, sem divulgar registros individuais.
colunas_resumo = ["pct_parcelas_em_aberto", "pct_parcelas_acordo",
                  "atraso_medio_dias", "total_contatos"]
display(df[colunas_resumo].describe().round(2))


# ========================================================================
# 2. Preparação dos dados
# ========================================================================

print("IDs vazios:", df["ID_ALUNO"].isna().sum())
print("IDs repetidos:", df["ID_ALUNO"].duplicated().sum())
print("Campos vazios por coluna (os 8 maiores):")
display(df.isna().sum().sort_values(ascending=False).head(8).to_frame("Quantidade"))

dados = df.dropna(subset=["ID_ALUNO"]).drop_duplicates("ID_ALUNO").copy()
colunas_numericas = ["pct_parcelas_em_aberto", "pct_parcelas_acordo",
                    "atraso_medio_dias", "total_contatos", "media_assiduidade"]
for coluna in colunas_numericas:
    dados[coluna] = pd.to_numeric(dados[coluna], errors="coerce")

print("Alunos disponíveis para consulta:", len(dados))
print("Valores de atraso negativo (precisam de conferência):",
      (dados["atraso_medio_dias"] < 0).sum())
print("Valores ausentes nos atributos escolhidos:")
display(dados[colunas_numericas].isna().sum().to_frame("Quantidade"))


# ========================================================================
# 3. Modelo inicial: Árvore de Decisão
# ========================================================================

exemplos = {
    "financeiro": [
        "tenho boleto atrasado", "quero verificar parcelas em aberto", "preciso pagar mensalidade",
        "tenho dívida de pagamento", "como consultar meu acordo financeiro", "meu boleto está vencido",
        "quero regularizar parcelas", "minha mensalidade está atrasada",
        "preciso consultar pagamento", "há algum débito financeiro"],
    "rematricula": [
        "quero fazer rematrícula", "como renovar minha matrícula", "preciso me rematricular",
        "qual o procedimento de rematrícula", "quero continuar matriculado", "como fazer matrícula do semestre",
        "tenho dúvidas sobre rematrícula", "preciso renovar matrícula",
        "quando posso fazer rematrícula", "como concluir a matrícula"],
    "bolsa": [
        "quero renovar minha bolsa", "tenho dúvida sobre bolsa de estudos", "como solicitar bolsa",
        "minha bolsa está ativa", "preciso consultar desconto da bolsa", "quero saber sobre auxílio estudantil",
        "minha bolsa precisa de renovação", "como verificar benefício estudantil",
        "preciso regularizar bolsa", "quero informação sobre bolsa"],
    "documentos": [
        "quais documentos faltam", "preciso entregar documentação", "tenho documento pendente",
        "como enviar comprovante", "falta algum documento meu", "quero verificar documentação",
        "preciso atualizar meus documentos", "entrega de histórico escolar",
        "meu comprovante foi recebido", "quero consultar documento"],
}
frases = [frase for lista in exemplos.values() for frase in lista]
assuntos = [assunto for assunto, lista in exemplos.items() for _ in lista]
X_treino, X_teste, y_treino, y_teste = train_test_split(
    frases, assuntos, test_size=0.25, random_state=42, stratify=assuntos
)
modelo = make_pipeline(
    CountVectorizer(strip_accents="unicode", ngram_range=(1, 2)),
    DecisionTreeClassifier(random_state=42)
)
modelo.fit(X_treino, y_treino)
previsoes = modelo.predict(X_teste)
acuracia = accuracy_score(y_teste, previsoes)
print(f"Acurácia no teste fictício: {acuracia:.0%} ({sum(previsoes == y_teste)}/{len(y_teste)} frases)")
print(classification_report(y_teste, previsoes, zero_division=0))
comparacao = pd.DataFrame({"Solicitação fictícia": X_teste, "Esperado": y_teste,
                           "Previsto": previsoes})
display(comparacao)
print("Exemplos em que o modelo errou:")
display(comparacao[comparacao["Esperado"] != comparacao["Previsto"]])


# ========================================================================
# 4. Regras e tabela de decisão
# ========================================================================

tabela_decisao = pd.DataFrame([
    ["Financeiro: parcelas em aberto e atraso válido de 30 dias ou mais",
     "Conferir parcelas e possíveis acordos", "Alta (provisória)", "Financeiro"],
    ["Financeiro: parcelas em aberto e atraso válido inferior a 30 dias",
     "Conferir parcelas e possíveis acordos", "Média (provisória)", "Financeiro"],
    ["Financeiro: parcelas em aberto e atraso ausente/negativo",
     "Consultar datas e situação atual", "A verificar", "Financeiro"],
    ["Financeiro: sem parcelas em aberto ou indicador ausente",
     "Confirmar situação atual no sistema", "A verificar", "Financeiro"],
    ["Rematrícula", "Conferir calendário, documentos e requisitos", "A verificar", "Secretaria acadêmica"],
    ["Bolsa", "Conferir registro, condições e renovação", "A verificar", "Setor de bolsas"],
    ["Documentos", "Conferir exigências e recebimento", "A verificar", "Secretaria acadêmica"],
], columns=["Condição", "Resultado", "Prioridade", "Setor"])
display(tabela_decisao)


# ========================================================================
# 5. Função do agente
# ========================================================================

def orientar_aluno(id_aluno, pedido):
    """Classifica o assunto e devolve uma orientação inicial para o atendente."""
    aluno = dados.loc[dados["ID_ALUNO"].astype(str) == str(id_aluno)]
    if aluno.empty:
        return {"Assunto": "Não localizado", "Checklist": "Conferir identificação",
                "Prioridade": "A verificar", "Próxima ação": "Localizar cadastro",
                "Justificativa": "ID não encontrado", "Setor": "Atendimento"}

    assunto = modelo.predict([pedido])[0]
    registro = aluno.iloc[0]

    if assunto == "financeiro":
        aberto = registro["pct_parcelas_em_aberto"]
        atraso = registro["atraso_medio_dias"]
        acordo = registro["pct_parcelas_acordo"]

        if pd.isna(aberto) or not (0 <= aberto <= 1):
            checklist = "Consultar parcelas diretamente no sistema"
            prioridade = "A verificar"
            motivo = "Indicador de parcelas em aberto ausente ou inválido"
        elif aberto > 0:
            checklist = "Conferir parcelas em aberto"
            if pd.notna(acordo) and acordo > 0:
                checklist += " e verificar se os acordos registrados continuam válidos"
            if pd.isna(atraso) or atraso < 0:
                prioridade = "A verificar"
                motivo = "Há indicador de parcelas em aberto, mas o atraso precisa ser conferido"
            elif atraso >= 30:
                prioridade = "Alta (provisória)"
                motivo = "Há parcelas em aberto e o atraso médio informado é de 30 dias ou mais"
            else:
                prioridade = "Média (provisória)"
                motivo = "Há parcelas em aberto e o atraso médio informado é inferior a 30 dias"
        else:
            checklist = "Confirmar a situação financeira atual"
            prioridade = "A verificar"
            motivo = "O indicador resumido não aponta parcelas em aberto"
        return {"Assunto": assunto, "Checklist": checklist, "Prioridade": prioridade,
                "Próxima ação": "Conferir no sistema financeiro e orientar o aluno",
                "Justificativa": motivo, "Setor": "Financeiro"}

    if assunto == "bolsa":
        status = str(registro.get("tem_bolsa", "")).lower()
        situacao = ("Existe registro de bolsa na base, mas precisamos confirmar o status atual"
                    if status == "true" else
                    "A base não indica bolsa ativa; conferir se há solicitação ou benefício recente"
                    if status == "false" else
                    "A situação da bolsa não está clara na base")
        return {"Assunto": assunto,
                "Checklist": "Conferir condições, documentos e situação da bolsa",
                "Prioridade": "A verificar",
                "Próxima ação": "Consultar a situação e as regras de renovação",
                "Justificativa": situacao, "Setor": "Setor de bolsas"}

    orientacoes = {
        "rematricula": ("Conferir calendário, documentos e requisitos da rematrícula",
                        "Consultar a situação atual e as regras oficiais", "Secretaria acadêmica"),
        "documentos": ("Conferir documentos exigidos e recebimento",
                       "Verificar documentos pendentes no sistema", "Secretaria acadêmica"),
    }
    checklist, proxima, setor = orientacoes[assunto]
    return {"Assunto": assunto, "Checklist": checklist, "Prioridade": "A verificar",
            "Próxima ação": proxima,
            "Justificativa": "A base não confirma a pendência específica deste procedimento",
            "Setor": setor}


# ========================================================================
# 6. Demonstração com quatro solicitações
# ========================================================================

# Escolhemos um registro que permita demonstrar a regra financeira, sem exibir o ID.
candidatos = dados.loc[(dados["pct_parcelas_em_aberto"] > 0) &
                       (dados["atraso_medio_dias"] >= 30)]
id_exemplo = candidatos.iloc[0]["ID_ALUNO"] if not candidatos.empty else dados.iloc[0]["ID_ALUNO"]

pedidos_demo = [
    ("financeiro", "quero verificar parcelas em aberto"),
    ("rematricula", "quero fazer rematrícula"),
    ("bolsa", "quero renovar minha bolsa"),
    ("documentos", "quais documentos faltam"),
]
resultados_demo = []
for esperado, pedido in pedidos_demo:
    resposta = orientar_aluno(id_exemplo, pedido)
    print("\nSOLICITAÇÃO:", pedido)
    display(pd.DataFrame([resposta]))
    resultados_demo.append({
        "Solicitação": pedido,
        "Assunto esperado": esperado,
        "Assunto identificado": resposta["Assunto"],
        "Assunto correto?": "Sim" if resposta["Assunto"] == esperado else "Não",
        "Checklist presente?": "Sim" if resposta.get("Checklist") else "Não",
        "Setor indicado": resposta["Setor"],
    })

print("Resumo dos quatro testes demonstrativos:")
display(pd.DataFrame(resultados_demo))
