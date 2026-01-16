import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Global notifier used by the app to listen for theme changes.
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

class ThemeManager {
  static const _key = 'theme_mode';

  // Load saved theme from SharedPreferences. Defaults to light.
  // Supports: 'light', 'dark'
  static Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key) ?? 'light';
    themeNotifier.value = value == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  // Persist and notify listeners.
  static Future<void> setTheme(ThemeMode mode) async {
    themeNotifier.value = mode;
    final prefs = await SharedPreferences.getInstance();
    final value = mode == ThemeMode.dark ? 'dark' : 'light';
    await prefs.setString(_key, value);
  }

  // Toggle between light and dark.
  static Future<void> toggleTheme() async {
    final next = themeNotifier.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setTheme(next);
  }
}
