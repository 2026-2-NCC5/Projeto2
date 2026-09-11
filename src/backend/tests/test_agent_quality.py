import pytest
from app.agent.rag_pipeline import rag_pipeline


def test_atestado_matricula_answer_quality():
    """Valida que a solicitação de atestado traz passo a passo e alta confiança."""
    ans = rag_pipeline.answer_query("Como faço para solicitar o atestado de matrícula?")
    assert ans["is_abstained"] is False
    assert ans["confidence_score"] >= 0.70
    assert "Fonte: Atestado de Matrícula" in ans["source_citation"]
    assert "Portal do Aluno" in ans["content"]
    assert "Secretaria" in ans["suggested_action"]


def test_biblioteca_multa_answer_quality():
    """Valida resposta sobre a multa diária da biblioteca Paulo Ernesto Tolle."""
    ans = rag_pipeline.answer_query("Qual o valor da multa por dia de atraso na devolução de livros da biblioteca?")
    assert ans["is_abstained"] is False
    assert ans["confidence_score"] >= 0.70
    assert "5,00" in ans["content"] or "R$5" in ans["content"] or "R$ 5" in ans["content"]
    assert "Biblioteca" in ans["source_citation"]
    assert "Biblioteca" in ans["suggested_action"]


def test_transferencia_turno_answer_quality():
    """Valida recuperação de prazos de transferência de turno."""
    ans = rag_pipeline.answer_query("Qual o prazo para solicitar transferência de turno em 2026?")
    assert ans["is_abstained"] is False
    assert ans["confidence_score"] >= 0.70
    assert "Transferência de Turno" in ans["source_citation"] or "Transferência de turno" in ans["source_citation"]
    assert "Portal do Aluno" in ans["content"] or "Transferência" in ans["suggested_action"]


def test_colaplagio_conduta_answer_quality():
    """Valida recuperação das regras de integridade e cola em provas."""
    ans = rag_pipeline.answer_query("O que acontece se um aluno for pego colando na prova?")
    assert ans["is_abstained"] is False
    assert ans["confidence_score"] >= 0.60
    assert "reprovação" in ans["content"].lower() or "plágio" in ans["content"].lower() or "cola" in ans["content"].lower()


def test_out_of_scope_abstention_guarantee():
    """Garante abstenção total para perguntas fora do escopo acadêmico/institucional."""
    ans = rag_pipeline.answer_query("Qual a receita do bolo de cenoura com cobertura de chocolate?")
    assert ans["is_abstained"] is True
    assert ans["confidence_score"] < 0.60
    assert "Não encontrei uma informação oficial" in ans["content"]
    assert "atendente" in ans["content"]
