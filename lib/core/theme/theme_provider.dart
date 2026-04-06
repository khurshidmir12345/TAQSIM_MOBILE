import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kThemeKey = 'theme_mode';

class ThemeModeNotifier extends AsyncNotifier<ThemeMode> {
  @override
  Future<ThemeMode> build() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kThemeKey);
    return switch (saved) {
      'dark'  => ThemeMode.dark,
      'light' => ThemeMode.light,
      _       => ThemeMode.system,
    };
  }

  Future<void> setLight() => _save(ThemeMode.light);
  Future<void> setDark()  => _save(ThemeMode.dark);
  Future<void> setSystem() => _save(ThemeMode.system);

  Future<void> toggle() async {
    final current = state.value ?? ThemeMode.system;
    await _save(current == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }

  Future<void> _save(ThemeMode mode) async {
    state = AsyncData(mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeKey, mode.name);
  }
}

final themeModeProvider =
    AsyncNotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
