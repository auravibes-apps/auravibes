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
    testWidgets('wraps overflowing actions in only one horizontal scroll', (
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

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

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

    testWidgets('escaped inline delimiters are not toggled as formatting', (
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

      for (final action in [
        (icon: Icons.format_italic, marker: '*', wrapper: '*'),
        (icon: Icons.format_italic, marker: '_', wrapper: '*'),
        (icon: Icons.code, marker: '`', wrapper: '`'),
      ]) {
        final text = '\\${action.marker}word${action.marker}';
        final contentStart = text.indexOf('word');
        controller.value = TextEditingValue(
          text: text,
          selection: TextSelection(
            baseOffset: contentStart,
            extentOffset: contentStart + 'word'.length,
          ),
        );
        await tester.pump();

        await tester.tap(find.byIcon(action.icon));
        await tester.pump();

        expect(
          controller.text,
          '\\${action.marker}${action.wrapper}word'
          '${action.wrapper}${action.marker}',
        );
      }

      const evenBackslashText = r'\\*word*';
      controller.value = const TextEditingValue(
        text: evenBackslashText,
        selection: TextSelection(baseOffset: 3, extentOffset: 7),
      );
      await tester.pump();
      await tester.tap(find.byIcon(Icons.format_italic));
      await tester.pump();

      expect(controller.text, r'\\word');
      expect(
        controller.selection,
        const TextSelection(baseOffset: 2, extentOffset: 6),
      );
    });

    testWidgets('bold wrapping does not cross-pair existing spans', (
      tester,
    ) async {
      const text = '**one** and **two**';
      final controller = TextEditingController(text: text);
      final focusNode = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);
      final selectionStart = text.indexOf(' and ');
      controller.selection = TextSelection(
        baseOffset: selectionStart,
        extentOffset: selectionStart + ' and '.length,
      );

      await pumpAndInit(
        tester,
        buildSubject(controller: controller, focusNode: focusNode),
      );
      await tester.tap(find.byIcon(Icons.format_bold));
      await tester.pump();

      expect(controller.text, '**one**** and ****two**');
    });

    testWidgets(
      'bold italic and inline code actions unwrap selected matching spans',
      (tester) async {
        final controller = TextEditingController();
        final focusNode = FocusNode();
        addTearDown(controller.dispose);
        addTearDown(focusNode.dispose);

        await pumpAndInit(
          tester,
          buildSubject(controller: controller, focusNode: focusNode),
        );

        for (final action in [
          (icon: Icons.format_bold, marker: '**', content: 'bold'),
          (icon: Icons.format_italic, marker: '_', content: 'italic'),
          (icon: Icons.format_italic, marker: '*', content: 'italic'),
          (icon: Icons.code, marker: '`', content: 'code'),
        ]) {
          final text =
              'before ${action.marker}${action.content}'
              '${action.marker} after';
          final contentStart = text.indexOf(action.content);
          final unmarkedStart = contentStart - action.marker.length;
          controller.value = TextEditingValue(
            text: text,
            selection: TextSelection(
              baseOffset: contentStart,
              extentOffset: contentStart + action.content.length,
            ),
          );
          await tester.pump();

          await tester.tap(find.byIcon(action.icon));
          await tester.pump();

          expect(controller.text, 'before ${action.content} after');
          expect(
            controller.selection,
            TextSelection(
              baseOffset: unmarkedStart,
              extentOffset: unmarkedStart + action.content.length,
            ),
          );
        }
      },
    );

    testWidgets(
      'selection containing complete marked span unwraps markers and selects text',
      (tester) async {
        final controller = TextEditingController();
        final focusNode = FocusNode();
        addTearDown(controller.dispose);
        addTearDown(focusNode.dispose);

        await pumpAndInit(
          tester,
          buildSubject(controller: controller, focusNode: focusNode),
        );

        for (final action in [
          (icon: Icons.format_bold, marker: '**', content: 'bold'),
          (icon: Icons.format_italic, marker: '_', content: 'italic'),
          (icon: Icons.code, marker: '`', content: 'code'),
        ]) {
          final text =
              'before ${action.marker}${action.content}'
              '${action.marker} after';
          final markedStart = text.indexOf(action.marker);
          final contentStart = markedStart + action.marker.length;
          final unmarkedStart = markedStart;
          controller.value = TextEditingValue(
            text: text,
            selection: TextSelection(
              baseOffset: markedStart,
              extentOffset:
                  contentStart + action.content.length + action.marker.length,
            ),
          );
          await tester.pump();

          await tester.tap(find.byIcon(action.icon));
          await tester.pump();

          expect(controller.text, 'before ${action.content} after');
          expect(
            controller.selection,
            TextSelection(
              baseOffset: unmarkedStart,
              extentOffset: unmarkedStart + action.content.length,
            ),
          );
        }
      },
    );

    testWidgets('format actions still wrap unformatted selections', (
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

      for (final action in [
        (icon: Icons.format_bold, marker: '**', content: 'bold'),
        (icon: Icons.format_italic, marker: '*', content: 'italic'),
        (icon: Icons.code, marker: '`', content: 'code'),
      ]) {
        final text = 'before ${action.content} after';
        final contentStart = text.indexOf(action.content);
        controller.value = TextEditingValue(
          text: text,
          selection: TextSelection(
            baseOffset: contentStart,
            extentOffset: contentStart + action.content.length,
          ),
        );
        await tester.pump();

        await tester.tap(find.byIcon(action.icon));
        await tester.pump();

        final wrapped = '${action.marker}${action.content}${action.marker}';
        expect(controller.text, 'before $wrapped after');
        expect(
          controller.selection,
          TextSelection.collapsed(offset: contentStart + wrapped.length),
        );
      }
    });

    testWidgets(
      'partial selection leaves existing formatting markers unchanged',
      (tester) async {
        final controller = TextEditingController();
        final focusNode = FocusNode();
        addTearDown(controller.dispose);
        addTearDown(focusNode.dispose);

        await pumpAndInit(
          tester,
          buildSubject(controller: controller, focusNode: focusNode),
        );

        for (final action in [
          (icon: Icons.format_bold, marker: '**', content: 'bold'),
          (icon: Icons.format_italic, marker: '_', content: 'italic'),
          (icon: Icons.code, marker: '`', content: 'code'),
        ]) {
          final text =
              'before ${action.marker}${action.content}'
              '${action.marker} after';
          final contentStart = text.indexOf(action.content);
          final initialValue = TextEditingValue(
            text: text,
            selection: TextSelection(
              baseOffset: contentStart + 1,
              extentOffset: contentStart + action.content.length - 1,
            ),
          );
          controller.value = initialValue;
          await tester.pump();

          await tester.tap(find.byIcon(action.icon));
          await tester.pump();

          expect(controller.value, initialValue);
          final undoButton = find.byWidgetPredicate(
            (widget) => widget is AuraIconButton && widget.icon == Icons.undo,
          );
          expect(tester.widget<AuraIconButton>(undoButton).onPressed, isNull);
        }
      },
    );

    testWidgets(
      'undo and redo restore wrapped and unwrapped values and selections',
      (tester) async {
        final controller = TextEditingController(text: 'bold');
        final focusNode = FocusNode();
        addTearDown(controller.dispose);
        addTearDown(focusNode.dispose);
        controller.selection = const TextSelection(
          baseOffset: 0,
          extentOffset: 4,
        );
        final original = controller.value;

        await pumpAndInit(
          tester,
          buildSubject(controller: controller, focusNode: focusNode),
        );
        await tester.tap(find.byIcon(Icons.format_bold));
        await tester.pump();
        final wrapped = controller.value;
        expect(wrapped.text, '**bold**');

        await tester.tap(find.byIcon(Icons.undo));
        await tester.pump();
        expect(controller.value, original);
        await tester.tap(find.byIcon(Icons.redo));
        await tester.pump();
        expect(controller.value, wrapped);

        controller.selection = const TextSelection(
          baseOffset: 2,
          extentOffset: 6,
        );
        await tester.pump();
        final selectedWrapped = controller.value;
        await tester.tap(find.byIcon(Icons.format_bold));
        await tester.pump();
        final unwrapped = controller.value;
        expect(unwrapped.text, 'bold');
        expect(
          unwrapped.selection,
          const TextSelection(baseOffset: 0, extentOffset: 4),
        );

        await tester.tap(find.byIcon(Icons.undo));
        await tester.pump();
        expect(controller.value, selectedWrapped);
        await tester.tap(find.byIcon(Icons.redo));
        await tester.pump();
        expect(controller.value, unwrapped);
      },
    );

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

    testWidgets('link dialog prefills selected text and inserts destination', (
      tester,
    ) async {
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

      final fields = find.byType(TextField);
      expect(
        tester.widget<TextField>(fields.at(1)).controller?.text,
        'Documentation',
      );
      expect(controller.text, 'Documentation');
      await tester.enterText(fields.last, 'https://docs.example.com');
      await tester.tap(find.text('Confirm'));
      final _ = await tester.pumpAndSettle();

      expect(controller.text, '[Documentation](https://docs.example.com)');
      expect(controller.selection.isCollapsed, isTrue);
      expect(controller.selection.baseOffset, controller.text.length);
      expect(focusNode.hasFocus, isTrue);
      expect(find.bySemanticsLabel('Link'), findsOneWidget);
    });

    testWidgets('link dialog edits the link at the caret in place', (
      tester,
    ) async {
      const text = 'Read [documentation](https://old.example/guide) carefully';
      final controller = TextEditingController(text: text);
      final focusNode = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);
      controller.selection = TextSelection.collapsed(
        offset: text.indexOf('documentation') + 5,
      );

      await pumpAndInit(
        tester,
        buildSubject(controller: controller, focusNode: focusNode),
      );
      await tester.tap(find.byIcon(Icons.link));
      await tester.pump();

      final fields = find.byType(TextField);
      expect(
        tester.widget<TextField>(fields.at(1)).controller?.text,
        'documentation',
      );
      expect(
        tester.widget<TextField>(fields.last).controller?.text,
        'https://old.example/guide',
      );
      await tester.enterText(fields.at(1), 'API docs');
      await tester.enterText(fields.last, 'https://new.example/api');
      await tester.tap(find.text('Confirm'));
      final _ = await tester.pumpAndSettle();

      expect(
        controller.text,
        'Read [API docs](https://new.example/api) carefully',
      );
      expect(focusNode.hasFocus, isTrue);
    });

    testWidgets('link dialog detects a caret adjacent to the link', (
      tester,
    ) async {
      const text = 'Read [guide](https://guide.example) now';
      final controller = TextEditingController(text: text);
      final focusNode = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);
      controller.selection = TextSelection.collapsed(
        offset: text.indexOf(') now') + 1,
      );

      await pumpAndInit(
        tester,
        buildSubject(controller: controller, focusNode: focusNode),
      );
      await tester.tap(find.byIcon(Icons.link));
      await tester.pump();

      final fields = find.byType(TextField);
      expect(tester.widget<TextField>(fields.at(1)).controller?.text, 'guide');
      expect(
        tester.widget<TextField>(fields.last).controller?.text,
        'https://guide.example',
      );
      await tester.tap(find.text('Cancel'));
      final _ = await tester.pumpAndSettle();
    });

    testWidgets(
      'selected markdown link updates without changing surrounding text',
      (tester) async {
        const text = 'before [guide](https://old.example) after';
        final controller = TextEditingController(text: text);
        final focusNode = FocusNode();
        addTearDown(controller.dispose);
        addTearDown(focusNode.dispose);
        final linkStart = text.indexOf('[guide]');
        final linkEnd = text.indexOf(') after') + 1;
        controller.selection = TextSelection(
          baseOffset: linkEnd,
          extentOffset: linkStart,
          isDirectional: true,
        );
        final initialValue = controller.value;

        await pumpAndInit(
          tester,
          buildSubject(controller: controller, focusNode: focusNode),
        );
        await tester.tap(find.byIcon(Icons.link));
        await tester.pump();

        final fields = find.byType(TextField);
        expect(
          tester.widget<TextField>(fields.at(1)).controller?.text,
          'guide',
        );
        expect(
          tester.widget<TextField>(fields.last).controller?.text,
          'https://old.example',
        );
        await tester.enterText(fields.at(1), 'handbook');
        await tester.enterText(fields.last, 'https://new.example');
        await tester.tap(find.text('Confirm'));
        final _ = await tester.pumpAndSettle();

        expect(controller.text, 'before [handbook](https://new.example) after');
        final updatedValue = controller.value;
        await tester.tap(find.byIcon(Icons.undo));
        await tester.pump();
        expect(controller.value, initialValue);
        await tester.tap(find.byIcon(Icons.redo));
        await tester.pump();
        expect(controller.value, updatedValue);
      },
    );

    testWidgets('canceling link edit preserves text and selection', (
      tester,
    ) async {
      const text = 'before [guide](https://guide.example) after';
      final controller = TextEditingController(text: text);
      final focusNode = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);
      final linkStart = text.indexOf('[guide]');
      final linkEnd = text.indexOf(') after') + 1;
      controller.selection = TextSelection(
        baseOffset: linkEnd,
        extentOffset: linkStart,
        isDirectional: true,
      );
      final initialValue = controller.value;

      await pumpAndInit(
        tester,
        buildSubject(controller: controller, focusNode: focusNode),
      );
      await tester.tap(find.byIcon(Icons.link));
      await tester.pump();
      await tester.tap(find.text('Cancel'));
      final _ = await tester.pumpAndSettle();

      expect(controller.value, initialValue);
    });

    testWidgets('edits a link destination containing parentheses', (
      tester,
    ) async {
      const text =
          'Read [source](https://example.com/path_(with_parentheses)) next';
      final controller = TextEditingController(text: text);
      final focusNode = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);
      controller.selection = TextSelection.collapsed(
        offset: text.indexOf('with_parentheses') + 3,
      );

      await pumpAndInit(
        tester,
        buildSubject(controller: controller, focusNode: focusNode),
      );
      await tester.tap(find.byIcon(Icons.link));
      await tester.pump();

      final fields = find.byType(TextField);
      expect(tester.widget<TextField>(fields.at(1)).controller?.text, 'source');
      expect(
        tester.widget<TextField>(fields.last).controller?.text,
        'https://example.com/path_(with_parentheses)',
      );
      await tester.enterText(fields.at(1), 'guide');
      await tester.enterText(fields.last, 'https://new.example/path_(updated)');
      await tester.tap(find.text('Confirm'));
      final _ = await tester.pumpAndSettle();

      expect(
        controller.text,
        'Read [guide](https://new.example/path_(updated)) next',
      );
    });

    testWidgets('selection spanning multiple links keeps insertion behavior', (
      tester,
    ) async {
      const text =
          'See [one](https://one.example) and [two](https://two.example) now';
      final controller = TextEditingController(text: text);
      final focusNode = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);
      final selectionStart = text.indexOf('[one]');
      final selectionEnd =
          text.indexOf('[two]') + '[two](https://two.example)'.length;
      controller.selection = TextSelection(
        baseOffset: selectionStart,
        extentOffset: selectionEnd,
      );
      final selectedText = controller.selection.textInside(text);

      await pumpAndInit(
        tester,
        buildSubject(controller: controller, focusNode: focusNode),
      );
      await tester.tap(find.byIcon(Icons.link));
      await tester.pump();

      final fields = find.byType(TextField);
      expect(
        tester.widget<TextField>(fields.at(1)).controller?.text,
        selectedText,
      );
      await tester.enterText(fields.last, 'https://combined.example');
      await tester.tap(find.text('Confirm'));
      final _ = await tester.pumpAndSettle();

      expect(
        controller.text,
        'See [$selectedText](https://combined.example) now',
      );
    });

    testWidgets('link dialog uses localized placeholder for empty selection', (
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

      final fields = find.byType(TextField);
      expect(tester.widget<TextField>(fields.at(1)).controller?.text, isEmpty);
      expect(
        tester.widget<TextField>(fields.at(1)).decoration?.hintText,
        'Link text',
      );
      await tester.enterText(fields.last, 'https://example.com');
      await tester.tap(find.text('Confirm'));
      final _ = await tester.pumpAndSettle();

      expect(controller.text, '[Link text](https://example.com)');
      expect(controller.selection.textInside(controller.text), 'Link text');
    });

    testWidgets('link dialog rejects blank destination and cancel is inert', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'read more');
      final focusNode = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);
      controller.selection = const TextSelection(
        baseOffset: 0,
        extentOffset: 4,
      );
      final initialValue = controller.value;

      await pumpAndInit(
        tester,
        buildSubject(controller: controller, focusNode: focusNode),
      );
      await tester.tap(find.byIcon(Icons.link));
      await tester.pump();
      await tester.tap(find.text('Confirm'));
      await tester.pump();

      expect(find.text('Enter a destination URL'), findsOneWidget);
      expect(controller.value, initialValue);
      await tester.tap(find.text('Cancel'));
      final _ = await tester.pumpAndSettle();

      expect(controller.value, initialValue);
      expect(find.bySemanticsLabel('Link'), findsOneWidget);
    });

    testWidgets('task action preserves indentation and multiline selection', (
      tester,
    ) async {
      final controller = TextEditingController(
        text: '  first\n\tsecond\nthird',
      );
      final focusNode = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);
      controller.selection = const TextSelection(
        baseOffset: 2,
        extentOffset: 15,
      );

      await pumpAndInit(
        tester,
        buildSubject(controller: controller, focusNode: focusNode),
      );
      await tester.tap(find.byIcon(Icons.checklist));
      await tester.pump();

      expect(controller.text, '  - [ ] first\n\t- [ ] second\nthird');
      expect(
        controller.selection.textInside(controller.text),
        'first\n\t- [ ] second',
      );
      expect(find.bySemanticsLabel('Task list'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.undo));
      await tester.pump();
      expect(controller.text, '  first\n\tsecond\nthird');
      expect(
        controller.selection,
        const TextSelection(baseOffset: 2, extentOffset: 15),
      );
    });

    testWidgets('task action inserts at caret and skips existing markers', (
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
      await tester.tap(find.byIcon(Icons.checklist));
      await tester.pump();
      expect(controller.text, '- [ ] ');
      expect(controller.selection, const TextSelection.collapsed(offset: 6));

      controller
        ..text = 'a line'
        ..selection = const TextSelection.collapsed(offset: 2);
      await tester.tap(find.byIcon(Icons.checklist));
      await tester.pump();
      expect(controller.text, '- [ ] a line');
      expect(controller.selection, const TextSelection.collapsed(offset: 8));

      controller
        ..text = '- [x] done\n- [ ] next'
        ..selection = const TextSelection(baseOffset: 0, extentOffset: 20);
      await tester.tap(find.byIcon(Icons.checklist));
      await tester.pump();
      expect(controller.text, '- [x] done\n- [ ] next');
    });

    testWidgets('task action converts bullets and keeps backward selection', (
      tester,
    ) async {
      final controller = TextEditingController(text: '- item\n- [x] done');
      final focusNode = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);
      controller.selection = .new(
        baseOffset: controller.text.length,
        extentOffset: 0,
      );

      await pumpAndInit(
        tester,
        buildSubject(controller: controller, focusNode: focusNode),
      );
      await tester.tap(find.byIcon(Icons.checklist));
      await tester.pump();

      expect(controller.text, '- [ ] item\n- [x] done');
      expect(controller.selection.baseOffset, controller.text.length);
      expect(controller.selection.extentOffset, 6);
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

    testWidgets('undo and redo restore multiple actions and selections', (
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
      final original = controller.value;

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

      await tester.tap(find.byIcon(Icons.undo));
      await tester.pump();
      expect(controller.value, original);

      final redoButton = find.byWidgetPredicate(
        (widget) => widget is AuraIconButton && widget.icon == Icons.redo,
      );
      expect(tester.widget<AuraIconButton>(redoButton).onPressed, isNotNull);
      await tester.tap(find.byIcon(Icons.redo));
      await tester.pump();
      expect(controller.text, '**text**');
      await tester.tap(find.byIcon(Icons.redo));
      await tester.pump();
      expect(controller.text, '***text***');
      expect(find.bySemanticsLabel('Redo'), findsOneWidget);
      expect(tester.widget<AuraIconButton>(redoButton).onPressed, isNull);
    });

    testWidgets('new toolbar action after undo clears redo', (tester) async {
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
      await tester.tap(find.byIcon(Icons.undo));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.format_italic));
      await tester.pump();

      expect(controller.text, '*text*');
      final redoButton = find.byWidgetPredicate(
        (widget) => widget is AuraIconButton && widget.icon == Icons.redo,
      );
      expect(tester.widget<AuraIconButton>(redoButton).onPressed, isNull);
    });

    testWidgets('typing after undo discards stale redo', (tester) async {
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
      await tester.tap(find.byIcon(Icons.undo));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'typed');
      await tester.pump();

      expect(controller.text, 'typed');
      final redoButton = find.byWidgetPredicate(
        (widget) => widget is AuraIconButton && widget.icon == Icons.redo,
      );
      expect(tester.widget<AuraIconButton>(redoButton).onPressed, isNull);
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
