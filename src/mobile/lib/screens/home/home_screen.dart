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
    final isAttendantOrAdmin =
        user?.profileType == 'ATENDENTE_ASA' || user?.profileType == 'ADMINISTRADOR';

    final List<Widget> tabs = [
      _buildHomeContent(user, isAttendantOrAdmin),
      const ConversationsListScreen(isTab: true),
      const AcademicServicesScreen(isTab: true),
      const ProfileScreen(isTab: true),
    ];

    String appBarTitle = '';
    if (_currentIndex == 1) appBarTitle = 'Conversas';
    if (_currentIndex == 2) appBarTitle = 'Serviços Acadêmicos';
    if (_currentIndex == 3) appBarTitle = 'Perfil';

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: AppColors.headerGreen),
              accountName: Text(
                user?.fullName ?? 'Estudante Alvarista',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              accountEmail: Text(user?.email ?? user?.ra ?? 'aluno@fecap.br'),
              currentAccountPicture: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/persona_aluna.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            if (isAttendantOrAdmin)
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
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: AppColors.error),
              title: const Text('Sair', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
              onTap: () async {
                Navigator.of(context).pop();
                await auth.logout();
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
                    border: Border.all(color: Colors.white, width: 2),
                    image: const DecorationImage(
                      image: AssetImage('assets/images/persona_aluna.png'),
                      fit: BoxFit.cover,
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
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.borderLight, width: 1)),
          color: Colors.white,
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          selectedItemColor: AppColors.headerGreen,
          unselectedItemColor: AppColors.textMuted,
          backgroundColor: Colors.white,
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

  Widget _buildHomeContent(user, bool isAttendantOrAdmin) {
    final firstName = user?.fullName.split(' ').first ?? 'Aluno';

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
                      'Olá, $firstName!',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Como posso ajudar você hoje?',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textBody,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 2. Campo de Prompt ASA Connect IA com Botão Roxo #845EF2
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderMedium.withOpacity(0.6)),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
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
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    decoration: const InputDecoration(
                      hintText: 'Pergunte ao ASA Connect...',
                      hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
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
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
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
          const Text(
            'ACESSO RÁPIDO',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              color: AppColors.textDark,
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
            children: [
              // 1. Documentos (Roxo #845EF2)
              _buildOfficialQuickCard(
                icon: Icons.description_outlined,
                iconColor: AppColors.aiPurple,
                iconBgColor: AppColors.aiPurple.withOpacity(0.12),
                title: 'DOCUMENTOS',
                subtitle: 'Histórico, Atestados',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DocumentsScreen()),
                ),
              ),
              // 2. Requerimentos (Verde #02845E)
              _buildOfficialQuickCard(
                icon: Icons.assignment_outlined,
                iconColor: AppColors.headerGreen,
                iconBgColor: AppColors.headerGreen.withOpacity(0.12),
                title: 'REQUERIMENTOS',
                subtitle: 'Processos e Protocolos',
                onTap: () => setState(() => _currentIndex = 2),
              ),
              // 3. Acadêmico (Verde Esmeralda #00E387)
              _buildOfficialQuickCard(
                icon: Icons.school_outlined,
                iconColor: AppColors.headerGreen,
                iconBgColor: AppColors.success.withOpacity(0.22),
                title: 'ACADÊMICO',
                subtitle: 'Matrícula, Notas',
                onTap: () => setState(() => _currentIndex = 2),
              ),
              // 4. Financeiro (Amarelo Ouro #FFDE34)
              _buildOfficialQuickCard(
                icon: Icons.account_balance_wallet_outlined,
                iconColor: const Color(0xFFB45309),
                iconBgColor: AppColors.warningYellow.withOpacity(0.3),
                title: 'FINANCEIRO',
                subtitle: 'Boletos, Mensalidades',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DocumentsScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 4. Seção: PERGUNTAS FREQUENTES
          const Text(
            'PERGUNTAS FREQUENTES',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Column(
            children: [
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
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
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
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(8),
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
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
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
    );
  }
}
