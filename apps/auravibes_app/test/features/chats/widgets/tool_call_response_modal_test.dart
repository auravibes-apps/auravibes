// ignore_for_file: prefer-moving-to-variable
// Required: Tests repeat finders and fixture lookups for clarity.
import 'package:auravibes_app/features/chats/widgets/tool_call_response_modal.dart';
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
      child: Builder(
        builder: (context) {
          return MaterialApp(
            home: Theme(
              data: ThemeData(extensions: [AuraTheme.light]),
              child: Scaffold(
                body: Builder(
                  builder: (innerContext) {
                    return TextButton(
                      onPressed: () {
                        ToolCallResponseModal.show(
                          innerContext,
                          toolName: toolName,
                          content: content,
                        );
                      },
                      child: const Text('Open Modal'),
                    );
                  },
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

  group('ToolCallResponseModal', () {
    testWidgets('shows modal with tool name in header', (tester) async {
      await pumpAndInit(
        tester,
        buildSubject(toolName: 'read_file', content: 'File contents here'),
      );
      await tester.tap(find.text('Open Modal'));
      await tester.pump();
      await tester.pump();

      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('read_file'), findsOneWidget);
    });

    testWidgets('shows markdown content in scrollable view', (tester) async {
      const content = '# Header\n\nSome **bold** text';
      await pumpAndInit(
        tester,
        buildSubject(toolName: 'search', content: content),
      );
      await tester.tap(find.text('Open Modal'));
      await tester.pump();
      await tester.pump();

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('close button dismisses modal', (tester) async {
      await pumpAndInit(
        tester,
        buildSubject(toolName: 'read_file', content: 'content'),
      );
      await tester.tap(find.text('Open Modal'));
      await tester.pump();
      await tester.pump();

      expect(find.byType(Dialog), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('displays terminal icon in header', (tester) async {
      await pumpAndInit(
        tester,
        buildSubject(toolName: 'test_tool', content: 'content'),
      );
      await tester.tap(find.text('Open Modal'));
      await tester.pump();
      await tester.pump();

      expect(find.byIcon(Icons.terminal), findsOneWidget);
    });
  });
}
