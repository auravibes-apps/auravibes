// Required: Toolbar actions intentionally mutate selected editor text.
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class MarkdownEditorToolbar extends StatelessWidget {
  const MarkdownEditorToolbar({
    required this.controller,
    required this.focusNode,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: AuraRow(
        children: [
          _ToolbarButton(
            icon: Icons.format_bold,
            label: LocaleKeys.markdown_editor_toolbar_bold.tr(
              context: context,
            ),
            onPressed: () => _wrapSelection('**', '**'),
          ),
          _ToolbarButton(
            icon: Icons.format_italic,
            label: LocaleKeys.markdown_editor_toolbar_italic.tr(
              context: context,
            ),
            onPressed: () => _wrapSelection('*', '*'),
          ),
          _ToolbarButton(
            icon: Icons.title,
            label: LocaleKeys.markdown_editor_toolbar_heading.tr(
              context: context,
            ),
            onPressed: () => _prefixLines('# '),
          ),
          _ToolbarButton(
            icon: Icons.format_list_bulleted,
            label: LocaleKeys.markdown_editor_toolbar_bullets.tr(
              context: context,
            ),
            onPressed: () => _prefixLines('- '),
          ),
          _ToolbarButton(
            icon: Icons.code,
            label: LocaleKeys.markdown_editor_toolbar_code.tr(
              context: context,
            ),
            onPressed: _formatCode,
          ),
          _ToolbarButton(
            icon: Icons.format_quote,
            label: LocaleKeys.markdown_editor_toolbar_quote.tr(
              context: context,
            ),
            onPressed: () => _prefixLines('> '),
          ),
        ],
        spacing: .xs,
      ),
    );
  }

  void _wrapSelection(String before, String after) {
    final selection = _safeSelection;
    final text = controller.text;
    final selected = selection.textInside(text);
    final replacement = '$before$selected$after';
    final cursorOffset = selected.isEmpty
        ? selection.start + before.length
        : selection.start + replacement.length;

    _replace(selection, replacement, cursorOffset);
  }

  void _prefixLines(String prefix) {
    final selection = _safeSelection;
    final text = controller.text;
    final selectionStart = selection.start.clamp(0, text.length);
    final selectionEnd = selection.end.clamp(selectionStart, text.length);
    final lineStart = selectionStart == 0
        ? 0
        : text.lastIndexOf('\n', selectionStart - 1) + 1;
    final lineEnd = selectionEnd >= text.length
        ? text.length
        : text.indexOf('\n', selectionEnd);
    final end = lineEnd == -1 ? text.length : lineEnd;
    final selected = TextSelection(
      baseOffset: lineStart,
      extentOffset: end,
    ).textInside(text);
    final replacement = selected
        .split('\n')
        .map((line) => line.startsWith(prefix) ? line : '$prefix$line')
        .join('\n');

    _replace(
      TextSelection(baseOffset: lineStart, extentOffset: end),
      replacement,
      lineStart + replacement.length,
    );
  }

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
    controller.value = TextEditingValue(
      text: text.replaceRange(selection.start, selection.end, replacement),
      selection: TextSelection.collapsed(offset: cursorOffset),
    );
    if (!focusNode.hasFocus) {
      focusNode.requestFocus();
    }
  }

  TextSelection get _safeSelection {
    final selection = controller.selection;
    if (selection.isValid) return selection;

    final length = controller.text.length;

    return TextSelection.collapsed(offset: length);
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ExcludeFocus(
      child: AuraIconButton(
        icon: icon,
        onPressed: onPressed,
        variant: AuraIconButtonVariant.outlined,
        semanticLabel: label,
        tooltip: label,
      ),
    );
  }
}
