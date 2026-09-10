import 'package:flutter/material.dart';
import 'package:asa_connect/core/constants.dart';
import 'package:asa_connect/widgets/common/brand_header.dart';

enum AppHeaderVariant {
  brand,
  standard,
  chat,
}

/// Cabeçalho unificado do ASA Connect equivalente a AppHeader.tsx
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final String? subtitle;
  final AppHeaderVariant variant;
  final VoidCallback? onBack;
  final VoidCallback? onMenuClick;
  final String? avatarAsset;
  final VoidCallback? onAvatarClick;
  final Widget? leading;
  final List<Widget>? actions;

  const AppHeader({
    super.key,
    this.title,
    this.subtitle,
    this.variant = AppHeaderVariant.standard,
    this.onBack,
    this.onMenuClick,
    this.avatarAsset = 'assets/images/persona_aluna.png',
    this.onAvatarClick,
    this.leading,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: preferredSize.height + MediaQuery.of(context).padding.top,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: const BoxDecoration(
        color: AppColors.headerGreen,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Lado Esquerdo
            if (variant == AppHeaderVariant.brand) ...[
              if (leading != null)
                leading!
              else
                const AsaLogo(width: 125, isDarkBackground: true),
            ] else ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onBack != null)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: onBack,
                      tooltip: 'Voltar',
                    )
                  else if (Navigator.of(context).canPop())
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Voltar',
                    ),
                  const SizedBox(width: 10),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: -0.2,
                            ),
                          ),
                          if (variant == AppHeaderVariant.chat) ...[
                            const SizedBox(width: 6),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty)
                        Text(
                          subtitle!,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],

            // Lado Direito
            if (actions != null)
              Row(mainAxisSize: MainAxisSize.min, children: actions!)
            else if (variant == AppHeaderVariant.brand) ...[
              GestureDetector(
                onTap: onAvatarClick,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    image: DecorationImage(
                      image: AssetImage(avatarAsset ?? 'assets/images/persona_aluna.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ] else ...[
              IconButton(
                icon: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: onMenuClick ?? () {},
                tooltip: 'Mais opções',
              ),
            ],
          ],
        ),
      ),
    );
  }
}
