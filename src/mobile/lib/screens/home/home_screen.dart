import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:asa_connect/core/constants.dart';
import 'package:asa_connect/widgets/common/brand_header.dart';
import 'package:asa_connect/state/auth_provider.dart';
import 'package:asa_connect/state/chat_provider.dart';
import 'package:asa_connect/screens/chat/chat_screen.dart';
import 'package:asa_connect/screens/chat/conversations_list_screen.dart';
import 'package:asa_connect/screens/documents/documents_screen.dart';
import 'package:asa_connect/screens/academic_services/academic_services_screen.dart';
import 'package:asa_connect/screens/profile/profile_screen.dart';
import 'package:asa_connect/screens/dashboard/manager_dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openChatWithQuery([String? query]) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.startNewChat();
    if (query != null && query.isNotEmpty) {
      chatProvider.sendMessage(query);
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ChatScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;
    final isTimeASA =
        user?.profileType == 'ATENDENTE_ASA' || user?.profileType == 'ADMINISTRADOR' || user?.profileType == 'COLABORADOR';
    final isProfessor = user?.profileType == 'PROFESSOR';

    final List<Widget> tabs = [
      _buildHomeContent(user, isTimeASA, isProfessor),
      const ConversationsListScreen(isTab: true),
      const AcademicServicesScreen(isTab: true),
      const ProfileScreen(isTab: true),
    ];

    String appBarTitle = '';
    if (_currentIndex == 1) appBarTitle = 'Conversas';
    if (_currentIndex == 2) appBarTitle = 'Serviços Acadêmicos';
    if (_currentIndex == 3) appBarTitle = 'Perfil';

    return Scaffold(
      backgroundColor: context.backgroundColor,
      drawer: Drawer(
        backgroundColor: context.cardColor,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.headerGreen, Color(0xFF0D5238)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              accountName: Text(
                user?.fullName ?? (isProfessor ? 'Prof. Rafael Rossetti' : (isTimeASA ? 'Time ASA Atendimento' : 'Estudante Alvarista')),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              accountEmail: Text(user?.email ?? user?.ra ?? (isProfessor ? 'prof.almeida@fecap.br' : (isTimeASA ? 'atendente@fecap.br' : 'aluno@fecap.br'))),
              currentAccountPicture: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Icon(
                    isProfessor
                        ? Icons.menu_book_rounded
                        : (isTimeASA ? Icons.support_agent_rounded : Icons.person_rounded),
                    color: Colors.white,
                    size: 38,
                  ),
                ),
              ),
            ),
            if (isTimeASA)
              ListTile(
                leading: const Icon(Icons.dashboard_rounded, color: AppColors.primaryGreen),
                title: const Text('Painel Gerencial ASA', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Métricas RAG, fila humana e fontes'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ManagerDashboardScreen()),
                  );
                },
              ),
            if (isProfessor)
              ListTile(
                leading: const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706)),
                title: const Text('Sinalização Preventiva (Alerta ASA)', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Encaminhar aluno em risco ao apoio do ASA'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showEarlyWarningModal(context);
                },
              ),
            ListTile(
              leading: const Icon(Icons.school_outlined, color: AppColors.primaryGreen),
              title: const Text('Serviços Acadêmicos'),
              onTap: () {
                Navigator.of(context).pop();
                setState(() => _currentIndex = 2);
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder_open_rounded, color: AppColors.primaryGreen),
              title: const Text('Meus Documentos'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DocumentsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primaryGreen),
              title: const Text('Histórico de Conversas'),
              onTap: () {
                Navigator.of(context).pop();
                setState(() => _currentIndex = 1);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline_rounded, color: AppColors.primaryGreen),
              title: const Text('Meu Perfil'),
              onTap: () {
                Navigator.of(context).pop();
                setState(() => _currentIndex = 3);
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: AppColors.headerGreen,
        elevation: 1,
        toolbarHeight: 64,
        centerTitle: true,
        // Menu hambúrguer na esquerda
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 26),
            tooltip: 'Menu',
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        // Título central: Logo ASA na Home, título textual nas outras abas
        title: _currentIndex == 0
            ? const AsaLogo(width: 125, isDarkBackground: true)
            : Text(
                appBarTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
        // Avatar circular na direita com foto da persona
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: GestureDetector(
                onTap: () => setState(() => _currentIndex = 3),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.2),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 1.5),
                  ),
                  child: Center(
                    child: Icon(
                      isProfessor
                          ? Icons.menu_book_rounded
                          : (isTimeASA ? Icons.support_agent_rounded : Icons.person_rounded),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: tabs[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: context.borderColor, width: 1)),
          color: context.isDarkMode ? AppDarkColors.bottomNav : Colors.white,
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          selectedItemColor: context.isDarkMode ? AppColors.accentEmerald : AppColors.headerGreen,
          unselectedItemColor: context.isDarkMode ? AppDarkColors.textMuted : AppColors.textMuted,
          backgroundColor: context.isDarkMode ? AppDarkColors.bottomNav : Colors.white,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
          onTap: (idx) => setState(() => _currentIndex = idx),
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Início',
            ),
            BottomNavigationBarItem(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.chat_bubble_outline_rounded),
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.aiPurple,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              label: 'Conversas',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.school_outlined),
              label: 'Serviços',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              label: 'Perfil',
            ),
          ],
        ),
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              backgroundColor: AppColors.aiPurple,
              foregroundColor: Colors.white,
              elevation: 4,
              tooltip: 'Chat com IA',
              onPressed: () => _openChatWithQuery(),
              child: const Icon(Icons.auto_awesome_rounded),
            )
          : null,
    );
  }

  Widget _buildHomeContent(
    user,
    bool isTimeASA,
    bool isProfessor,
  ) {
    final firstName = user?.fullName.split(' ').first ?? (isProfessor ? 'Professor' : (isTimeASA ? 'Time ASA' : 'Aluno'));

    String greetingTitle = 'Olá, $firstName!';
    String greetingSubtitle = 'Como posso ajudar você hoje?';
    String searchHint = 'Pergunte ao ASA Connect...';
    String quickAccessTitle = 'ACESSO RÁPIDO';
    String faqTitle = 'PERGUNTAS FREQUENTES';

    if (isProfessor) {
      greetingTitle = 'Olá, Prof. $firstName!';
      greetingSubtitle = 'Portal de Apoio Docente e Atendimento ASA';
      searchHint = 'Pergunte sobre normas, notas, diário ou ASA...';
      quickAccessTitle = 'ACESSO RÁPIDO DOCENTE';
      faqTitle = 'DÚVIDAS FREQUENTES DOCENTES';
    } else if (isTimeASA) {
      greetingTitle = 'Olá, $firstName!';
      greetingSubtitle = 'Base Corporativa e Fluxos Institucionais ASA';
      searchHint = 'Consulte 311 manuais, normas, taxas ou protocolos...';
      quickAccessTitle = 'ACESSO OPERACIONAL TIME ASA';
      faqTitle = 'CONSULTAS OPERACIONAIS FREQUENTES';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Saudação Oficial com Ícone Sparkles em Caixa Verde
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.headerGreen,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.success,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greetingTitle,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: context.primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      greetingSubtitle,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: context.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Banner Exclusivo Docente: Sinalização Preventiva ASA
          if (isProfessor) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2B1055), Color(0xFF591A8A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF591A8A).withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.psychology_alt_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sinalização Preventiva NAE / ASA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Identificou um aluno em risco de evasão ou vulnerabilidade? Notifique a equipe em 1 toque.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 11,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF591A8A),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                      elevation: 0,
                    ),
                    onPressed: () => _showEarlyWarningModal(context),
                    child: const Text('Sinalizar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],

          // 2. Campo de Prompt ASA Connect IA com Botão Roxo #845EF2
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: context.borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 10),
                const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: context.primaryTextColor),
                    decoration: InputDecoration(
                      hintText: searchHint,
                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onSubmitted: (val) {
                      if (val.trim().isNotEmpty) {
                        _openChatWithQuery(val.trim());
                        _searchController.clear();
                      }
                    },
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    if (_searchController.text.trim().isNotEmpty) {
                      _openChatWithQuery(_searchController.text.trim());
                      _searchController.clear();
                    } else {
                      _openChatWithQuery();
                    }
                  },
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.aiPurple,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 3. Seção: ACESSO RÁPIDO (Grade 2x2)
          Text(
            quickAccessTitle,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              color: context.primaryTextColor,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.25,
            children: isProfessor
                ? [
                    _buildOfficialQuickCard(
                      icon: Icons.warning_amber_rounded,
                      iconColor: const Color(0xFFD97706),
                      iconBgColor: const Color(0xFFD97706).withOpacity(0.12),
                      title: 'SINALIZAÇÃO ASA',
                      subtitle: 'Alerta Preventivo NAE',
                      onTap: () => _showEarlyWarningModal(context),
                    ),
                    _buildOfficialQuickCard(
                      icon: Icons.gavel_rounded,
                      iconColor: AppColors.headerGreen,
                      iconBgColor: AppColors.headerGreen.withOpacity(0.12),
                      title: 'REGULAMENTOS & PEDP',
                      subtitle: 'Avaliações e Extensão',
                      onTap: () => _openChatWithQuery(
                        'Quais são as principais normas de avaliação, arredondamento oficial de notas e projetos de extensão PEDP na FECAP?',
                      ),
                    ),
                    _buildOfficialQuickCard(
                      icon: Icons.edit_note_rounded,
                      iconColor: AppColors.aiPurple,
                      iconBgColor: AppColors.aiPurple.withOpacity(0.12),
                      title: 'DIÁRIO & NOTAS',
                      subtitle: 'Lançamento e Prazos',
                      onTap: () => _openChatWithQuery(
                        'Como funciona e quais são os prazos para lançamento de notas e faltas no Portal do Professor da FECAP?',
                      ),
                    ),
                    _buildOfficialQuickCard(
                      icon: Icons.support_agent_rounded,
                      iconColor: const Color(0xFF02845E),
                      iconBgColor: AppColors.success.withOpacity(0.22),
                      title: 'TIME ASA DOCENTE',
                      subtitle: 'Suporte Pedagógico',
                      onTap: () => _openChatWithQuery(
                        'Como o professor entra em contato com o Time ASA para encaminhar solicitações ou dúvidas de alunos?',
                      ),
                    ),
                  ]
                : isTimeASA
                    ? [
                        _buildOfficialQuickCard(
                          icon: Icons.menu_book_rounded,
                          iconColor: AppColors.aiPurple,
                          iconBgColor: AppColors.aiPurple.withOpacity(0.12),
                          title: '311 MANUAIS',
                          subtitle: 'Regulamentos & Normas',
                          onTap: () => _openChatWithQuery(
                            'Quais são as principais normas dos manuais institucionais e regulamentos acadêmicos da FECAP?',
                          ),
                        ),
                        _buildOfficialQuickCard(
                          icon: Icons.price_change_outlined,
                          iconColor: const Color(0xFFB45309),
                          iconBgColor: AppColors.warningYellow.withOpacity(0.3),
                          title: 'TABELA DE TAXAS',
                          subtitle: 'Valores e Prazos Úteis',
                          onTap: () => _openChatWithQuery(
                            'Qual é a tabela institucional de taxas e prazos em dias úteis para emissão de documentos na FECAP?',
                          ),
                        ),
                        _buildOfficialQuickCard(
                          icon: Icons.assignment_turned_in_outlined,
                          iconColor: AppColors.headerGreen,
                          iconBgColor: AppColors.headerGreen.withOpacity(0.12),
                          title: 'REQUERIMENTOS',
                          subtitle: 'Fluxos de Protocolo',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AcademicServicesScreen(filterCategory: 'Requerimentos'),
                            ),
                          ),
                        ),
                        _buildOfficialQuickCard(
                          icon: Icons.headset_mic_rounded,
                          iconColor: const Color(0xFF02845E),
                          iconBgColor: AppColors.success.withOpacity(0.22),
                          title: 'FILA TIME ASA',
                          subtitle: 'Transbordo e Escalação',
                          onTap: () => _openChatWithQuery(
                            'Como funciona o processo de escalação para atendimento humano e acompanhamento de protocolos no ASA?',
                          ),
                        ),
                      ]
                    : [
                            // 1. Documentos (Roxo #845EF2)
                            _buildOfficialQuickCard(
                              icon: Icons.description_outlined,
                              iconColor: AppColors.aiPurple,
                              iconBgColor: AppColors.aiPurple.withOpacity(0.12),
                              title: 'DOCUMENTOS',
                              subtitle: 'Histórico, Atestados',
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const DocumentsScreen(initialCategory: 'Acadêmicos')),
                              ),
                            ),
                            // 2. Requerimentos (Verde #02845E)
                            _buildOfficialQuickCard(
                              icon: Icons.assignment_outlined,
                              iconColor: AppColors.headerGreen,
                              iconBgColor: AppColors.headerGreen.withOpacity(0.12),
                              title: 'REQUERIMENTOS',
                              subtitle: 'Processos e Protocolos',
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const AcademicServicesScreen(filterCategory: 'Requerimentos'),
                                ),
                              ),
                            ),
                            // 3. Acadêmico (Verde Esmeralda #00E387)
                            _buildOfficialQuickCard(
                              icon: Icons.school_outlined,
                              iconColor: AppColors.headerGreen,
                              iconBgColor: AppColors.success.withOpacity(0.22),
                              title: 'ACADÊMICO',
                              subtitle: 'Matrícula, Notas',
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const AcademicServicesScreen(filterCategory: 'Matrícula'),
                                ),
                              ),
                            ),
                            // 4. Financeiro (Amarelo Ouro #FFDE34)
                            _buildOfficialQuickCard(
                              icon: Icons.account_balance_wallet_outlined,
                              iconColor: const Color(0xFFB45309),
                              iconBgColor: AppColors.warningYellow.withOpacity(0.3),
                              title: 'FINANCEIRO',
                              subtitle: 'Boletos, Mensalidades',
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const AcademicServicesScreen(filterCategory: 'Financeiro'),
                                ),
                              ),
                            ),
                          ],
          ),
          const SizedBox(height: 24),

          // 4. Seção: PERGUNTAS FREQUENTES
          Text(
            faqTitle,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              color: context.primaryTextColor,
            ),
          ),
          const SizedBox(height: 12),
          Column(
            children: isProfessor
                ? [
                    _buildFaqQuestionCard(
                      question: 'Como sinalizar um aluno com faltas consecutivas ou em risco de evasão?',
                      badge: 'Alerta ASA',
                      badgeBg: const Color(0xFFD97706).withOpacity(0.12),
                      badgeColor: const Color(0xFFD97706),
                      onTap: () => _showEarlyWarningModal(context),
                    ),
                    const SizedBox(height: 10),
                    _buildFaqQuestionCard(
                      question: 'Qual a regra oficial de arredondamento de notas e cálculo de médias?',
                      badge: 'Docente',
                      badgeBg: AppColors.headerGreen.withOpacity(0.1),
                      badgeColor: AppColors.headerGreen,
                      onTap: () => _openChatWithQuery('Qual a regra oficial de arredondamento de notas e cálculo de médias semestrais na FECAP?'),
                    ),
                    const SizedBox(height: 10),
                    _buildFaqQuestionCard(
                      question: 'Como orientar e acolher alunos com laudo de neurodivergência ou PCD?',
                      badge: 'Acessibilidade NAE',
                      badgeBg: AppColors.aiPurple.withOpacity(0.1),
                      badgeColor: AppColors.aiPurple,
                      onTap: () => _openChatWithQuery('Quais são as diretrizes de acessibilidade e adaptação de provas para alunos do NAE na FECAP?'),
                    ),
                  ]
                : isTimeASA
                    ? [
                        _buildFaqQuestionCard(
                          question: 'Qual o prazo institucional para compensação bancária de boletos?',
                          badge: 'Financeiro',
                          badgeBg: AppColors.warningYellow.withOpacity(0.25),
                          badgeColor: const Color(0xFFB45309),
                          onTap: () => _openChatWithQuery('Qual o prazo de compensação bancária e baixa de pagamentos no sistema financeiro da FECAP?'),
                        ),
                        const SizedBox(height: 10),
                        _buildFaqQuestionCard(
                          question: 'Qual a taxa e o prazo para emissão de 2ª via de diploma?',
                          badge: 'Secretaria',
                          badgeBg: AppColors.headerGreen.withOpacity(0.1),
                          badgeColor: AppColors.headerGreen,
                          onTap: () => _openChatWithQuery('Qual é a taxa e o prazo institucional para emissão de 2ª via de diploma na FECAP?'),
                        ),
                        const SizedBox(height: 10),
                        _buildFaqQuestionCard(
                          question: 'Como funciona o fluxo de briefing e encaminhamento do bot para a fila humana?',
                          badge: 'Time ASA',
                          badgeBg: AppColors.aiPurple.withOpacity(0.1),
                          badgeColor: AppColors.aiPurple,
                          onTap: () => _openChatWithQuery('Como funciona o fluxo de encaminhamento e transferência de chamados entre o ASA e as coordenações?'),
                        ),
                      ]
                    : [
                            _buildFaqQuestionCard(
                              question: 'Como solicitar um atestado de matrícula?',
                              badge: 'Acadêmico',
                              badgeBg: AppColors.headerGreen.withOpacity(0.1),
                              badgeColor: AppColors.headerGreen,
                              onTap: () => _openChatWithQuery('Como solicitar um atestado de matrícula?'),
                            ),
                            const SizedBox(height: 10),
                            _buildFaqQuestionCard(
                              question: 'Qual o prazo para entrega de horas complementares?',
                              badge: 'IA Assistente',
                              badgeBg: AppColors.aiPurple.withOpacity(0.1),
                              badgeColor: AppColors.aiPurple,
                              onTap: () => _openChatWithQuery('Qual o prazo para entrega de horas complementares?'),
                            ),
                            const SizedBox(height: 10),
                            _buildFaqQuestionCard(
                              question: 'Preciso da 2ª via do boleto deste mês.',
                              badge: 'Financeiro',
                              badgeBg: AppColors.warningYellow.withOpacity(0.25),
                              badgeColor: const Color(0xFFB45309),
                              onTap: () => _openChatWithQuery('Preciso da 2ª via do boleto deste mês.'),
                            ),
                          ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildOfficialQuickCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(context.isDarkMode ? 0.2 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: context.primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10,
                        color: context.secondaryTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFaqQuestionCard({
    required String question,
    required String badge,
    required Color badgeBg,
    required Color badgeColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(context.isDarkMode ? 0.2 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: badgeColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        question,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: context.primaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textLight, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
  void _showEarlyWarningModal(BuildContext context) {
    final raController = TextEditingController();
    final obsController = TextEditingController();
    String selectedReason = 'Frequência Crítica (Risco de Reprovação por Faltas)';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97706).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sinalização Preventiva ASA / NAE',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.primaryTextColor),
                        ),
                        Text(
                          'Encaminhe apoio ao aluno antes da reprovação ou evasão.',
                          style: TextStyle(fontSize: 11, color: context.secondaryTextColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text('RA DO ALUNO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.secondaryTextColor)),
              const SizedBox(height: 6),
              TextField(
                controller: raController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Ex: 123456',
                  prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                  filled: true,
                  fillColor: context.inputFillColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 14),
              Text('MOTIVO DA SINALIZAÇÃO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.secondaryTextColor)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: selectedReason,
                isExpanded: true,
                dropdownColor: context.cardColor,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: context.inputFillColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                items: const [
                  DropdownMenuItem(value: 'Frequência Crítica (Risco de Reprovação por Faltas)', child: Text('Frequência Crítica (Faltas consecutivas)', style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: 'Queda Abrupta no Rendimento Acadêmico', child: Text('Queda Abrupta no Rendimento / Desmotivação', style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: 'Apoio Psicológico / Acolhimento NAE', child: Text('Apoio Psicológico / Acolhimento NAE', style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: 'Adaptação de Acessibilidade / Neurodivergência', child: Text('Adaptação de Acessibilidade / Neurodivergência', style: TextStyle(fontSize: 12))),
                ],
                onChanged: (val) {
                  if (val != null) setModalState(() => selectedReason = val);
                },
              ),
              const SizedBox(height: 14),
              Text('OBSERVAÇÕES DO PROFESSOR (OPCIONAL)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.secondaryTextColor)),
              const SizedBox(height: 6),
              TextField(
                controller: obsController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Ex: O aluno faltou nas últimas 3 semanas e não respondeu...',
                  filled: true,
                  fillColor: context.inputFillColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD97706),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text('Enviar Alerta ao Time ASA', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    final ra = raController.text.trim();
                    if (ra.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Por favor, informe o RA do aluno.'), backgroundColor: AppColors.error),
                      );
                      return;
                    }
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Expanded(child: Text('Alerta registrado! O Time ASA foi notificado para acolher o aluno RA ' + ra + '.')),
                          ],
                        ),
                        backgroundColor: AppColors.success,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
