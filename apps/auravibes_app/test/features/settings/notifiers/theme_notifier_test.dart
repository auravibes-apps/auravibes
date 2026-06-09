// ignore_for_file: no-magic-number
// Required: Tests use numeric fixtures and dimensions.

import 'package:auravibes_app/features/settings/notifiers/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AppTheme', () {
    test('light maps to ThemeMode.light', () {
      expect(AppTheme.light.themeMode, ThemeMode.light);
    });

    test('dark maps to ThemeMode.dark', () {
      expect(AppTheme.dark.themeMode, ThemeMode.dark);
    });

    test('system maps to ThemeMode.system', () {
      expect(AppTheme.system.themeMode, ThemeMode.system);
    });

    test('has exactly three values', () {
      expect(AppTheme.values, hasLength(3));
    });

    test('values are in correct order', () {
      expect(AppTheme.values, [AppTheme.light, AppTheme.dark, AppTheme.system]);
    });

    test('indices are sequential', () {
      for (var i = 0; i < AppTheme.values.length; i++) {
        expect(AppTheme.values[i].index, i);
      }
    });
  });

  group('ThemeNotifier', () {
    var container = ProviderContainer();

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
    });

    tearDown(() => container.dispose());

    test('build defaults to system theme', () async {
      final theme = await container.read(themeProvider.future);
      expect(theme, AppTheme.system);
    });

    test('build restores saved theme from preferences', () async {
      SharedPreferences.setMockInitialValues({'app_theme': 0});
      final container2 = ProviderContainer();
      addTearDown(container2.dispose);

      final theme = await container2.read(themeProvider.future);
      expect(theme, AppTheme.light);
    });

    test('build restores dark theme from preferences', () async {
      SharedPreferences.setMockInitialValues({'app_theme': 1});
      final container2 = ProviderContainer();
      addTearDown(container2.dispose);

      final theme = await container2.read(themeProvider.future);
      expect(theme, AppTheme.dark);
    });

    test('build falls back to system for out-of-range index', () async {
      SharedPreferences.setMockInitialValues({'app_theme': 99});
      final container2 = ProviderContainer();
      addTearDown(container2.dispose);

      final theme = await container2.read(themeProvider.future);
      expect(theme, AppTheme.system);
    });

    test('build falls back to system for negative index', () async {
      SharedPreferences.setMockInitialValues({'app_theme': -1});
      final container2 = ProviderContainer();
      addTearDown(container2.dispose);

      final theme = await container2.read(themeProvider.future);
      expect(theme, AppTheme.system);
    });

    test('setTheme persists to SharedPreferences', () async {
      await container.read(themeProvider.notifier).setTheme(AppTheme.dark);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('app_theme'), AppTheme.dark.index);
    });

    test('setTheme round-trips through SharedPreferences', () async {
      await container.read(themeProvider.notifier).setTheme(AppTheme.light);
      container.dispose();

      final container2 = ProviderContainer();
      addTearDown(container2.dispose);

      final theme = await container2.read(themeProvider.future);
      expect(theme, AppTheme.light);
    });
  });
}
