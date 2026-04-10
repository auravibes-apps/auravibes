import 'package:auravibes_app/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_notifier.g.dart';

enum AppTheme {
  light,
  dark,
  system
  ;

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
    final themeIndex = prefs.getInt(_themeKey);
    if (themeIndex != null &&
        themeIndex >= 0 &&
        themeIndex < AppTheme.values.length) {
      return .values[themeIndex];
    }
    return .system;
  }

  Future<void> setTheme(AppTheme theme) async {
    state = .data(theme);
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setInt(_themeKey, theme.index);
  }
}
