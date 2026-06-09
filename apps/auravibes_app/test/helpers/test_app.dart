// ignore_for_file: avoid-top-level-members-in-tests
// Required: Test files keep shared fixtures and helpers top-level.
// ignore_for_file: prefer-static-class
// Required: Tests keep fixture helpers and fakes top-level.

// ignore_for_file: avoid-returning-widgets
// Required: Widget tests use helpers that build widgets under test.
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart' show ProviderScope;

/// Creates a testable widget wrapped with EasyLocalization and
/// ProviderScope.
///
/// Use this for widget tests that depend on localized text or Riverpod
/// providers.
///
/// Example:
/// ```dart
/// testWidgets('SettingsScreen renders', (tester) async {
///   await tester.pumpWidget(
///     testableApp(child: SettingsScreen()),
///   );
///   await tester.pumpAndSettle();
///   expect(find.text('Settings'), findsOneWidget);
/// });
/// ```
Widget testableApp({
  required Widget child,
  List<Object> overrides = const [],
}) => EasyLocalization(
  child: Builder(
    builder: (context) {
      return ProviderScope(
        overrides: overrides.cast(),
        child: MaterialApp(
          home: child,
          locale: context.locale,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
        ),
      );
    },
  ),
  supportedLocales: const [Locale('en')],
  path: 'assets/i18n',
  fallbackLocale: const Locale('en'),
  startLocale: const Locale('en'),
  useOnlyLangCode: true,
  useFallbackTranslations: true,
);
