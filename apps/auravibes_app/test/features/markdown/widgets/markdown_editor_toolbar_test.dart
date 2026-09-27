import 'package:auravibes_app/features/markdown/widgets/markdown_editor_toolbar.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  Widget buildSubject({
    required TextEditingController controller,
    required FocusNode focusNode,
  }) {
    return EasyLocalization(
      child: Builder(
        builder: (context) {
          return MaterialApp(
            home: AuraThemeScope(
              theme: .light,
              child: Theme(
                data: .new(),
                child: Scaffold(
                  body: Column(
                    children: [
                      TextField(controller: controller, focusNode: focusNode),
                      MarkdownEditorToolbar(
                        controller: controller,
                        focusNode: focusNode,
                      ),
                    ],
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
      (icon: Icons.format_list_numbered, prefix: '1. '),
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

    testWidgets('inserts a link around selected text', (tester) async {
      final controller = TextEditingController(text: 'Documentation');
      final focusNode = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);
      controller.selection = const TextSelection(
        baseOffset: 0,
        extentOffset: 13,
      );

      await pumpAndInit(
        tester,
        buildSubject(controller: controller, focusNode: focusNode),
      );
      await tester.tap(find.byIcon(Icons.link));
      await tester.pump();

      expect(controller.text, '[Documentation](https://example.com)');
      expect(
        controller.selection.textInside(controller.text),
        'https://example.com',
      );
      expect(find.bySemanticsLabel('Link'), findsOneWidget);
    });

    testWidgets('inserts a localized link placeholder without a selection', (
      tester,
    ) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);

      await pumpAndInit(
        tester,
        buildSubject(controller: controller, focusNode: focusNode),
      );
      await tester.tap(find.byIcon(Icons.link));
      await tester.pump();

      expect(controller.text, '[Link text](https://example.com)');
      expect(controller.selection.textInside(controller.text), 'Link text');
    });

    testWidgets('numbers every selected line in order', (tester) async {
      final controller = TextEditingController(text: 'one\ntwo\nthree');
      final focusNode = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);
      controller.selection = const TextSelection(
        baseOffset: 1,
        extentOffset: 6,
      );

      await pumpAndInit(
        tester,
        buildSubject(controller: controller, focusNode: focusNode),
      );
      await tester.tap(find.byIcon(Icons.format_list_numbered));
      await tester.pump();

      expect(controller.text, '1. one\n2. two\nthree');
      expect(controller.selection, const TextSelection.collapsed(offset: 13));
    });

    testWidgets('undo restores the last toolbar text and selection', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'bold');
      final focusNode = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);
      controller.selection = const TextSelection(
        baseOffset: 4,
        extentOffset: 0,
      );
      final initialValue = controller.value;

      await pumpAndInit(
        tester,
        buildSubject(controller: controller, focusNode: focusNode),
      );
      final undoButton = find.byWidgetPredicate(
        (widget) => widget is AuraIconButton && widget.icon == Icons.undo,
      );
      expect(tester.widget<AuraIconButton>(undoButton).onPressed, isNull);

      await tester.tap(find.byIcon(Icons.format_bold));
      await tester.pump();
      expect(tester.widget<AuraIconButton>(undoButton).onPressed, isNotNull);

      await tester.tap(find.byIcon(Icons.undo));
      await tester.pump();

      expect(controller.value, initialValue);
      expect(tester.widget<AuraIconButton>(undoButton).onPressed, isNull);
      expect(find.bySemanticsLabel('Undo'), findsOneWidget);
    });

    testWidgets('undo reverses only the most recent toolbar action', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'text');
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
      await tester.tap(find.byIcon(Icons.format_bold));
      await tester.pump();
      controller.selection = .new(
        baseOffset: 0,
        extentOffset: controller.text.length,
      );
      await tester.tap(find.byIcon(Icons.format_italic));
      await tester.pump();
      expect(controller.text, '***text***');

      await tester.tap(find.byIcon(Icons.undo));
      await tester.pump();

      expect(controller.text, '**text**');
      expect(
        controller.selection,
        const TextSelection(baseOffset: 0, extentOffset: 8),
      );
    });

    testWidgets('typing invalidates toolbar undo without changing typed text', (
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
      await tester.tap(find.byIcon(Icons.format_bold));
      await tester.pump();
      await tester.enterText(find.byType(TextField), '**bold** typed');
      await tester.pump();

      final undoButton = find.byWidgetPredicate(
        (widget) => widget is AuraIconButton && widget.icon == Icons.undo,
      );
      expect(tester.widget<AuraIconButton>(undoButton).onPressed, isNull);
      expect(controller.text, '**bold** typed');
    });

    testWidgets('keeps multiline code formatting fenced', (tester) async {
      final controller = TextEditingController(text: 'first\nsecond');
      final focusNode = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);
      controller.selection = const TextSelection(
        baseOffset: 0,
        extentOffset: 12,
      );

      await pumpAndInit(
        tester,
        buildSubject(controller: controller, focusNode: focusNode),
      );
      await tester.tap(find.byIcon(Icons.code));
      await tester.pump();

      expect(controller.text, '```\nfirst\nsecond\n```');
      expect(controller.selection, const TextSelection.collapsed(offset: 20));
    });
  });
}
