// ASA Connect+ — Interactive Mobile Web App Engine
const API_BASE = '/api/v1';

// App State
let authToken = localStorage.getItem('asa_token') || null;
let currentUser = null;
let currentConversationId = null;
let activeProfileIndex = 0;

const profiles = [
  { key: 'ALUNO', title: 'ALUNO', desc: 'ENCONTRE RESPOSTAS, SERVIÇOS E ORIENTAÇÕES ACADÊMICAS.', icon: 'fa-graduation-cap', functional: true },
  { key: 'PROFESSOR', title: 'PROFESSOR', desc: 'CONSULTE INFORMAÇÕES E PROCEDIMENTOS PARA APOIAR SUA ATIVIDADE.', icon: 'fa-chalkboard-user', functional: false },
  { key: 'RESPONSAVEL', title: 'RESPONSÁVEL', desc: 'ENCONTRE INFORMAÇÕES E ORIENTAÇÕES SOBRE OS SERVIÇOS DA INSTITUIÇÃO.', icon: 'fa-users', functional: false },
  { key: 'COLABORADOR', title: 'COLABORADOR', desc: 'ACESSE INFORMAÇÕES E PROCEDIMENTOS INSTITUCIONAIS AUTORIZADOS.', icon: 'fa-id-card-clip', functional: false },
];

// Router Functions
function navigateTo(screenId) {
  document.querySelectorAll('.app-screen').forEach(s => s.classList.remove('active'));
  const target = document.getElementById(screenId);
  if (target) target.classList.add('active');

  // Control Bottom Nav visibility
  const mainTabs = ['screen-home', 'screen-conversations', 'screen-profile'];
  const bottomNav = document.getElementById('bottom-nav-bar');
  if (mainTabs.includes(screenId)) {
    bottomNav.classList.remove('hidden');
    // update active tab icon
    document.querySelectorAll('.nav-item').forEach(btn => {
      if (btn.getAttribute('data-target') === screenId) {
        btn.classList.add('text-[#00664F]');
        btn.classList.remove('text-slate-400');
      } else {
        btn.classList.remove('text-[#00664F]');
        btn.classList.add('text-slate-400');
      }
    });
  } else {
    bottomNav.classList.add('hidden');
  }
}

// API Helper
async function apiRequest(endpoint, method = 'GET', body = null) {
  const headers = { 'Content-Type': 'application/json' };
  if (authToken) headers['Authorization'] = `Bearer ${authToken}`;

  const options = { method, headers };
  if (body) options.body = JSON.stringify(body);

  const res = await fetch(`${API_BASE}${endpoint}`, options);
  if (res.status === 401) {
    logout();
    throw new Error('Sessão expirada. Faça login novamente.');
  }
  return res;
}

// Login
async function login(identifier, password) {
  try {
    const res = await apiRequest('/auth/login', 'POST', {
      ra_or_email: identifier,
      password: password,
    });
    const data = await res.json();
    if (!res.ok) throw new Error(data.detail || 'Erro de autenticação');

    authToken = data.access_token;
    localStorage.setItem('asa_token', authToken);
    await loadUserProfile();
    navigateTo('screen-home');
  } catch (err) {
    alert(err.message);
  }
}

// User Profile
async function loadUserProfile() {
  try {
    const res = await apiRequest('/auth/me');
    if (res.ok) {
      currentUser = await res.json();
      updateUserUI();
    }
  } catch (e) {}
}

function updateUserUI() {
  if (!currentUser) return;
  const firstName = currentUser.full_name.split(' ')[0];
  const initial = firstName.charAt(0).toUpperCase();

  document.getElementById('home-greeting').textContent = `Olá, ${firstName}!`;
  document.getElementById('home-user-avatar').textContent = initial;
  document.getElementById('profile-card-initial').textContent = initial;
  document.getElementById('profile-card-name').textContent = currentUser.full_name;
  document.getElementById('profile-card-ra').textContent = `RA: ${currentUser.ra || '123456'}`;
  document.getElementById('profile-card-badge').textContent = currentUser.profile_type;

  // Show dashboard icon for attendant/admin
  const dashBtn = document.getElementById('btn-top-dashboard');
  if (currentUser.profile_type === 'ATENDENTE_ASA' || currentUser.profile_type === 'ADMINISTRADOR') {
    dashBtn.classList.remove('hidden');
  } else {
    dashBtn.classList.add('hidden');
  }
}

function logout() {
  authToken = null;
  currentUser = null;
  localStorage.removeItem('asa_token');
  navigateTo('screen-login');
}

// Chat Engine
async function sendMessage(text) {
  if (!text || !text.trim()) return;
  const list = document.getElementById('chat-messages-list');

  // Render user bubble
  const userBubble = document.createElement('div');
  userBubble.className = 'flex justify-end';
  userBubble.innerHTML = `
    <div class="bg-[#00664F] text-white p-3 rounded-2xl rounded-tr-none text-xs max-w-[85%] shadow-sm leading-relaxed">
      ${escapeHtml(text)}
    </div>
  `;
  list.appendChild(userBubble);
  list.scrollTop = list.scrollHeight;

  // Render typing bubble
  const typingBubble = document.createElement('div');
  typingBubble.id = 'chat-typing-indicator';
  typingBubble.className = 'flex gap-2 max-w-[85%] items-center';
  typingBubble.innerHTML = `
    <div class="w-6 h-6 rounded-full bg-[#00664F] text-white flex items-center justify-center text-[10px] shrink-0">
      <i class="fa-solid fa-robot"></i>
    </div>
    <div class="bg-white p-2.5 rounded-2xl rounded-tl-none border border-slate-200 text-[11px] text-slate-400 italic">
      Consultando base oficial de regulamentos...
    </div>
  `;
  list.appendChild(typingBubble);
  list.scrollTop = list.scrollHeight;

  try {
    const res = await apiRequest('/chat', 'POST', {
      query: text,
      conversation_id: currentConversationId,
    });
    const data = await res.json();
    typingBubble.remove();

    if (res.ok) {
      currentConversationId = data.conversation_id;
      renderAgentBubble(data);
    } else {
      renderErrorBubble(data.detail || 'Erro ao processar mensagem');
    }
  } catch (err) {
    typingBubble.remove();
    renderErrorBubble(err.message);
  }
  list.scrollTop = list.scrollHeight;
}

function renderAgentBubble(data) {
  const list = document.getElementById('chat-messages-list');
  const isAbstained = data.is_abstained;

  const agentBubble = document.createElement('div');
  agentBubble.className = 'flex gap-2 max-w-[90%]';

  const bgColor = isAbstained ? 'bg-amber-50 border-amber-300' : 'bg-white border-slate-200/90';
  const iconColor = isAbstained ? 'bg-amber-500' : 'bg-[#00664F]';
  const icon = isAbstained ? 'fa-triangle-exclamation' : 'fa-robot';

  agentBubble.innerHTML = `
    <div class="w-6 h-6 rounded-full ${iconColor} text-white flex items-center justify-center text-[10px] shrink-0 mt-1">
      <i class="fa-solid ${icon}"></i>
    </div>
    <div class="${bgColor} p-3.5 rounded-2xl rounded-tl-none border shadow-sm text-xs text-slate-800 space-y-2 leading-relaxed">
      ${isAbstained ? `
        <div class="flex items-center gap-1.5 text-amber-800 font-bold text-[10px] uppercase tracking-wider">
          <i class="fa-solid fa-shield-halved"></i>
          <span>Aviso de Confiança Controlada</span>
        </div>
      ` : ''}

      <div>${escapeHtml(data.response_text)}</div>

      ${data.source_citation && !isAbstained ? `
        <div class="p-2 bg-slate-100/80 rounded-xl border border-slate-200/80 text-[10px] text-slate-600 font-medium flex items-center gap-1.5">
          <i class="fa-solid fa-certificate text-emerald-600 text-xs shrink-0"></i>
          <span>${escapeHtml(data.source_citation)}</span>
        </div>
      ` : ''}

      ${data.suggested_action && !isAbstained ? `
        <div class="text-[10px] text-slate-500 italic flex items-center gap-1">
          <i class="fa-solid fa-arrow-right text-[9px] text-emerald-600"></i>
          <span>${escapeHtml(data.suggested_action)}</span>
        </div>
      ` : ''}

      <!-- Bottom actions -->
      <div class="pt-2 border-t border-slate-100 flex items-center justify-between text-[10px]">
        ${!isAbstained ? `
          <div class="flex items-center gap-2">
            <button class="btn-feedback text-slate-400 hover:text-emerald-700 flex items-center gap-1 p-1" data-msg="${data.message_id}" data-helpful="true">
              <i class="fa-regular fa-thumbs-up"></i>
              <span>Útil</span>
            </button>
            <button class="btn-feedback text-slate-400 hover:text-red-600 flex items-center gap-1 p-1" data-msg="${data.message_id}" data-helpful="false">
              <i class="fa-regular fa-thumbs-down"></i>
              <span>Não útil</span>
            </button>
          </div>
        ` : '<div></div>'}

        <button class="btn-escalate-bubble px-2.5 py-1 ${isAbstained ? 'bg-[#00664F] text-white' : 'bg-slate-100 text-slate-700 hover:bg-slate-200'} rounded-lg font-bold flex items-center gap-1">
          <i class="fa-solid fa-headset text-[9px]"></i>
          <span>Falar com o ASA</span>
        </button>
      </div>
    </div>
  `;

  // Attach feedback listener
  agentBubble.querySelectorAll('.btn-feedback').forEach(btn => {
    btn.addEventListener('click', async (e) => {
      const msgId = btn.getAttribute('data-msg');
      const isHelpful = btn.getAttribute('data-helpful') === 'true';
      await apiRequest('/feedback', 'POST', { message_id: msgId, is_helpful: isHelpful });
      btn.parentElement.innerHTML = `<span class="text-emerald-700 font-bold text-[10px]">✓ Feedback registrado!</span>`;
    });
  });

  agentBubble.querySelectorAll('.btn-escalate-bubble').forEach(btn => {
    btn.addEventListener('click', () => {
      document.getElementById('modal-escalation').classList.remove('hidden');
    });
  });

  list.appendChild(agentBubble);
}

function renderErrorBubble(msg) {
  const list = document.getElementById('chat-messages-list');
  const errBubble = document.createElement('div');
  errBubble.className = 'flex justify-center my-2';
  errBubble.innerHTML = `<span class="p-2 bg-red-50 text-red-700 border border-red-200 rounded-xl text-[10px] font-semibold">${escapeHtml(msg)}</span>`;
  list.appendChild(errBubble);
}

// Conversations History
async function loadConversations() {
  const container = document.getElementById('conversations-list-container');
  container.innerHTML = '<div class="text-center py-4 text-xs text-slate-400">Carregando histórico...</div>';
  try {
    const res = await apiRequest('/chat/conversations');
    if (res.ok) {
      const list = await res.json();
      if (list.length === 0) {
        container.innerHTML = '<div class="text-center py-8 text-xs text-slate-400">Nenhuma conversa anterior.</div>';
        return;
      }
      container.innerHTML = '';
      list.forEach(c => {
        const item = document.createElement('div');
        item.className = 'bg-white p-3 rounded-xl border border-slate-200 flex items-center justify-between hover:border-emerald-500 cursor-pointer shadow-sm';
        item.innerHTML = `
          <div class="flex items-center gap-2.5">
            <div class="w-8 h-8 rounded-full bg-emerald-50 text-emerald-700 flex items-center justify-center text-xs">
              <i class="fa-regular fa-comment-dots"></i>
            </div>
            <div>
              <h5 class="font-bold text-xs text-slate-800">${escapeHtml(c.title)}</h5>
              <p class="text-[10px] text-slate-400">${c.last_message ? escapeHtml(c.last_message.substring(0, 35)) + '...' : 'Sem mensagens'}</p>
            </div>
          </div>
          <i class="fa-solid fa-chevron-right text-[10px] text-slate-300"></i>
        `;
        item.addEventListener('click', () => {
          currentConversationId = c.id;
          navigateTo('screen-chat');
        });
        container.appendChild(item);
      });
    }
  } catch (e) {
    container.innerHTML = '<div class="text-center py-4 text-xs text-red-400">Erro ao carregar conversas.</div>';
  }
}

// Manager Dashboard Engine
async function loadDashboard() {
  try {
    const [statsRes, escRes, docsRes] = await Promise.all([
      apiRequest('/dashboard/stats'),
      apiRequest('/escalations'),
      apiRequest('/documents?active_only=false'),
    ]);

    if (statsRes.ok) {
      const stats = await statsRes.json();
      document.getElementById('kpi-conversations').textContent = stats.total_conversations;
      document.getElementById('kpi-messages').textContent = `${stats.total_messages} mensagens`;
      document.getElementById('kpi-abstention').textContent = `${stats.abstention_rate}%`;
      document.getElementById('kpi-satisfaction').textContent = `${stats.feedback.satisfaction_rate}%`;
      document.getElementById('kpi-feedbacks').textContent = `${stats.feedback.total_feedbacks} avaliações`;
      document.getElementById('kpi-escalations').textContent = stats.pending_escalations;
      document.getElementById('kpi-resolved').textContent = `${stats.resolved_escalations} resolvidos`;

      // Categories
      const catContainer = document.getElementById('dash-categories-container');
      catContainer.innerHTML = '';
      stats.top_categories.forEach(c => {
        catContainer.innerHTML += `
          <div>
            <div class="flex justify-between text-[11px] mb-1">
              <span class="font-bold text-slate-700">${c.category}</span>
              <span class="text-slate-400">${c.percentage}% (${c.count} docs)</span>
            </div>
            <div class="w-full bg-slate-100 h-1.5 rounded-full overflow-hidden">
              <div class="bg-emerald-600 h-full" style="width: ${c.percentage}%"></div>
            </div>
          </div>
        `;
      });
    }

    if (escRes.ok) {
      const escList = await escRes.json();
      const queueContainer = document.getElementById('dash-queue-container');
      queueContainer.innerHTML = '';
      if (escList.length === 0) {
        queueContainer.innerHTML = '<div class="text-center py-4 text-xs text-slate-400">Nenhum caso pendente.</div>';
      } else {
        escList.forEach(e => {
          const isResolved = e.status === 'RESOLVIDO';
          const card = document.createElement('div');
          card.className = `bg-white p-3 rounded-xl border ${isResolved ? 'border-slate-200' : 'border-red-200'} space-y-1.5 shadow-sm`;
          card.innerHTML = `
            <div class="flex justify-between items-center text-[10px]">
              <span class="px-2 py-0.5 rounded font-bold ${isResolved ? 'bg-emerald-100 text-emerald-800' : 'bg-red-100 text-red-800'}">${e.status}</span>
              <span class="text-slate-400">Prioridade: ${e.priority}</span>
            </div>
            <h5 class="font-bold text-xs text-slate-800">Estudante: ${e.student_name} (RA: ${e.student_ra || 'N/A'})</h5>
            <p class="text-[11px] text-slate-600">Motivo: ${escapeHtml(e.reason)}</p>
            ${e.user_notes ? `<p class="text-[10px] text-slate-400 italic">"${escapeHtml(e.user_notes)}"</p>` : ''}
            ${!isResolved ? `
              <button class="btn-open-resolve w-full mt-2 py-1.5 bg-[#00664F] text-white rounded-lg text-xs font-bold shadow" data-id="${e.id}">
                Resolver Caso
              </button>
            ` : `<div class="p-1.5 bg-slate-50 text-[10px] text-slate-600 rounded">Orientação: ${escapeHtml(e.resolution_notes || '')}</div>`}
          `;
          card.querySelectorAll('.btn-open-resolve').forEach(b => {
            b.addEventListener('click', () => {
              document.getElementById('modal-resolve-case-id').value = b.getAttribute('data-id');
              document.getElementById('modal-resolve-case').classList.remove('hidden');
            });
          });
          queueContainer.appendChild(card);
        });
      }
    }

    if (docsRes.ok) {
      const docsList = await docsRes.json();
      const docsContainer = document.getElementById('dash-docs-container');
      docsContainer.innerHTML = '';
      docsList.forEach(d => {
        const item = document.createElement('div');
        item.className = 'bg-white p-3 rounded-xl border border-slate-200 flex items-center justify-between shadow-sm';
        item.innerHTML = `
          <div>
            <h5 class="font-bold text-xs text-slate-800">${escapeHtml(d.title)}</h5>
            <p class="text-[10px] text-slate-400">${escapeHtml(d.official_source)} · ${d.category}</p>
          </div>
          <input type="checkbox" ${d.is_active ? 'checked' : ''} class="toggle-doc-active accent-emerald-700 h-4 w-4" data-id="${d.id}">
        `;
        item.querySelector('.toggle-doc-active').addEventListener('change', async (ev) => {
          await apiRequest(`/documents/${d.id}/toggle-active`, 'PATCH', { is_active: ev.target.checked });
        });
        docsContainer.appendChild(item);
      });
    }
  } catch (e) {}
}

function escapeHtml(text) {
  if (!text) return '';
  return text.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

// DOM Setup and Event Listeners
document.addEventListener('DOMContentLoaded', () => {
  // 1. Splash screen auto transition
  setTimeout(() => {
    if (authToken) {
      loadUserProfile().then(() => navigateTo('screen-home'));
    } else {
      navigateTo('screen-profile-choice');
    }
  }, 1600);

  // Profile Carousel
  document.getElementById('profile-avatar-container').addEventListener('click', () => {
    activeProfileIndex = (activeProfileIndex + 1) % profiles.length;
    const p = profiles[activeProfileIndex];
    document.getElementById('profile-title').textContent = p.title;
    document.getElementById('profile-desc').textContent = p.desc;
    document.getElementById('profile-icon').className = `fa-solid ${p.icon} text-6xl text-white`;

    const dots = document.querySelectorAll('#profile-dots span');
    dots.forEach((d, i) => {
      if (i === activeProfileIndex) {
        d.className = 'w-6 h-2 rounded-full bg-emerald-400 transition-all';
      } else {
        d.className = 'w-2 h-2 rounded-full bg-white/30 transition-all';
      }
    });
  });

  document.getElementById('btn-profile-continue').addEventListener('click', () => {
    navigateTo('screen-login');
  });

  // Login
  document.getElementById('btn-do-login').addEventListener('click', () => {
    const id = document.getElementById('login-identifier').value.trim();
    const pwd = document.getElementById('login-password').value;
    login(id, pwd);
  });

  document.querySelectorAll('.btn-fast-login').forEach(btn => {
    btn.addEventListener('click', () => {
      document.getElementById('login-identifier').value = btn.getAttribute('data-id');
      document.getElementById('login-password').value = btn.getAttribute('data-pwd');
      login(btn.getAttribute('data-id'), btn.getAttribute('data-pwd'));
    });
  });

  document.getElementById('btn-toggle-pwd').addEventListener('click', () => {
    const pwdInput = document.getElementById('login-password');
    pwdInput.type = pwdInput.type === 'password' ? 'text' : 'password';
  });

  // Recovery
  document.getElementById('btn-to-recovery').addEventListener('click', () => navigateTo('screen-recovery'));
  document.getElementById('btn-recovery-back').addEventListener('click', () => navigateTo('screen-login'));
  document.getElementById('btn-do-recover').addEventListener('click', async () => {
    const val = document.getElementById('recovery-input').value.trim();
    if (!val) return;
    try {
      const res = await apiRequest('/auth/recover-password', 'POST', { identifier: val });
      const data = await res.json();
      const msgBox = document.getElementById('recovery-msg-box');
      msgBox.textContent = data.message;
      msgBox.classList.remove('hidden');
    } catch (e) {}
  });

  // Home search to chat
  const sendFromHome = () => {
    const q = document.getElementById('home-search-input').value.trim();
    if (!q) return;
    document.getElementById('home-search-input').value = '';
    currentConversationId = null;
    document.getElementById('chat-messages-list').innerHTML = '';
    navigateTo('screen-chat');
    sendMessage(q);
  };
  document.getElementById('btn-home-send').addEventListener('click', sendFromHome);
  document.getElementById('home-search-input').addEventListener('keypress', (e) => {
    if (e.key === 'Enter') sendFromHome();
  });

  // FAQ buttons
  document.querySelectorAll('.btn-ask-faq').forEach(btn => {
    btn.addEventListener('click', () => {
      const q = btn.getAttribute('data-q');
      currentConversationId = null;
      document.getElementById('chat-messages-list').innerHTML = '';
      navigateTo('screen-chat');
      sendMessage(q);
    });
  });

  // Chat send
  const sendChatMessage = () => {
    const text = document.getElementById('chat-input-text').value.trim();
    if (!text) return;
    document.getElementById('chat-input-text').value = '';
    sendMessage(text);
  };
  document.getElementById('btn-send-chat').addEventListener('click', sendChatMessage);
  document.getElementById('chat-input-text').addEventListener('keypress', (e) => {
    if (e.key === 'Enter') sendChatMessage();
  });
  document.getElementById('btn-chat-back').addEventListener('click', () => navigateTo('screen-home'));

  // Nav items
  document.querySelectorAll('.nav-item').forEach(btn => {
    btn.addEventListener('click', () => {
      const target = btn.getAttribute('data-target');
      if (target === 'screen-conversations') loadConversations();
      navigateTo(target);
    });
  });

  document.querySelectorAll('.btn-back-home').forEach(btn => {
    btn.addEventListener('click', () => navigateTo('screen-home'));
  });

  document.querySelectorAll('.btn-nav-docs').forEach(b => b.addEventListener('click', () => navigateTo('screen-documents')));
  document.querySelectorAll('.btn-nav-services').forEach(b => b.addEventListener('click', () => navigateTo('screen-services')));

  // Service Detail Navigation
  document.querySelectorAll('.btn-service-detail').forEach(b => {
    b.addEventListener('click', () => {
      const title = b.getAttribute('data-title');
      document.getElementById('detail-header-title').textContent = title;
      document.getElementById('detail-main-title').textContent = title;
      navigateTo('screen-service-detail');
    });
  });
  document.getElementById('btn-detail-back').addEventListener('click', () => navigateTo('screen-services'));
  document.getElementById('btn-detail-ask').addEventListener('click', () => {
    const title = document.getElementById('detail-main-title').textContent;
    currentConversationId = null;
    document.getElementById('chat-messages-list').innerHTML = '';
    navigateTo('screen-chat');
    sendMessage(`Como funciona o procedimento de: ${title}?`);
  });

  // Documents file upload simulator
  document.getElementById('btn-upload-file').addEventListener('click', () => {
    const msg = document.getElementById('upload-status-msg');
    msg.textContent = "Processando e analisando arquivo com IA...";
    msg.classList.remove('hidden');
    setTimeout(() => {
      msg.textContent = "✓ 'Comprovante_2024.pdf' analisado com sucesso pela IA do ASA Connect!";
    }, 1200);
  });

  // Font Scale Selector (Real dynamic accessibility!)
  document.getElementById('font-scale-selector').addEventListener('change', (e) => {
    const scale = e.target.value;
    document.documentElement.style.setProperty('--font-scale', scale);
    apiRequest('/profile', 'PATCH', { font_size_factor: scale === '0.85' ? 'small' : scale === '1.15' ? 'medium' : scale === '1.35' ? 'large' : 'normal' });
  });

  // Modals Info
  document.getElementById('btn-show-personal-data').addEventListener('click', () => {
    alert(`DADOS PESSOAIS (LGPD):\nNome: ${currentUser?.full_name}\nRA: ${currentUser?.ra}\nE-mail: ${currentUser?.email}\nCurso: ${currentUser?.course}\nCampus: ${currentUser?.campus}`);
  });
  document.getElementById('btn-show-about').addEventListener('click', () => {
    alert(`ASA Connect+\nVersão: 1.0.0\nProjeto Interdisciplinar 5º Semestre CC FECAP\nAgente Inteligente para o Estudante Alvarista`);
  });
  document.getElementById('btn-show-lgpd').addEventListener('click', () => {
    alert(`PRIVACIDADE E LGPD (Lei 13.709/2018):\n- Minimização de dados acadêmicos\n- Explicabilidade oficial (RF06)\n- Abstenção segura sem alucinações (RF04)\n- Todos os dados deste ambiente são fictícios.`);
  });
  document.getElementById('btn-do-logout').addEventListener('click', logout);

  // Escalation Modals
  document.getElementById('btn-escalate-top').addEventListener('click', () => {
    document.getElementById('modal-escalation').classList.remove('hidden');
  });
  document.getElementById('btn-cancel-escalate').addEventListener('click', () => {
    document.getElementById('modal-escalation').classList.add('hidden');
  });
  document.getElementById('btn-confirm-escalate').addEventListener('click', async () => {
    const notes = document.getElementById('modal-escalate-notes').value.trim();
    document.getElementById('modal-escalation').classList.add('hidden');
    if (!currentConversationId) {
      alert('Envie uma mensagem antes de transferir a conversa.');
      return;
    }
    await apiRequest('/escalations', 'POST', {
      conversation_id: currentConversationId,
      reason: 'Solicitado pelo estudante via aplicativo',
      user_notes: notes || null,
      priority: 'MEDIA',
    });
    alert('Solicitação enviada com sucesso! Um atendente do ASA entrará em contato.');
  });

  // Top Dashboard button
  document.getElementById('btn-top-dashboard').addEventListener('click', () => {
    loadDashboard();
    navigateTo('screen-dashboard');
  });
  document.getElementById('btn-refresh-dashboard').addEventListener('click', loadDashboard);

  // Dashboard Tabs
  document.querySelectorAll('.dash-tab-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('.dash-tab-btn').forEach(b => {
        b.classList.remove('border-emerald-600', 'text-emerald-700');
        b.classList.add('border-transparent');
      });
      btn.classList.add('border-emerald-600', 'text-emerald-700');
      btn.classList.remove('border-transparent');

      const tab = btn.getAttribute('data-tab');
      document.getElementById('dash-tab-metrics').classList.toggle('hidden', tab !== 'metrics');
      document.getElementById('dash-tab-queue').classList.toggle('hidden', tab !== 'queue');
      document.getElementById('dash-tab-ragdocs').classList.toggle('hidden', tab !== 'ragdocs');
    });
  });

  // Modal Resolve Case
  document.getElementById('btn-cancel-resolve').addEventListener('click', () => {
    document.getElementById('modal-resolve-case').classList.add('hidden');
  });
  document.getElementById('btn-confirm-resolve').addEventListener('click', async () => {
    const caseId = document.getElementById('modal-resolve-case-id').value;
    const notes = document.getElementById('modal-resolve-notes').value.trim();
    if (!notes) {
      alert('A justificativa / orientação é obrigatória (RF08).');
      return;
    }
    document.getElementById('modal-resolve-case').classList.add('hidden');
    await apiRequest(`/escalations/${caseId}/resolve`, 'PATCH', {
      status: 'RESOLVIDO',
      resolution_notes: notes,
    });
    alert('Caso encerrado com sucesso!');
    loadDashboard();
  });
});
