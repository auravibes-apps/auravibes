// Required: Toolbar actions intentionally mutate selected editor text.
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:material_ui/material_ui.dart';

class const MarkdownEditorToolbar({
  required final TextEditingController controller,
  required final FocusNode focusNode,
  super.key,
}) extends StatefulWidget {
  @override
  State<MarkdownEditorToolbar> createState() => _MarkdownEditorToolbarState();
}

class _MarkdownEditorToolbarState extends State<MarkdownEditorToolbar> {
  TextEditingValue? _previousValue;
  String? _toolbarResultText;

  TextEditingController get _controller => widget.controller;

  FocusNode get _focusNode => widget.focusNode;

  bool get _canUndo =>
      _previousValue != null && _controller.text == _toolbarResultText;

  @override
  void didUpdateWidget(MarkdownEditorToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;

    _previousValue = null;
    _toolbarResultText = null;
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: _controller,
    builder: (_, _, _) => SingleChildScrollView(
      scrollDirection: .horizontal,
      child: _ToolbarActions(toolbar: this),
    ),
  );

  void _rememberAction(TextEditingValue previousValue) {
    setState(() {
      _previousValue = previousValue;
      _toolbarResultText = _controller.text;
    });
  }

  void _undo() {
    final previousValue = _previousValue;
    if (!_canUndo || previousValue == null) return;

    _controller.value = previousValue;
    if (!_focusNode.hasFocus) _focusNode.requestFocus();
    setState(() {
      _previousValue = null;
      _toolbarResultText = null;
    });
  }
}

extension on _MarkdownEditorToolbarState {
  TextSelection get _safeSelection {
    final selection = _controller.selection;
    if (selection.isValid) return selection;

    final length = _controller.text.length;

    return TextSelection.collapsed(offset: length);
  }

  void _applyAction(_ToolbarActionKind action, BuildContext context) {
    final previousValue = _controller.value;
    switch (action) {
      case .bold:
        _wrapSelection('**', '**');
      case .italic:
        _wrapSelection('*', '*');
      case .heading:
        _prefixLines('# ');
      case .bullets:
        _prefixLines('- ');
      case .numberedList:
        _prefixNumberedLines();
      case .link:
        _formatLink(context);
      case .code:
        _formatCode();
      case .quote:
        _prefixLines('> ');
    }
    _rememberAction(previousValue);
  }

  void _wrapSelection(String before, String after) {
    final selection = _safeSelection;
    final selected = selection.textInside(_controller.text);
    final result = _wrapSelectionResult((
      selection: selection,
      selected: selected,
      before: before,
      after: after,
    ));

    _replace(
      selection,
      result.replacement,
      .collapsed(offset: result.cursorOffset),
    );
  }

  void _prefixLines(String prefix) {
    final selection = _safeSelection;
    final text = _controller.text;
    final range = _lineRange(selection, text);
    final replacement = _prefixReplacement(range.textInside(text), prefix);

    _replace(
      range,
      replacement,
      .collapsed(offset: range.start + replacement.length),
    );
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

extension on _MarkdownEditorToolbarState {
  String _prefixReplacement(String selected, String prefix) => selected
      .split('\n')
      .map((line) => line.startsWith(prefix) ? line : '$prefix$line')
      .join('\n');

  void _prefixNumberedLines() {
    final selection = _safeSelection;
    final text = _controller.text;
    final range = _lineRange(selection, text);
    final replacement = _numberedReplacement(range.textInside(text));

    _replace(
      range,
      replacement,
      .collapsed(offset: range.start + replacement.length),
    );
  }

  String _numberedReplacement(String selected) {
    final existingPrefix = RegExp(r'^\d+\. ');

    return selected
        .split('\n')
        .indexed
        .map((entry) {
          final line = entry.$2.replaceFirst(existingPrefix, '');

          return '${entry.$1 + 1}. $line';
        })
        .join('\n');
  }

  void _formatLink(BuildContext context) {
    final selection = _safeSelection;
    final selected = selection.textInside(_controller.text);
    if (selected.isEmpty) {
      _insertLinkPlaceholder(context, selection);

      return;
    }

    _insertSelectedLink(context, selection, selected);
  }

  void _insertSelectedLink(
    BuildContext context,
    TextSelection selection,
    String selected,
  ) {
    final url = _linkUrl(context);
    final urlStart = selection.start + selected.length + 3;
    _replace(
      selection,
      '[$selected]($url)',
      .new(baseOffset: urlStart, extentOffset: urlStart + url.length),
    );
  }

  void _insertLinkPlaceholder(BuildContext context, TextSelection selection) {
    final label = LocaleKeys.markdown_editor_toolbar_link_text_placeholder.tr(
      context: context,
    );
    final url = _linkUrl(context);
    final labelStart = selection.start + 1;
    _replace(
      selection,
      '[$label]($url)',
      .new(baseOffset: labelStart, extentOffset: labelStart + label.length),
    );
  }

  String _linkUrl(BuildContext context) => LocaleKeys
      .markdown_editor_toolbar_link_url_placeholder
      .tr(context: context);

  void _formatCode() {
    final selection = _safeSelection;
    final selected = selection.textInside(_controller.text);
    if (selected.contains('\n')) {
      final replacement = '```\n$selected\n```';
      _replace(
        selection,
        replacement,
        .collapsed(offset: selection.start + replacement.length),
      );

      return;
    }

    _wrapSelection('`', '`');
  }

  void _replace(
    TextSelection selection,
    String replacement,
    TextSelection replacementSelection,
  ) {
    final text = _controller.text;
    _controller.value = .new(
      text: text.replaceRange(selection.start, selection.end, replacement),
      selection: replacementSelection,
    );
    _requestFocus();
  }

  void _requestFocus() {
    if (!_focusNode.hasFocus) _focusNode.requestFocus();
  }
}

int _toolbarLineStart(String text, int selectionStart) =>
    selectionStart == 0 ? 0 : text.lastIndexOf('\n', selectionStart - 1) + 1;

int _toolbarLineEnd(String text, int selectionEnd) =>
    selectionEnd >= text.length
    ? text.length
    : text.indexOf('\n', selectionEnd);

class const _ToolbarActions({
  required final _MarkdownEditorToolbarState toolbar,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _ToolbarActionList(toolbar: toolbar);
}

class const _ToolbarActionList({
  required final _MarkdownEditorToolbarState toolbar,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final undoLabel = LocaleKeys.markdown_editor_toolbar_undo.tr(
      context: context,
    );

    return AuraRow(
      children: [
        _ToolbarButton(
          icon: Icons.undo,
          label: undoLabel,
          onPressed: toolbar._canUndo ? toolbar._undo : null,
        ),
        for (final action in _ToolbarActionKind.values)
          _ToolbarAction(toolbar: toolbar, action: action),
      ],
      spacing: .xs,
    );
  }
}

class const _ToolbarAction({
  required final _MarkdownEditorToolbarState toolbar,
  required final _ToolbarActionKind action,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _ToolbarButton(
    icon: action.icon,
    label: action.labelKey.tr(context: context),
    onPressed: () => toolbar._applyAction(action, context),
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
  numberedList(
    Icons.format_list_numbered,
    LocaleKeys.markdown_editor_toolbar_numbered_list,
  ),
  link(Icons.link, LocaleKeys.markdown_editor_toolbar_link),
  code(Icons.code, LocaleKeys.markdown_editor_toolbar_code),
  quote(Icons.format_quote, LocaleKeys.markdown_editor_toolbar_quote);

  new(this.icon, this.labelKey);

  final IconData icon;
  final String labelKey;
}

class const _ToolbarButton({
  required final IconData icon,
  required final String label,
  required final VoidCallback? onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ExcludeFocus(
      child: AuraIconButton(
        icon: icon,
        onPressed: onPressed,
        disabled: onPressed == null,
        variant: .outlined,
        semanticLabel: label,
        tooltip: label,
      ),
    );
  }
}
