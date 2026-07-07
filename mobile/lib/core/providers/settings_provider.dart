import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ════════════════════════════════════════════════════════
// SETTINGS STATE
// ════════════════════════════════════════════════════════

class SettingsState {
  final ThemeMode themeMode;
  final Locale locale;

  const SettingsState({
    required this.themeMode,
    required this.locale,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
    );
  }
}

// ════════════════════════════════════════════════════════
// SETTINGS NOTIFIER
// ════════════════════════════════════════════════════════

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState(
    themeMode: ThemeMode.system,
    locale: Locale('fr'),
  )) {
    _loadSettings();
  }

  static const _themeKey = 'theme_mode';
  static const _localeKey = 'locale_code';

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    final themeIndex = prefs.getInt(_themeKey);
    final themeMode = themeIndex != null 
        ? ThemeMode.values[themeIndex] 
        : ThemeMode.system;

    final localeCode = prefs.getString(_localeKey) ?? 'fr';
    
    state = SettingsState(
      themeMode: themeMode,
      locale: Locale(localeCode),
    );
  }

  Future<void> toggleTheme(bool isDark) async {
    final newMode = isDark ? ThemeMode.dark : ThemeMode.light;
    state = state.copyWith(themeMode: newMode);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, newMode.index);
  }

  Future<void> setLocale(String languageCode) async {
    final newLocale = Locale(languageCode);
    state = state.copyWith(locale: newLocale);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, languageCode);
  }
}

// ════════════════════════════════════════════════════════
// PROVIDER
// ════════════════════════════════════════════════════════

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
