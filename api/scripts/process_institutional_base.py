import os
import sys
import re
import zipfile
import io
import sqlite3
import xml.etree.ElementTree as ET
from datetime import datetime

ZIP_PATH = r"D:\projetos\Asa-Connect-plus\Base.zip"
OUTPUT_DIR = r"D:\projetos\ASA-PI\Projeto2\src\backend\app\data\base_institucional"
DB_PATH = os.path.join(OUTPUT_DIR, "institutional_data.db")
KB_DIR = r"D:\projetos\ASA-PI\Projeto2\src\backend\app\knowledge_base\dados_estruturados"

os.makedirs(OUTPUT_DIR, exist_ok=True)
os.makedirs(KB_DIR, exist_ok=True)

def col_letter_to_index(col_str):
    idx = 0
    for char in col_str:
        idx = idx * 26 + (ord(char) - ord('A') + 1)
    return idx - 1

def parse_xlsx_stream(xlsx_bytes):
    with zipfile.ZipFile(io.BytesIO(xlsx_bytes)) as xz:
        sst = []
        if 'xl/sharedStrings.xml' in xz.namelist():
            root = ET.fromstring(xz.read('xl/sharedStrings.xml'))
            for si in root.findall('{http://schemas.openxmlformats.org/spreadsheetml/2006/main}si'):
                texts = [t.text for t in si.findall('.//{http://schemas.openxmlformats.org/spreadsheetml/2006/main}t') if t.text]
                sst.append(''.join(texts))

        sheet_xml = xz.read('xl/worksheets/sheet1.xml')
        del xz

    context = ET.iterparse(io.BytesIO(sheet_xml), events=('end',))
    ns = '{http://schemas.openxmlformats.org/spreadsheetml/2006/main}'

    for event, elem in context:
        if elem.tag == f'{ns}row':
            cells_dict = {}
            for c in elem.findall(f'{ns}c'):
                r_attr = c.attrib.get('r', '')
                col_match = re.match(r'([A-Z]+)', r_attr)
                if not col_match:
                    continue
                col_idx = col_letter_to_index(col_match.group(1))

                t_attr = c.attrib.get('t', '')
                if t_attr == 's':
                    v_elem = c.find(f'{ns}v')
                    val = sst[int(v_elem.text)] if (v_elem is not None and v_elem.text and v_elem.text.isdigit()) else ''
                elif t_attr == 'inlineStr':
                    is_elem = c.find(f'{ns}is')
                    if is_elem is not None:
                        t_e = is_elem.find(f'{ns}t')
                        val = t_e.text if (t_e is not None and t_e.text) else ''
                    else:
                        val = ''
                else:
                    v_elem = c.find(f'{ns}v')
                    val = v_elem.text if (v_elem is not None and v_elem.text) else ''
                cells_dict[col_idx] = val

            max_col = max(cells_dict.keys()) if cells_dict else 0
            row_list = [cells_dict.get(i, '') for i in range(max_col + 1)]
            yield row_list
            elem.clear()

def process_all():
    print(f"[{datetime.now().strftime('%H:%M:%S')}] Abrindo {ZIP_PATH}...")
    with zipfile.ZipFile(ZIP_PATH, 'r') as mz:
        file_list = mz.namelist()
        print(f"Arquivos no ZIP: {file_list}")

        conn = sqlite3.connect(DB_PATH)
        cur = conn.cursor()
        cur.execute("PRAGMA synchronous = OFF;")
        cur.execute("PRAGMA journal_mode = MEMORY;")

        # 1. Contato
        if "Contato.xlsx" in file_list:
            print(f"[{datetime.now().strftime('%H:%M:%S')}] Processando Contato.xlsx...")
            cur.execute("DROP TABLE IF EXISTS contato;")
            cur.execute("""
                CREATE TABLE contato (
                    id_aluno TEXT PRIMARY KEY,
                    idade INTEGER,
                    bairro TEXT,
                    cidade TEXT,
                    estado TEXT,
                    estado_civil TEXT,
                    sexo TEXT
                );
            """)
            rows_gen = parse_xlsx_stream(mz.read("Contato.xlsx"))
            header = next(rows_gen, None)
            batch = []
            count = 0
            for r in rows_gen:
                if not r or not r[0]:
                    continue
                aluno_id = str(r[0]).strip()
                idade = int(float(r[1])) if len(r) > 1 and r[1] and r[1].replace('.', '', 1).isdigit() else None
                bairro = r[2] if len(r) > 2 else None
                cidade = r[3] if len(r) > 3 else None
                estado = r[4] if len(r) > 4 else None
                est_civil = r[5] if len(r) > 5 else None
                sexo = r[6] if len(r) > 6 else None
                batch.append((aluno_id, idade, bairro, cidade, estado, est_civil, sexo))
                count += 1
                if len(batch) >= 10000:
                    cur.executemany("INSERT OR REPLACE INTO contato VALUES (?,?,?,?,?,?,?)", batch)
                    batch = []
            if batch:
                cur.executemany("INSERT OR REPLACE INTO contato VALUES (?,?,?,?,?,?,?)", batch)
            conn.commit()
            print(f"Contato concluído: {count} registros inseridos.")

        # 2. Matriculas
        if "Matriculas.xlsx" in file_list:
            print(f"[{datetime.now().strftime('%H:%M:%S')}] Processando Matriculas.xlsx...")
            cur.execute("DROP TABLE IF EXISTS matriculas;")
            cur.execute("""
                CREATE TABLE matriculas (
                    id_aluno TEXT,
                    periodo_letivo_atual TEXT,
                    forma_ingresso TEXT,
                    curso TEXT,
                    grau_academico TEXT,
                    turno TEXT,
                    periodo_ingresso TEXT,
                    risco_evasao INTEGER,
                    periodo_academico TEXT,
                    status_academico TEXT
                );
            """)
            rows_gen = parse_xlsx_stream(mz.read("Matriculas.xlsx"))
            header = next(rows_gen, None)
            batch = []
            count = 0
            for r in rows_gen:
                if not r or not r[0]:
                    continue
                aluno_id = str(r[0]).strip()
                periodo_letivo = r[1] if len(r) > 1 else None
                forma_ingresso = r[2] if len(r) > 2 else None
                curso = r[3] if len(r) > 3 else None
                grau = r[4] if len(r) > 4 else None
                turno = r[5] if len(r) > 5 else None
                periodo_ingr = r[6] if len(r) > 6 else None
                risco = int(float(r[7])) if len(r) > 7 and r[7] and r[7].isdigit() else 0
                periodo_acad = r[8] if len(r) > 8 else None
                status_acad = r[10] if len(r) > 10 else (r[9] if len(r) > 9 else None)
                batch.append((aluno_id, periodo_letivo, forma_ingresso, curso, grau, turno, periodo_ingr, risco, periodo_acad, status_acad))
                count += 1
                if len(batch) >= 10000:
                    cur.executemany("INSERT INTO matriculas VALUES (?,?,?,?,?,?,?,?,?,?)", batch)
                    batch = []
            if batch:
                cur.executemany("INSERT INTO matriculas VALUES (?,?,?,?,?,?,?,?,?,?)", batch)
            cur.execute("CREATE INDEX IF NOT EXISTS idx_mat_aluno ON matriculas(id_aluno);")
            cur.execute("CREATE INDEX IF NOT EXISTS idx_mat_curso ON matriculas(curso);")
            conn.commit()
            print(f"Matriculas concluído: {count} registros inseridos.")

        # 3. Relacionamentos
        if "Relacionamentos.xlsx" in file_list:
            print(f"[{datetime.now().strftime('%H:%M:%S')}] Processando Relacionamentos.xlsx...")
            cur.execute("DROP TABLE IF EXISTS relacionamentos;")
            cur.execute("""
                CREATE TABLE relacionamentos (
                    id_aluno TEXT,
                    codigo TEXT,
                    tema_relacionamento TEXT,
                    motivo_contato TEXT,
                    motivo_evasao TEXT,
                    alternativa_permanencia TEXT,
                    data_criacao TEXT
                );
            """)
            rows_gen = parse_xlsx_stream(mz.read("Relacionamentos.xlsx"))
            header = next(rows_gen, None)
            batch = []
            count = 0
            for r in rows_gen:
                if not r or not r[0]:
                    continue
                aluno_id = str(r[0]).strip()
                codigo = str(r[1]).strip() if len(r) > 1 else None
                tema = r[2] if len(r) > 2 else None
                motivo_contato = r[3] if len(r) > 3 else None
                motivo_evasao = r[4] if len(r) > 4 else None
                alt_perm = r[5] if len(r) > 5 else None
                data_criacao = str(r[6]) if len(r) > 6 else None
                batch.append((aluno_id, codigo, tema, motivo_contato, motivo_evasao, alt_perm, data_criacao))
                count += 1
                if len(batch) >= 10000:
                    cur.executemany("INSERT INTO relacionamentos VALUES (?,?,?,?,?,?,?)", batch)
                    batch = []
            if batch:
                cur.executemany("INSERT INTO relacionamentos VALUES (?,?,?,?,?,?,?)", batch)
            cur.execute("CREATE INDEX IF NOT EXISTS idx_rel_aluno ON relacionamentos(id_aluno);")
            cur.execute("CREATE INDEX IF NOT EXISTS idx_rel_tema ON relacionamentos(tema_relacionamento);")
            conn.commit()
            print(f"Relacionamentos concluído: {count} registros inseridos.")

        # 4. Historico
        if "Historico.xlsx" in file_list:
            print(f"[{datetime.now().strftime('%H:%M:%S')}] Processando Historico.xlsx...")
            cur.execute("DROP TABLE IF EXISTS historico;")
            cur.execute("""
                CREATE TABLE historico (
                    id_aluno TEXT,
                    ano_semestre TEXT,
                    periodo_oferta TEXT,
                    perc_assiduidade REAL,
                    perc_faltas REAL,
                    perc_nota REAL,
                    aulas_ministradas REAL,
                    nota_distribuida REAL,
                    disciplina TEXT,
                    situacao TEXT,
                    nota_obtida REAL,
                    faltas_lancadas REAL
                );
            """)
            rows_gen = parse_xlsx_stream(mz.read("Historico.xlsx"))
            header = next(rows_gen, None)
            batch = []
            count = 0
            for r in rows_gen:
                if not r or not r[0]:
                    continue
                aluno_id = str(r[0]).strip()
                ano_sem = r[1] if len(r) > 1 else None
                per_oferta = r[2] if len(r) > 2 else None
                assiduidade = float(r[3]) if len(r) > 3 and r[3] and r[3].replace('.', '', 1).replace('-', '', 1).isdigit() else None
                faltas_p = float(r[4]) if len(r) > 4 and r[4] and r[4].replace('.', '', 1).replace('-', '', 1).isdigit() else None
                perc_nota = float(r[5]) if len(r) > 5 and r[5] and r[5].replace('.', '', 1).replace('-', '', 1).isdigit() else None
                aulas = float(r[6]) if len(r) > 6 and r[6] and r[6].replace('.', '', 1).isdigit() else None
                nota_dist = float(r[7]) if len(r) > 7 and r[7] and r[7].replace('.', '', 1).isdigit() else None
                disciplina = r[8] if len(r) > 8 else None
                situacao = r[9] if len(r) > 9 else None
                nota_obt = float(r[10]) if len(r) > 10 and r[10] and r[10].replace('.', '', 1).replace('-', '', 1).isdigit() else None
                faltas_l = float(r[11]) if len(r) > 11 and r[11] and r[11].replace('.', '', 1).isdigit() else None

                batch.append((aluno_id, ano_sem, per_oferta, assiduidade, faltas_p, perc_nota, aulas, nota_dist, disciplina, situacao, nota_obt, faltas_l))
                count += 1
                if len(batch) >= 10000:
                    cur.executemany("INSERT INTO historico VALUES (?,?,?,?,?,?,?,?,?,?,?,?)", batch)
                    batch = []
            if batch:
                cur.executemany("INSERT INTO historico VALUES (?,?,?,?,?,?,?,?,?,?,?,?)", batch)
            cur.execute("CREATE INDEX IF NOT EXISTS idx_hist_aluno ON historico(id_aluno);")
            cur.execute("CREATE INDEX IF NOT EXISTS idx_hist_disc ON historico(disciplina);")
            conn.commit()
            print(f"Historico concluído: {count} registros inseridos.")

        # 5. Financeiro
        if "Financeiro.xlsx" in file_list:
            print(f"[{datetime.now().strftime('%H:%M:%S')}] Processando Financeiro.xlsx...")
            cur.execute("DROP TABLE IF EXISTS financeiro;")
            cur.execute("""
                CREATE TABLE financeiro (
                    id_aluno TEXT,
                    unidade TEXT,
                    periodo_letivo TEXT,
                    curso TEXT,
                    parcela TEXT,
                    servico_parcela TEXT,
                    bolsa_aluno TEXT,
                    valor_original REAL,
                    status_lancamento TEXT,
                    data_vencimento TEXT,
                    data_baixa TEXT
                );
            """)
            rows_gen = parse_xlsx_stream(mz.read("Financeiro.xlsx"))
            header = next(rows_gen, None)
            batch = []
            count = 0
            for r in rows_gen:
                if not r or not r[0]:
                    continue
                aluno_id = str(r[0]).strip()
                unidade = r[1] if len(r) > 1 else None
                per_letivo = r[2] if len(r) > 2 else None
                curso = r[3] if len(r) > 3 else None
                parcela = str(r[4]) if len(r) > 4 else None
                servico = r[5] if len(r) > 5 else None
                bolsa = r[6] if len(r) > 6 else None
                valor = float(r[7]) if len(r) > 7 and r[7] and r[7].replace('.', '', 1).isdigit() else None
                status = r[8] if len(r) > 8 else None
                dt_venc = str(r[9]) if len(r) > 9 else None
                dt_baixa = str(r[10]) if len(r) > 10 else None

                batch.append((aluno_id, unidade, per_letivo, curso, parcela, servico, bolsa, valor, status, dt_venc, dt_baixa))
                count += 1
                if len(batch) >= 10000:
                    cur.executemany("INSERT INTO financeiro VALUES (?,?,?,?,?,?,?,?,?,?,?)", batch)
                    batch = []
            if batch:
                cur.executemany("INSERT INTO financeiro VALUES (?,?,?,?,?,?,?,?,?,?,?)", batch)
            cur.execute("CREATE INDEX IF NOT EXISTS idx_fin_aluno ON financeiro(id_aluno);")
            cur.execute("CREATE INDEX IF NOT EXISTS idx_fin_status ON financeiro(status_lancamento);")
            cur.execute("CREATE INDEX IF NOT EXISTS idx_fin_bolsa ON financeiro(bolsa_aluno);")
            conn.commit()
            print(f"Financeiro concluído: {count} registros inseridos.")

        # Re-ativar sincronismo padrão
        cur.execute("PRAGMA synchronous = NORMAL;")
        cur.execute("PRAGMA journal_mode = WAL;")
        conn.close()
        print(f"[{datetime.now().strftime('%H:%M:%S')}] SQLite criado com sucesso em {DB_PATH}!")

if __name__ == "__main__":
    process_all()
