// Required: Toolbar actions intentionally mutate selected editor text.
import 'dart:async';

import 'package:auravibes_app/features/markdown/widgets/markdown_link_dialog.dart';
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
  final _undoHistory = <({TextEditingValue before, TextEditingValue after})>[];
  final _redoHistory = <({TextEditingValue before, TextEditingValue after})>[];
  String _lastText = '';

  TextEditingController get _controller => widget.controller;

  FocusNode get _focusNode => widget.focusNode;

  bool get _canUndo =>
      _undoHistory.isNotEmpty &&
      _controller.text == _undoHistory.last.after.text;

  bool get _canRedo =>
      _redoHistory.isNotEmpty &&
      _controller.text == _redoHistory.last.before.text;

  @override
  void initState() {
    super.initState();
    _lastText = _controller.text;
  }

  @override
  void didUpdateWidget(MarkdownEditorToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;

    _lastText = _controller.text;
    _undoHistory.clear();
    _redoHistory.clear();
  }

  @override
  Widget build(BuildContext context) => _ToolbarActions(toolbar: this);

  void _rememberAction(TextEditingValue before) {
    final after = _controller.value;
    if (after.text == before.text) return;

    setState(() {
      _undoHistory.add((before: before, after: after));
      _redoHistory.clear();
    });
  }

  void _undo() {
    if (!_canUndo) return;

    final action = _undoHistory.removeLast();
    _toolbarEdit(() => _controller.value = action.before);
    if (!_focusNode.hasFocus) _focusNode.requestFocus();
    setState(() => _redoHistory.add(action));
  }

  void _redo() {
    if (!_canRedo) return;

    final action = _redoHistory.removeLast();
    _toolbarEdit(() => _controller.value = action.after);
    if (!_focusNode.hasFocus) _focusNode.requestFocus();
    setState(() => _undoHistory.add(action));
  }
}

extension on _MarkdownEditorToolbarState {
  void _toolbarEdit(VoidCallback edit) {
    edit();
    _lastText = _controller.text;
  }

  void _syncHistory(String text) {
    if (text == _lastText) return;

    _lastText = text;
    _undoHistory.clear();
    _redoHistory.clear();
  }

  TextSelection get _safeSelection {
    final selection = _controller.selection;
    if (selection.isValid) return selection;

    final length = _controller.text.length;

    return TextSelection.collapsed(offset: length);
  }

  void _applyAction(_ToolbarActionKind action, BuildContext context) {
    if (action == .link) {
      unawaited(_formatLink(context));

      return;
    }

    final previousValue = _controller.value;
    _toolbarEdit(() {
      if (!_applyInlineAction(action)) _applyLineAction(action);
    });
    _rememberAction(previousValue);
  }

  bool _applyInlineAction(_ToolbarActionKind action) {
    switch (action) {
      case .bold:
        _wrapSelection('**', '**');
      case .italic:
        _wrapSelection('*', '*');
      case .code:
        _formatCode();
      case .heading ||
          .bullets ||
          .numberedList ||
          .taskList ||
          .link ||
          .quote:
        return false;
    }

    return true;
  }

  void _applyLineAction(_ToolbarActionKind action) {
    switch (action) {
      case .heading:
        _prefixLines('# ');
      case .bullets:
        _prefixLines('- ');
      case .numberedList:
        _prefixNumberedLines();
      case .taskList:
        _formatTaskList();
      case .quote:
        _prefixLines('> ');
      case .bold || .italic || .link || .code:
        break;
    }
  }
}

extension on _MarkdownEditorToolbarState {
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
}

extension on _MarkdownEditorToolbarState {
  void _formatTaskList() {
    final selection = _safeSelection;
    final updated = _taskListValue(_controller.value, selection);
    if (updated == _controller.value) return;

    _controller.value = updated;
    _requestFocus();
  }

  Future<void> _formatLink(BuildContext context) async {
    final before = _controller.value;
    final selection = _safeSelection;
    final result = await MarkdownLinkDialog.show(
      context,
      selectedText: selection.textInside(before.text),
    );
    if (!context.mounted || _controller.text != before.text) return;

    _completeLink((value: before, selection: selection), result, context);
  }

  void _completeLink(
    ({TextEditingValue value, TextSelection selection}) snapshot,
    ({String text, String destination})? result,
    BuildContext context,
  ) {
    if (result == null) {
      _restoreLinkSelection(snapshot.value.selection);

      return;
    }

    _insertLink(snapshot, _linkValue(result, context));
  }

  void _restoreLinkSelection(TextSelection selection) {
    if (_controller.selection == selection) return;

    _toolbarEdit(() => _controller.selection = selection);
  }

  ({String label, String destination, bool isPlaceholder}) _linkValue(
    ({String text, String destination}) result,
    BuildContext context,
  ) {
    final isPlaceholder = result.text.isEmpty;
    final label = isPlaceholder
        ? LocaleKeys.markdown_editor_toolbar_link_text_placeholder.tr(
            context: context,
          )
        : result.text;

    return (
      label: label,
      destination: result.destination,
      isPlaceholder: isPlaceholder,
    );
  }

  void _insertLink(
    ({TextEditingValue value, TextSelection selection}) snapshot,
    ({String label, String destination, bool isPlaceholder}) linkValue,
  ) {
    final before = snapshot.value;
    final selection = snapshot.selection;
    final link = '[${linkValue.label}](${linkValue.destination})';
    final insertedSelection = _linkSelection(selection.start, link, linkValue);
    _toolbarEdit(() => _replace(selection, link, insertedSelection));
    _rememberAction(before);
  }

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

int _toolbarLineEnd(String text, int selectionEnd) {
  final end = text.indexOf('\n', selectionEnd);

  return end == -1 ? text.length : end;
}

TextSelection _linkSelection(
  int start,
  String link,
  ({String label, String destination, bool isPlaceholder}) value,
) => value.isPlaceholder
    ? TextSelection(
        baseOffset: start + 1,
        extentOffset: start + 1 + value.label.length,
      )
    : TextSelection.collapsed(offset: start + link.length);

typedef _TaskEdit = ({int start, int end, String replacement});

final _taskMarker = RegExp(r'^[ \t]*- \[[ xX]\] ');

TextEditingValue _taskListValue(
  TextEditingValue value,
  TextSelection selection,
) {
  if (selection.isCollapsed) return _insertTaskMarker(value, selection);

  final edits = _selectedTaskEdits(value.text, selection);
  if (edits.isEmpty) return value;

  return _applyTaskEdits(value, edits);
}

TextEditingValue _insertTaskMarker(
  TextEditingValue value,
  TextSelection selection,
) {
  final text = value.text;
  final start = _toolbarLineStart(text, selection.start);
  final line = _textInside(text, start, _toolbarLineEnd(text, selection.start));
  final edit = _taskEdit(line, start);
  if (edit == null) return value;

  return _applyTaskEdits(value, [edit]);
}

List<_TaskEdit> _selectedTaskEdits(String text, TextSelection selection) {
  final selected = _selectedTaskLines(text, selection);
  var lineStart = selected.start;
  final edits = <_TaskEdit>[];
  for (final line in selected.lines) {
    final edit = _taskEdit(line, lineStart);
    if (edit != null) edits.add(edit);
    lineStart += line.length + '\n'.length;
  }

  return edits;
}

({int start, List<String> lines}) _selectedTaskLines(
  String text,
  TextSelection selection,
) {
  final start = _toolbarLineStart(text, selection.start);
  final end = _toolbarLineEnd(text, selection.end - 1);

  return (start: start, lines: _textInside(text, start, end).split('\n'));
}

String _textInside(String text, int start, int end) =>
    TextSelection(baseOffset: start, extentOffset: end).textInside(text);

_TaskEdit? _taskEdit(String line, int lineStart) {
  final content = line.trimLeft();
  if (_taskMarker.hasMatch(content)) return null;

  final markerStart = lineStart + line.length - content.length;
  final bulletEnd = content.startsWith('- ')
      ? markerStart + '- '.length
      : markerStart;

  return (start: markerStart, end: bulletEnd, replacement: '- [ ] ');
}

TextEditingValue _applyTaskEdits(
  TextEditingValue value,
  List<_TaskEdit> edits,
) => value.copyWith(
  text: _applyTaskTextEdits(value.text, edits),
  selection: _taskSelection(value.selection, edits),
);

String _applyTaskTextEdits(String text, List<_TaskEdit> edits) {
  var updated = text;
  for (final edit in edits.reversed) {
    updated = updated.replaceRange(edit.start, edit.end, edit.replacement);
  }

  return updated;
}

TextSelection _taskSelection(TextSelection selection, List<_TaskEdit> edits) =>
    TextSelection(
      baseOffset: _taskSelectionOffset(selection.baseOffset, edits),
      extentOffset: _taskSelectionOffset(selection.extentOffset, edits),
      affinity: selection.affinity,
      isDirectional: selection.isDirectional,
    );

int _taskSelectionOffset(int offset, List<_TaskEdit> edits) {
  var shift = 0;
  for (final edit in edits) {
    if (offset < edit.start) break;
    if (offset <= edit.end) {
      return edit.start + shift + edit.replacement.length;
    }
    shift += edit.replacement.length - (edit.end - edit.start);
  }

  return offset + shift;
}

class const _ToolbarActions({
  required final _MarkdownEditorToolbarState toolbar,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: toolbar._controller,
    builder: (_, value, _) {
      toolbar._syncHistory(value.text);

      return SingleChildScrollView(
        scrollDirection: .horizontal,
        child: _ToolbarActionList(toolbar: toolbar),
      );
    },
  );
}

class const _ToolbarActionList({
  required final _MarkdownEditorToolbarState toolbar,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraRow(
    children: [
      _ToolbarHistoryButton(toolbar: toolbar, isUndo: true),
      _ToolbarHistoryButton(toolbar: toolbar, isUndo: false),
      for (final action in _ToolbarActionKind.values)
        _ToolbarAction(toolbar: toolbar, action: action),
    ],
    spacing: .xs,
  );
}

class const _ToolbarHistoryButton({
  required final _MarkdownEditorToolbarState toolbar,
  required final bool isUndo,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _ToolbarButton(
    icon: isUndo ? Icons.undo : Icons.redo,
    label:
        (isUndo
                ? LocaleKeys.markdown_editor_toolbar_undo
                : LocaleKeys.markdown_editor_toolbar_redo)
            .tr(context: context),
    onPressed: _historyCallback(toolbar, isUndo),
  );
}

VoidCallback? _historyCallback(
  _MarkdownEditorToolbarState toolbar,
  bool isUndo,
) {
  if (isUndo) return toolbar._canUndo ? toolbar._undo : null;

  return toolbar._canRedo ? toolbar._redo : null;
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
  taskList(Icons.checklist, LocaleKeys.markdown_editor_toolbar_task_list),
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
