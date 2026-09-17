import os
import sqlite3
from typing import Dict, Any, List, Optional

def _find_default_db_path() -> str:
    possible_paths = [
        os.path.abspath(os.path.join(os.path.dirname(__file__), "../data/base_institucional/institutional_data.db")),
        os.path.abspath(os.path.join(os.path.dirname(__file__), "../../data/base_institucional/institutional_data.db")),
        os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../data/base_institucional/institutional_data.db")),
        "D:/projetos/Asa-Connect-plus/data/base_institucional/institutional_data.db",
        "D:/projetos/ASA-PI/Projeto2/src/backend/app/data/base_institucional/institutional_data.db",
    ]
    for p in possible_paths:
        if os.path.isfile(p):
            return p
    return possible_paths[0]

DB_PATH = _find_default_db_path()


class InstitutionalDataService:
    """
    Serviço analítico e operacional para consulta e inteligência sobre a
    base institucional de dados da FECAP (Contato, Matrículas, Histórico,
    Financeiro e Relacionamentos/Sucesso do Aluno).
    """

    def __init__(self, db_path: Optional[str] = None):
        self.db_path = db_path or DB_PATH

    def _get_connection(self) -> sqlite3.Connection:
        if not os.path.isfile(self.db_path):
            raise FileNotFoundError(f"Banco institucional não encontrado em: {self.db_path}")
        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row
        return conn

    def get_student_360(self, id_aluno: str) -> Optional[Dict[str, Any]]:
        """
        Retorna a visão integrada 360º de um estudante na FECAP.
        """
        id_aluno = str(id_aluno).strip()
        conn = self._get_connection()
        try:
            cur = conn.cursor()

            # Matrícula
            cur.execute("SELECT * FROM matriculas WHERE id_aluno = ? LIMIT 1;", (id_aluno,))
            mat_row = cur.fetchone()

            # Contato
            cur.execute("SELECT * FROM contato WHERE id_aluno = ? LIMIT 1;", (id_aluno,))
            contato_row = cur.fetchone()

            # Se não existir nem em matrícula nem em contato, aluno não existe na base
            if not mat_row and not contato_row:
                return None

            # Histórico
            cur.execute("""
                SELECT ano_semestre, disciplina, perc_assiduidade, perc_faltas, nota_obtida, situacao
                FROM historico
                WHERE id_aluno = ?
                ORDER BY ano_semestre DESC;
            """, (id_aluno,))
            hist_rows = [dict(r) for r in cur.fetchall()]

            # Financeiro
            cur.execute("""
                SELECT periodo_letivo, parcela, servico_parcela, bolsa_aluno, valor_original, status_lancamento, data_vencimento
                FROM financeiro
                WHERE id_aluno = ?
                ORDER BY data_vencimento DESC;
            """, (id_aluno,))
            fin_rows = [dict(r) for r in cur.fetchall()]

            # Relacionamentos / Sucesso do Aluno (ASA)
            cur.execute("""
                SELECT codigo, tema_relacionamento, motivo_contato, motivo_evasao, alternativa_permanencia, data_criacao
                FROM relacionamentos
                WHERE id_aluno = ?
                ORDER BY data_criacao DESC;
            """, (id_aluno,))
            rel_rows = [dict(r) for r in cur.fetchall()]

            return {
                "id_aluno": id_aluno,
                "matricula": dict(mat_row) if mat_row else None,
                "contato": dict(contato_row) if contato_row else None,
                "historico": hist_rows,
                "financeiro": fin_rows,
                "relacionamentos": rel_rows,
            }
        finally:
            conn.close()

    def get_institutional_kpis(self) -> Dict[str, Any]:
        """
        Calcula os principais KPIs gerenciais da instituição a partir da base integrada.
        """
        conn = self._get_connection()
        try:
            cur = conn.cursor()

            # Alunos e Evasão
            cur.execute("SELECT COUNT(DISTINCT id_aluno) FROM matriculas;")
            total_alunos = cur.fetchone()[0] or 0

            cur.execute("SELECT COUNT(*) FROM matriculas WHERE risco_evasao = 1;")
            risco_evasao = cur.fetchone()[0] or 0

            # Cursos
            cur.execute("SELECT curso, COUNT(*) as qtd FROM matriculas GROUP BY curso ORDER BY qtd DESC LIMIT 5;")
            top_cursos = [{"curso": r[0], "total": r[1]} for r in cur.fetchall()]

            # Financeiro
            cur.execute("SELECT status_lancamento, COUNT(*), ROUND(SUM(valor_original), 2) FROM financeiro GROUP BY status_lancamento;")
            fin_status = [{"status": r[0], "quantidade": r[1], "valor_total": r[2]} for r in cur.fetchall()]

            # Atendimentos ASA
            cur.execute("SELECT tema_relacionamento, COUNT(*) as qtd FROM relacionamentos GROUP BY tema_relacionamento ORDER BY qtd DESC LIMIT 5;")
            top_temas = [{"tema": r[0], "total": r[1]} for r in cur.fetchall()]

            return {
                "total_alunos_cadastrados": total_alunos,
                "alunos_em_risco_evasao": risco_evasao,
                "taxa_risco_evasao_percentual": round((risco_evasao / total_alunos * 100), 2) if total_alunos else 0.0,
                "top_cursos": top_cursos,
                "resumo_financeiro": fin_status,
                "top_temas_atendimento_asa": top_temas,
            }
        finally:
            conn.close()
