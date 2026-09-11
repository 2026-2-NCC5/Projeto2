import 'package:flutter/material.dart';

class AppColors {
  // Verde Principal (Institucional)
  static const Color primaryGreen = Color(0xFF02845E);       // #02845E Verde principal
  static const Color headerGreen = Color(0xFF02845E);        // #02845E Verde institucional de cabeçalho e login
  static const Color darkBackground = Color(0xFF02845E);

  // Verdes de Apoio
  static const Color greenDeep = Color(0xFF006C4C);          // #006C4C Verde de apoio profundo
  static const Color greenAction = Color(0xFF03A576);        // #03A576 Verde de apoio / ação
  static const Color greenMedium = Color(0xFF128760);        // #128760 Verde de apoio médio
  static const Color primaryDarkGreen = Color(0xFF006C4C);
  static const Color primaryLightGreen = Color(0xFF03A576);

  // Roxo (IA / Inteligência / Tecnologia)
  static const Color aiPurple = Color(0xFF845EF2);           // #845EF2 Roxo principal de acento
  static const Color aiPurpleDark = Color(0xFF653CD2);       // #653CD2 Roxo escuro
  static const Color aiPurpleDeep = Color(0xFF4B297D);       // #4B297D Roxo bem escuro

  // Amarelo e Dourado (Acentos e Destaques)
  static const Color warningYellow = Color(0xFFFFDE34);      // #FFDE34 Amarelo de destaque / asa
  static const Color golden = Color(0xFFC3930C);             // #C3930C Dourado
  static const Color accentPillYellow = Color(0xFFFFDE34);

  // Sucesso
  static const Color success = Color(0xFF00E387);            // #00E387 Confirmação
  static const Color accentEmerald = Color(0xFF03A576);
  static const Color accentMint = Color(0xFFD1FAE5);

  // Fundos e Superfícies (Brancos Consolidados)
  static const Color surfaceWhite = Color(0xFFFFFFFF);       // #FFFFFF Fundo puro
  static const Color background = Color(0xFFFCF9F8);         // #FCF9F8 Fundo padrão do design oficial
  static const Color surfaceInput = Color(0xFFF8FAF9);       // #F8FAF9 Fundo suave de inputs
  static const Color surfaceMuted = Color(0xFFF6F3F2);       // #F6F3F2 Fundo alternativo
  static const Color surfaceCard = Color(0xFFFFFFFF);

  // Textos
  static const Color textDark = Color(0xFF1B1C1C);           // #1B1C1C Conteúdo e títulos
  static const Color textBody = Color(0xFF3D4A42);           // #3D4A42 Conteúdo secundário

  // Cinzas e Bordas
  static const Color textMuted = Color(0xFF6B7280);          // #6B7280 Cinza de legendas e ícones neutros
  static const Color borderMedium = Color(0xFFBCCAC0);       // #BCCAC0 Cinza de borda de input
  static const Color borderLight = Color(0xFFE5E7EB);        // #E5E7EB Cinza de divisórias e cards
  static const Color textLight = Color(0xFF6B7280);

  // Erro e Alerta
  static const Color error = Color(0xFFBA1A1A);              // #BA1A1A Erro principal
  static const Color errorDark = Color(0xFF93000A);          // #93000A Erro escuro
  static const Color errorContainer = Color(0xFFFFDAD6);     // #FFDAD6 Container de alerta

  // Explicabilidade e Abstenção
  static const Color abstentionAmber = Color(0xFFC3930C);    // #C3930C Dourado de abstenção
  static const Color abstentionBg = Color(0xFFFFFBEB);
  static const Color abstentionBorder = Color(0xFFFCD34D);

  // Acentos de interface
  static const Color info = Color(0xFF845EF2);
  static const Color accentPillOrange = Color(0xFFF97316);
  static const Color accentPillBlue = Color(0xFF845EF2);
}

class AppConstants {
  static const String appName = "ASA Connect+";
  static const String institutionName = "ÁREA DO SUCESSO ALVARISTA FECAP";
  
  // URL base padrão da API em nuvem (Render + Supabase)
  static const String defaultApiBaseUrl = "https://projeto2-7gf7.onrender.com/api/v1";
}
