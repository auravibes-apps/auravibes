import 'dart:convert';

import 'package:auravibes_app/features/workspaces/models/workspace_csv_input.dart';
import 'package:csv/csv.dart';

class const WorkspaceCsvCodec() {
  WorkspaceCsvInput read(String source) {
    _sourceSize(source);

    try {
      return _input(_decode(source));
    } on FormatException catch (_, stackTrace) {
      Error.throwWithStackTrace(
        const WorkspaceCsvException('workspace_csv.invalid_file'),
        stackTrace,
      );
    }
  }

  WorkspaceCsvInput _input(List<List<dynamic>> rows) {
    final headers = (rows.firstOrNull ?? const []).cast<String>();
    _validate(rows, headers.length);

    return WorkspaceCsvInput(
      headers: headers,
      rows: rows.skip(1).map((row) => row.cast<String>()).toList(),
    );
  }

  List<List<dynamic>> _decode(String source) {
    final normalized = source.replaceFirst(RegExp(r'^\uFEFF'), '');
    _validateQuotes(normalized);

    return Csv(autoDetect: false, skipEmptyLines: false).decode(normalized);
  }

  void _validate(List<List<dynamic>> rows, int length) {
    if (rows.length < 2 || rows.skip(1).any((row) => row.length != length)) {
      throw const WorkspaceCsvException('workspace_csv.invalid_file');
    }
  }
}

enum _CsvQuoteState { fieldStart, unquoted, quoted, afterQuote }

typedef _CsvQuoteStep = ({_CsvQuoteState state, int skipped});

void _validateQuotes(String source) {
  var state = _CsvQuoteState.fieldStart;

  for (var index = 0; index < source.length; index++) {
    final step = _consumeQuoteCharacter(source, index, state);
    state = step.state;
    index += step.skipped;
  }

  if (state == _CsvQuoteState.quoted) {
    throw const FormatException('Unclosed quoted field');
  }
}

_CsvQuoteStep _consumeQuoteCharacter(
  String source,
  int index,
  _CsvQuoteState state,
) => switch (state) {
  .fieldStart => _consumeFieldStart(source[index]),
  .unquoted => _consumeUnquoted(source[index]),
  .quoted => _consumeQuoted(source, index),
  .afterQuote => _consumeAfterQuote(source[index]),
};

_CsvQuoteStep _consumeFieldStart(String character) {
  if (character == '"') {
    return (state: _CsvQuoteState.quoted, skipped: 0);
  }

  return _nextUnquotedField(character);
}

_CsvQuoteStep _consumeUnquoted(String character) {
  if (character == '"') {
    throw const FormatException('Quote inside unquoted field');
  }

  return _nextUnquotedField(character);
}

_CsvQuoteStep _consumeQuoted(String source, int index) {
  if (source[index] != '"') {
    return (state: _CsvQuoteState.quoted, skipped: 0);
  }
  if (!_isEscapedQuote(source, index)) {
    return (state: _CsvQuoteState.afterQuote, skipped: 0);
  }

  return (state: _CsvQuoteState.quoted, skipped: 1);
}

_CsvQuoteStep _consumeAfterQuote(String character) {
  if (!_isFieldSeparator(character)) {
    throw const FormatException('Unexpected character after closing quote');
  }

  return (state: _CsvQuoteState.fieldStart, skipped: 0);
}

_CsvQuoteStep _nextUnquotedField(String character) => (
  state: _isFieldSeparator(character)
      ? _CsvQuoteState.fieldStart
      : _CsvQuoteState.unquoted,
  skipped: 0,
);

bool _isFieldSeparator(String character) =>
    character == ',' || character == '\r' || character == '\n';

bool _isEscapedQuote(String source, int index) =>
    index + 1 < source.length && source[index + 1] == '"';

void _sourceSize(String source) {
  if (utf8.encode(source).length > WorkspaceCsvInput.maxSourceBytes) {
    throw const WorkspaceCsvException('workspace_csv.too_large');
  }
}
