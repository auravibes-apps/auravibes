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

  test('indent and outdent bullet task and numbered list subtrees', () {
    for (final marker in ['- ', '- [x] ', '1. ']) {
      final nextMarker = marker == '1. ' ? '2. ' : marker;
      final indentedNextMarker = marker == '1. ' ? '1. ' : marker;
      final original = TextEditingValue(
        text: '${marker}parent\n  - child\n    - grandchild\n${nextMarker}next',
        selection: .collapsed(offset: marker.length + 2),
      );

      final indented = MarkdownListInputFormatter.adjustIndentation(
        original,
        outdent: false,
      );
      final expected =
          '  ${marker}parent\n'
          '    - child\n'
          '      - grandchild\n'
          '${indentedNextMarker}next';
      expect(indented?.text, expected);
      expect(indented?.selection.baseOffset, original.selection.baseOffset + 2);
      if (indented == null) {
        fail('Expected list item to indent');
      }
      expect(
        MarkdownListInputFormatter.adjustIndentation(indented, outdent: true),
        original,
      );
    }
  });

  test('renumber ordered siblings at each indentation level', () {
    const original = TextEditingValue(
      text: '1. first\n  1. child\n  2. sibling\n2. last',
      selection: .collapsed(offset: 23),
    );

    final result = MarkdownListInputFormatter.adjustIndentation(
      original,
      outdent: true,
    );

    expect(result?.text, '1. first\n  1. child\n2. sibling\n3. last');
    expect(result?.selection, const TextSelection.collapsed(offset: 21));

    const firstItem = TextEditingValue(
      text: '1. first\n2. second\n3. third',
      selection: .collapsed(offset: 4),
    );
    expect(
      MarkdownListInputFormatter.adjustIndentation(
        firstItem,
        outdent: false,
      )?.text,
      '  1. first\n1. second\n2. third',
    );

    const separateGroup = TextEditingValue(
      text: '1. first\n2. second\n- break\n7. other\n8. next',
      selection: .collapsed(offset: 4),
    );
    expect(
      MarkdownListInputFormatter.adjustIndentation(
        separateGroup,
        outdent: false,
      )?.text,
      '  1. first\n1. second\n- break\n7. other\n8. next',
    );
  });

  test(
    'outdent an empty nested item and leave an empty root item unchanged',
    () {
      const nested = TextEditingValue(
        text: '- parent\n  - ',
        selection: .collapsed(offset: 13),
      );
      const root = TextEditingValue(
        text: '- ',
        selection: .collapsed(offset: 2),
      );

      expect(
        MarkdownListInputFormatter.adjustIndentation(nested, outdent: true),
        const TextEditingValue(
          text: '- parent\n- ',
          selection: .collapsed(offset: 11),
        ),
      );
      expect(
        MarkdownListInputFormatter.adjustIndentation(root, outdent: true),
        isNull,
      );
    },
  );

  test('indent selected list lines without changing adjacent prose', () {
    const original = TextEditingValue(
      text: 'before\n- one\n- two\nafter',
      selection: .new(baseOffset: 7, extentOffset: 18),
    );

    final result = MarkdownListInputFormatter.adjustIndentation(
      original,
      outdent: false,
    );

    expect(result?.text, 'before\n  - one\n  - two\nafter');
    expect(
      result?.selection,
      const TextSelection(baseOffset: 9, extentOffset: 22),
    );
  });

  test(
    'indenting a bullet leaves unrelated nested ordered items unchanged',
    () {
      const original = TextEditingValue(
        text: '- first\n- second\n  7. child\n  9. sibling',
        selection: .collapsed(offset: 3),
      );

      final result = MarkdownListInputFormatter.adjustIndentation(
        original,
        outdent: false,
      );

      expect(result?.text, '  - first\n- second\n  7. child\n  9. sibling');
      expect(result?.selection, const TextSelection.collapsed(offset: 5));
    },
  );

  test('indent traverses continuation prose to reach nested list items', () {
    const original = TextEditingValue(
      text: '- parent\n  continuation\n  - child',
      selection: .collapsed(offset: 3),
    );

    final result = MarkdownListInputFormatter.adjustIndentation(
      original,
      outdent: false,
    );

    expect(result?.text, '  - parent\n  continuation\n    - child');
    expect(result?.selection, const TextSelection.collapsed(offset: 5));
  });

  test('outdent removes one existing tab indentation level', () {
    const original = TextEditingValue(
      text: '\t- child',
      selection: .collapsed(offset: 5),
    );

    expect(
      MarkdownListInputFormatter.adjustIndentation(original, outdent: true),
      const TextEditingValue(text: '- child', selection: .collapsed(offset: 4)),
    );
  });
}
