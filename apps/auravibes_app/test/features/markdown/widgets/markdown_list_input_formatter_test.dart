import 'package:auravibes_app/features/markdown/widgets/markdown_list_input_formatter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const formatter = MarkdownListInputFormatter();

  TextEditingValue edit(
    String text, {
    required TextSelection selection,
    required String replacement,
  }) {
    final oldValue = TextEditingValue(text: text, selection: selection);
    final newValue = TextEditingValue(
      text: text.replaceRange(selection.start, selection.end, replacement),
      selection: .collapsed(offset: selection.start + replacement.length),
    );

    return formatter.formatEditUpdate(oldValue, newValue);
  }

  test(
    'Enter continues indented bullets and keeps the cursor after marker',
    () {
      final result = edit(
        '  - first\ntail',
        selection: const TextSelection.collapsed(offset: 9),
        replacement: '\n',
      );

      expect(result.text, '  - first\n  - \ntail');
      expect(result.selection, const TextSelection.collapsed(offset: 14));
    },
  );

  test('Enter splits a list item without deleting trailing content', () {
    final result = edit(
      '- first half',
      selection: const TextSelection.collapsed(offset: 7),
      replacement: '\n',
    );

    expect(result.text, '- first\n-  half');
    expect(result.selection, const TextSelection.collapsed(offset: 10));
  });

  test('Enter on empty item exits list without a stray marker', () {
    final result = edit(
      '- first\n- \nnext',
      selection: const TextSelection.collapsed(offset: 10),
      replacement: '\n',
    );

    expect(result.text, '- first\n\nnext');
    expect(result.selection, const TextSelection.collapsed(offset: 8));
  });

  test('whitespace-only item exits without leaving spaces', () {
    final result = edit(
      '- first\n-   ',
      selection: const TextSelection.collapsed(offset: 11),
      replacement: '\n',
    );

    expect(result.text, '- first\n');
    expect(result.selection, const TextSelection.collapsed(offset: 8));
  });

  test('Enter replacing selected text leaves the native selection result', () {
    final result = edit(
      '- first',
      selection: const TextSelection(baseOffset: 2, extentOffset: 7),
      replacement: '\n',
    );

    expect(result.text, '- \n');
    expect(result.selection, const TextSelection.collapsed(offset: 3));
  });

  test('Backspace on empty first item removes marker only', () {
    final result = formatter.formatEditUpdate(
      const TextEditingValue(
        text: '- \nnext',
        selection: .collapsed(offset: 2),
      ),
      const TextEditingValue(text: '-\nnext', selection: .collapsed(offset: 1)),
    );

    expect(result.text, '\nnext');
    expect(result.selection, const TextSelection.collapsed(offset: 0));
  });

  test('Enter continues and renumbers existing numbered items', () {
    final result = edit(
      '1. first\n2. second',
      selection: const TextSelection.collapsed(offset: 8),
      replacement: '\n',
    );

    expect(result.text, '1. first\n2. \n3. second');
    expect(result.selection, const TextSelection.collapsed(offset: 12));
  });

  test('removing first numbered item restarts remaining sequence', () {
    final result = edit(
      '1. first\n2. second\n3. third',
      selection: const TextSelection(baseOffset: 0, extentOffset: 9),
      replacement: '',
    );

    expect(result.text, '1. second\n2. third');
    expect(result.selection, const TextSelection.collapsed(offset: 0));
  });

  test('renumbering preserves caret when number grows to two digits', () {
    final result = edit(
      '9. first\n10. second',
      selection: const TextSelection.collapsed(offset: 8),
      replacement: '\n',
    );

    expect(result.text, '9. first\n10. \n11. second');
    expect(result.selection, const TextSelection.collapsed(offset: 13));
  });

  test('unrelated numbered block remains unchanged', () {
    final result = edit(
      '1. first\n2. second\n\n7. other\n8. other',
      selection: const TextSelection.collapsed(offset: 8),
      replacement: '\n',
    );

    expect(result.text, '1. first\n2. \n3. second\n\n7. other\n8. other');
  });

  test('task items continue as unchecked items', () {
    final result = edit(
      '- [x] done',
      selection: const TextSelection.collapsed(offset: 10),
      replacement: '\n',
    );

    expect(result.text, '- [x] done\n- [ ] ');
    expect(result.selection, const TextSelection.collapsed(offset: 17));
  });

  test('active composition is left to the input method', () {
    const oldValue = TextEditingValue(
      text: '- item',
      selection: .collapsed(offset: 6),
    );
    const newValue = TextEditingValue(
      text: '- item\n',
      selection: .collapsed(offset: 7),
      composing: .new(start: 6, end: 7),
    );

    expect(formatter.formatEditUpdate(oldValue, newValue), newValue);
  });
}
