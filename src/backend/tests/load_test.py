"""
ASA Connect+ — Teste de Carga com Locust (Entrega 2)
=====================================================
Simula usuários concorrentes interagindo com a API.

Uso rápido (headless):
  locust -f tests/load_test.py --host http://localhost:8080 \\
         --users 50 --spawn-rate 5 --run-time 2m --headless

Interface Web (abre http://localhost:8089):
  locust -f tests/load_test.py --host http://localhost:8080
"""

import random
from locust import HttpUser, task, between, events

TEST_USERS = [
    {"username": "123456",               "password": "senha123"},
    {"username": "prof.almeida@fecap.br", "password": "senha123"},
    {"username": "colaborador@fecap.br",  "password": "senha123"},
]

ADMIN_USER = {"username": "atendente@fecap.br", "password": "senha123"}

CHAT_QUESTIONS = [
    "Qual é o calendário acadêmico do segundo semestre?",
    "Como faço para solicitar revisão de nota?",
    "Quais são os horários do restaurante universitário?",
    "Como funciona o sistema de bolsas da FECAP?",
    "Preciso de um atestado de matrícula, como solicito?",
    "Qual é o prazo para trancamento de disciplina?",
    "Como acesso o portal do aluno?",
    "Quais são as regras de frequência mínima?",
    "Onde fica a secretaria acadêmica?",
    "Como solicitar aproveitamento de disciplina?",
]


class StudentUser(HttpUser):
    """Simula aluno típico: login → perfil → chat. Peso 70% do tráfego."""
    wait_time = between(1, 3)
    weight = 70

    def on_start(self):
        user = random.choice(TEST_USERS)
        with self.client.post(
            "/api/v1/auth/login",
            data={"username": user["username"], "password": user["password"]},
            catch_response=True,
            name="/api/v1/auth/login",
        ) as resp:
            if resp.status_code == 200:
                self.token = resp.json().get("access_token", "")
                self.headers = {"Authorization": f"Bearer {self.token}"}
                resp.success()
            else:
                self.token = None
                self.headers = {}
                resp.failure(f"Login falhou: {resp.status_code}")

    @task(3)
    def chat_message(self):
        """Envia pergunta ao agente RAG — tarefa mais pesada."""
        if not self.token:
            return
        with self.client.post(
            "/api/v1/chat/message",
            json={"content": random.choice(CHAT_QUESTIONS)},
            headers=self.headers,
            catch_response=True,
            name="/api/v1/chat/message",
        ) as resp:
            if resp.status_code in (200, 201):
                resp.success()
            elif resp.status_code == 401:
                resp.failure("Token expirado")
            else:
                resp.failure(f"Chat erro: {resp.status_code}")

    @task(2)
    def get_profile(self):
        """Consulta perfil do usuário logado."""
        if not self.token:
            return
        self.client.get(
            "/api/v1/profile/me",
            headers=self.headers,
            name="/api/v1/profile/me",
        )

    @task(1)
    def health_check(self):
        """Healthcheck periódico."""
        self.client.get("/health", name="/health")


class AdminUser(HttpUser):
    """Simula atendente consultando o dashboard. Peso 30% do tráfego."""
    wait_time = between(5, 10)
    weight = 30

    def on_start(self):
        with self.client.post(
            "/api/v1/auth/login",
            data={"username": ADMIN_USER["username"], "password": ADMIN_USER["password"]},
            catch_response=True,
            name="/api/v1/auth/login [admin]",
        ) as resp:
            if resp.status_code == 200:
                self.token = resp.json().get("access_token", "")
                self.headers = {"Authorization": f"Bearer {self.token}"}
                resp.success()
            else:
                self.token = None
                self.headers = {}
                resp.failure(f"Login admin falhou: {resp.status_code}")

    @task(2)
    def dashboard_stats(self):
        if not self.token:
            return
        self.client.get(
            "/api/v1/dashboard/stats",
            headers=self.headers,
            name="/api/v1/dashboard/stats",
        )

    @task(1)
    def list_escalations(self):
        if not self.token:
            return
        self.client.get(
            "/api/v1/escalations/",
            headers=self.headers,
            name="/api/v1/escalations/",
        )


@events.quitting.add_listener
def on_quitting(environment, **kwargs):
    """Exibe resumo de métricas ao final do teste."""
    stats = environment.stats
    print("\n" + "=" * 60)
    print("  ASA Connect+ — Resultado do Teste de Carga")
    print("=" * 60)
    for name, entry in stats.entries.items():
        if entry.num_requests > 0:
            print(f"\n  [{name[0]}] {name[1]}")
            print(f"    Requisições : {entry.num_requests}")
            print(f"    Falhas      : {entry.num_failures} ({entry.fail_ratio*100:.1f}%)")
            print(f"    Latência    : avg={entry.avg_response_time:.0f}ms  p95={entry.get_response_time_percentile(0.95):.0f}ms  p99={entry.get_response_time_percentile(0.99):.0f}ms")
            print(f"    Throughput  : {entry.total_rps:.2f} req/s")
    print("=" * 60)

