import 'package:auravibes_app/features/chats/widgets/conversation_sidebar_toggle_button.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('shows total tab count and toggles the conversation sidebar', (
    tester,
  ) async {
    var pressed = false;
    await tester.pumpWidget(
      EasyLocalization(
        child: Builder(
          builder: (context) => MaterialApp(
            home: AuraThemeScope(
              theme: .light,
              child: Scaffold(
                appBar: AppBar(
                  actions: [
                    ConversationSidebarToggleButton(
                      isPanelVisible: false,
                      tabCount: 3,
                      onPressed: () => pressed = true,
                    ),
                  ],
                ),
              ),
            ),
            locale: context.locale,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
          ),
        ),
        supportedLocales: const [Locale('en')],
        path: 'unused',
        fallbackLocale: const Locale('en'),
        startLocale: const Locale('en'),
        assetLoader: const _TestAssetLoader(),
      ),
    );
    final _ = await tester.pumpAndSettle();

    expect(find.byType(ConversationSidebarToggleButton), findsOneWidget);
    expect(find.byIcon(Icons.view_sidebar_outlined), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.byTooltip('Open sidebar'), findsOneWidget);

    final _ = await tester.tap(find.byType(AuraIconButton));
    expect(pressed, isTrue);
  });
}

class const _TestAssetLoader() extends AssetLoader {
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async => {
    'sidebar': {
      'open': 'Open sidebar',
      'close': 'Close sidebar',
      'tabs_count': {
        'zero': 'No tabs open',
        'one': '1 tab open',
        'other': '{} tabs open',
      },
    },
  };
}
