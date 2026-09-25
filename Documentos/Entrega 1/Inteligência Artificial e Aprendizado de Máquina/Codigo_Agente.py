# Agente de Pendências — código da baseline
# Execute na pasta que contém Base Unificada.csv

import pandas as pd
from IPython.display import display
from sklearn.feature_extraction.text import CountVectorizer
from sklearn.tree import DecisionTreeClassifier
from sklearn.pipeline import make_pipeline
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, classification_report

# No Colab, faça upload de Base Unificada.csv quando solicitado.
df = pd.read_csv("Base Unificada.csv")
print("Linhas:", len(df), "| Colunas:", len(df.columns))
print("Alunos distintos:", df["ID_ALUNO"].nunique())
display(df.head())

print("IDs vazios:", df["ID_ALUNO"].isna().sum())
print("IDs duplicados:", df["ID_ALUNO"].duplicated().sum())
display(df.isna().sum().sort_values(ascending=False).head(10).to_frame("Valores vazios"))

dados = df.dropna(subset=["ID_ALUNO"]).drop_duplicates("ID_ALUNO").copy()
colunas_numericas = ["pct_parcelas_em_aberto", "pct_parcelas_acordo", "atraso_medio_dias", "total_contatos", "media_assiduidade"]
for coluna in colunas_numericas:
    dados[coluna] = pd.to_numeric(dados[coluna], errors="coerce")
print("Registros após preparação:", len(dados))
display(dados[["ID_ALUNO"] + colunas_numericas].head())

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
modelo = make_pipeline(CountVectorizer(), DecisionTreeClassifier(max_depth=6, random_state=42))
modelo.fit(X_treino, y_treino)
previsoes = modelo.predict(X_teste)
print("Acurácia demonstrativa:", round(accuracy_score(y_teste, previsoes) * 100, 1), "%")
print(classification_report(y_teste, previsoes, zero_division=0))
display(pd.DataFrame({"Pedido de teste": X_teste, "Esperado": y_teste, "Previsto": previsoes}).head())

tabela_decisao = pd.DataFrame([
    ["Financeiro: parcelas em aberto e atraso >= 30 dias", "Conferir parcelas e acordos", "Alta (provisória)", "Financeiro"],
    ["Financeiro: parcelas em aberto e atraso < 30 dias", "Conferir parcelas", "Média (provisória)", "Financeiro"],
    ["Financeiro: sem indicador suficiente", "Consultar situação atual", "A verificar", "Financeiro"],
    ["Rematrícula", "Conferir calendário, requisitos e eventuais bloqueios", "A verificar", "Secretaria"],
    ["Bolsa", "Conferir regras, situação e renovação", "A verificar", "Bolsas/atendimento"],
    ["Documentos", "Conferir lista exigida e recebimento", "A verificar", "Secretaria"],
], columns=["Condição", "Resultado", "Prioridade", "Setor"])
display(tabela_decisao)

def orientar_aluno(id_aluno, pedido):
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
        if pd.isna(aberto):
            checklist, prioridade, motivo = "Consultar parcelas no sistema", "A verificar", "Indicador ausente"
        elif aberto > 0:
            checklist = "Conferir parcelas em aberto e eventuais acordos"
            prioridade = "Alta (provisória)" if pd.notna(atraso) and atraso >= 30 else "Média (provisória)"
            motivo = "Indicador de parcelas em aberto; atraso médio: " + (str(round(atraso, 1)) if pd.notna(atraso) else "não informado")
        else:
            checklist, prioridade, motivo = "Confirmar situação financeira atual", "A verificar", "Sem parcelas em aberto no indicador resumido"
        return {"Assunto": assunto, "Checklist": checklist, "Prioridade": prioridade,
                "Próxima ação": "Conferir no sistema financeiro e orientar o aluno",
                "Justificativa": motivo, "Setor": "Financeiro"}
    orientacoes = {
        "rematricula": ("Conferir calendário, documentos e requisitos da rematrícula", "Consultar situação atual e regras oficiais", "Secretaria acadêmica"),
        "bolsa": ("Conferir registro, condições e documentos da bolsa", "Consultar situação e regras de renovação", "Setor de bolsas"),
        "documentos": ("Conferir documentos exigidos e recebimento", "Verificar documentos pendentes no sistema", "Secretaria acadêmica"),
    }
    checklist, proxima, setor = orientacoes[assunto]
    return {"Assunto": assunto, "Checklist": checklist, "Prioridade": "A verificar",
            "Próxima ação": proxima, "Justificativa": "A base não confirma a pendência específica deste procedimento",
            "Setor": setor}

# Demonstração com ID fictício retirado da base; não publicar dados pessoais.
id_exemplo = dados.iloc[0]["ID_ALUNO"]
for pedido in ["quero verificar parcelas em aberto", "quero fazer rematrícula",
               "quero renovar minha bolsa", "quais documentos faltam"]:
    print("\nSOLICITAÇÃO:", pedido)
    display(pd.DataFrame([orientar_aluno(id_exemplo, pedido)]))

