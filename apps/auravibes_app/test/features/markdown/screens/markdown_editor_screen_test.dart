import 'package:auravibes_app/features/markdown/screens/markdown_editor_screen.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/test_app.dart';

const _initialMarkdown = 'Saved content';
const _editedMarkdown = 'Unsaved content';

void main() {
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
    await tester.enterText(find.byType(EditableText), _editedMarkdown);
    final _ = await tester.pumpAndSettle();

    final _ = await tester.binding.handlePopRoute();
    final _ = await tester.pumpAndSettle();

    final dialog = find.byType(AuraConfirmDialog);
    expect(dialog, findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    final _ = await tester.pumpAndSettle();
    expect(find.byType(MarkdownEditorScreen), findsOneWidget);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
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
    await tester.enterText(find.byType(EditableText), _editedMarkdown);
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
    await tester.enterText(find.byType(EditableText), _editedMarkdown);
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
}) async {
  await tester.runAsync(() async {
    await tester.pumpWidget(
      TestableApp(
        child: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () {
                final _ = _showMarkdownEditor(context, onResult: onResult);
              },
              child: const Text('Open editor'),
            ),
          ),
        ),
      ),
    );
  });
  final _ = await tester.pumpAndSettle();
  await tester.tap(find.text('Open editor'));
  final _ = await tester.pumpAndSettle();
  expect(find.byType(MarkdownEditorScreen), findsOneWidget);
  expect(find.byType(EditableText), findsOneWidget);
}

Future<void> _showMarkdownEditor(
  BuildContext context, {
  required void Function(String?) onResult,
}) async {
  final result = await Navigator.of(context).push<String>(
    MaterialPageRoute<String>(
      builder: (_) =>
          const MarkdownEditorScreen(initialMarkdown: _initialMarkdown),
    ),
  );
  onResult(result);
}
