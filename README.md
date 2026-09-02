# Projeto2

## FECAP - Fundação de Comércio Álvares Penteado

<p align="center">
  <a href="https://www.fecap.br/">
    <img src="https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRhZPrRa89Kma0ZZogxm0pi-tCn_TLKeHGVxywp-LXAFGR3B1DPouAJYHgKZGV0XTEf4AE&usqp=CAU" alt="FECAP - Fundação de Comércio Álvares Penteado" border="0">
  </a>
</p>



# ASA - Agentes Inteligentes para o Sucesso do Estudante

## 👥 Grupo: CorePI

## Integrantes

* **[Gustavo Henrique Da Silva Santos](https://github.com/GSPrograms)**
* **[Luan Rocha da Silva](https://github.com/LuanRoccha13)**
* **[Saulo Ribeiro Santos](mailto:santos.saulo@edu.fecap.br)**
* **[Thiffany Morais Vieira da Silva](https://github.com/thiffanymorais)**

---

### 📚 Professor Orientador

* **[Rafael Diogo Rossetti](https://www.linkedin.com/in/rafael-rossetti/)**

### 📔 Orientadores Complementares

* **[Marcelo de Moura Amorim](#)**
* **[Marcos Minoru Nakatsugawa](#)**
* **[Rodnil da Silva Moreira Lisboa](https://www.linkedin.com/in/professorrodnil/)**
* **[Rodrigo da Rosa](#)**

## 📖 1. Apresentação do Projeto
A **Área do Sucesso Alvarista (ASA)** acolhe e acompanha os estudantes ao longo de sua jornada na **FECAP**, com foco no acolhimento, na permanência e no sucesso acadêmico. O objetivo deste projeto é desenvolver uma solução baseada em **Agentes Inteligentes** — composta por aplicação mobile, serviços de Inteligência Artificial, API e infraestrutura em nuvem —, capaz de analisar dados autorizados, apoiar os atendentes do ASA, orientar os estudantes e sinalizar situações que necessitem de acompanhamento preventivo.

A solução explora princípios de **Inteligência Artificial**, **Programação Mobile**, **Álgebra Linear** e **Computação em Nuvem**, garantindo explicabilidade dos resultados, preservação da privacidade e manutenção da validação humana nas decisões.

---

## 🛠 2. Estrutura de Pastas
Conforme os requisitos das disciplinas:
```text
📁 Documentos
 └── 📁 Entrega_1
 └── 📁 Entrega_2
📁 src
 └── 📁 backend
 └── 📁 mobile
 └── 📁 notebooks
📄 .gitignore
📄 README.md
```

---

## 🚀 3. Como Executar o Projeto

### Pré-requisitos
- **Python 3.11+**
- **Flutter SDK 3.x**
- *(Opcional)* **Docker e Docker Compose**

---

### ⚙️ 3.1 Backend (FastAPI + RAG)

1. Navegue até a pasta do backend:
   ```bash
   cd src/backend
   ```
2. Crie e ative o ambiente virtual:
   ```bash
   # Windows (PowerShell)
   python -m venv .venv
   .venv\Scripts\Activate.ps1

   # Linux / macOS
   python3 -m venv .venv
   source .venv/bin/activate
   ```
3. Instale as dependências:
   ```bash
   pip install -r requirements.txt
   ```
4. *(Opcional)* Copie o arquivo de variáveis de ambiente:
   ```bash
   cp .env.example .env
   ```
5. Inicie o servidor da API:
   ```bash
   uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
   ```
   > 📍 **API Backend:** [http://localhost:8000](http://localhost:8000)  
   > 📖 **Documentação Swagger (OpenAPI):** [http://localhost:8000/docs](http://localhost:8000/docs)  
   > 🧪 **Executar testes automatizados:** `pytest` (22 testes)

*(Alternativa com Docker)*:
```bash
cd src/backend
docker compose up -d
```

---

### 📱 3.2 Mobile (Flutter)

1. Em outro terminal, navegue até a pasta do mobile:
   ```bash
   cd src/mobile
   ```
2. Baixe as dependências do Flutter:
   ```bash
   flutter pub get
   ```
3. Execute o aplicativo no navegador (Google Chrome):
   ```bash
   flutter run -d chrome --web-port=3000
   ```
   > 📍 **App no Navegador:** [http://localhost:3000](http://localhost:3000)

---

### 🔑 3.3 Credenciais de Teste para Avaliação

O banco de dados SQLite local é inicializado automaticamente com os seguintes usuários fictícios:

| Perfil | Identificador (RA / E-mail) | Senha | Acesso / Permissão |
|---|---|---|---|
| **Aluno** | `123456` | `senha123` | Orientações RAG, serviços, requerimentos |
| **Atendente ASA** | `atendente@fecap.br` | `senha123` | Fila humana, escalonamentos e triagem |
| **Administrador** | `admin@fecap.br` | `senha123` | Painel gerencial, auditoria e métricas RAG |

---

## 📋 Licença/License

A licença desse projeto é a <a href="https://creativecommons.org/licenses/by-sa/4.0/">Creative Commons BY-SA 4.0<a/>.

---
## 🎓 Referências

Aqui estão as referências usadas no projeto.

* [FECAP - Área do Sucesso Alvarista (ASA)](https://www.fecap.br/asa/)
