import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class ThemeService {
  Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode.name);
  }

  Future<ThemeMode> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedMode = prefs.getString('theme_mode');
    if (savedMode == null) {
      return ThemeMode.system;
    }
    return ThemeMode.values.byName(savedMode);
  }
}
