import 'package:auravibes_app/features/chats/widgets/tool_call_response_preview.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildSubject({
    required String toolName,
    required String content,
  }) {
    return EasyLocalization(
      supportedLocales: const [Locale('en')],
      path: 'assets/i18n',
      fallbackLocale: const Locale('en'),
      startLocale: const Locale('en'),
      useFallbackTranslations: true,
      useOnlyLangCode: true,
      child: Builder(
        builder: (context) {
          return MaterialApp(
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            home: Theme(
              data: ThemeData(extensions: [AuraTheme.light]),
              child: Scaffold(
                body: ToolCallResponsePreview(
                  toolName: toolName,
                  content: content,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> pumpAndInit(WidgetTester tester, Widget widget) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(widget);
    });
    await tester.pump();
    await tester.pump();
  }

  group('ToolCallResponsePreview', () {
    testWidgets('renders content text', (tester) async {
      await pumpAndInit(
        tester,
        buildSubject(toolName: 'test_tool', content: 'Hello world'),
      );

      expect(find.text('Hello world'), findsOneWidget);
    });

    testWidgets('renders with empty content', (tester) async {
      await pumpAndInit(
        tester,
        buildSubject(toolName: 'test_tool', content: ''),
      );

      expect(find.byType(ToolCallResponsePreview), findsOneWidget);
    });

    test('static maxPreviewLines is 3', () {
      expect(ToolCallResponsePreview.maxPreviewLines, equals(3));
    });

    testWidgets('renders short content without show more button', (
      tester,
    ) async {
      await pumpAndInit(
        tester,
        buildSubject(toolName: 'test_tool', content: 'Short text'),
      );

      expect(find.byType(ToolCallResponsePreview), findsOneWidget);
      expect(find.text('Short text'), findsOneWidget);
    });
  });
}
