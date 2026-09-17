import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:asa_connect/core/constants.dart';
import 'package:asa_connect/state/auth_provider.dart';
import 'package:asa_connect/state/accessibility_provider.dart';
import 'package:asa_connect/screens/profile_selection/profile_selection_screen.dart';
import 'package:asa_connect/screens/documents/documents_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool isTab;

  const ProfileScreen({super.key, this.isTab = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notifications = true;

  void _showThemeDialog() {
    final access = Provider.of<AccessibilityProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final current = access.themeMode;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Aparência e Tema',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.primaryTextColor),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, size: 20, color: context.primaryTextColor),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Escolha a paleta de cores para o aplicativo. A alteração é persistida automaticamente.',
                  style: TextStyle(fontSize: 12, color: context.secondaryTextColor),
                ),
                const SizedBox(height: 16),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.light,
                  groupValue: current,
                  activeColor: AppColors.primaryGreen,
                  title: Text('Tema Claro', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.primaryTextColor)),
                  subtitle: Text('Fundo claro padrão institucional', style: TextStyle(fontSize: 11, color: context.secondaryTextColor)),
                  onChanged: (val) {
                    if (val != null) {
                      access.setThemeMode(val);
                      setModalState(() {});
                    }
                  },
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.dark,
                  groupValue: current,
                  activeColor: AppColors.primaryGreen,
                  title: Text('Tema Escuro', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.primaryTextColor)),
                  subtitle: Text('Tons escuros e alto contraste para ambientes com pouca luz', style: TextStyle(fontSize: 11, color: context.secondaryTextColor)),
                  onChanged: (val) {
                    if (val != null) {
                      access.setThemeMode(val);
                      setModalState(() {});
                    }
                  },
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.system,
                  groupValue: current,
                  activeColor: AppColors.primaryGreen,
                  title: Text('Padrão do Sistema', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.primaryTextColor)),
                  subtitle: Text('Acompanha a configuração do seu dispositivo Android', style: TextStyle(fontSize: 11, color: context.secondaryTextColor)),
                  onChanged: (val) {
                    if (val != null) {
                      access.setThemeMode(val);
                      setModalState(() {});
                    }
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showPhotoSyncDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.camera_alt_rounded, color: AppColors.primaryGreen),
            const SizedBox(width: 8),
            Text('Foto de Perfil', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.primaryTextColor)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Foto Institucional Sincronizada',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.primaryTextColor),
            ),
            const SizedBox(height: 8),
            Text(
              'Sua foto de identificação acadêmica é vinculada diretamente à matrícula na Secretaria Geral da FECAP.\n\n'
              'Para atualização de foto cadastral ou emissão de nova carteirinha, procure o atendimento presencial do ASA no Campus Liberdade.',
              style: TextStyle(fontSize: 12, color: context.secondaryTextColor, height: 1.4),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _showAboutAsaDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: context.isDarkMode ? AppColors.primaryGreen.withValues(alpha: 0.25) : AppColors.accentMint,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.school_rounded, color: AppColors.primaryGreen, size: 20),
            ),
            const SizedBox(width: 10),
            Text('Sobre o ASA Connect+', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.primaryTextColor)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Versão 1.0.0 Release (Ambiente FECAP)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
              ),
              const SizedBox(height: 8),
              Text(
                'O ASA Connect+ é uma plataforma de atendimento inteligente baseada em IA e Recuperação Aumentada por Geração (RAG), concebida para atender os estudantes e o corpo docente Alvarista com máxima confiabilidade, transparência e velocidade.',
                style: TextStyle(fontSize: 12, color: context.secondaryTextColor, height: 1.4),
              ),
              const SizedBox(height: 12),
              Text(
                'Pilares de Governança e Qualidade:',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.primaryTextColor),
              ),
              const SizedBox(height: 4),
              Text(
                '• Limiar de Confiança e Abstenção Ética (RF04)\n'
                '• Explicabilidade e Citação de Fontes Oficiais (RF06)\n'
                '• Escalonamento Integrado para a Fila Humana do ASA (RF08)\n'
                '• Acessibilidade Universal e Tema Personalizável',
                style: TextStyle(fontSize: 11, color: context.secondaryTextColor, height: 1.4),
              ),
              const SizedBox(height: 14),
              Text(
                'Desenvolvimento: Projeto Interdisciplinar • Ciência da Computação\nCentro Universitário FECAP • 2024',
                style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: context.secondaryTextColor),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _showSupportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.support_agent_rounded, color: AppColors.primaryGreen),
            const SizedBox(width: 8),
            Text('Atendimento ASA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.primaryTextColor)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Canais Oficiais de Atendimento ao Aluno (ASA):',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.primaryTextColor),
            ),
            const SizedBox(height: 12),
            _buildSupportChannel(Icons.phone_android_rounded, 'WhatsApp Oficial', '(11) 3272-2222'),
            _buildSupportChannel(Icons.email_outlined, 'E-mail do ASA', 'asa@fecap.br'),
            _buildSupportChannel(Icons.access_time_rounded, 'Horário de Atendimento', 'Segunda a Sexta, 08h às 21h'),
            _buildSupportChannel(Icons.location_on_outlined, 'Localização Presencial', 'Campus Liberdade • Bloco B • Térreo'),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportChannel(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primaryGreen),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.primaryTextColor)),
                Text(desc, style: TextStyle(fontSize: 12, color: context.secondaryTextColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFontSizeDialog() {
    final access = Provider.of<AccessibilityProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final current = access.fontSizeName;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tamanho do Texto (Acessibilidade)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.primaryTextColor),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, size: 20, color: context.primaryTextColor),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Selecione o tamanho ideal para leitura. A alteração é aplicada globalmente em todo o aplicativo.',
                    style: TextStyle(fontSize: 12, color: context.secondaryTextColor),
                  ),
                  const SizedBox(height: 16),

                  _buildFontSizeOption(context, 'small', 'Pequeno (85%)', 'Exemplo de texto reduzido.', current, access, setModalState),
                  _buildFontSizeOption(context, 'normal', 'Padrão / Normal (100%)', 'Tamanho recomendado pelo sistema.', current, access, setModalState),
                  _buildFontSizeOption(context, 'medium', 'Médio (115%)', 'Aumento moderado para conforto visual.', current, access, setModalState),
                  _buildFontSizeOption(context, 'large', 'Grande (135%)', 'Maior legibilidade e destaque visual.', current, access, setModalState),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFontSizeOption(
    BuildContext context,
    String key,
    String label,
    String desc,
    String current,
    AccessibilityProvider access,
    StateSetter setModalState,
  ) {
    return RadioListTile<String>(
      value: key,
      groupValue: current,
      activeColor: AppColors.primaryGreen,
      title: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.primaryTextColor)),
      subtitle: Text(desc, style: TextStyle(fontSize: 11, color: context.secondaryTextColor)),
      onChanged: (val) {
        if (val != null) {
          access.setFontSize(val);
          setModalState(() {});
        }
      },
    );
  }

  void _showPersonalDataDialog(user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.person_pin_rounded, color: AppColors.primaryGreen),
            const SizedBox(width: 8),
            Text('Dados Pessoais', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.primaryTextColor)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDataRow(context, 'Nome Completo:', user?.fullName ?? 'Lucas Alvarista Silva'),
            _buildDataRow(context, 'RA:', user?.ra ?? '123456'),
            _buildDataRow(context, 'E-mail Institucional:', user?.email ?? 'aluno@fecap.br'),
            _buildDataRow(context, 'Curso:', user?.course ?? 'Ciência da Computação'),
            _buildDataRow(context, 'Semestre:', '${user?.semester ?? 5}º Semestre'),
            _buildDataRow(context, 'Campus:', user?.campus ?? 'Campus Liberdade'),
            _buildDataRow(context, 'Perfil Institucional:', user?.profileType ?? 'ALUNO'),
            const SizedBox(height: 8),
            Text(
              'Nota de Privacidade (LGPD): Os dados exibidos são estritamente fictícios e pertencem ao ambiente do Projeto Interdisciplinar.',
              style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: context.secondaryTextColor),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.secondaryTextColor)),
          Text(value, style: TextStyle(fontSize: 13, color: context.primaryTextColor, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showPrivacyLgpdDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.shield_outlined, color: AppColors.primaryGreen),
            const SizedBox(width: 8),
            Text('Privacidade & LGPD', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.primaryTextColor)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Princípios de Proteção de Dados do ASA Connect+:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.primaryTextColor),
              ),
              const SizedBox(height: 8),
              Text(
                '1. Minimização de Dados: Apenas dados essenciais para atendimento e identificação acadêmica são processados.\n\n'
                '2. Explicabilidade (RF06): Toda resposta do assistente explicita a fonte oficial, trecho normativo e data de atualização.\n\n'
                '3. Não-Discriminação e Abstenção (RF04): O agente não alucina e se abstém quando o nível de similaridade da base for insuficiente.\n\n'
                '4. Anonimização: Todos os registros deste ambiente de teste são fictícios.',
                style: TextStyle(fontSize: 11, color: context.secondaryTextColor, height: 1.4),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final access = Provider.of<AccessibilityProvider>(context);
    final user = auth.user;

    final content = SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        children: [
          // Card Superior do Perfil (Figma tela 7)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.borderColor),
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _showPhotoSyncDialog,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.headerGreen, width: 2.5),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            user?.profileType == 'PROFESSOR'
                                ? 'assets/images/persona_aluno.png'
                                : 'assets/images/persona_aluna.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          color: AppColors.headerGreen,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user?.fullName ?? (user?.profileType == 'PROFESSOR' ? 'Prof. Almeida' : 'Nome do Aluno'),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.primaryTextColor),
                ),
                const SizedBox(height: 2),
                Text(
                  'RA / Matrícula: ${user?.ra ?? (user?.profileType == 'PROFESSOR' ? 'DOC-4481' : '123456')}',
                  style: TextStyle(fontSize: 12, color: context.secondaryTextColor),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.isDarkMode
                        ? AppColors.success.withValues(alpha: 0.2)
                        : AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: context.isDarkMode
                          ? const Color(0xFF00E387).withValues(alpha: 0.4)
                          : AppColors.success.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    user?.profileType ?? 'ALUNO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: context.isDarkMode ? const Color(0xFF00E387) : AppColors.headerGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Seção CONTA
          _buildSectionHeader(context, 'CONTA'),
          _buildMenuTile(
            context: context,
            icon: Icons.person_outline_rounded,
            title: 'Dados Pessoais',
            onTap: () => _showPersonalDataDialog(user),
          ),
          _buildMenuTile(
            context: context,
            icon: Icons.bookmark_border_rounded,
            title: 'Documentos Salvos',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DocumentsScreen()),
              );
            },
          ),
          const SizedBox(height: 16),

          // Seção PREFERÊNCIAS
          _buildSectionHeader(context, 'PREFERÊNCIAS'),
          _buildSwitchTile(
            context: context,
            icon: Icons.notifications_none_rounded,
            title: 'Notificações',
            value: _notifications,
            onChanged: (val) => setState(() => _notifications = val),
          ),
          _buildMenuTile(
            context: context,
            icon: Icons.dark_mode_outlined,
            title: 'Aparência',
            trailingText: access.themeModeName,
            onTap: _showThemeDialog,
          ),
          const SizedBox(height: 16),

          // Seção ACESSIBILIDADE (Crucial para o briefing e avaliação)
          _buildSectionHeader(context, 'ACESSIBILIDADE'),
          _buildMenuTile(
            context: context,
            icon: Icons.text_fields_rounded,
            title: 'Tamanho do Texto',
            trailingText: access.fontSizeName.toUpperCase(),
            onTap: _showFontSizeDialog,
          ),
          _buildSwitchTile(
            context: context,
            icon: Icons.contrast_rounded,
            title: 'Alto Contraste',
            value: access.highContrast,
            onChanged: (val) => access.toggleHighContrast(val),
          ),
          const SizedBox(height: 16),

          // Seção INSTITUCIONAL
          _buildSectionHeader(context, 'INSTITUCIONAL'),
          _buildMenuTile(
            context: context,
            icon: Icons.info_outline_rounded,
            title: 'Sobre o ASA Connect+',
            onTap: _showAboutAsaDialog,
          ),
          _buildMenuTile(
            context: context,
            icon: Icons.help_outline_rounded,
            title: 'Ajuda e Suporte',
            onTap: _showSupportDialog,
          ),
          _buildMenuTile(
            context: context,
            icon: Icons.privacy_tip_outlined,
            title: 'Privacidade e LGPD',
            onTap: _showPrivacyLgpdDialog,
          ),
          const SizedBox(height: 24),

          // Botão SAIR
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: context.isDarkMode ? const Color(0xFF7F1D1D) : const Color(0xFFFCA5A5)),
                backgroundColor: context.isDarkMode ? const Color(0xFF2A1515) : const Color(0xFFFEF2F2),
                foregroundColor: context.isDarkMode ? const Color(0xFFF87171) : AppColors.error,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('SAIR', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.8)),
              onPressed: () async {
                await auth.logout();
                if (!context.mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const ProfileSelectionScreen()),
                  (route) => false,
                );
              },
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );

    if (widget.isTab) return content;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: context.headerColor,
        title: const Text('Perfil', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          IconButton(icon: const Icon(Icons.more_vert_rounded), onPressed: () {}),
        ],
      ),
      body: content,
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          title,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: context.secondaryTextColor),
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? trailingText,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primaryGreen, size: 20),
        title: Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: context.primaryTextColor)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailingText != null)
              Text(trailingText, style: TextStyle(fontSize: 11, color: context.secondaryTextColor)),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, color: context.secondaryTextColor, size: 20),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSwitchTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor),
      ),
      child: SwitchListTile(
        secondary: Icon(icon, color: AppColors.primaryGreen, size: 20),
        title: Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: context.primaryTextColor)),
        value: value,
        activeThumbColor: AppColors.primaryGreen,
        onChanged: onChanged,
      ),
    );
  }
}
