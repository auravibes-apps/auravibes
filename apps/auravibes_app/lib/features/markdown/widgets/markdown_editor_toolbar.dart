// Required: Toolbar actions intentionally mutate selected editor text.
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class const MarkdownEditorToolbar({
  required final TextEditingController controller,
  required final FocusNode focusNode,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: .horizontal,
      child: _ToolbarActions(toolbar: this),
    );
  }
}

extension on MarkdownEditorToolbar {
  TextSelection get _safeSelection {
    final selection = controller.selection;
    if (selection.isValid) return selection;

    final length = controller.text.length;

    return TextSelection.collapsed(offset: length);
  }

  void _applyAction(_ToolbarActionKind action) => switch (action) {
    .bold => _wrapSelection('**', '**'),
    .italic => _wrapSelection('*', '*'),
    .heading => _prefixLines('# '),
    .bullets => _prefixLines('- '),
    .code => _formatCode(),
    .quote => _prefixLines('> '),
  };

  void _wrapSelection(String before, String after) {
    final selection = _safeSelection;
    final selected = selection.textInside(controller.text);
    final result = _wrapSelectionResult((
      selection: selection,
      selected: selected,
      before: before,
      after: after,
    ));

    _replace(selection, result.replacement, result.cursorOffset);
  }

  void _prefixLines(String prefix) {
    final selection = _safeSelection;
    final text = controller.text;
    final range = _lineRange(selection, text);
    final replacement = _prefixReplacement(range.textInside(text), prefix);

    _replace(range, replacement, range.start + replacement.length);
  }

  TextSelection _lineRange(TextSelection selection, String text) {
    final bounds = _selectionBounds(selection, text);
    final lineEnd = _toolbarLineEnd(text, bounds.end);

    return TextSelection(
      baseOffset: _toolbarLineStart(text, bounds.start),
      extentOffset: lineEnd == -1 ? text.length : lineEnd,
    );
  }

  ({String replacement, int cursorOffset}) _wrapSelectionResult(
    ({TextSelection selection, String selected, String before, String after})
    input,
  ) {
    final replacement = '${input.before}${input.selected}${input.after}';
    final cursorOffset = input.selected.isEmpty
        ? input.selection.start + input.before.length
        : input.selection.start + replacement.length;

    return (replacement: replacement, cursorOffset: cursorOffset);
  }

  ({int start, int end}) _selectionBounds(
    TextSelection selection,
    String text,
  ) {
    final start = selection.start.clamp(0, text.length);

    return (start: start, end: selection.end.clamp(start, text.length));
  }
}

extension on MarkdownEditorToolbar {
  String _prefixReplacement(String selected, String prefix) => selected
      .split('\n')
      .map((line) => line.startsWith(prefix) ? line : '$prefix$line')
      .join('\n');

  void _formatCode() {
    final selection = _safeSelection;
    final selected = selection.textInside(controller.text);
    if (selected.contains('\n')) {
      final replacement = '```\n$selected\n```';
      _replace(selection, replacement, selection.start + replacement.length);

      return;
    }

    _wrapSelection('`', '`');
  }

  void _replace(TextSelection selection, String replacement, int cursorOffset) {
    final text = controller.text;
    controller.value = .new(
      text: text.replaceRange(selection.start, selection.end, replacement),
      selection: TextSelection.collapsed(offset: cursorOffset),
    );
    if (!focusNode.hasFocus) {
      focusNode.requestFocus();
    }
  }
}

int _toolbarLineStart(String text, int selectionStart) =>
    selectionStart == 0 ? 0 : text.lastIndexOf('\n', selectionStart - 1) + 1;

int _toolbarLineEnd(String text, int selectionEnd) =>
    selectionEnd >= text.length
    ? text.length
    : text.indexOf('\n', selectionEnd);

class const _ToolbarActions({required final MarkdownEditorToolbar toolbar})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _ToolbarActionList(toolbar: toolbar);
}

class const _ToolbarActionList({required final MarkdownEditorToolbar toolbar})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraRow(
    children: [
      for (final action in _ToolbarActionKind.values)
        _ToolbarAction(toolbar: toolbar, action: action),
    ],
    spacing: .xs,
  );
}

class const _ToolbarAction({
  required final MarkdownEditorToolbar toolbar,
  required final _ToolbarActionKind action,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _ToolbarButton(
    icon: action.icon,
    label: action.labelKey.tr(context: context),
    onPressed: () => toolbar._applyAction(action),
  );
}

enum _ToolbarActionKind {
  bold(Icons.format_bold, LocaleKeys.markdown_editor_toolbar_bold),
  italic(Icons.format_italic, LocaleKeys.markdown_editor_toolbar_italic),
  heading(Icons.title, LocaleKeys.markdown_editor_toolbar_heading),
  bullets(
    Icons.format_list_bulleted,
    LocaleKeys.markdown_editor_toolbar_bullets,
  ),
  code(Icons.code, LocaleKeys.markdown_editor_toolbar_code),
  quote(Icons.format_quote, LocaleKeys.markdown_editor_toolbar_quote);

  new(this.icon, this.labelKey);

  final IconData icon;
  final String labelKey;
}

class const _ToolbarButton({
  required final IconData icon,
  required final String label,
  required final VoidCallback onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ExcludeFocus(
      child: AuraIconButton(
        icon: icon,
        onPressed: onPressed,
        variant: .outlined,
        semanticLabel: label,
        tooltip: label,
      ),
    );
  }
}
