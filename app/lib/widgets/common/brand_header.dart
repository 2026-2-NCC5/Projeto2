import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:asa_connect/core/constants.dart';

enum AsaLogoVariant {
  full,
  compact,
  header,
  iconOnly,
}

/// Ícone das asas em três camadas (verde, roxo e amarelo) do ASA Connect
class AsaWingIcon extends StatelessWidget {
  final double size;

  const AsaWingIcon({super.key, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/asa_symbol.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}

/// Widget que exibe a logo oficial do ASA Connect+ com suporte a variantes equivalentes ao AsaLogo.tsx
class AsaLogo extends StatelessWidget {
  final double width;
  final bool isDarkBackground;
  final AsaLogoVariant variant;

  const AsaLogo({
    super.key,
    this.width = 180,
    this.isDarkBackground = true,
    this.variant = AsaLogoVariant.full,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDarkBackground ? Colors.white : AppColors.textDark;

    if (variant == AsaLogoVariant.iconOnly) {
      return AsaWingIcon(size: width);
    }

    if (variant == AsaLogoVariant.header) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'asa',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 22,
              letterSpacing: -0.5,
              color: textColor,
              height: 1.0,
            ),
          ),
          const SizedBox(width: 4),
          const AsaWingIcon(size: 24),
          const SizedBox(width: 4),
          Text(
            'connect ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: textColor,
              height: 1.0,
            ),
          ),
          const Text(
            '+',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.warningYellow,
              height: 1.0,
            ),
          ),
        ],
      );
    }

    if (variant == AsaLogoVariant.compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'asa',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: width * 0.28,
              letterSpacing: -1.0,
              color: textColor,
              height: 1.0,
            ),
          ),
          const SizedBox(width: 4),
          AsaWingIcon(size: width * 0.28),
        ],
      );
    }

    // Default: Full SVG institucional
    return SvgPicture.asset(
      'assets/images/asa_logo.svg',
      width: width,
      fit: BoxFit.contain,
      semanticsLabel: 'ASA Connect+',
    );
  }
}

/// Cabeçalho de marca usado nas telas de splash, login e recovery.
class BrandHeader extends StatelessWidget {
  final bool isDarkBackground;
  final double logoWidth;
  final AsaLogoVariant variant;

  const BrandHeader({
    super.key,
    this.isDarkBackground = true,
    this.logoWidth = 200,
    this.variant = AsaLogoVariant.full,
  });

  @override
  Widget build(BuildContext context) {
    return AsaLogo(
      width: logoWidth,
      isDarkBackground: isDarkBackground,
      variant: variant,
    );
  }
}
