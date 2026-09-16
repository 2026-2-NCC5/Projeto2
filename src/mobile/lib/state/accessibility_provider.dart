import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccessibilityProvider with ChangeNotifier {
  String _fontSizeName = "normal";
  double _fontScaleFactor = 1.0;
  bool _highContrast = false;
  ThemeMode _themeMode = ThemeMode.system;

  String get fontSizeName => _fontSizeName;
  double get fontScaleFactor => _fontScaleFactor;
  bool get highContrast => _highContrast;
  ThemeMode get themeMode => _themeMode;

  String get themeModeName {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Claro';
      case ThemeMode.dark:
        return 'Escuro';
      case ThemeMode.system:
        return 'Sistema';
    }
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedSize = prefs.getString('pref_font_size') ?? "normal";
    final savedTheme = prefs.getString('pref_theme_mode') ?? "system";
    _highContrast = prefs.getBool('pref_high_contrast') ?? false;

    if (savedTheme == "light") {
      _themeMode = ThemeMode.light;
    } else if (savedTheme == "dark") {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }

    setFontSize(savedSize, notify: false);
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    String modeStr = 'system';
    if (mode == ThemeMode.light) modeStr = 'light';
    if (mode == ThemeMode.dark) modeStr = 'dark';
    await prefs.setString('pref_theme_mode', modeStr);
    notifyListeners();
  }

  void setFontSize(String sizeName, {bool notify = true}) async {
    _fontSizeName = sizeName;
    switch (sizeName) {
      case "small":
        _fontScaleFactor = 0.85;
        break;
      case "medium":
        _fontScaleFactor = 1.15;
        break;
      case "large":
        _fontScaleFactor = 1.35;
        break;
      case "normal":
      default:
        _fontScaleFactor = 1.0;
        break;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pref_font_size', sizeName);

    if (notify) {
      notifyListeners();
    }
  }

  void toggleHighContrast(bool value) async {
    _highContrast = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pref_high_contrast', value);
    notifyListeners();
  }
}
