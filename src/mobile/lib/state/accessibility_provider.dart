import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccessibilityProvider with ChangeNotifier {
  String _fontSizeName = "normal";
  double _fontScaleFactor = 1.0;
  bool _highContrast = false;

  String get fontSizeName => _fontSizeName;
  double get fontScaleFactor => _fontScaleFactor;
  bool get highContrast => _highContrast;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedSize = prefs.getString('pref_font_size') ?? "normal";
    _highContrast = prefs.getBool('pref_high_contrast') ?? false;
    setFontSize(savedSize, notify: false);
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
