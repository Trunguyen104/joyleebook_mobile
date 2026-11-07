import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _keyThemeMode = 'app_theme_mode';
  SharedPreferencesAsync? _prefs;

  SharedPreferencesAsync? get _safePrefs {
    try {
      _prefs ??= SharedPreferencesAsync();
      return _prefs;
    } catch (_) {
      return null;
    }
  }

  @override
  ThemeMode build() {
    _loadSavedTheme();
    return ThemeMode.light;
  }

  Future<void> _loadSavedTheme() async {
    try {
      final p = _safePrefs;
      if (p != null) {
        final saved = await p.getString(_keyThemeMode);
        if (saved == 'dark') {
          state = ThemeMode.dark;
        } else if (saved == 'light') {
          state = ThemeMode.light;
        } else if (saved == 'system') {
          state = ThemeMode.system;
        }
      }
    } catch (_) {}
  }

  Future<void> toggleTheme() async {
    final next = (state == ThemeMode.dark) ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(next);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      final p = _safePrefs;
      if (p != null) {
        await p.setString(_keyThemeMode, mode.name);
      }
    } catch (_) {}
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
