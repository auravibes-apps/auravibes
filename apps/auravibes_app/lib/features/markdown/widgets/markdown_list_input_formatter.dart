import 'package:flutter/services.dart';

final _listMarker = RegExp(r'^([ \t]*)(- \[[ xX]\] |- |\d+\. )');
final _numberedMarker = RegExp(r'^([ \t]*)(\d+)\. ');
const _numberGroup = 2;
const _noIndentation = 0;
const _oneCharacter = 1;
const _indentationWidth = 2;
const _firstOrderedNumber = 1;

typedef _ListLine = ({String text, int start, int end, RegExpMatch marker});
typedef _NumberEdit = ({int start, int end, String replacement});
typedef _NumberedBlock = ({int start, String indentation, int firstNumber});
typedef _OrderedGroup = ({int level, int start});
typedef _IndexRange = ({int first, int last});
typedef _NumberedLine = ({RegExpMatch marker, int number});
typedef _OldListItem = ({int indentation, int? number});
typedef _GroupChanges = ({
  Set<int> affected,
  Map<int, _OrderedGroup> oldGroups,
  Set<_OrderedGroup> movedGroups,
});
typedef _RenumberSource = ({
  List<String> lines,
  List<String> oldLines,
  _IndexRange range,
});
typedef _RenumberGroups = ({
  _GroupChanges changes,
  Map<int, _OrderedGroup> newGroups,
  Set<_OrderedGroup> touchedGroups,
});
typedef _RenumberContext = ({
  _RenumberSource source,
  _RenumberGroups groups,
  Map<int, int> nextNumbers,
});

/// Keeps Markdown list markers in the same edit as the user's keystroke.
class MarkdownListInputFormatter extends TextInputFormatter {
  const new();

  static TextEditingValue? adjustIndentation(
    TextEditingValue value, {
    required bool outdent,
  }) {
    if (!_canFormat(value, value)) return null;

    final affected = _affectedListLines(value, outdent: outdent);
    if (affected.isEmpty) return null;

    final edits = _indentationEdits(value.text, affected, outdent: outdent);
    final adjusted = _applyNumberEdits(value, edits);

    return _renumberIndentedBlock(adjusted, affected, oldText: value.text);
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (!_canFormat(oldValue, newValue)) return newValue;

    return _listEdit(oldValue, newValue) ??
        _renumberAfterLineChange(oldValue, newValue);
  }
}

Set<int> _affectedListLines(TextEditingValue value, {required bool outdent}) {
  final lines = value.text.split('\n');
  final range = _selectedLineRange(value);
  final affected = <int>{};
  for (var index = range.first; index <= range.last; index++) {
    _addAffectedListLine(lines, index, outdent: outdent, affected: affected);
  }

  return affected;
}

_IndexRange _selectedLineRange(TextEditingValue value) {
  final selection = value.selection;
  final lastOffset = selection.isCollapsed
      ? selection.end
      : selection.end - _oneCharacter;

  return (
    first: _lineIndex(value.text, selection.start),
    last: _lineIndex(value.text, lastOffset),
  );
}

void _addAffectedListLine(
  List<String> lines,
  int index, {
  required bool outdent,
  required Set<int> affected,
}) {
  final marker = _listMarker.firstMatch(lines[index]);
  if (marker == null) return;

  final indentation = _markerIndentation(marker);
  if (outdent && _outdentWidth(marker.group(1) ?? '') == _noIndentation) {
    return;
  }

  final _ = affected.add(index);
  _addIndentedDescendants(lines, index, indentation, affected);
}

void _addIndentedDescendants(
  List<String> lines,
  int index,
  int indentation,
  Set<int> affected,
) {
  for (var child = index + 1; child < lines.length; child++) {
    final childLine = lines[child];
    final childMarker = _listMarker.firstMatch(childLine);
    if (childMarker == null) {
      if (_isIndentedContinuation(childLine, indentation)) continue;
      break;
    }
    if (_markerIndentation(childMarker) <= indentation) break;

    final _ = affected.add(child);
  }
}

bool _isIndentedContinuation(String line, int indentation) =>
    line.trim().isNotEmpty && _leadingIndentation(line) > indentation;

List<_NumberEdit> _indentationEdits(
  String text,
  Set<int> affected, {
  required bool outdent,
}) {
  final lines = text.split('\n');
  final indices = affected.toList()..sort();

  return [
    for (final index in indices)
      _indentationEdit(lines, index, outdent: outdent),
  ];
}

_NumberEdit _indentationEdit(
  List<String> lines,
  int index, {
  required bool outdent,
}) {
  final start = _lineOffset(lines, index);
  final width = _outdentWidth(
    _listMarker.firstMatch(lines[index])?.group(1) ?? '',
  );

  return outdent
      ? (start: start, end: start + width, replacement: '')
      : (start: start, end: start, replacement: '  ');
}

int _outdentWidth(String indentation) {
  if (indentation.startsWith('\t')) return _oneCharacter;

  return indentation.length >= _indentationWidth
      ? _indentationWidth
      : _noIndentation;
}

int _markerIndentation(RegExpMatch marker) =>
    marker.group(1)?.length ?? _noIndentation;

_RenumberContext _renumberContext(
  TextEditingValue value,
  Set<int> affected,
  String oldText,
) {
  final source = _renumberSource(value, affected, oldText);

  return (
    source: source,
    groups: _renumberGroups(source, affected),
    nextNumbers: <int, int>{},
  );
}

_RenumberSource _renumberSource(
  TextEditingValue value,
  Set<int> affected,
  String oldText,
) {
  final lines = value.text.split('\n');

  return (
    lines: lines,
    oldLines: oldText.split('\n'),
    range: _expandedListRange(lines, affected),
  );
}

_RenumberGroups _renumberGroups(_RenumberSource source, Set<int> affected) {
  final oldGroups = _orderedGroups(source.oldLines, source.range);
  final newGroups = _orderedGroups(source.lines, source.range);
  final changes = _groupChanges(affected, oldGroups);

  return (
    changes: changes,
    newGroups: newGroups,
    touchedGroups: _touchedGroups(changes, newGroups),
  );
}

_GroupChanges _groupChanges(
  Set<int> affected,
  Map<int, _OrderedGroup> oldGroups,
) => (
  affected: affected,
  oldGroups: oldGroups,
  movedGroups: {for (final index in affected) ?oldGroups[index]},
);

TextEditingValue _renumberIndentedBlock(
  TextEditingValue value,
  Set<int> affected, {
  required String oldText,
}) {
  final context = _renumberContext(value, affected, oldText);
  final edits = _renumberEdits(context);

  return edits.isEmpty ? value : _applyNumberEdits(value, edits);
}

_IndexRange _expandedListRange(List<String> lines, Set<int> affected) {
  final bounds = _affectedListBounds(affected);

  return (
    first: _expandedListStart(lines, bounds.first),
    last: _expandedListEnd(lines, bounds.last),
  );
}

_IndexRange _affectedListBounds(Set<int> affected) => (
  first: affected.reduce((a, b) => a < b ? a : b),
  last: affected.reduce((a, b) => a > b ? a : b),
);

int _expandedListStart(List<String> lines, int first) {
  var start = first;
  while (start > _noIndentation &&
      _listMarker.hasMatch(lines[start - _oneCharacter])) {
    start--;
  }

  return start;
}

int _expandedListEnd(List<String> lines, int last) {
  var end = last;
  while (end + _oneCharacter < lines.length &&
      _listMarker.hasMatch(lines[end + _oneCharacter])) {
    end++;
  }

  return end;
}

Map<int, _OrderedGroup> _orderedGroups(List<String> lines, _IndexRange range) {
  final starts = <int, int>{};
  final groups = <int, _OrderedGroup>{};
  for (var index = range.first; index <= range.last; index++) {
    final group = _orderedGroupForLine(lines[index], index, starts);
    if (group == null) continue;

    groups[index] = group;
  }

  return groups;
}

_OrderedGroup? _orderedGroupForLine(
  String line,
  int index,
  Map<int, int> starts,
) {
  final marker = _listMarker.firstMatch(line);
  if (marker == null) return null;

  final level = _markerIndentation(marker);
  _removeDeeperOrderedGroups(starts, level);
  final numberedMarker = _numberedMarker.firstMatch(line);
  if (numberedMarker == null) {
    final _ = starts.remove(level);

    return null;
  }

  return (level: level, start: starts.putIfAbsent(level, () => index));
}

void _removeDeeperOrderedGroups(Map<int, int> starts, int level) {
  starts.removeWhere((depth, _) => depth > level);
}

Set<_OrderedGroup> _touchedGroups(
  _GroupChanges changes,
  Map<int, _OrderedGroup> newGroups,
) {
  final touchedGroups = <_OrderedGroup>{};
  for (final entry in newGroups.entries) {
    if (_isTouchedGroup(changes, entry.key, entry.value)) {
      final _ = touchedGroups.add(entry.value);
    }
  }

  return touchedGroups;
}

bool _isTouchedGroup(_GroupChanges changes, int index, _OrderedGroup group) =>
    changes.affected.contains(index) ||
    changes.oldGroups[index] != group ||
    changes.movedGroups.contains(changes.oldGroups[index]);

List<_NumberEdit> _renumberEdits(_RenumberContext context) {
  final edits = <_NumberEdit>[];
  for (
    var index = context.source.range.first;
    index <= context.source.range.last;
    index++
  ) {
    final edit = _renumberLine(context, index);
    if (edit != null) edits.add(edit);
  }

  return edits;
}

_NumberEdit? _renumberLine(_RenumberContext context, int index) {
  final numberedLine = _numberedLine(context, index);
  if (numberedLine == null) return null;

  final group = context.groups.newGroups[index];
  if (group == null || !context.groups.touchedGroups.contains(group)) {
    return null;
  }

  return _numberEdit(
    numberedLine.marker,
    numberedLine.number,
    _lineOffset(context.source.lines, index),
  );
}

_NumberedLine? _numberedLine(_RenumberContext context, int index) {
  final marker = _renumberMarker(context, index);
  if (marker == null) return null;

  return (
    marker: marker.marker,
    number: _currentLineNumber(context, index, marker.indentation),
  );
}

({RegExpMatch marker, int indentation})? _renumberMarker(
  _RenumberContext context,
  int index,
) {
  final line = context.source.lines[index];
  final listMarker = _listMarker.firstMatch(line);
  if (listMarker == null) return null;

  final indentation = _markerIndentation(listMarker);
  _prepareNumberSequence(context.nextNumbers, indentation);
  final numberedMarker = _numberedMarkerForLine(
    line,
    indentation,
    context.nextNumbers,
  );
  if (numberedMarker == null) return null;

  return (marker: numberedMarker, indentation: indentation);
}

RegExpMatch? _numberedMarkerForLine(
  String line,
  int indentation,
  Map<int, int> nextNumbers,
) {
  final marker = _numberedMarker.firstMatch(line);
  if (marker != null) return marker;

  final _ = nextNumbers.remove(indentation);

  return null;
}

void _prepareNumberSequence(Map<int, int> nextNumbers, int indentation) {
  nextNumbers.removeWhere((level, _) => level > indentation);
}

int _currentLineNumber(_RenumberContext context, int index, int indentation) {
  final number =
      context.nextNumbers[indentation] ??
      _oldGroupStartNumber(context, index, indentation);
  context.nextNumbers[indentation] = number + _oneCharacter;

  return number;
}

int _leadingIndentation(String line) =>
    RegExp(r'^[ \t]*').firstMatch(line)?.end ?? _noIndentation;

int _oldGroupStartNumber(
  _RenumberContext context,
  int index,
  int indentation,
) => _firstOldGroupNumber(context, index, indentation) ?? _firstOrderedNumber;

int? _firstOldGroupNumber(
  _RenumberContext context,
  int index,
  int indentation,
) => _firstPriorNumber(
  context.source.oldLines,
  index,
  context.source.range.first,
  indentation,
);

int? _firstPriorNumber(
  List<String> lines,
  int index,
  int firstLine,
  int indentation,
) {
  int? firstNumber;
  for (var previous = index; previous >= firstLine; previous--) {
    final item = _oldListItem(lines[previous]);
    if (item == null) break;
    if (_endsOldNumberGroup(item, indentation)) break;
    if (item.indentation > indentation) continue;
    firstNumber = item.number;
  }

  return firstNumber;
}

bool _endsOldNumberGroup(_OldListItem item, int indentation) =>
    item.indentation < indentation ||
    (item.indentation == indentation && item.number == null);

_OldListItem? _oldListItem(String line) {
  final marker = _listMarker.firstMatch(line);
  if (marker == null) return null;

  final numbered = _numberedMarker.firstMatch(line);

  return (
    indentation: _markerIndentation(marker),
    number: int.tryParse(numbered?.group(_numberGroup) ?? ''),
  );
}

bool _canFormat(TextEditingValue oldValue, TextEditingValue newValue) =>
    oldValue.selection.isValid &&
    newValue.selection.isValid &&
    newValue.composing.isCollapsed;

TextEditingValue? _listEdit(
  TextEditingValue oldValue,
  TextEditingValue newValue,
) {
  final line = _listLine(oldValue);
  if (line == null) return null;

  return _continueOrExitList(oldValue, newValue, line) ??
      _exitListWithBackspace(oldValue, newValue, line);
}

TextEditingValue _renumberAfterLineChange(
  TextEditingValue oldValue,
  TextEditingValue newValue,
) {
  final oldText = oldValue.text;
  final newText = newValue.text;
  if (_lineCount(oldText) == _lineCount(newText)) return newValue;

  return _renumber(
    newValue,
    oldText: oldText,
    changeOffset: _firstDifference(oldText, newText),
  );
}

_ListLine? _listLine(TextEditingValue value) {
  final text = value.text;
  final bounds = _lineBounds(text, value.selection.start);
  final line = _textInsideLine(text, bounds);
  final marker = _listMarker.firstMatch(line);
  if (marker == null) return null;

  return (text: line, start: bounds.start, end: bounds.end, marker: marker);
}

({int start, int end}) _lineBounds(String text, int position) =>
    (start: _lineStart(text, position), end: _lineEnd(text, position));

String _textInsideLine(String text, ({int start, int end}) bounds) =>
    TextSelection(
      baseOffset: bounds.start,
      extentOffset: bounds.end,
    ).textInside(text);

TextEditingValue? _continueOrExitList(
  TextEditingValue oldValue,
  TextEditingValue newValue,
  _ListLine line,
) {
  if (!_insertedNewline(oldValue, newValue)) return null;

  final marker = line.marker;
  if (oldValue.selection.start < line.start + marker.end) return newValue;
  if (_itemIsEmpty(line.text, marker.end)) return _exitList(oldValue, line);

  return _continueList(oldValue, line);
}

bool _insertedNewline(TextEditingValue oldValue, TextEditingValue newValue) {
  final selection = oldValue.selection;

  return selection.isCollapsed &&
      newValue.text ==
          oldValue.text.replaceRange(selection.start, selection.end, '\n');
}

TextEditingValue _continueList(TextEditingValue oldValue, _ListLine line) {
  final number = _numberedMarker.firstMatch(line.text)?.group(_numberGroup);
  final result = _insertAtSelection(
    oldValue,
    _continuation(line.marker, number),
  );
  if (number == null) return result;

  return _renumber(
    result,
    oldText: oldValue.text,
    changeOffset: result.selection.start,
  );
}

String _continuation(RegExpMatch marker, String? number) =>
    '\n${marker.group(1) ?? ''}${_nextMarker(marker, number)}';

TextEditingValue _insertAtSelection(TextEditingValue value, String insertion) {
  final start = value.selection.start;

  return .new(
    text: value.text.replaceRange(start, start, insertion),
    selection: .collapsed(offset: start + insertion.length),
  );
}

String _nextMarker(RegExpMatch marker, String? number) {
  if (number != null) return '${int.parse(number) + 1}. ';
  if (marker.group(_numberGroup)?.startsWith('- [') ?? false) return '- [ ] ';

  return '- ';
}

TextEditingValue? _exitListWithBackspace(
  TextEditingValue oldValue,
  TextEditingValue newValue,
  _ListLine line,
) {
  if (!_deletedEmptyMarker(oldValue, newValue, line)) return null;

  return _exitList(oldValue, line);
}

bool _deletedEmptyMarker(
  TextEditingValue oldValue,
  TextEditingValue newValue,
  _ListLine line,
) {
  final selection = oldValue.selection;
  if (!_itemIsEmpty(line.text, line.marker.end) || !selection.isCollapsed) {
    return false;
  }
  if (selection.start != line.start + line.marker.end) return false;

  return newValue.text ==
      oldValue.text.replaceRange(selection.start - 1, selection.start, '');
}

TextEditingValue _exitList(TextEditingValue oldValue, _ListLine line) {
  final start = line.start;
  final text = oldValue.text;

  return _renumber(
    .new(
      text: text.replaceRange(start, line.end, ''),
      selection: .collapsed(offset: start),
    ),
    oldText: text,
    changeOffset: start,
  );
}

TextEditingValue _renumber(
  TextEditingValue value, {
  required String oldText,
  required int changeOffset,
}) {
  final lines = value.text.split('\n');
  final block = _numberedBlock(value, oldText, changeOffset);
  if (block == null) return value;

  final edits = _numberEdits(lines, block);
  if (edits.isEmpty) return value;

  return _applyNumberEdits(value, edits);
}

_NumberedBlock? _numberedBlock(
  TextEditingValue value,
  String oldText,
  int changeOffset,
) {
  final text = value.text;
  final lines = text.split('\n');
  final start = _numberedBlockStart(lines, text, changeOffset);
  if (start == null) return null;

  final match = _numberedMarker.firstMatch(lines[start]);
  if (match == null) return null;

  return _numberedBlockFromMatch(
    start,
    match,
    _startingNumber(oldText, changeOffset),
  );
}

_NumberedBlock? _numberedBlockFromMatch(
  int start,
  RegExpMatch match,
  String? oldNumber,
) {
  final firstNumber = oldNumber ?? match.group(_numberGroup);
  if (firstNumber == null) return null;

  return (
    start: start,
    indentation: match.group(1) ?? '',
    firstNumber: int.parse(firstNumber),
  );
}

String? _startingNumber(String oldText, int changeOffset) {
  final lines = oldText.split('\n');
  final start = _numberedBlockStart(lines, oldText, changeOffset);
  if (start == null) return null;

  return _numberedMarker.firstMatch(lines[start])?.group(_numberGroup);
}

TextEditingValue _applyNumberEdits(
  TextEditingValue value,
  List<_NumberEdit> edits,
) => value.copyWith(
  text: _replaceNumberEdits(value.text, edits),
  selection: _numberSelection(value.selection, edits),
);

String _replaceNumberEdits(String text, List<_NumberEdit> edits) {
  var updated = text;
  for (final edit in edits.reversed) {
    updated = updated.replaceRange(edit.start, edit.end, edit.replacement);
  }

  return updated;
}

TextSelection _numberSelection(
  TextSelection selection,
  List<_NumberEdit> edits,
) => .new(
  baseOffset: _mappedOffset(selection.baseOffset, edits),
  extentOffset: _mappedOffset(selection.extentOffset, edits),
  affinity: selection.affinity,
  isDirectional: selection.isDirectional,
);

int? _numberedBlockStart(List<String> lines, String text, int offset) {
  final affected = _nearbyNumberedLine(lines, _lineIndex(text, offset));
  if (affected == null) return null;

  return _blockStart(lines, affected);
}

List<_NumberEdit> _numberEdits(List<String> lines, _NumberedBlock block) {
  var number = block.firstNumber;
  final edits = <_NumberEdit>[];
  for (final line in _numberedLines(lines, block)) {
    final edit = _numberEdit(line.marker, number, line.offset);
    if (edit != null) edits.add(edit);
    number++;
  }

  return edits;
}

Iterable<({RegExpMatch marker, int offset})> _numberedLines(
  List<String> lines,
  _NumberedBlock block,
) sync* {
  var offset = _lineOffset(lines, block.start);
  for (final line in lines.skip(block.start)) {
    if (_numberedMarker.firstMatch(line) case final marker?
        when marker.group(1) == block.indentation) {
      yield (marker: marker, offset: offset);
      offset = _nextLineOffset(offset, line);
    } else {
      return;
    }
  }
}

int _nextLineOffset(int offset, String line) =>
    offset + line.length + '\n'.length;

_NumberEdit? _numberEdit(RegExpMatch match, int number, int offset) {
  if (match.group(_numberGroup) == '$number') return null;

  return (
    start: offset + (match.group(1)?.length ?? 0),
    end: offset + match.end,
    replacement: '$number. ',
  );
}

int _lineOffset(List<String> lines, int index) => lines
    .take(index)
    .fold(0, (offset, line) => offset + line.length + '\n'.length);

int _mappedOffset(int offset, List<_NumberEdit> edits) {
  var shift = 0;
  for (final edit in edits) {
    final start = edit.start;
    final end = edit.end;
    if (_offsetPrecedesEdit(offset, start, end)) break;

    final mappedOffset = _offsetInsideEdit(offset, edit, shift);
    if (mappedOffset != null) return mappedOffset;

    shift = _shiftAfterEdit(edit, shift);
  }

  return offset + shift;
}

bool _offsetPrecedesEdit(int offset, int start, int end) =>
    offset < start || (offset == start && start != end);

int? _offsetInsideEdit(int offset, _NumberEdit edit, int shift) =>
    offset < edit.end ? edit.start + shift + edit.replacement.length : null;

int _shiftAfterEdit(_NumberEdit edit, int shift) =>
    shift + edit.replacement.length - (edit.end - edit.start);

int? _nearbyNumberedLine(List<String> lines, int index) {
  if (_numberedMarker.hasMatch(lines[index])) return index;
  if (index + 1 < lines.length && _numberedMarker.hasMatch(lines[index + 1])) {
    return index + 1;
  }
  if (index > 0 && _numberedMarker.hasMatch(lines[index - 1])) {
    return index - 1;
  }

  return null;
}

int _blockStart(List<String> lines, int index) {
  final indentation = _numberedMarker.firstMatch(lines[index])?.group(1);
  var current = index;
  while (current > 0 &&
      _numberedMarker.firstMatch(lines[current - 1])?.group(1) == indentation) {
    current--;
  }

  return current;
}

int _lineIndex(String text, int offset) {
  var count = 0;
  for (var i = 0; i < offset.clamp(0, text.length); i++) {
    if (text[i] == '\n') count++;
  }

  return count;
}

int _lineCount(String text) => '\n'.allMatches(text).length;

int _firstDifference(String oldText, String newText) {
  var index = 0;
  while (index < oldText.length &&
      index < newText.length &&
      oldText.codeUnitAt(index) == newText.codeUnitAt(index)) {
    index++;
  }

  return index;
}

int _lineStart(String text, int offset) =>
    offset == 0 ? 0 : text.lastIndexOf('\n', offset - 1) + 1;

int _lineEnd(String text, int offset) {
  final end = text.indexOf('\n', offset);

  return end == -1 ? text.length : end;
}

bool _itemIsEmpty(String line, int markerEnd) => TextSelection(
  baseOffset: markerEnd,
  extentOffset: line.length,
).textInside(line).trim().isEmpty;
