import os
import sys

# Adiciona o diretório da API ao path para permitir imports
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "../api")))

from app.core.database import SessionLocal, init_db
from app.core.security import get_password_hash
from app.models.user import User, ProfileType
from app.models.audit import AuditLog


def seed_database():
    """Popula o banco com dados fictícios de estudantes, atendentes e administradores."""
    init_db()
    db = SessionLocal()

    try:
        users_data = [
            {
                "ra_or_email": "123456",
                "email": "aluno@fecap.br",
                "full_name": "Lucas Alvarista Silva",
                "password": "senha123",
                "profile_type": ProfileType.ALUNO,
                "ra": "123456",
                "course": "Ciência da Computação",
                "semester": 5,
                "campus": "Campus Liberdade",
            },
            {
                "ra_or_email": "234567",
                "email": "beatriz@fecap.br",
                "full_name": "Beatriz Mendes Costa",
                "password": "senha123",
                "profile_type": ProfileType.ALUNO,
                "ra": "234567",
                "course": "Administração de Empresas",
                "semester": 3,
                "campus": "Campus Liberdade",
            },
            {
                "ra_or_email": "345678",
                "email": "carlos@fecap.br",
                "full_name": "Carlos Eduardo Santos",
                "password": "senha123",
                "profile_type": ProfileType.ALUNO,
                "ra": "345678",
                "course": "Engenharia de Software",
                "semester": 7,
                "campus": "Campus Liberdade",
            },
            {
                "ra_or_email": "atendente@fecap.br",
                "email": "atendente@fecap.br",
                "full_name": "Mariana Atendente ASA",
                "password": "senha123",
                "profile_type": ProfileType.ATENDENTE_ASA,
                "ra": "AT9901",
                "course": "Área de Sucesso Alvarista",
                "semester": None,
                "campus": "Campus Liberdade",
            },
            {
                "ra_or_email": "admin@fecap.br",
                "email": "admin@fecap.br",
                "full_name": "Coordenação Geral ASA",
                "password": "senha123",
                "profile_type": ProfileType.ADMINISTRADOR,
                "ra": "ADM001",
                "course": "Diretoria Acadêmica",
                "semester": None,
                "campus": "Campus Liberdade",
            },
            {
                "ra_or_email": "prof.almeida@fecap.br",
                "email": "prof.almeida@fecap.br",
                "full_name": "Prof. Dr. Roberto Almeida",
                "password": "senha123",
                "profile_type": ProfileType.PROFESSOR,
                "ra": "PF102",
                "course": "Corpo Docente CC",
                "semester": None,
                "campus": "Campus Liberdade",
            },
            {
                "ra_or_email": "responsavel@fecap.br",
                "email": "responsavel@fecap.br",
                "full_name": "Ana Paula Silva (Mãe/Responsável)",
                "password": "senha123",
                "profile_type": ProfileType.RESPONSAVEL,
                "ra": "RP501",
                "course": "Responsável Legal",
                "semester": None,
                "campus": "Campus Liberdade",
            },
            {
                "ra_or_email": "colaborador@fecap.br",
                "email": "colaborador@fecap.br",
                "full_name": "Secretaria Acadêmica Central",
                "password": "senha123",
                "profile_type": ProfileType.COLABORADOR,
                "ra": "CL301",
                "course": "Secretaria Geral",
                "semester": None,
                "campus": "Campus Liberdade",
            },
        ]

        created_count = 0
        for u in users_data:
            existing = db.query(User).filter(User.ra_or_email == u["ra_or_email"]).first()
            if not existing:
                new_user = User(
                    ra_or_email=u["ra_or_email"],
                    email=u["email"],
                    full_name=u["full_name"],
                    hashed_password=get_password_hash(u["password"]),
                    profile_type=u["profile_type"],
                    ra=u["ra"],
                    course=u["course"],
                    semester=u["semester"],
                    campus=u["campus"],
                    is_active=True,
                )
                db.add(new_user)
                created_count += 1

        db.commit()
        print(f"Seed concluído com sucesso: {created_count} novos usuários fictícios criados.")
    finally:
        db.close()


if __name__ == "__main__":
    seed_database()
