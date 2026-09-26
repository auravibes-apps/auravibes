// Required: Tests repeat finders and fixture lookups for clarity.
import 'package:auravibes_app/features/chats/widgets/tool_call_response_modal.dart';
import 'package:auravibes_app/features/chats/widgets/tool_call_response_preview.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  Widget buildSubject({
    required String toolName,
    required String content,
    TextScaler? textScaler,
  }) {
    return EasyLocalization(
      child: Builder(
        builder: (context) {
          return MaterialApp(
            home: AuraThemeScope(
              theme: .light,
              child: Theme(
                data: .new(),
                child: MediaQuery(
                  data: .new(textScaler: textScaler ?? TextScaler.noScaling),
                  child: Scaffold(
                    body: ToolCallResponsePreview(
                      toolName: toolName,
                      content: content,
                    ),
                  ),
                ),
              ),
            ),
            locale: context.locale,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
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
      expect(find.byIcon(Icons.copy_outlined), findsNothing);
    });

    testWidgets('copies the full response content', (tester) async {
      const content = 'First line\nSecond line\nThird line\nFourth line';
      String? copiedContent;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copiedContent = (call.arguments as Map)['text'] as String?;
          }

          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await pumpAndInit(
        tester,
        buildSubject(toolName: 'test_tool', content: content),
      );

      await tester.tap(find.byIcon(Icons.copy_outlined));
      await tester.pump();

      expect(copiedContent, content);
      expect(find.byIcon(Icons.check), findsOneWidget);
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

    testWidgets('opens the full result modal for overflowing content', (
      tester,
    ) async {
      await pumpAndInit(
        tester,
        buildSubject(
          toolName: 'test_tool',
          content: 'First line\nSecond line\nThird line\nFourth line',
        ),
      );

      expect(find.text('Show more'), findsOneWidget);
      expect(
        tester.getTopLeft(find.byIcon(Icons.copy_outlined)).dx,
        lessThan(tester.getTopLeft(find.text('Show more')).dx),
      );

      await tester.tap(find.text('Show more'));
      final _ = await tester.pumpAndSettle();

      expect(find.byType(ToolCallResponseModal), findsOneWidget);
      expect(find.text('test_tool'), findsOneWidget);
    });

    testWidgets('uses inherited text scaling when detecting overflow', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      const content =
          'abcdefghij abcdefghij abcdefghij abcdefghij abcdefghij '
          'abcdefghij';

      await pumpAndInit(
        tester,
        buildSubject(toolName: 'test_tool', content: content),
      );
      expect(find.text('Show more'), findsNothing);

      await pumpAndInit(
        tester,
        buildSubject(
          toolName: 'test_tool',
          content: content,
          textScaler: const .linear(2),
        ),
      );
      expect(find.text('Show more'), findsOneWidget);
    });
  });
}
