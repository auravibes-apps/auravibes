import 'package:auravibes_app/features/markdown/widgets/markdown_editor_toolbar.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildSubject({
    required TextEditingController controller,
    required FocusNode focusNode,
  }) {
    return EasyLocalization(
      child: Builder(
        builder: (context) {
          return MaterialApp(
            home: Theme(
              data: ThemeData(extensions: [AuraTheme.light]),
              child: Scaffold(
                body: Column(
                  children: [
                    TextField(
                      controller: controller,
                      focusNode: focusNode,
                    ),
                    MarkdownEditorToolbar(
                      controller: controller,
                      focusNode: focusNode,
                    ),
                  ],
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

  group('MarkdownEditorToolbar', () {
    testWidgets('keeps editor focus when formatting selected text', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'bold');
      final focusNode = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);

      controller.selection = const TextSelection(
        baseOffset: 0,
        extentOffset: 4,
      );

      await pumpAndInit(
        tester,
        buildSubject(controller: controller, focusNode: focusNode),
      );

      focusNode.requestFocus();
      await tester.pump();

      await tester.tap(find.byIcon(Icons.format_bold));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(focusNode.hasFocus, isTrue);
      expect(controller.text, '**bold**');
    });

    for (final action in [
      (icon: Icons.title, prefix: '# '),
      (icon: Icons.format_list_bulleted, prefix: '- '),
      (icon: Icons.format_quote, prefix: '> '),
    ]) {
      testWidgets('${action.prefix}prefixes empty content', (tester) async {
        final controller = TextEditingController();
        final focusNode = FocusNode();
        addTearDown(controller.dispose);
        addTearDown(focusNode.dispose);

        await pumpAndInit(
          tester,
          buildSubject(controller: controller, focusNode: focusNode),
        );

        await tester.tap(find.byIcon(action.icon));
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(controller.text, action.prefix);
        expect(controller.selection.baseOffset, action.prefix.length);
      });
    }
  });
}
