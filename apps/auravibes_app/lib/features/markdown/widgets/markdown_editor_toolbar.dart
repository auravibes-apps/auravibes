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
  required final MarkdownEditorShortcutController shortcutController,
  super.key,
}) extends StatefulWidget {
  @override
  State<MarkdownEditorToolbar> createState() => _MarkdownEditorToolbarState();
}

class _MarkdownEditorToolbarState extends State<MarkdownEditorToolbar> {
  final _history = _MarkdownToolbarHistory();
  String _lastText = '';

  TextEditingController get _controller => widget.controller;

  FocusNode get _focusNode => widget.focusNode;

  bool get _canUndo => _history.canUndo(_controller.text);

  bool get _canRedo => _history.canRedo(_controller.text);

  @override
  void initState() {
    super.initState();
    _lastText = _controller.text;
    widget.shortcutController._toolbarState = this;
  }

  @override
  void dispose() {
    if (identical(widget.shortcutController._toolbarState, this)) {
      widget.shortcutController._toolbarState = null;
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(MarkdownEditorToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shortcutController != widget.shortcutController) {
      if (identical(oldWidget.shortcutController._toolbarState, this)) {
        oldWidget.shortcutController._toolbarState = null;
      }
      widget.shortcutController._toolbarState = this;
    }
    if (oldWidget.controller == widget.controller) return;

    _lastText = _controller.text;
    _history.clear();
  }

  @override
  Widget build(BuildContext context) => AuraEdgy(
    child: _ToolbarActions(toolbar: this),
    axis: .horizontal,
    allowMouseDrag: true,
  );

  void _rememberAction(TextEditingValue before) =>
      _history.remember(before, _controller.value, setState);

  void _changeHistory({required bool undo}) {
    _history.change((
      undo: undo,
      controller: _controller,
      focusNode: _focusNode,
      onEdit: () => _lastText = _controller.text,
      setState: setState,
    ));
  }
}

extension on _MarkdownEditorToolbarState {
  void _applyShortcut(
    MarkdownEditorShortcutAction action,
    BuildContext context,
  ) {
    final toolbarAction = switch (action) {
      .bold => _ToolbarActionKind.bold,
      .italic => _ToolbarActionKind.italic,
      .code => _ToolbarActionKind.code,
      .link => _ToolbarActionKind.link,
    };
    _applyAction(toolbarAction, context);
  }

  void _toolbarEdit(VoidCallback edit) {
    edit();
    _lastText = _controller.text;
  }

  void _syncHistory(String text) {
    if (text == _lastText) return;

    _lastText = text;
    _history.clear();
  }

  TextSelection get _safeSelection {
    final selection = _controller.selection;
    if (selection.isValid) return selection;

    return TextSelection.collapsed(offset: _controller.text.length);
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
        _toggleBlockPrefix(action);
      case .bullets:
        _prefixLines('- ');
      case .numberedList:
        _prefixNumberedLines();
      case .taskList:
        _formatTaskList();
      case .quote:
        _toggleBlockPrefix(action);
      case .bold || .italic || .link || .code:
        break;
    }
  }
}

/// A Markdown formatting operation bound to an editor keyboard shortcut.
enum MarkdownEditorShortcutAction { bold, italic, code, link }

/// Dispatches keyboard actions to the Markdown editor toolbar.
class MarkdownEditorShortcutController {
  _MarkdownEditorToolbarState? _toolbarState;

  /// Applies [action] through the active toolbar.
  void invoke(MarkdownEditorShortcutAction action, BuildContext context) =>
      _toolbarState?._applyShortcut(action, context);
}

typedef _MarkdownHistoryAction = ({
  TextEditingValue before,
  TextEditingValue after,
});

typedef _MarkdownHistoryChange = ({
  bool undo,
  TextEditingController controller,
  FocusNode focusNode,
  void Function() onEdit,
  void Function(void Function()) setState,
});

class _MarkdownToolbarHistory {
  final _undoHistory = <_MarkdownHistoryAction>[];
  final _redoHistory = <_MarkdownHistoryAction>[];

  bool canUndo(String text) =>
      _undoHistory.isNotEmpty && text == _undoHistory.last.after.text;

  bool canRedo(String text) =>
      _redoHistory.isNotEmpty && text == _redoHistory.last.before.text;

  void clear() {
    _undoHistory.clear();
    _redoHistory.clear();
  }

  void remember(
    TextEditingValue before,
    TextEditingValue after,
    void Function(void Function()) setState,
  ) {
    if (after.text == before.text) return;

    setState(() {
      _undoHistory.add((before: before, after: after));
      _redoHistory.clear();
    });
  }

  void change(_MarkdownHistoryChange change) {
    final action = _take(change.undo, change.controller.text);
    if (action == null) return;

    _applyValue(action, change);
    _restoreFocus(change.focusNode);
    _pushAction(action, change);
  }

  void _applyValue(
    _MarkdownHistoryAction action,
    _MarkdownHistoryChange change,
  ) {
    change.controller.value = change.undo ? action.before : action.after;
    change.onEdit();
  }

  void _restoreFocus(FocusNode focusNode) {
    if (!focusNode.hasFocus) focusNode.requestFocus();
  }

  void _pushAction(
    _MarkdownHistoryAction action,
    _MarkdownHistoryChange change,
  ) {
    change.setState(() => _historyForDirection(change.undo).add(action));
  }

  _MarkdownHistoryAction? _take(bool undo, String text) {
    if (!(undo ? canUndo(text) : canRedo(text))) return null;

    return (undo ? _undoHistory : _redoHistory).removeLast();
  }

  List<_MarkdownHistoryAction> _historyForDirection(bool undo) =>
      undo ? _redoHistory : _undoHistory;
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

  void _toggleBlockPrefix(_ToolbarActionKind action) {
    final update = _toggleBlockPrefixUpdate(
      action,
      _safeSelection,
      _controller.text,
    );
    _replace(update.range, update.replacement, update.selection);
  }
}

typedef _LinePrefixEdit = ({int start, int removedLength, int insertedLength});
typedef _BlockPrefixUpdate = ({
  TextSelection range,
  String replacement,
  TextSelection selection,
});
typedef _BlockLinesUpdate = ({String replacement, List<_LinePrefixEdit> edits});
typedef _BlockLineUpdate = ({String line, _LinePrefixEdit? edit});
typedef _BlockPrefixPlan = ({
  List<int> markerLengths,
  bool removeMarkers,
  String prefix,
});
typedef _BlockLineContext = ({
  int markerLength,
  bool removeMarkers,
  String prefix,
  int lineOffset,
});

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

final _headingMarker = RegExp(r'^#{1,6}[ \t]+');

int _blockMarkerLength(String line, _ToolbarActionKind action) =>
    switch (action) {
      .heading => _headingMarker.matchAsPrefix(line)?.group(0)?.length ?? 0,
      .quote => line.startsWith(_quoteMarker) ? _quoteMarker.length : 0,
      _ => 0,
    };

String _blockPrefix(_ToolbarActionKind action) => switch (action) {
  .heading => '# ',
  .quote => _quoteMarker,
  _ => '',
};

_BlockPrefixUpdate _toggleBlockPrefixUpdate(
  _ToolbarActionKind action,
  TextSelection selection,
  String text,
) {
  final range = _lineRange(selection, text);
  final lines = range.textInside(text).split('\n');
  final plan = _blockPrefixPlan(action, lines);
  final transformed = _toggleBlockLines(lines, plan, range.start);

  return (
    range: range,
    replacement: transformed.replacement,
    selection: _selectionAfterLinePrefixEdits(selection, transformed.edits),
  );
}

_BlockPrefixPlan _blockPrefixPlan(
  _ToolbarActionKind action,
  List<String> lines,
) {
  final markerLengths = [
    for (final line in lines) _blockMarkerLength(line, action),
  ];

  return (
    markerLengths: markerLengths,
    removeMarkers: markerLengths.every((length) => length > 0),
    prefix: _blockPrefix(action),
  );
}

_BlockLinesUpdate _toggleBlockLines(
  List<String> lines,
  _BlockPrefixPlan plan,
  int startOffset,
) => _BlockPrefixLineBuilder(
  lines: lines,
  plan: plan,
  startOffset: startOffset,
).build();

class _BlockPrefixLineBuilder({
  required final List<String> lines,
  required final _BlockPrefixPlan plan,
  required final int startOffset,
}) {
  final List<_LinePrefixEdit> edits = [];
  final StringBuffer replacement = .new();
  int lineOffset = 0;
  int index = 0;

  _BlockLinesUpdate build() {
    lineOffset = startOffset;
    while (index < lines.length) {
      _appendNextLine();
    }

    return (replacement: replacement.toString(), edits: edits);
  }

  void _appendNextLine() {
    final line = lines[index];
    final context = _blockLineContext(index, lineOffset);
    final update = _toggleBlockLine(line, context);
    _appendUpdate(update, index);
    lineOffset += line.length + _lineBreakLength;
    index++;
  }

  _BlockLineContext _blockLineContext(int index, int offset) => (
    markerLength: plan.markerLengths[index],
    removeMarkers: plan.removeMarkers,
    prefix: plan.prefix,
    lineOffset: offset,
  );

  void _appendUpdate(_BlockLineUpdate update, int lineIndex) {
    replacement.write(update.line);
    if (lineIndex < lines.length - 1) replacement.write('\n');
    if (update.edit case final edit?) edits.add(edit);
  }
}

_BlockLineUpdate _toggleBlockLine(String line, _BlockLineContext context) {
  if (context.removeMarkers) {
    return (
      line: line.characters.skip(context.markerLength).toString(),
      edit: (
        start: context.lineOffset,
        removedLength: context.markerLength,
        insertedLength: 0,
      ),
    );
  }
  if (context.markerLength > 0) return (line: line, edit: null);

  return (
    line: '${context.prefix}$line',
    edit: (
      start: context.lineOffset,
      removedLength: 0,
      insertedLength: context.prefix.length,
    ),
  );
}

TextSelection _selectionAfterLinePrefixEdits(
  TextSelection selection,
  List<_LinePrefixEdit> edits,
) => TextSelection(
  baseOffset: _linePrefixSelectionOffset(selection.baseOffset, edits),
  extentOffset: _linePrefixSelectionOffset(selection.extentOffset, edits),
  affinity: selection.affinity,
  isDirectional: selection.isDirectional,
);

int _linePrefixSelectionOffset(int offset, List<_LinePrefixEdit> edits) {
  var shift = 0;
  for (final edit in edits) {
    final editStart = edit.start;
    if (offset < editStart) break;

    final removedEnd = editStart + edit.removedLength;
    if (offset <= removedEnd) {
      return editStart + shift + edit.insertedLength;
    }
    shift += edit.insertedLength - edit.removedLength;
  }

  return offset + shift;
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
        child: _ToolbarActionList(toolbar: toolbar, value: value),
      );
    },
  );
}

class const _ToolbarActionList({
  required final _MarkdownEditorToolbarState toolbar,
  required final TextEditingValue value,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraRow(
    children: [
      _ToolbarHistoryButton(toolbar: toolbar, isUndo: true),
      _ToolbarHistoryButton(toolbar: toolbar, isUndo: false),
      for (final action in _ToolbarActionKind.values)
        _ToolbarAction(toolbar: toolbar, action: action, value: value),
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
  if (isUndo) {
    return toolbar._canUndo ? () => toolbar._changeHistory(undo: true) : null;
  }

  return toolbar._canRedo ? () => toolbar._changeHistory(undo: false) : null;
}

class const _ToolbarAction({
  required final _MarkdownEditorToolbarState toolbar,
  required final _ToolbarActionKind action,
  required final TextEditingValue value,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      _ToolbarActionButton(toolbar: toolbar, action: action, value: value);
}

class const _ToolbarActionButton({
  required final _MarkdownEditorToolbarState toolbar,
  required final _ToolbarActionKind action,
  required final TextEditingValue value,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final presentation = _toolbarActionPresentation(action, value);

    return _ToolbarButton(
      icon: action.icon,
      label: action.labelKey.tr(context: context),
      onPressed: () => toolbar._applyAction(action, context),
      variant: presentation.variant,
      toggleState: presentation.state,
      toggleName: presentation.name,
    );
  }
}

typedef _ToolbarActionPresentation = ({
  AuraIconButtonVariant variant,
  _ToolbarActionState? state,
  String? name,
});

_ToolbarActionPresentation _toolbarActionPresentation(
  _ToolbarActionKind action,
  TextEditingValue value,
) {
  final state = switch (action) {
    .bold || .italic || .code => _inlineFormattingState(action, value),
    _ => null,
  };

  return (
    variant: state == .active ? .filled : .outlined,
    state: state,
    name: state == null ? null : action.name,
  );
}

enum _ToolbarActionState { inactive, active, mixed }

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
  final AuraIconButtonVariant variant = .outlined,
  final _ToolbarActionState? toggleState,
  final String? toggleName,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final button = _ToolbarIconButton(
      icon: icon,
      label: label,
      onPressed: onPressed,
      variant: variant,
    );
    final content = toggleState == .mixed
        ? _MixedFormattingButtonContent(child: button, toggleName: toggleName)
        : button;

    return ExcludeFocus(
      child: _ToolbarToggleSemantics(state: toggleState, child: content),
    );
  }
}

class const _ToolbarIconButton({
  required final IconData icon,
  required final String label,
  required final VoidCallback? onPressed,
  required final AuraIconButtonVariant variant,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraIconButton(
    icon: icon,
    onPressed: onPressed,
    disabled: onPressed == null,
    variant: variant,
    semanticLabel: label,
    tooltip: label,
  );
}

class const _MixedFormattingButtonContent({
  required final Widget child,
  required final String? toggleName,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: .none,
    children: [
      child,
      _MixedFormattingIndicator(toggleName: toggleName),
    ],
  );
}

class const _MixedFormattingIndicator({required final String? toggleName})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Positioned(
    right: _mixedIndicatorInset,
    bottom: _mixedIndicatorInset,
    child: IgnorePointer(
      child: ExcludeSemantics(
        child: DecoratedBox(
          key: ValueKey('markdown-toolbar-mixed-indicator-$toggleName'),
          decoration: BoxDecoration(
            color: context.auraColors.colorFor(.primary),
            borderRadius: const BorderRadius.all(.circular(1)),
          ),
          child: const SizedBox(width: 8, height: 2),
        ),
      ),
    ),
  );
}

class const _ToolbarToggleSemantics({
  required final _ToolbarActionState? state,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (state) {
    null => child,
    .mixed => Semantics(child: child, mixed: true),
    .active => Semantics(child: child, toggled: true),
    .inactive => Semantics(child: child, toggled: false),
  };
}

typedef _InlineFormattingSpan = ({
  int start,
  int contentStart,
  int contentEnd,
  int end,
});
typedef _InlineSpanScan = ({_InlineFormattingSpan? span, int? nextOffset});
typedef _CodeContentRange = ({int start, int end});
typedef _SelectionBounds = ({int start, int end});
typedef _MarkdownLine = ({int start, int end, int newlineOffset});
typedef _FenceContainerScan = ({
  _FenceContainerPrefix? prefix,
  int markerStart,
});
typedef _FencePrefixState = ({
  int markerStart,
  List<_FenceContainerPrefix> containerPrefixes,
});
typedef _FenceMarker = ({int markerCharacter, int markerLength, int infoStart});

const _quoteMarker = '> ';
const double _mixedIndicatorInset = 6;
const _lineBreakLength = 1;
const _singleCodeUnitLength = 1;
const _maximumFenceIndentation = 3;
const _minimumFenceMarkerLength = 3;
const _maximumListMarkerDigits = 9;
const _spaceCodeUnit = 0x20;
const _tabCodeUnit = 0x09;
const _carriageReturnCodeUnit = 0x0d;
const _plusCodeUnit = 0x2b;
const _minusCodeUnit = 0x2d;
const _asteriskCodeUnit = 0x2a;
const _periodCodeUnit = 0x2e;
const _rightParenthesisCodeUnit = 0x29;
const _zeroCodeUnit = 0x30;
const _nineCodeUnit = 0x39;
const _greaterThanCodeUnit = 0x3e;
const _backtickCodeUnit = 0x60;
const _tildeCodeUnit = 0x7e;

_ToolbarActionState _inlineFormattingState(
  _ToolbarActionKind action,
  TextEditingValue value,
) {
  final markers = _inlineFormattingMarkers(action);
  if (markers.isEmpty) return .inactive;

  final selection = _validFormattingSelection(value);
  final spans = _formattingSpansOutsideCode(action, value.text, markers);

  return _formattingStateForSelection(selection, value.text, spans);
}

List<String> _inlineFormattingMarkers(_ToolbarActionKind action) =>
    switch (action) {
      .bold => const ['**'],
      .italic => const ['*', '_'],
      .code => const ['`'],
      _ => const <String>[],
    };

TextSelection _validFormattingSelection(TextEditingValue value) =>
    value.selection.isValid
    ? value.selection
    : TextSelection.collapsed(offset: value.text.length);

List<_InlineFormattingSpan> _formattingSpansOutsideCode(
  _ToolbarActionKind action,
  String text,
  List<String> markers,
) {
  final spans = [
    for (final marker in markers) ..._inlineFormattingSpans(text, marker),
  ];
  final codeRanges = _codeContentRanges(action, text);

  return spans
      .where((span) => !_spanIsInsideCodeRange(span, codeRanges))
      .toList();
}

List<_CodeContentRange> _codeContentRanges(
  _ToolbarActionKind action,
  String text,
) => [
  if (action != .code)
    for (final span in _inlineFormattingSpans(text, '`'))
      (start: span.contentStart, end: span.contentEnd),
  ..._fencedCodeBlockContentRanges(text),
];

bool _spanIsInsideCodeRange(
  _InlineFormattingSpan span,
  List<_CodeContentRange> codeRanges,
) => codeRanges.any(
  (range) => span.start >= range.start && span.end <= range.end,
);

_ToolbarActionState _formattingStateForSelection(
  TextSelection selection,
  String text,
  List<_InlineFormattingSpan> spans,
) {
  final bounds = _selectionBounds(selection, text);
  if (selection.isCollapsed) {
    return _isCursorInsideFormattingContent(bounds.start, spans)
        ? .active
        : .inactive;
  }
  if (spans.any((span) => _selectionMatchesFormattingSpan(bounds, span))) {
    return .active;
  }
  if (spans.any((span) => _selectionOverlapsFormattingContent(bounds, span))) {
    return .mixed;
  }

  return .inactive;
}

bool _isCursorInsideFormattingContent(
  int offset,
  List<_InlineFormattingSpan> spans,
) => spans.any(
  (span) => offset >= span.contentStart && offset <= span.contentEnd,
);

bool _selectionMatchesFormattingSpan(
  _SelectionBounds bounds,
  _InlineFormattingSpan span,
) {
  final withinContent =
      bounds.start >= span.contentStart && bounds.end <= span.contentEnd;
  final matchesWholeSpan = bounds.start == span.start && bounds.end == span.end;

  return withinContent || matchesWholeSpan;
}

bool _selectionOverlapsFormattingContent(
  _SelectionBounds bounds,
  _InlineFormattingSpan span,
) => span.contentStart < bounds.end && span.contentEnd > bounds.start;

List<_InlineFormattingSpan> _inlineFormattingSpans(String text, String marker) {
  final spans = <_InlineFormattingSpan>[];
  var searchOffset = 0;
  while (searchOffset < text.length) {
    final scan = _inlineSpanScanAt(text, marker, searchOffset);
    if (scan.span case final span?) spans.add(span);
    final nextOffset = scan.nextOffset;
    if (nextOffset == null) break;
    searchOffset = nextOffset;
  }

  return spans;
}

_InlineSpanScan _inlineSpanScanAt(
  String text,
  String marker,
  int searchOffset,
) {
  final span = _inlineSpanAt(text, marker, searchOffset);
  if (span != null) return (span: span, nextOffset: span.end);

  final unmatchedStart = _nextInlineMarker(
    text,
    marker,
    searchOffset,
    opening: true,
  );
  if (unmatchedStart == -1) return (span: null, nextOffset: null);

  return (span: null, nextOffset: unmatchedStart + marker.length);
}

List<({int start, int end})> _fencedCodeBlockContentRanges(String text) {
  return _FencedCodeBlockScanner(text: text).scan();
}

typedef _FenceContainerPrefix = ({bool isBlockQuote, int indent});
typedef _FencedCodeFence = ({
  int markerCharacter,
  int markerLength,
  int infoStart,
  List<_FenceContainerPrefix> containerPrefixes,
});

class _FencedCodeBlockScanner({required final String text}) {
  final List<_CodeContentRange> ranges = [];
  _FencedCodeFence? openFence;
  int? contentStart;
  int lineStart = 0;

  List<_CodeContentRange> scan() {
    while (lineStart <= text.length) {
      final line = _markdownLineAt(text, lineStart);
      _processLine(line);
      if (line.newlineOffset == -1) break;
      lineStart = line.newlineOffset + _lineBreakLength;
    }
    _addUnclosedContentRange();

    return ranges;
  }

  void _processLine(_MarkdownLine line) {
    final fence = _candidateFence(line);
    if (openFence == null) {
      _startFence(fence, line);
    } else if (_isClosingFence(fence, line)) {
      _closeFence(line.start);
    }
  }

  _FencedCodeFence? _candidateFence(_MarkdownLine line) {
    final currentFence = openFence;
    if (currentFence == null) {
      return _fencedCodeFenceAt(text, line.start, line.end);
    }

    return _fencedCodeClosingFenceAt(
      text,
      line.start,
      line.end,
      currentFence.containerPrefixes,
    );
  }

  bool _isClosingFence(_FencedCodeFence? fence, _MarkdownLine line) {
    final currentFence = openFence;
    if (fence == null || currentFence == null) return false;

    return fence.markerCharacter == currentFence.markerCharacter &&
        fence.markerLength >= currentFence.markerLength &&
        _isCodeFenceWhitespace(text, fence.infoStart, line.end);
  }

  void _startFence(_FencedCodeFence? fence, _MarkdownLine line) {
    if (fence == null) return;

    openFence = fence;
    contentStart = line.end < text.length
        ? line.end + _lineBreakLength
        : text.length;
  }

  void _closeFence(int lineStart) {
    final activeContentStart = contentStart;
    if (activeContentStart != null) {
      ranges.add((start: activeContentStart, end: lineStart));
    }
    openFence = null;
    contentStart = null;
  }

  void _addUnclosedContentRange() {
    final activeContentStart = contentStart;
    if (activeContentStart != null) {
      ranges.add((start: activeContentStart, end: text.length));
    }
  }
}

_MarkdownLine _markdownLineAt(String text, int start) {
  final newlineOffset = text.indexOf('\n', start);

  return (
    start: start,
    end: newlineOffset == -1 ? text.length : newlineOffset,
    newlineOffset: newlineOffset,
  );
}

_FencedCodeFence? _fencedCodeFenceAt(String text, int lineStart, int lineEnd) {
  final state = _fencedCodePrefixState(text, lineStart, lineEnd);

  return _openingFenceAt(
    text,
    state.markerStart,
    lineEnd,
    state.containerPrefixes,
  );
}

_FencePrefixState _fencedCodePrefixState(
  String text,
  int lineStart,
  int lineEnd,
) => _FencePrefixScanner(
  text: text,
  initialMarkerStart: lineStart,
  lineEnd: lineEnd,
).scan();

class _FencePrefixScanner({
  required final String text,
  required final int initialMarkerStart,
  required final int lineEnd,
}) {
  final List<_FenceContainerPrefix> containerPrefixes = [];
  int markerStart = initialMarkerStart;
  int containerEnd = initialMarkerStart;

  _FencePrefixState scan() {
    while (markerStart < lineEnd) {
      if (!_scanNextPrefix()) break;
    }

    return (markerStart: markerStart, containerPrefixes: containerPrefixes);
  }

  bool _scanNextPrefix() {
    final scan = _nextFenceContainerPrefix(
      text,
      markerStart,
      lineEnd,
      containerEnd,
    );
    markerStart = scan.markerStart;
    final prefix = scan.prefix;
    if (prefix == null) return false;

    containerEnd = markerStart;
    containerPrefixes.add(prefix);

    return true;
  }
}

_FenceContainerScan _nextFenceContainerPrefix(
  String text,
  int markerStart,
  int lineEnd,
  int containerEnd,
) {
  final prefixStart = _skipFenceIndentation(text, markerStart, lineEnd);
  final scan = _fenceContainerPrefixAt(
    text,
    prefixStart,
    lineEnd,
    containerEnd,
  );

  return scan ?? (prefix: null, markerStart: prefixStart);
}

_FenceContainerScan? _fenceContainerPrefixAt(
  String text,
  int markerStart,
  int lineEnd,
  int containerEnd,
) {
  if (_isCodeUnitAt(text, markerStart, lineEnd, _greaterThanCodeUnit)) {
    return _blockQuoteFencePrefixAt(text, markerStart, lineEnd);
  }

  return _listFencePrefixAt(text, markerStart, lineEnd, containerEnd);
}

_FenceContainerScan _blockQuoteFencePrefixAt(
  String text,
  int markerStart,
  int lineEnd,
) => (
  prefix: (isBlockQuote: true, indent: 0),
  markerStart: _skipOptionalMarkdownWhitespace(
    text,
    markerStart + _singleCodeUnitLength,
    lineEnd,
  ),
);

_FenceContainerScan? _listFencePrefixAt(
  String text,
  int markerStart,
  int lineEnd,
  int containerEnd,
) {
  final listMarkerEnd = _markdownListMarkerEnd(text, markerStart, lineEnd);
  if (listMarkerEnd == null) return null;
  final nextMarkerStart = _skipOptionalMarkdownWhitespace(
    text,
    listMarkerEnd,
    lineEnd,
  );

  return (
    prefix: (isBlockQuote: false, indent: nextMarkerStart - containerEnd),
    markerStart: nextMarkerStart,
  );
}

_FencedCodeFence? _openingFenceAt(
  String text,
  int markerStart,
  int lineEnd,
  List<_FenceContainerPrefix> containerPrefixes,
) {
  final marker = _fencedCodeMarkerAt(text, markerStart, lineEnd);
  if (marker == null || !_isValidOpeningFence(text, marker, lineEnd)) {
    return null;
  }

  return _fenceWithPrefixes(marker, containerPrefixes);
}

bool _isValidOpeningFence(String text, _FenceMarker marker, int lineEnd) {
  final hasBacktickInfo =
      marker.markerCharacter == _backtickCodeUnit &&
      _containsCodeUnit(text, marker.infoStart, lineEnd, _backtickCodeUnit);

  return !hasBacktickInfo;
}

_FencedCodeFence _fenceWithPrefixes(
  _FenceMarker marker,
  List<_FenceContainerPrefix> containerPrefixes,
) => (
  markerCharacter: marker.markerCharacter,
  markerLength: marker.markerLength,
  infoStart: marker.infoStart,
  containerPrefixes: containerPrefixes,
);

int _skipFenceIndentation(String text, int start, int end) {
  var cursor = start;
  while (_isCodeUnitAt(text, cursor, end, _spaceCodeUnit) &&
      cursor - start < _maximumFenceIndentation) {
    cursor++;
  }

  return cursor;
}

int _skipOptionalMarkdownWhitespace(String text, int start, int end) =>
    _isWhitespaceAt(text, start, end) ? start + _singleCodeUnitLength : start;

bool _isCodeUnitAt(String text, int offset, int end, int expected) =>
    offset < end && text.codeUnitAt(offset) == expected;

bool _isWhitespaceAt(String text, int offset, int end) =>
    offset < end && _isMarkdownWhitespace(text.codeUnitAt(offset));

_FencedCodeFence? _fencedCodeClosingFenceAt(
  String text,
  int lineStart,
  int lineEnd,
  List<_FenceContainerPrefix> containerPrefixes,
) {
  final markerStart = _closingFenceMarkerStart(
    text,
    lineStart,
    lineEnd,
    containerPrefixes,
  );
  if (markerStart == null) return null;

  final marker = _fencedCodeMarkerAt(text, markerStart, lineEnd);
  if (marker == null) return null;

  return _fenceWithPrefixes(marker, containerPrefixes);
}

int? _closingFenceMarkerStart(
  String text,
  int lineStart,
  int lineEnd,
  List<_FenceContainerPrefix> containerPrefixes,
) {
  var markerStart = lineStart;
  for (final prefix in containerPrefixes) {
    final nextMarkerStart = prefix.isBlockQuote
        ? _blockQuoteContinuationStart(text, markerStart, lineEnd)
        : _listContinuationStart(text, markerStart, lineEnd, prefix.indent);
    if (nextMarkerStart == null) return null;
    markerStart = nextMarkerStart;
  }

  return _skipFenceIndentation(text, markerStart, lineEnd);
}

int? _blockQuoteContinuationStart(String text, int start, int end) {
  final quoteStart = _skipFenceIndentation(text, start, end);
  if (!_isCodeUnitAt(text, quoteStart, end, _greaterThanCodeUnit)) return null;

  return _skipOptionalMarkdownWhitespace(
    text,
    quoteStart + _singleCodeUnitLength,
    end,
  );
}

int? _listContinuationStart(String text, int start, int end, int indent) {
  var cursor = start;
  for (var count = 0; count < indent; count++) {
    if (!_isWhitespaceAt(text, cursor, end)) return null;
    cursor++;
  }

  return cursor;
}

_FenceMarker? _fencedCodeMarkerAt(String text, int markerStart, int lineEnd) {
  if (markerStart >= lineEnd) return null;

  final markerCharacter = text.codeUnitAt(markerStart);
  if (!_isFenceMarkerCharacter(markerCharacter)) return null;

  final markerEnd = _fenceMarkerEnd(
    text,
    markerStart,
    lineEnd,
    markerCharacter,
  );
  final markerLength = markerEnd - markerStart;
  if (markerLength < _minimumFenceMarkerLength) return null;

  return (
    markerCharacter: markerCharacter,
    markerLength: markerLength,
    infoStart: markerEnd,
  );
}

bool _isFenceMarkerCharacter(int character) =>
    character == _backtickCodeUnit || character == _tildeCodeUnit;

int _fenceMarkerEnd(String text, int start, int end, int markerCharacter) {
  var cursor = start;
  while (_isCodeUnitAt(text, cursor, end, markerCharacter)) {
    cursor++;
  }

  return cursor;
}

int? _markdownListMarkerEnd(String text, int start, int end) {
  if (start >= end) return null;

  final firstCharacter = text.codeUnitAt(start);
  if (_isUnorderedListMarker(firstCharacter)) {
    return _unorderedListMarkerEnd(text, start, end);
  }

  return _orderedListMarkerEnd(text, start, end);
}

bool _isUnorderedListMarker(int character) =>
    character == _plusCodeUnit ||
    character == _minusCodeUnit ||
    character == _asteriskCodeUnit;

int? _unorderedListMarkerEnd(String text, int start, int end) {
  final markerEnd = start + _singleCodeUnitLength;
  if (markerEnd == end || _isWhitespaceAt(text, markerEnd, end)) {
    return markerEnd;
  }

  return null;
}

int? _orderedListMarkerEnd(String text, int start, int end) {
  final numberEnd = _listNumberEnd(text, start, end);
  if (numberEnd == null || numberEnd == end) return null;

  final delimiter = text.codeUnitAt(numberEnd);
  if (!_isOrderedListDelimiter(delimiter)) return null;
  final markerEnd = numberEnd + _singleCodeUnitLength;
  if (!_isWhitespaceAt(text, markerEnd, end) && markerEnd != end) return null;

  return markerEnd;
}

int? _listNumberEnd(String text, int start, int end) {
  if (!_isAsciiDigit(text.codeUnitAt(start))) return null;
  var cursor = start;
  while (cursor < end && _isAsciiDigit(text.codeUnitAt(cursor))) {
    cursor++;
    if (cursor - start > _maximumListMarkerDigits) return null;
  }

  return cursor;
}

bool _isAsciiDigit(int character) =>
    character >= _zeroCodeUnit && character <= _nineCodeUnit;

bool _isOrderedListDelimiter(int character) =>
    character == _periodCodeUnit || character == _rightParenthesisCodeUnit;

bool _isMarkdownWhitespace(int codeUnit) =>
    codeUnit == _spaceCodeUnit || codeUnit == _tabCodeUnit;

bool _containsCodeUnit(String text, int start, int end, int target) {
  for (var offset = start; offset < end; offset++) {
    if (text.codeUnitAt(offset) == target) return true;
  }

  return false;
}

bool _isCodeFenceWhitespace(String text, int start, int end) {
  for (var offset = start; offset < end; offset++) {
    final codeUnit = text.codeUnitAt(offset);
    if (codeUnit != _spaceCodeUnit &&
        codeUnit != _tabCodeUnit &&
        codeUnit != _carriageReturnCodeUnit) {
      return false;
    }
  }

  return true;
}
