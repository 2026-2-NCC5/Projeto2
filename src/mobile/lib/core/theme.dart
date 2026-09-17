import 'package:flutter/material.dart';
import 'package:asa_connect/core/constants.dart';

class AppTheme {
  static ThemeData getLightTheme({double fontScale = 1.0, bool highContrast = false}) {
    final baseTextColor = highContrast ? Colors.black : AppColors.textDark;
    final bodyTextColor = highContrast ? const Color(0xFF000000) : AppColors.textBody;
    final primaryColor = highContrast ? const Color(0xFF004D3C) : AppColors.primaryGreen;

    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: highContrast ? Colors.white : AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: AppColors.accentEmerald,
        surface: AppColors.surfaceWhite,
      ),
      fontFamily: 'Roboto',
      textTheme: TextTheme(
        displayLarge: TextStyle(fontSize: 32 * fontScale, fontWeight: FontWeight.bold, color: baseTextColor),
        displayMedium: TextStyle(fontSize: 26 * fontScale, fontWeight: FontWeight.bold, color: baseTextColor),
        titleLarge: TextStyle(fontSize: 20 * fontScale, fontWeight: FontWeight.w700, color: baseTextColor),
        titleMedium: TextStyle(fontSize: 16 * fontScale, fontWeight: FontWeight.w600, color: baseTextColor),
        bodyLarge: TextStyle(fontSize: 15 * fontScale, fontWeight: FontWeight.normal, color: bodyTextColor, height: 1.4),
        bodyMedium: TextStyle(fontSize: 13 * fontScale, fontWeight: FontWeight.normal, color: bodyTextColor, height: 1.4),
        bodySmall: TextStyle(fontSize: 11 * fontScale, fontWeight: FontWeight.normal, color: AppColors.textMuted),
        labelLarge: TextStyle(fontSize: 14 * fontScale, fontWeight: FontWeight.w600, color: Colors.white),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: highContrast ? primaryColor : AppColors.headerGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(fontSize: 18 * fontScale, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: highContrast ? Colors.black : AppColors.borderLight, width: highContrast ? 1.5 : 1.0),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: TextStyle(fontSize: 15 * fontScale, fontWeight: FontWeight.bold),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: highContrast ? Colors.white : AppColors.surfaceInput,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: highContrast ? Colors.black : AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
        ),
        hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13 * fontScale),
      ),
    );
  }

  static ThemeData getDarkTheme({double fontScale = 1.0, bool highContrast = false}) {
    final primaryColor = highContrast ? const Color(0xFF00E387) : AppColors.accentEmerald;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: AppDarkColors.background,
      cardColor: AppDarkColors.surfaceCard,
      dividerColor: AppDarkColors.borderSubtle,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: AppColors.aiPurple,
        surface: AppDarkColors.surfaceCard,
        onSurface: AppDarkColors.textLight,
        outline: AppDarkColors.border,
      ),
      fontFamily: 'Roboto',
      textTheme: TextTheme(
        displayLarge: TextStyle(fontSize: 32 * fontScale, fontWeight: FontWeight.bold, color: AppDarkColors.textLight),
        displayMedium: TextStyle(fontSize: 26 * fontScale, fontWeight: FontWeight.bold, color: AppDarkColors.textLight),
        titleLarge: TextStyle(fontSize: 20 * fontScale, fontWeight: FontWeight.w700, color: AppDarkColors.textLight),
        titleMedium: TextStyle(fontSize: 16 * fontScale, fontWeight: FontWeight.w600, color: AppDarkColors.textLight),
        bodyLarge: TextStyle(fontSize: 15 * fontScale, fontWeight: FontWeight.normal, color: AppDarkColors.textLight, height: 1.4),
        bodyMedium: TextStyle(fontSize: 13 * fontScale, fontWeight: FontWeight.normal, color: AppDarkColors.textMuted, height: 1.4),
        bodySmall: TextStyle(fontSize: 11 * fontScale, fontWeight: FontWeight.normal, color: AppDarkColors.textMuted),
        labelLarge: TextStyle(fontSize: 14 * fontScale, fontWeight: FontWeight.w600, color: Colors.white),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppDarkColors.headerGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(fontSize: 18 * fontScale, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppDarkColors.bottomNav,
        selectedItemColor: AppColors.accentEmerald,
        unselectedItemColor: AppDarkColors.textMuted,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppDarkColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppDarkColors.border),
        ),
        titleTextStyle: TextStyle(fontSize: 18 * fontScale, fontWeight: FontWeight.bold, color: AppDarkColors.textLight),
        contentTextStyle: TextStyle(fontSize: 13 * fontScale, color: AppDarkColors.textMuted),
      ),
      cardTheme: CardThemeData(
        color: AppDarkColors.surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: highContrast ? Colors.white : AppDarkColors.border,
            width: highContrast ? 1.5 : 1.0,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: TextStyle(fontSize: 15 * fontScale, fontWeight: FontWeight.bold),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppDarkColors.surfaceInput,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppDarkColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: highContrast ? Colors.white : AppDarkColors.border),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: AppColors.accentEmerald, width: 2),
        ),
        hintStyle: TextStyle(color: AppDarkColors.textMuted, fontSize: 13 * fontScale),
      ),
    );
  }
}
