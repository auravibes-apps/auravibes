
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart' show ProviderScope;

/// Creates a testable widget wrapped with EasyLocalization and ProviderScope.
class TestableApp extends StatelessWidget {
  /// Creates a [TestableApp].
  const TestableApp({
    required this.child,
    this.overrides = const [],
    super.key,
  });

  /// The widget under test.
  final Widget child;

  /// Riverpod provider overrides for the test.
  final List<Object> overrides;

  @override
  Widget build(BuildContext context) {
    return EasyLocalization(
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
  }
}
