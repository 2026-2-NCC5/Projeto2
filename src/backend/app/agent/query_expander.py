import re
import unicodedata
from typing import Dict, List, Tuple, Optional


def _normalize(text: str) -> str:
    if not text:
        return ""
    text = unicodedata.normalize("NFKD", text)
    text = "".join([c for c in text if not unicodedata.combining(c)])
    text = text.lower()
    text = re.sub(r"[^\w\s]", " ", text)
    return re.sub(r"\s+", " ", text).strip()


class QueryExpander:
    """
    Motor de Mapeamento Semântico e Expansão de Intenções Acadêmicas (FECAP).
    Converte linguagem coloquial, gírias e formulações indiretas de alunos em
    termos institucionais canônicos para busca RAG de alta fidelidade.
    """

    INTENT_RULES = [
        {
            "id": "prova_substitutiva",
            "triggers": [
                r"\bsub\b", r"\bsubs\b", r"prova substitutiva", r"segunda chamada",
                r"perdi a prova", r"perder prova", r"faltei na prova", r"recuperar nota",
                r"substituir nota", r"substitutiva"
            ],
            "canonical_terms": "avaliacao substitutiva sub prova p1 p2 recuperacao de nota calendario oficial requerimento",
            "boost_keywords": ["substitutiva", "sub", "prova"],
            "category": "Secretaria",
        },
        {
            "id": "reprovacao_falta_exame",
            "triggers": [
                r"reprovar por falta", r"reprovado por falta", r"estourar em falta",
                r"estourar falta", r"estourou falta", r"muita falta", r"posso fazer exame",
                r"fazer exame final", r"direito a exame", r"direito ao exame",
                r"\brf\b", r"reprovacao por frequencia"
            ],
            "canonical_terms": "avaliacao aproveitamento escolar exames frequencia minima 75 assiduidade reprovacao por frequencia rf nota semestral exame suplementar",
            "boost_keywords": ["exame", "exames", "frequencia", "assiduidade", "reprovacao"],
            "category": "Regimento",
        },
        {
            "id": "trancamento_bolsa",
            "triggers": [
                r"trancar", r"trancamento", r"tranquei", r"congelar", r"congelamento",
                r"bolsa de estudo", r"bolsa de estudos", r"minha bolsa", r"prouni",
                r"fies", r"perco a bolsa", r"perder a bolsa"
            ],
            "canonical_terms": "trancamento da matricula semestre letivo bolsa bolsas manutencao regularidade prouni fies financeiro",
            "boost_keywords": ["trancamento", "matricula", "bolsa", "bolsas"],
            "category": "Secretaria",
        },
        {
            "id": "criterios_aprovacao",
            "triggers": [
                r"media minima", r"media para passar", r"nota para passar",
                r"criterios de aprovacao", r"quanto preciso para passar",
                r"como funciona a nota", r"porcentagem de frequencia"
            ],
            "canonical_terms": "regime academico criterios de aprovacao media semestral 6 0 frequencia minima 75 por cento carga horaria",
            "boost_keywords": ["criterios", "aprovacao", "media", "frequencia"],
            "category": "Regimento",
        },
        {
            "id": "dependencia_dp",
            "triggers": [
                r"\bdp\b", r"\bdps\b", r"dependencia", r"dependencias",
                r"reprovei na materia", r"fazer dp", r"puxar materia"
            ],
            "canonical_terms": "regime de dependencia dp reprovacao disciplina limite de creditos matricula simultanea",
            "boost_keywords": ["dependencia", "dp", "disciplina"],
            "category": "Secretaria",
        },
        {
            "id": "carteirinha",
            "triggers": [
                r"carteirinha", r"carteira de estudante", r"carteira estudantil",
                r"identificacao estudantil", r"cartao do aluno", r"cracha"
            ],
            "canonical_terms": "carteira de identificacao estudantil solicitacao foto portal do aluno dne",
            "boost_keywords": ["carteira", "identificacao", "estudantil"],
            "category": "Documentos",
        },
        {
            "id": "atestado_matricula",
            "triggers": [
                r"atestado de matricula", r"declaracao de matricula", r"declaracao de vinculo",
                r"comprovante de matricula", r"declaracao de frequencia"
            ],
            "canonical_terms": "atestado de matricula declaracao secretaria portal do aluno emissao documentos",
            "boost_keywords": ["atestado", "matricula", "secretaria"],
            "category": "Documentos",
        },
        {
            "id": "estagio_tce",
            "triggers": [
                r"estagio", r"\btce\b", r"termo de compromisso", r"relatorio de estagio",
                r"validar estagio", r"central de carreiras"
            ],
            "canonical_terms": "estagio supervisionado termo de compromisso tce central de carreiras seguro",
            "boost_keywords": ["estagio", "tce", "carreiras"],
            "category": "Estágio",
        },
        {
            "id": "biblioteca",
            "triggers": [
                r"biblioteca", r"multa", r"atraso de livro", r"renovacao de livro",
                r"pegar livro", r"paulo ernesto tolle"
            ],
            "canonical_terms": "biblioteca paulo ernesto tolle multa diaria atraso devolucao catalogo emprestimo",
            "boost_keywords": ["biblioteca", "multa", "livro"],
            "category": "Biblioteca",
        },
        {
            "id": "transferencia_turno",
            "triggers": [
                r"transferencia de turno", r"mudar de turno", r"mudar para a noite",
                r"mudar para a manha", r"trocar de turno", r"noturno", r"matutino"
            ],
            "canonical_terms": "transferencia de turno prazo requerimento portal do aluno vagas deferimento",
            "boost_keywords": ["transferencia", "turno"],
            "category": "Secretaria",
        },
        {
            "id": "financeiro_boleto",
            "triggers": [
                r"boleto", r"mensalidade", r"pagamento", r"atraso pagamento",
                r"desconto", r"parcela", r"segunda via boleto"
            ],
            "canonical_terms": "financeiro boletos mensalidade segunda via portal do aluno vencimento negociacao",
            "boost_keywords": ["financeiro", "boleto", "mensalidade"],
            "category": "Financeiro",
        },
    ]

    @classmethod
    def expand(cls, query: str) -> Tuple[str, List[str], Optional[str]]:
        norm_query = _normalize(query)
        expanded_parts = [query]
        all_boost_keywords: List[str] = []
        detected_category: Optional[str] = None

        for rule in cls.INTENT_RULES:
            matched = False
            for trig in rule["triggers"]:
                if re.search(trig, norm_query, re.IGNORECASE):
                    matched = True
                    break
            
            if matched:
                expanded_parts.append(rule["canonical_terms"])
                all_boost_keywords.extend(rule["boost_keywords"])
                if not detected_category:
                    detected_category = rule["category"]

        unique_boost_keywords = list(dict.fromkeys(all_boost_keywords))
        expanded_query = " ".join(expanded_parts)
        return expanded_query, unique_boost_keywords, detected_category


query_expander = QueryExpander()
