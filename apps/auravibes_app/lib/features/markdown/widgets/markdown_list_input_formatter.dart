import 'package:flutter/services.dart';

final _listMarker = RegExp(r'^([ \t]*)(- \[[ xX]\] |- |\d+\. )');
final _numberedMarker = RegExp(r'^([ \t]*)(\d+)\. ');
const _numberGroup = 2;

typedef _ListLine = ({String text, int start, int end, RegExpMatch marker});
typedef _NumberEdit = ({int start, int end, String replacement});
typedef _NumberedBlock = ({int start, String indentation, int firstNumber});
typedef _OrderedGroup = ({int level, int start});

/// Keeps Markdown list markers in the same edit as the user's keystroke.
class MarkdownListInputFormatter extends TextInputFormatter {
  const new();

  static TextEditingValue? adjustIndentation(
    TextEditingValue value, {
    required bool outdent,
  }) {
    if (!value.selection.isValid || !value.composing.isCollapsed) return null;

    final lines = value.text.split('\n');
    final first = _lineIndex(value.text, value.selection.start);
    final last = _lineIndex(
      value.text,
      value.selection.isCollapsed
          ? value.selection.end
          : value.selection.end - 1,
    );
    final affected = <int>{};
    for (var index = first; index <= last; index++) {
      final marker = _listMarker.firstMatch(lines[index]);
      if (marker == null) continue;
      final indentation = marker.group(1)?.length ?? 0;
      if (outdent && _outdentWidth(marker.group(1) ?? '') == 0) continue;
      final _ = affected.add(index);
      for (var child = index + 1; child < lines.length; child++) {
        final childMarker = _listMarker.firstMatch(lines[child]);
        if (childMarker == null) {
          if (lines[child].trim().isNotEmpty &&
              _leadingIndentation(lines[child]) > indentation) {
            continue;
          }
          break;
        }
        if ((childMarker.group(1)?.length ?? 0) <= indentation) {
          break;
        }
        final _ = affected.add(child);
      }
    }
    if (affected.isEmpty) return null;

    final edits = <_NumberEdit>[];
    for (final index in affected.toList()..sort()) {
      final start = _lineOffset(lines, index);
      final width = _outdentWidth(
        _listMarker.firstMatch(lines[index])?.group(1) ?? '',
      );
      edits.add(
        outdent
            ? (start: start, end: start + width, replacement: '')
            : (start: start, end: start, replacement: '  '),
      );
    }
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

int _outdentWidth(String indentation) {
  if (indentation.startsWith('\t')) return 1;

  return indentation.length >= 2 ? 2 : 0;
}

TextEditingValue _renumberIndentedBlock(
  TextEditingValue value,
  Set<int> affected, {
  required String oldText,
}) {
  final lines = value.text.split('\n');
  var first = affected.reduce((a, b) => a < b ? a : b);
  var last = affected.reduce((a, b) => a > b ? a : b);
  while (first > 0 && _listMarker.hasMatch(lines[first - 1])) {
    first--;
  }
  while (last + 1 < lines.length && _listMarker.hasMatch(lines[last + 1])) {
    last++;
  }

  final oldLines = oldText.split('\n');
  final oldGroups = _orderedGroups(oldLines, first, last);
  final newGroups = _orderedGroups(lines, first, last);
  final movedGroups = {for (final index in affected) ?oldGroups[index]};
  final touchedGroups = <_OrderedGroup>{};
  for (final entry in newGroups.entries) {
    final index = entry.key;
    if (affected.contains(index) ||
        oldGroups[index] != entry.value ||
        movedGroups.contains(oldGroups[index])) {
      final _ = touchedGroups.add(entry.value);
    }
  }

  final nextNumbers = <int, int>{};
  final edits = <_NumberEdit>[];
  for (var index = first; index <= last; index++) {
    final marker = _listMarker.firstMatch(lines[index]);
    if (marker == null) continue;
    final indentation = marker.group(1)?.length ?? 0;
    nextNumbers.removeWhere((level, _) => level > indentation);
    final numbered = _numberedMarker.firstMatch(lines[index]);
    if (numbered == null) {
      final _ = nextNumbers.remove(indentation);
      continue;
    }
    final number =
        nextNumbers[indentation] ??
        _oldGroupStartNumber(oldLines, index, first, indentation);
    final edit = _numberEdit(numbered, number, _lineOffset(lines, index));
    if (edit != null && touchedGroups.contains(newGroups[index])) {
      edits.add(edit);
    }
    nextNumbers[indentation] = number + 1;
  }

  return edits.isEmpty ? value : _applyNumberEdits(value, edits);
}

Map<int, _OrderedGroup> _orderedGroups(
  List<String> lines,
  int first,
  int last,
) {
  final starts = <int, int>{};
  final groups = <int, _OrderedGroup>{};
  for (var index = first; index <= last; index++) {
    final marker = _listMarker.firstMatch(lines[index]);
    if (marker == null) continue;
    final level = marker.group(1)?.length ?? 0;
    starts.removeWhere((depth, _) => depth > level);
    if (!_numberedMarker.hasMatch(lines[index])) {
      final _ = starts.remove(level);
      continue;
    }
    final start = starts.putIfAbsent(level, () => index);
    groups[index] = (level: level, start: start);
  }

  return groups;
}

int _leadingIndentation(String line) =>
    RegExp(r'^[ \t]*').firstMatch(line)?.end ?? 0;

int _oldGroupStartNumber(
  List<String> lines,
  int index,
  int first,
  int indentation,
) {
  int? firstNumber;
  for (var previous = index; previous >= first; previous--) {
    final marker = _listMarker.firstMatch(lines[previous]);
    if (marker == null) break;
    final level = marker.group(1)?.length ?? 0;
    if (level < indentation) break;
    if (level > indentation) continue;
    final numbered = _numberedMarker.firstMatch(lines[previous]);
    if (numbered == null) break;
    final numberText = numbered.group(_numberGroup);
    if (numberText == null) break;
    firstNumber = int.parse(numberText);
  }

  return firstNumber ?? 1;
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
    if (offset < edit.start ||
        (offset == edit.start && edit.start != edit.end)) {
      break;
    }
    if (offset < edit.end) {
      return edit.start + shift + edit.replacement.length;
    }
    shift += edit.replacement.length - (edit.end - edit.start);
  }

  return offset + shift;
}

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
