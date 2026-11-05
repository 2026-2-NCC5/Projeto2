# Guia Definitivo: Como Rodar o ASA Connect 🚀

Este guia foi feito para você rodar o projeto completo de forma simples e rápida, mesmo em outro computador.

---

## 📋 Resumo em 1 Clique (100% na Nuvem)

O ASA Connect agora está **hospedado na nuvem (Render + Supabase PostgreSQL)**.
Você **NÃO precisa mais ligar nenhum servidor local no seu PC** nem usar túnel USB!

Basta dar duplo clique em:
👉 **`instalar_apk_no_celular.bat`**  
Ele limpa qualquer cache antigo do celular, instala a versão mais recente oficial e abre o app pronto para uso.

*(Opcional: se quiser testar no navegador do computador sem celular, basta acessar diretamente pelo link oficial da nuvem: https://projeto2-7gf7.onrender.com ou usar `rodar_no_navegador.bat`)*.

---

## 🔑 Credenciais para Teste

Ao abrir o app, você pode clicar diretamente na foto de qualquer persona ou digitar os dados abaixo:

| Perfil | E-mail ou RA | Senha | O que faz |
| :--- | :--- | :--- | :--- |
| **Aluno** | `aluno@fecap.br` *(ou `123456`)* | `senha123` | Acesso completo a solicitações, documentos, serviços acadêmicos e chat com IA RAG. |
| **Atendente ASA** | `atendente@fecap.br` | `senha123` | Visão de atendente acadêmico e fila de chamados. |
| **Coordenação / Admin** | `admin@fecap.br` | `senha123` | Painel de controle e auditoria acadêmica. |

---

## 📱 Dicas para Conectar o Celular via USB

Para o celular se comunicar com o computador sem erros:
1. **Ative a Depuração USB:**
   * No celular, vá em **Configurações > Opções do Desenvolvedor > Depuração USB** e ative.
2. **Conecte o cabo USB:**
   * Se aparecer a pergunta *"Permitir depuração USB?"*, marque a caixa **"Sempre permitir a partir deste computador"** e toque em **Permitir**.
3. **Mantenha a tela desbloqueada** na primeira vez que rodar o túnel.

---

## 🌐 Opção Alternativa: Testar no Navegador do PC (Chrome)

Se você não estiver com o celular ou cabo por perto e quiser ver a interface rodando no computador:
1. Dê dois cliques em **`iniciar_backend.bat`**.
2. Dê dois cliques em **`rodar_no_navegador.bat`**.
3. O Chrome abrirá com o app completo do ASA Connect rodando na Web!

---

## 🛠️ Comandos Manuais no Terminal (Se preferir usar o terminal)

### 1. Iniciar o Backend:
```powershell
cd api
# Ativar venv e rodar
.venv\Scripts\activate
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

### 2. Ativar o Túnel USB (ADB Reverse):
```powershell
adb reverse tcp:8000 tcp:8000
```

### 3. Rodar o App no Celular com Flutter:
```powershell
cd app
flutter pub get
flutter run
```
