import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/data_provider.dart' show sharedPrefsProvider;

// App-wide appearance + language settings, persisted to SharedPreferences so a
// user's choice survives restarts. Both providers are read by MaterialApp in
// main.dart (themeMode / locale) and driven from the teacher Settings screen.

const String _kThemeModeKey = 'sd_theme_mode';
const String _kLocaleKey = 'sd_locale';

// Locales the app ships translations/RTL support for. English (LTR) and
// Arabic (RTL) — Arabic flips the whole layout via Directionality.
const Locale kEnglishLocale = Locale('en');
const Locale kArabicLocale = Locale('ar');
const List<Locale> kSupportedLocales = [kEnglishLocale, kArabicLocale];

ThemeMode _themeModeFromString(String? raw) {
  switch (raw) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    case 'system':
      return ThemeMode.system;
    default:
      // No saved choice yet → default to Light for every device, regardless of
      // the OS setting. Users who want a dark background opt in explicitly from
      // Settings (persisted, app-wide across web + mobile).
      return ThemeMode.light;
  }
}

String _themeModeToString(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.light:
      return 'light';
    case ThemeMode.dark:
      return 'dark';
    case ThemeMode.system:
      return 'system';
  }
}

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(this._prefs) : super(_themeModeFromString(_prefs.getString(_kThemeModeKey)));

  final SharedPreferences _prefs;

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await _prefs.setString(_kThemeModeKey, _themeModeToString(mode));
  }

  Future<void> toggleLightDark() async {
    // Resolve `system` to its concrete opposite so a single tap always flips.
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await set(next);
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  return ThemeModeNotifier(prefs);
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier(this._prefs)
      : super(_prefs.getString(_kLocaleKey) == 'ar' ? kArabicLocale : kEnglishLocale);

  final SharedPreferences _prefs;

  Future<void> set(Locale locale) async {
    state = locale;
    await _prefs.setString(_kLocaleKey, locale.languageCode);
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  return LocaleNotifier(prefs);
});
