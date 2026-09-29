import 'package:auravibes_app/features/markdown/markdown_editor_launcher.dart';
import 'package:auravibes_app/features/markdown/screens/markdown_editor_screen.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/test_app.dart';

const _initialMarkdown = 'Saved content';
const _editedMarkdown = 'Unsaved content';

void main() {
  testWidgets('closing editor does not restore source field focus', (
    tester,
  ) async {
    final focusNode = FocusNode();
    var didReturn = false;
    addTearDown(focusNode.dispose);
    await _openMarkdownEditor(
      tester,
      onResult: (_) => didReturn = true,
      sourceFocusNode: focusNode,
    );

    expect(focusNode.hasFocus, isFalse);
    await tester.tap(find.byIcon(Icons.close));
    final _ = await tester.pumpAndSettle();
    expect(focusNode.hasFocus, isFalse);
    expect(didReturn, isTrue);
  });

  testWidgets('system back asks before discarding Markdown edits', (
    tester,
  ) async {
    String? result;
    var didReturn = false;
    await _openMarkdownEditor(
      tester,
      onResult: (value) {
        result = value;
        didReturn = true;
      },
    );
    await tester.enterText(_markdownEditorInput, _editedMarkdown);
    final _ = await tester.pumpAndSettle();

    final _ = await tester.binding.handlePopRoute();
    final _ = await tester.pumpAndSettle();

    final dialog = find.byType(AuraConfirmDialog);
    expect(dialog, findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    final _ = await tester.pumpAndSettle();
    expect(find.byType(MarkdownEditorScreen), findsOneWidget);
    expect(
      tester.widget<EditableText>(_markdownEditorInput).controller.text,
      _editedMarkdown,
    );

    final _ = await tester.binding.handlePopRoute();
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('Discard changes'));
    final _ = await tester.pumpAndSettle();

    expect(find.byType(MarkdownEditorScreen), findsNothing);
    expect(didReturn, isTrue);
    expect(result, isNull);
  });

  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    testWidgets('dirty downward drag asks before dismissing on $platform', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = platform;
      try {
        var didReturn = false;
        await _openMarkdownEditor(tester, onResult: (_) => didReturn = true);
        await tester.enterText(_markdownEditorInput, _editedMarkdown);
        final _ = await tester.pumpAndSettle();

        final editorRect = tester.getRect(find.byType(MarkdownEditorScreen));
        final appBarRect = tester.getRect(find.byType(AuraAppBar));
        await tester.flingFrom(
          appBarRect.center,
          .new(0, editorRect.height * 0.4),
          editorRect.height * 4,
        );
        final _ = await tester.pumpAndSettle();

        expect(find.byType(MarkdownEditorScreen), findsOneWidget);
        expect(find.byType(AuraConfirmDialog), findsOneWidget);
        expect(didReturn, isFalse);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  }

  testWidgets('opens and closes with reduced motion enabled', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    var didReturn = false;

    await _openMarkdownEditor(tester, onResult: (_) => didReturn = true);
    expect(find.byType(MarkdownEditorScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    final _ = await tester.pumpAndSettle();

    expect(find.byType(MarkdownEditorScreen), findsNothing);
    expect(didReturn, isTrue);
  });

  testWidgets('passes keyboard inset to the editor route', (tester) async {
    tester.view.viewInsets = const FakeViewPadding(bottom: 240);
    addTearDown(tester.view.resetViewInsets);
    var didReturn = false;

    await _openMarkdownEditor(tester, onResult: (_) => didReturn = true);

    final editorContext = tester.element(find.byType(MarkdownEditorScreen));
    expect(
      MediaQuery.viewInsetsOf(editorContext).bottom,
      240 / tester.view.devicePixelRatio,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.close));
    final _ = await tester.pumpAndSettle();
    expect(didReturn, isTrue);
  });

  testWidgets('unchanged Markdown editor closes without confirmation', (
    tester,
  ) async {
    var didReturn = false;
    await _openMarkdownEditor(tester, onResult: (_) => didReturn = true);

    final _ = await tester.binding.handlePopRoute();
    final _ = await tester.pumpAndSettle();

    expect(find.byType(AuraConfirmDialog), findsNothing);
    expect(find.byType(MarkdownEditorScreen), findsNothing);
    expect(didReturn, isTrue);
  });

  testWidgets('explicit Cancel discards Markdown edits without confirmation', (
    tester,
  ) async {
    String? result;
    var didReturn = false;
    await _openMarkdownEditor(
      tester,
      onResult: (value) {
        result = value;
        didReturn = true;
      },
    );
    await tester.enterText(_markdownEditorInput, _editedMarkdown);
    await tester.tap(find.byIcon(Icons.close));
    final _ = await tester.pumpAndSettle();

    expect(find.byType(AuraConfirmDialog), findsNothing);
    expect(find.byType(MarkdownEditorScreen), findsNothing);
    expect(didReturn, isTrue);
    expect(result, isNull);
  });

  testWidgets('Save returns Markdown edits without confirmation', (
    tester,
  ) async {
    String? result;
    await _openMarkdownEditor(tester, onResult: (value) => result = value);
    await tester.enterText(_markdownEditorInput, _editedMarkdown);
    await tester.tap(find.byIcon(Icons.save_outlined));
    final _ = await tester.pumpAndSettle();

    expect(find.byType(AuraConfirmDialog), findsNothing);
    expect(find.byType(MarkdownEditorScreen), findsNothing);
    expect(result, _editedMarkdown);
  });

  testWidgets('numbered lists continue and native undo restores', (
    tester,
  ) async {
    await _openMarkdownEditor(
      tester,
      onResult: (value) => fail('Unexpected editor close: $value'),
    );
    final editor = find.byType(EditableText);
    await tester.showKeyboard(editor);
    final controller = tester.widget<EditableText>(editor).controller
      ..value = const .new(
        text: '1. first\n2. second',
        selection: .collapsed(offset: 8),
      );
    await tester.pump(const Duration(milliseconds: 600));

    tester.testTextInput.updateEditingValue(
      const .new(
        text: '1. first\n\n2. second',
        selection: .collapsed(offset: 9),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));

    expect(controller.text, '1. first\n2. \n3. second');
    expect(controller.selection, const TextSelection.collapsed(offset: 12));

    final _ = await tester.sendKeyDownEvent(.controlLeft);
    final _ = await tester.sendKeyEvent(.keyZ);
    final _ = await tester.sendKeyUpEvent(.controlLeft);
    await tester.pump();
    expect(controller.text, '1. first\n2. second');
  });

  testWidgets('Tab indentation can be undone in the editor', (tester) async {
    await _openMarkdownEditor(
      tester,
      onResult: (value) => fail('Unexpected editor close: $value'),
    );
    final editor = find.byType(EditableText);
    await tester.showKeyboard(editor);
    const original = TextEditingValue(
      text: '- parent\n- sibling',
      selection: .collapsed(offset: 3),
    );
    final controller = tester.widget<EditableText>(editor).controller
      ..value = original;
    await tester.pump(const Duration(milliseconds: 600));

    final _ = await tester.sendKeyEvent(.tab);
    await tester.pump(const Duration(milliseconds: 600));
    expect(controller.text, '  - parent\n- sibling');
    expect(controller.selection, const TextSelection.collapsed(offset: 5));

    final _ = await tester.sendKeyDownEvent(.controlLeft);
    final _ = await tester.sendKeyEvent(.keyZ);
    final _ = await tester.sendKeyUpEvent(.controlLeft);
    await tester.pump();
    expect(controller.value, original);
  });

  testWidgets('editor input exits empty bullet on Enter', (tester) async {
    await _openMarkdownEditor(
      tester,
      onResult: (value) => fail('Unexpected editor close: $value'),
    );
    final editor = find.byType(EditableText);
    await tester.showKeyboard(editor);
    final controller = tester.widget<EditableText>(editor).controller
      ..value = const .new(
        text: '- first\n- ',
        selection: .collapsed(offset: 10),
      );
    await tester.pump();

    tester.testTextInput.updateEditingValue(
      const .new(text: '- first\n- \n', selection: .collapsed(offset: 11)),
    );
    await tester.pump();

    expect(controller.text, '- first\n');
    expect(controller.selection, const TextSelection.collapsed(offset: 8));
  });
}

Future<void> _openMarkdownEditor(
  WidgetTester tester, {
  required void Function(String?) onResult,
  FocusNode? sourceFocusNode,
}) async {
  await tester.runAsync(() async {
    await tester.pumpWidget(
      TestableApp(
        child: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                if (sourceFocusNode != null)
                  TextField(focusNode: sourceFocusNode),
                TextButton(
                  onPressed: () {
                    final _ = _showMarkdownEditor(context, onResult: onResult);
                  },
                  child: const Text('Open editor'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  });
  final _ = await tester.pumpAndSettle();
  if (sourceFocusNode != null) {
    sourceFocusNode.requestFocus();
    await tester.pump();
    expect(sourceFocusNode.hasFocus, isTrue);
  }
  await tester.tap(find.text('Open editor'));
  final _ = await tester.pumpAndSettle();
  expect(find.byType(MarkdownEditorScreen), findsOneWidget);
  expect(_markdownEditorInput, findsOneWidget);
}

Finder get _markdownEditorInput => find.descendant(
  of: find.byType(MarkdownEditorScreen),
  matching: find.byType(EditableText),
);

Future<void> _showMarkdownEditor(
  BuildContext context, {
  required void Function(String?) onResult,
}) async {
  final result = await MarkdownEditorLauncher.show(
    context,
    initialMarkdown: _initialMarkdown,
  );
  onResult(result);
}
