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
  supportedLocales: const [Locale('en')],
  path: 'assets/i18n',
  fallbackLocale: const Locale('en'),
  startLocale: const Locale('en'),
  useFallbackTranslations: true,
  useOnlyLangCode: true,
  child: Builder(
    builder: (context) {
      return ProviderScope(
        overrides: overrides.cast(),
        child: MaterialApp(
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          home: child,
        ),
      );
    },
  ),
);
