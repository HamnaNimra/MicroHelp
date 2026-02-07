import 'package:flutter/material.dart';
import '../services/preferences_service.dart';

enum ThemeSetting { system, light, dark }

class ThemeProvider extends ChangeNotifier {
  ThemeProvider(this._prefs) {
    _setting = _loadSetting();
  }

  final PreferencesService _prefs;
  late ThemeSetting _setting;

  ThemeSetting get setting => _setting;

  ThemeMode get themeMode {
    switch (_setting) {
      case ThemeSetting.system:
        return ThemeMode.system;
      case ThemeSetting.light:
        return ThemeMode.light;
      case ThemeSetting.dark:
        return ThemeMode.dark;
    }
  }

  void setSetting(ThemeSetting value) {
    _setting = value;
    _prefs.themeSetting = value.name;
    notifyListeners();
  }

  ThemeSetting _loadSetting() {
    final stored = _prefs.themeSetting;
    return ThemeSetting.values.firstWhere(
      (e) => e.name == stored,
      orElse: () => ThemeSetting.system,
    );
  }
}
