import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:asa_connect/core/constants.dart';
import 'package:asa_connect/core/responsive_breakpoints.dart';
import 'package:asa_connect/state/auth_provider.dart';
import 'package:asa_connect/state/chat_provider.dart';
import 'package:asa_connect/state/accessibility_provider.dart';
import 'package:asa_connect/widgets/common/brand_header.dart';
import 'package:asa_connect/screens/profile_selection/profile_selection_screen.dart';

class DesktopSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onOpenDocuments;
  final VoidCallback onOpenDashboard;

  const DesktopSidebar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.onOpenDocuments,
    required this.onOpenDashboard,
  });

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final accessibility = Provider.of<AccessibilityProvider>(context);
    final user = auth.user;

    final isAttendantOrAdmin =
        user?.profileType == 'ATENDENTE_ASA' || user?.profileType == 'ADMINISTRADOR';
    final isProfessor = user?.profileType == 'PROFESSOR';
    final isResponsavel = user?.profileType == 'RESPONSAVEL';
    final isColaborador = user?.profileType == 'COLABORADOR';

    String avatarAsset = 'assets/images/persona_aluna.png';
    if (isProfessor) {
      avatarAsset = 'assets/images/persona_professor.png';
    } else if (isResponsavel) {
      avatarAsset = 'assets/images/persona_coordenadora.png';
    } else if (isColaborador || isAttendantOrAdmin) {
      avatarAsset = 'assets/images/persona_atendente.png';
    }

    final isDark = context.isDarkMode;
    final bgColor = isDark ? AppDarkColors.surfaceCard : Colors.white;
    final borderColor = context.borderColor;

    return Container(
      width: ResponsiveBreakpoints.sidebarWidth,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          right: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Cabeçalho / Branding
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const AsaWingIcon(size: 28),
                    const SizedBox(width: 8),
                    Text(
                      'asa',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        letterSpacing: -0.5,
                        color: isDark ? Colors.white : AppColors.textDark,
                      ),
                    ),
                    Text(
                      ' connect+',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'FECAP · ÁREA DO SUCESSO ALVARISTA',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // 2. Itens de Navegação
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              children: [
                _SidebarItem(
                  icon: Icons.home_rounded,
                  label: 'Início',
                  isSelected: selectedIndex == 0,
                  onTap: () => onDestinationSelected(0),
                ),
                _SidebarItem(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Chat com o ASA',
                  badgeText: 'IA',
                  isSelected: selectedIndex == 1,
                  onTap: () => onDestinationSelected(1),
                ),
                _SidebarItem(
                  icon: Icons.school_outlined,
                  label: 'Serviços Acadêmicos',
                  isSelected: selectedIndex == 2,
                  onTap: () => onDestinationSelected(2),
                ),
                _SidebarItem(
                  icon: Icons.folder_open_rounded,
                  label: 'Meus Documentos',
                  isSelected: false,
                  onTap: onOpenDocuments,
                ),
                if (isAttendantOrAdmin)
                  _SidebarItem(
                    icon: Icons.dashboard_rounded,
                    label: 'Painel Gerencial ASA',
                    badgeText: 'Gestão',
                    isSelected: false,
                    onTap: onOpenDashboard,
                  ),
                _SidebarItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Meu Perfil',
                  isSelected: selectedIndex == 3,
                  onTap: () => onDestinationSelected(3),
                ),
              ],
            ),
          ),

          // 3. Rodapé com perfil do usuário e preferências
          const Divider(height: 1),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppDarkColors.background.withOpacity(0.5) : AppColors.surfaceInput,
            ),
            child: Column(
              children: [
                // Info do Usuário
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primaryGreen, width: 1.5),
                        image: DecorationImage(
                          image: AssetImage(avatarAsset),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.fullName ?? 'Estudante Alvarista',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: context.primaryTextColor,
                            ),
                          ),
                          Text(
                            user?.ra != null ? 'RA: ${user!.ra}' : (user?.email ?? 'aluno@fecap.br'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              color: context.secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Botões de Ação do Rodapé: Tema e Logout
                Row(
                  children: [
                    // Botão Alternar Tema Claro / Escuro
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          side: BorderSide(color: borderColor),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: Icon(
                          isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                          size: 15,
                          color: context.primaryTextColor,
                        ),
                        label: Text(
                          isDark ? 'Claro' : 'Escuro',
                          style: TextStyle(fontSize: 11, color: context.primaryTextColor),
                        ),
                        onPressed: () {
                          accessibility.toggleTheme();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Botão Sair
                    IconButton(
                      tooltip: 'Encerrar Sessão',
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.error.withOpacity(0.1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.logout_rounded, size: 16, color: AppColors.error),
                      onPressed: () async {
                        final chat = Provider.of<ChatProvider>(context, listen: false);
                        chat.clearChat();
                        await auth.logout();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const ProfileSelectionScreen()),
                            (route) => false,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? badgeText;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    this.badgeText,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final activeBg = AppColors.primaryGreen.withOpacity(isDark ? 0.2 : 0.1);
    final activeColor = isDark ? AppColors.accentEmerald : AppColors.primaryGreen;
    final inactiveColor = context.secondaryTextColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: isSelected ? activeBg : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          hoverColor: AppColors.primaryGreen.withOpacity(0.06),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? activeColor : inactiveColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? activeColor : context.primaryTextColor,
                    ),
                  ),
                ),
                if (badgeText != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? activeColor
                          : AppColors.aiPurple.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badgeText!,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? AppColors.aiPurple : AppColors.aiPurpleDark),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
