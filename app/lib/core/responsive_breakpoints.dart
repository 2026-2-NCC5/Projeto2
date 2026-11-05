import 'package:flutter/material.dart';

/// Constantes globais de breakpoints e restrições de layout para Desktop e Mobile
class ResponsiveBreakpoints {
  static const double mobileMaxWidth = 799.0;
  static const double desktopMinWidth = 800.0;
  static const double widescreenMinWidth = 1200.0;

  // Larguras máximas recomendadas para componentes desktop
  static const double maxContentWidth = 1200.0;
  static const double maxFormWidth = 480.0;
  static const double maxChatBubbleWidth = 720.0;
  static const double maxChatColumnWidth = 900.0;
  static const double sidebarWidth = 260.0;
}

/// Extensão no BuildContext para acesso rápido e ergonômico aos breakpoints
extension ResponsiveContextExtension on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;

  bool get isDesktop => screenWidth >= ResponsiveBreakpoints.desktopMinWidth;
  bool get isMobile => screenWidth < ResponsiveBreakpoints.desktopMinWidth;
  bool get isWidescreen => screenWidth >= ResponsiveBreakpoints.widescreenMinWidth;
}
