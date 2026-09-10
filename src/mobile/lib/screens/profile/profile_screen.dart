import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:asa_connect/core/constants.dart';
import 'package:asa_connect/state/auth_provider.dart';
import 'package:asa_connect/state/accessibility_provider.dart';
import 'package:asa_connect/screens/auth/login_screen.dart';
import 'package:asa_connect/screens/documents/documents_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool isTab;

  const ProfileScreen({super.key, this.isTab = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notifications = true;

  void _showFontSizeDialog() {
    final access = Provider.of<AccessibilityProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
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
                      const Text(
                        'Tamanho do Texto (Acessibilidade)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Selecione o tamanho ideal para leitura. A alteração é aplicada globalmente em todo o aplicativo.',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 16),

                  _buildFontSizeOption('small', 'Pequeno (85%)', 'Exemplo de texto reduzido.', current, access, setModalState),
                  _buildFontSizeOption('normal', 'Padrão / Normal (100%)', 'Tamanho recomendado pelo sistema.', current, access, setModalState),
                  _buildFontSizeOption('medium', 'Médio (115%)', 'Aumento moderado para conforto visual.', current, access, setModalState),
                  _buildFontSizeOption('large', 'Grande (135%)', 'Maior legibilidade e destaque visual.', current, access, setModalState),
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
      title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: Text(desc, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.person_pin_rounded, color: AppColors.primaryGreen),
            SizedBox(width: 8),
            Text('Dados Pessoais', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDataRow('Nome Completo:', user?.fullName ?? 'Lucas Alvarista Silva'),
            _buildDataRow('RA:', user?.ra ?? '123456'),
            _buildDataRow('E-mail Institucional:', user?.email ?? 'aluno@fecap.br'),
            _buildDataRow('Curso:', user?.course ?? 'Ciência da Computação'),
            _buildDataRow('Semestre:', '${user?.semester ?? 5}º Semestre'),
            _buildDataRow('Campus:', user?.campus ?? 'Campus Liberdade'),
            _buildDataRow('Perfil Institucional:', user?.profileType ?? 'ALUNO'),
            const SizedBox(height: 8),
            const Text(
              'Nota de Privacidade (LGPD): Os dados exibidos são estritamente fictícios e pertencem ao ambiente do Projeto Interdisciplinar.',
              style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: AppColors.textMuted),
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

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
          Text(value, style: const TextStyle(fontSize: 13, color: AppColors.textDark, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showPrivacyLgpdDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: AppColors.primaryGreen),
            SizedBox(width: 8),
            Text('Privacidade & LGPD', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Princípios de Proteção de Dados do ASA Connect+:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              SizedBox(height: 8),
              Text(
                '1. Minimização de Dados: Apenas dados essenciais para atendimento e identificação acadêmica são processados.\n\n'
                '2. Explicabilidade (RF06): Toda resposta do assistente explicita a fonte oficial, trecho normativo e data de atualização.\n\n'
                '3. Não-Discriminação e Abstenção (RF04): O agente não alucina e se abstém quando o nível de similaridade da base for insuficiente.\n\n'
                '4. Anonimização: Todos os registros deste ambiente de teste são fictícios.',
                style: TextStyle(fontSize: 11, color: AppColors.textBody, height: 1.4),
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              children: [
                Stack(
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
                          'assets/images/persona_aluna.png',
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
                const SizedBox(height: 12),
                Text(
                  user?.fullName ?? 'Nome do Aluno',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const SizedBox(height: 2),
                Text(
                  'RA: ${user?.ra ?? "123456"}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    user?.profileType ?? 'ALUNO',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppColors.headerGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Seção CONTA
          _buildSectionHeader('CONTA'),
          _buildMenuTile(
            icon: Icons.person_outline_rounded,
            title: 'Dados Pessoais',
            onTap: () => _showPersonalDataDialog(user),
          ),
          _buildMenuTile(
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
          _buildSectionHeader('PREFERÊNCIAS'),
          _buildSwitchTile(
            icon: Icons.notifications_none_rounded,
            title: 'Notificações',
            value: _notifications,
            onChanged: (val) => setState(() => _notifications = val),
          ),
          _buildMenuTile(
            icon: Icons.dark_mode_outlined,
            title: 'Aparência',
            trailingText: 'Sistema',
            onTap: () {},
          ),
          const SizedBox(height: 16),

          // Seção ACESSIBILIDADE (Crucial para o briefing e avaliação)
          _buildSectionHeader('ACESSIBILIDADE'),
          _buildMenuTile(
            icon: Icons.text_fields_rounded,
            title: 'Tamanho do Texto',
            trailingText: access.fontSizeName.toUpperCase(),
            onTap: _showFontSizeDialog,
          ),
          _buildSwitchTile(
            icon: Icons.contrast_rounded,
            title: 'Alto Contraste',
            value: access.highContrast,
            onChanged: (val) => access.toggleHighContrast(val),
          ),
          const SizedBox(height: 16),

          // Seção INSTITUCIONAL
          _buildSectionHeader('INSTITUCIONAL'),
          _buildMenuTile(
            icon: Icons.info_outline_rounded,
            title: 'Sobre o ASA Connect',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'ASA Connect+',
                applicationVersion: '1.0.0 (5º Semestre CC FECAP)',
                applicationLegalese: 'Projeto Interdisciplinar – Agente Inteligente para o Estudante Alvarista',
              );
            },
          ),
          _buildMenuTile(
            icon: Icons.help_outline_rounded,
            title: 'Ajuda e Suporte',
            onTap: () {},
          ),
          _buildMenuTile(
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
                side: const BorderSide(color: Color(0xFFFCA5A5)),
                backgroundColor: const Color(0xFFFEF2F2),
                foregroundColor: AppColors.error,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('SAIR', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.8)),
              onPressed: () async {
                await auth.logout();
                if (!context.mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: AppColors.headerGreen,
        title: const Text('Perfil', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          IconButton(icon: const Icon(Icons.more_vert_rounded), onPressed: () {}),
        ],
      ),
      body: content,
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          title,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: AppColors.textMuted),
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    String? trailingText,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primaryGreen, size: 20),
        title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textDark)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailingText != null)
              Text(trailingText, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textLight, size: 20),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: SwitchListTile(
        secondary: Icon(icon, color: AppColors.primaryGreen, size: 20),
        title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textDark)),
        value: value,
        activeColor: AppColors.primaryGreen,
        onChanged: onChanged,
      ),
    );
  }
}
