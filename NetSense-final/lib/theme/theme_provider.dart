import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';


class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadThemeMode();
  }

  static const String _themeModeKey = 'theme_mode';


  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeString = prefs.getString(_themeModeKey);
    
    if (themeModeString != null) {
      state = _stringToThemeMode(themeModeString);
    }
  }


  Future<void> _saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.toString());
  }


  ThemeMode _stringToThemeMode(String value) {
    return ThemeMode.values.firstWhere(
      (mode) => mode.toString() == value,
      orElse: () => ThemeMode.system,
    );
  }


  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _saveThemeMode(mode);
  }


  Future<void> toggleThemeMode() async {
    final newMode = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await setThemeMode(newMode);
  }


  Future<void> useSystemTheme() async {
    await setThemeMode(ThemeMode.system);
  }
}


final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);
