import 'package:auravibes_app/features/settings/widgets/legal_links_section.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/aura_legacy_material_bridge.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart' as sdk;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpLegalLinks(WidgetTester tester, String language) async {
  SharedPreferences.setMockInitialValues({});
  await tester.runAsync(() async {
    await tester.pumpWidget(
      EasyLocalization(
        child: Builder(
          builder: (context) => MaterialApp(
            home: AuraThemeScope(
              theme: .light,
              child: const AuraLegacyMaterialBridge(
                child: AuraSnackBarHost(child: LegalLinksSection()),
              ),
            ),
            locale: context.locale,
            localizationsDelegates: [
              ...GlobalMaterialLocalizations.delegates,
              sdk.GlobalMaterialLocalizations.delegate,
              ...context.localizationDelegates,
            ],
            supportedLocales: context.supportedLocales,
          ),
        ),
        supportedLocales: const [Locale('en'), Locale('es')],
        path: 'assets/i18n',
        fallbackLocale: const Locale('en'),
        startLocale: .new(language),
        saveLocale: false,
      ),
    );
  });
  final _ = await tester.pumpAndSettle();
}

void main() {
  const channel = MethodChannel('plugins.flutter.io/url_launcher');
  for (final language in ['en', 'es']) {
    testWidgets('opens localized $language privacy and terms pages', (
      tester,
    ) async {
      final urls = <String>[];
      final messenger = tester.binding.defaultBinaryMessenger
        ..setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'launch') {
            final arguments = call.arguments as Map<Object?, Object?>;
            urls.add(arguments['url']! as String);
          }

          return true;
        });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      await _pumpLegalLinks(tester, language);

      expect(
        find.text(
          LocaleKeys.settings_screen_legal_title.tr(
            context: tester.element(find.byType(LegalLinksSection)),
          ),
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey<String>('settings_privacy')));
      final _ = await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('settings_terms')));
      final _ = await tester.pumpAndSettle();
      expect(urls, [
        'https://auravibes.me/$language/privacy',
        'https://auravibes.me/$language/terms',
      ]);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('shows localized recovery when browser launch fails', (
    tester,
  ) async {
    final messenger = tester.binding.defaultBinaryMessenger
      ..setMockMethodCallHandler(channel, (_) async => false);
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    await _pumpLegalLinks(tester, 'es');
    await tester.tap(find.byKey(const ValueKey<String>('settings_privacy')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.text(
        LocaleKeys.settings_screen_legal_open_error.tr(
          context: tester.element(find.byType(LegalLinksSection)),
        ),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
