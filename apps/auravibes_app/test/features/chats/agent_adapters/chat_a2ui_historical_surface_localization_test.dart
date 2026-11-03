import 'package:auravibes_app/features/chats/widgets/chat_a2ui_warning.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('historical read-only status is localized for Spanish', (
    tester,
  ) async {
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('es')],
        path: 'assets/i18n',
        fallbackLocale: const Locale('en'),
        startLocale: const Locale('es'),
        useOnlyLangCode: true,
        useFallbackTranslations: true,
        useFallbackTranslationsForEmptyResources: true,
        saveLocale: false,
        child: Builder(
          builder: (context) => MaterialApp(
            locale: context.locale,
            localizationsDelegates: [
              ...GlobalMaterialLocalizations.delegates,
              ...context.localizationDelegates,
            ],
            supportedLocales: context.supportedLocales,
            home: Builder(
              builder: (context) {
                final directTranslation = LocaleKeys
                    .chats_screens_chat_conversation_a2ui_read_only
                    .tr(context: context);
                final label = chatA2uiText(
                  context,
                  LocaleKeys.chats_screens_chat_conversation_a2ui_read_only,
                  'Read only',
                );
                debugPrint(
                  'locale=${context.locale}, direct=$directTranslation, helper=$label',
                );
                return AuraThemeScope(
                  theme: .light,
                  child: AuraBadge.text(
                    variant: AuraBadgeVariant.neutral,
                    size: AuraBadgeSize.small,
                    semanticLabel: label,
                    child: Text(label),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Solo lectura'), findsOneWidget);
    expect(tester.getSemantics(find.byType(AuraBadge)).label, 'Solo lectura');
  });
}
