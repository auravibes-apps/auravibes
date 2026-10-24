// Required: Tests repeat finders and fixture lookups for clarity.
import 'package:auravibes_app/features/chats/widgets/connector_write_approval_preview.dart';
import 'package:auravibes_app/features/chats/widgets/tool_call_response_preview.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  Widget buildSubject({
    required String content,
    TextScaler? textScaler,
    Widget? subject,
    VoidCallback? onShowMore,
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
                    body:
                        subject ??
                        ToolCallResponsePreview(
                          content: content,
                          onShowMore: onShowMore ?? _noop,
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
    testWidgets(
      'uncertain writes show localized review state without an undo action',
      (tester) async {
        await pumpAndInit(
          tester,
          buildSubject(
            content:
                '{"kind":"connectorWrite","operationId":"write-1",'
                '"outcome":"uncertain","retryBlocked":true,'
                '"undoSupported":false}',
          ),
        );
        expect(
          find.textContaining('Outcome uncertain. Check the source.'),
          findsOneWidget,
        );
        expect(find.text('Undo'), findsNothing);
      },
    );

    testWidgets('write preview shows destination; read has no warning', (
      tester,
    ) async {
      await pumpAndInit(
        tester,
        buildSubject(
          content: '',
          subject: const ConnectorWriteApprovalPreview(
            argumentsRaw: '{"toolId":"connector/duckduckgo/search","args":{"query":"preview-input"}}',
          ),
        ),
      );
      expect(
        find.textContaining('POST https://html.duckduckgo.com/html/'),
        findsOneWidget,
      );
      expect(find.textContaining('preview-input'), findsOneWidget);
      expect(
        find.textContaining('Review the destination and inputs'),
        findsOneWidget,
      );
      await pumpAndInit(
        tester,
        buildSubject(
          content: '',
          subject: const ConnectorWriteApprovalPreview(
            argumentsRaw: '{"toolId":"connector/brave/web_search","args":{"query":"read-input"}}',
          ),
        ),
      );
      expect(
        find.textContaining('Review the destination and inputs'),
        findsNothing,
      );
    });

    testWidgets('renders content text', (tester) async {
      await pumpAndInit(tester, buildSubject(content: 'Hello world'));

      expect(find.text('Hello world'), findsOneWidget);
    });

    testWidgets('renders with empty content', (tester) async {
      await pumpAndInit(tester, buildSubject(content: ''));

      expect(find.byType(ToolCallResponsePreview), findsOneWidget);
      expect(find.byIcon(Icons.copy_outlined), findsNothing);
    });

    testWidgets('copies full response and opens its overflow tab', (
      tester,
    ) async {
      const content = 'First line\nSecond line\nThird line\nFourth line';
      var opened = false;
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
        buildSubject(content: content, onShowMore: () => opened = true),
      );

      expect(find.text('Show more'), findsOneWidget);
      expect(
        tester.getTopLeft(find.byIcon(Icons.copy_outlined)).dx,
        lessThan(tester.getTopLeft(find.text('Show more')).dx),
      );

      await tester.tap(find.byIcon(Icons.copy_outlined));
      await tester.pump();

      expect(copiedContent, content);
      expect(find.byIcon(Icons.check), findsOneWidget);

      await tester.tap(find.text('Show more'));
      final _ = await tester.pumpAndSettle();

      expect(opened, isTrue);
      expect(find.byType(Dialog), findsNothing);
    });

    test('static maxPreviewLines is 3', () {
      expect(ToolCallResponsePreview.maxPreviewLines, equals(3));
    });

    testWidgets('renders short content without show more button', (
      tester,
    ) async {
      await pumpAndInit(tester, buildSubject(content: 'Short text'));

      expect(find.byType(ToolCallResponsePreview), findsOneWidget);
      expect(find.text('Short text'), findsOneWidget);
    });

    testWidgets('keeps Markdown and HTML literal when opening the tab', (
      tester,
    ) async {
      var opened = false;
      const content =
          '**markdown stays literal**\n'
          '<b>HTML stays literal</b>\n'
          '[link stays literal](https://example.test)\n'
          'Fourth line';
      await pumpAndInit(
        tester,
        buildSubject(content: content, onShowMore: () => opened = true),
      );

      await tester.tap(find.text('Show more'));
      final _ = await tester.pumpAndSettle();

      expect(opened, isTrue);
      expect(find.byType(Dialog), findsNothing);
      expect(find.byType(GptMarkdown), findsNothing);
      expect(find.text(content), findsOneWidget);
    });

    testWidgets('uses inherited text scaling when detecting overflow', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      const content =
          'abcdefghij abcdefghij abcdefghij abcdefghij abcdefghij '
          'abcdefghij';

      await pumpAndInit(tester, buildSubject(content: content));
      expect(find.text('Show more'), findsNothing);

      await pumpAndInit(
        tester,
        buildSubject(content: content, textScaler: const .linear(2)),
      );
      expect(find.text('Show more'), findsOneWidget);
    });
  });
}

void _noop() {
  final _ = Object();
}
