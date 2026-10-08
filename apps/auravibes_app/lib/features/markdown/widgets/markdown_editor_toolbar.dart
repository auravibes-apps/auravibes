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
  Widget build(BuildContext context) => AuraEdgy(
    child: _ToolbarActions(toolbar: this),
    axis: .horizontal,
    allowMouseDrag: true,
  );

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
        _toggleSelection('**');
      case .italic:
        _toggleSelection('*', alternateMarker: '_');
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
  void _toggleSelection(String marker, {String? alternateMarker}) {
    final selection = _safeSelection;
    final text = _controller.text;
    final toggle = _inlineToggleEdit(selection, text, marker, alternateMarker);
    if (!toggle.matchedSpan) {
      _wrapSelection(marker, marker);

      return;
    }

    final edit = toggle.edit;
    if (edit == null) return;

    _replace(edit.range, edit.content, edit.selection);
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
}

typedef _InlineToggleResult = ({bool matchedSpan, _InlineUnwrapEdit? edit});

_InlineToggleResult _inlineToggleEdit(
  TextSelection selection,
  String text,
  String marker,
  String? alternateMarker,
) {
  final bounds = _selectionBounds(selection, text);
  final markers = [marker, ?alternateMarker];
  final span = _matchingInlineSpan(text, bounds, markers);
  if (span == null) return (matchedSpan: false, edit: null);

  return (matchedSpan: true, edit: _inlineUnwrapEdit(selection, text, span));
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

typedef _InlineUnwrapEdit = ({
  TextSelection range,
  String content,
  TextSelection selection,
});

({int start, int end}) _selectionBounds(TextSelection selection, String text) {
  final start = selection.start.clamp(0, text.length);

  return (start: start, end: selection.end.clamp(start, text.length));
}

_InlineUnwrapEdit? _inlineUnwrapEdit(
  TextSelection selection,
  String text,
  ({int start, int contentStart, int contentEnd, int end}) span,
) {
  final bounds = _selectionBounds(selection, text);
  if (!_selectsWholeInlineSpan(bounds, span)) return null;

  final content = _textInside(text, span.contentStart, span.contentEnd);

  return (
    range: TextSelection(baseOffset: span.start, extentOffset: span.end),
    content: content,
    selection: _selectionAfterUnwrap(selection, span, content),
  );
}

bool _selectsWholeInlineSpan(
  ({int start, int end}) bounds,
  ({int start, int contentStart, int contentEnd, int end}) span,
) =>
    (bounds.start == span.contentStart && bounds.end == span.contentEnd) ||
    (bounds.start == span.start && bounds.end == span.end);

TextSelection _selectionAfterUnwrap(
  TextSelection selection,
  ({int start, int contentStart, int contentEnd, int end}) span,
  String content,
) {
  final start = span.start;
  final contentEnd = start + content.length;
  final isReversed = selection.baseOffset > selection.extentOffset;

  return TextSelection(
    baseOffset: isReversed ? contentEnd : start,
    extentOffset: isReversed ? start : contentEnd,
    affinity: selection.affinity,
    isDirectional: selection.isDirectional,
  );
}

({int start, int contentStart, int contentEnd, int end})? _matchingInlineSpan(
  String text,
  ({int start, int end}) selection,
  List<String> markers,
) {
  ({int start, int contentStart, int contentEnd, int end})? bestSpan;

  for (final marker in markers) {
    final span = _matchingSpanForMarker(text, selection, marker);
    if (_isNarrowerInlineSpan(bestSpan, span)) bestSpan = span;
  }

  return bestSpan;
}

bool _isNarrowerInlineSpan(
  ({int start, int contentStart, int contentEnd, int end})? current,
  ({int start, int contentStart, int contentEnd, int end})? candidate,
) =>
    candidate != null &&
    (current == null ||
        candidate.end - candidate.start < current.end - current.start);

({int start, int contentStart, int contentEnd, int end})?
_matchingSpanForMarker(
  String text,
  ({int start, int end}) selection,
  String marker,
) {
  var searchOffset = 0;
  while (searchOffset < text.length) {
    final span = _inlineSpanAt(text, marker, searchOffset);
    if (span == null) return null;
    if (selection.start >= span.start && selection.end <= span.end) return span;

    searchOffset = span.end;
  }

  return null;
}

({int start, int contentStart, int contentEnd, int end})? _inlineSpanAt(
  String text,
  String marker,
  int searchOffset,
) {
  final start = _nextInlineMarker(text, marker, searchOffset, opening: true);
  if (start == -1) return null;

  final contentStart = start + marker.length;
  final contentEnd = _nextInlineMarker(
    text,
    marker,
    contentStart,
    opening: false,
  );
  if (contentEnd == -1) return null;

  return (
    start: start,
    contentStart: contentStart,
    contentEnd: contentEnd,
    end: contentEnd + marker.length,
  );
}

extension on _MarkdownEditorToolbarState {
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
}

String _prefixReplacement(String selected, String prefix) => selected
    .split('\n')
    .map((line) => line.startsWith(prefix) ? line : '$prefix$line')
    .join('\n');

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

TextSelection _linkSourceRange(_LinkEditSnapshot snapshot) {
  final link = snapshot.link;
  if (link == null) return snapshot.selection;

  return TextSelection(baseOffset: link.start, extentOffset: link.end);
}

Future<({String text, String destination})?> _showLinkDialog(
  BuildContext context,
  _LinkEditSnapshot snapshot,
) => MarkdownLinkDialog.show(
  context,
  selectedText:
      snapshot.link?.label ??
      snapshot.selection.textInside(snapshot.value.text),
  selectedDestination: snapshot.link?.destination ?? '',
);

extension on _MarkdownEditorToolbarState {
  void _formatTaskList() {
    final selection = _safeSelection;
    final updated = _taskListValue(_controller.value, selection);
    if (updated == _controller.value) return;

    _controller.value = updated;
    _requestFocus();
  }

  Future<void> _formatLink(BuildContext context) async {
    final snapshot = _linkEditSnapshot();
    final result = await _showLinkDialog(context, snapshot);
    if (!context.mounted || _controller.text != snapshot.value.text) return;

    _completeLink(snapshot, result, context);
  }

  _LinkEditSnapshot _linkEditSnapshot() {
    final value = _controller.value;
    final selection = _safeSelection;

    return (
      value: value,
      selection: selection,
      link: _markdownLinkAtSelection(value.text, selection),
    );
  }

  void _applyLink(
    _LinkEditSnapshot snapshot,
    ({String label, String destination, bool isPlaceholder}) linkValue,
  ) {
    final sourceRange = _linkSourceRange(snapshot);
    final markdownLink = _markdownLinkText(linkValue);
    final start = snapshot.link?.start ?? sourceRange.start;
    final insertedSelection = _linkSelection(start, markdownLink, linkValue);
    _toolbarEdit(() => _replace(sourceRange, markdownLink, insertedSelection));
    _rememberAction(snapshot.value);
  }

  void _completeLink(
    _LinkEditSnapshot snapshot,
    ({String text, String destination})? result,
    BuildContext context,
  ) {
    if (result == null) {
      _restoreLinkValue(snapshot.value);

      return;
    }

    _applyLink(snapshot, _linkValue(result, context));
  }

  void _restoreLinkValue(TextEditingValue value) {
    if (_controller.value == value) return;

    _toolbarEdit(() => _controller.value = value);
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

    _toggleSelection('`');
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

String _markdownLinkText(
  ({String label, String destination, bool isPlaceholder}) value,
) => '[${value.label}](${value.destination})';

int _nextInlineMarker(
  String text,
  String marker,
  int start, {
  required bool opening,
}) {
  final search = (text: text, marker: marker, opening: opening);
  var offset = text.indexOf(marker, start);
  while (offset != -1) {
    final nextOffset = offset + marker.length;
    if (_isValidInlineMarker(search, offset, nextOffset)) return offset;

    offset = text.indexOf(marker, nextOffset);
  }

  return -1;
}

bool _isValidInlineMarker(
  _InlineMarkerSearch search,
  int offset,
  int nextOffset,
) {
  final text = search.text;
  if (_hasAdjacentInlineMarker(search, offset, nextOffset) ||
      _isEscapedMarkdownCharacter(text, offset)) {
    return false;
  }

  return search.marker[0] == '`' || _hasEmphasisBoundary(search, offset);
}

bool _hasAdjacentInlineMarker(
  _InlineMarkerSearch search,
  int offset,
  int nextOffset,
) {
  final marker = search.marker;
  final text = search.text;
  final markerCharacter = marker[0];
  final previousMatches = offset > 0 && text[offset - 1] == markerCharacter;
  final nextMatches =
      nextOffset < text.length && text[nextOffset] == markerCharacter;

  return previousMatches || nextMatches;
}

bool _hasEmphasisBoundary(_InlineMarkerSearch search, int offset) {
  final boundaryOffset = search.opening
      ? offset + search.marker.length
      : offset - 1;
  final text = search.text;
  if (boundaryOffset < 0 || boundaryOffset >= text.length) return false;

  return text[boundaryOffset].trim().isNotEmpty;
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

typedef _InlineMarkerSearch = ({String text, String marker, bool opening});

typedef _MarkdownLink = ({
  int start,
  int end,
  String label,
  String destination,
});
typedef _MarkdownLinkOffsets = ({int labelEnd, int destinationEnd});

typedef _LinkEditSnapshot = ({
  TextEditingValue value,
  TextSelection selection,
  _MarkdownLink? link,
});

_MarkdownLink? _markdownLinkAtSelection(String text, TextSelection selection) {
  _MarkdownLink? match;
  for (final link in _markdownLinks(text)) {
    if (!_selectionMatchesLink(selection, link)) continue;
    if (match != null) return null;

    match = link;
  }

  return match;
}

bool _selectionMatchesLink(TextSelection selection, _MarkdownLink link) =>
    selection.isCollapsed
    ? selection.start >= link.start && selection.start <= link.end
    : selection.start < link.end && selection.end > link.start;

List<_MarkdownLink> _markdownLinks(String text) {
  final links = <_MarkdownLink>[];
  var start = text.indexOf('[');
  while (start != -1) {
    final link = _markdownLinkAt(text, start);
    if (link == null) {
      start = text.indexOf('[', start + '['.length);
      continue;
    }

    links.add(link);
    start = text.indexOf('[', link.end);
  }

  return links;
}

_MarkdownLink? _markdownLinkAt(String text, int start) {
  if (!_isMarkdownLinkStart(text, start)) return null;
  final offsets = _markdownLinkOffsets(text, start);
  if (offsets == null) return null;

  return (
    start: start,
    end: offsets.destinationEnd + ')'.length,
    label: _textInside(text, start + '['.length, offsets.labelEnd),
    destination: _textInside(
      text,
      offsets.labelEnd + '(['.length,
      offsets.destinationEnd,
    ),
  );
}

bool _isMarkdownLinkStart(String text, int start) =>
    !_isEscapedMarkdownCharacter(text, start) &&
    !_isImageLinkStart(text, start);

_MarkdownLinkOffsets? _markdownLinkOffsets(String text, int start) {
  final labelEnd = _matchingMarkdownBracket(text, start);
  if (labelEnd == -1) return null;

  final destinationEnd = _markdownDestinationEnd(text, labelEnd);
  if (destinationEnd == null) return null;

  return (labelEnd: labelEnd, destinationEnd: destinationEnd);
}

bool _isImageLinkStart(String text, int start) =>
    start > 0 && text[start - '['.length] == '!';

int? _markdownDestinationEnd(String text, int labelEnd) {
  final openParenthesis = labelEnd + ']'.length;
  if (openParenthesis >= text.length || text[openParenthesis] != '(') {
    return null;
  }

  final destinationEnd = _matchingMarkdownParenthesis(text, openParenthesis);

  return destinationEnd == -1 ? null : destinationEnd;
}

int _matchingMarkdownBracket(String text, int start) {
  var depth = 1;
  for (var index = start + 1; index < text.length; index++) {
    if (_isEscapedMarkdownCharacter(text, index)) continue;
    if (text[index] == '[') depth++;
    if (text[index] == ']') {
      depth--;
      if (depth == 0) return index;
    }
  }

  return -1;
}

int _matchingMarkdownParenthesis(String text, int start) {
  var depth = 0;
  for (var index = start; index < text.length; index++) {
    if (_isEscapedMarkdownCharacter(text, index)) continue;
    if (text[index] == '(') depth++;
    if (text[index] == ')') {
      depth--;
      if (depth == 0) return index;
    }
  }

  return -1;
}

bool _isEscapedMarkdownCharacter(String text, int offset) {
  var backslashCount = 0;
  for (var index = offset - 1; index >= 0 && text[index] == r'\'; index--) {
    backslashCount++;
  }

  return backslashCount.isOdd;
}

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
