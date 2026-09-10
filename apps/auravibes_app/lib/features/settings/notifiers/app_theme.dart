// Required: Existing test and UI helpers keep compact return flow.
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_theme.g.dart';

enum AppTheme {
  light,
  dark,
  system;

  ThemeMode get themeMode {
    switch (this) {
      case .light:
        return .light;
      case .dark:
        return .dark;
      case .system:
        return .system;
    }
  }
}

@Riverpod(keepAlive: true)
class ThemeNotifier extends _$ThemeNotifier {
  static const _themeKey = 'app_theme';

  @override
  Future<AppTheme> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    return _appThemeFromStoredValue(prefs.get(_themeKey));
  }

  Future<void> setTheme(AppTheme theme) async {
    state = .data(theme);
    final prefs = await ref.read(sharedPreferencesProvider.future);
    final _ = await prefs.setInt(_themeKey, theme.index);
  }
}

AppTheme _appThemeFromStoredValue(Object? value) {
  if (value is int && value >= 0 && value < AppTheme.values.length) {
    return .values[value];
  }
  return .system;
}
