import 'dart:convert';

import 'package:auravibes_app/features/chats/agent_adapters/aura_chat_catalog_adapter.dart';
import 'package:auravibes_app/features/chats/widgets/chat_a2ui_surface_host.dart';
import 'package:auravibes_app/widgets/aura_legacy_material_bridge.dart';
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
    final payloads = [
      jsonEncode({
        'version': 'v0.9',
        'createSurface': {
          'surfaceId': 'main',
          'catalogId': auraChatCatalogId,
        },
      }),
      jsonEncode({
        'version': 'v0.9',
        'updateComponents': {
          'surfaceId': 'main',
          'components': [
            {'id': 'root', 'component': 'Text', 'text': 'Saved response'},
          ],
        },
      }),
    ];

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
        child: AuraThemeScope(
          theme: .light,
          child: MaterialApp(
            builder: _legacyMaterialBuilder,
            locale: const Locale('es'),
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            supportedLocales: const [Locale('en'), Locale('es')],
            theme: ThemeData(),
            home: SingleChildScrollView(
              child: ChatA2uiSurfaceHost.historical(
                messageId: 'assistant-1',
                payloads: payloads,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Saved response'), findsOneWidget);
    expect(find.text('Solo lectura'), findsOneWidget);
    expect(tester.getSemantics(find.byType(AuraBadge)).label, 'Solo lectura');
  });
}

Widget _legacyMaterialBuilder(BuildContext _, Widget? child) =>
    AuraLegacyMaterialBridge(child: child ?? const SizedBox.shrink());
