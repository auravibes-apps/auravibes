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

void _validateQuotes(String source) {
  var quoted = false;
  var afterQuote = false;
  var fieldStart = true;

  for (var index = 0; index < source.length; index++) {
    final character = source[index];
    if (quoted) {
      if (character != '"') continue;
      if (index + 1 < source.length && source[index + 1] == '"') {
        index++;
      } else {
        quoted = false;
        afterQuote = true;
      }
      continue;
    }

    if (afterQuote) {
      if (character == ',') {
        afterQuote = false;
        fieldStart = true;
        continue;
      }
      if (character == '\r' || character == '\n') {
        afterQuote = false;
        fieldStart = true;
        if (character == '\r' &&
            index + 1 < source.length &&
            source[index + 1] == '\n') {
          index++;
        }
        continue;
      }
      throw const FormatException('Unexpected character after closing quote');
    }

    if (character == '"') {
      if (!fieldStart) {
        throw const FormatException('Quote inside unquoted field');
      }
      quoted = true;
      fieldStart = false;
      continue;
    }
    if (character == ',') {
      fieldStart = true;
      continue;
    }
    if (character == '\r' || character == '\n') {
      fieldStart = true;
      if (character == '\r' &&
          index + 1 < source.length &&
          source[index + 1] == '\n') {
        index++;
      }
      continue;
    }
    fieldStart = false;
  }

  if (quoted) throw const FormatException('Unclosed quoted field');
}

void _sourceSize(String source) {
  if (utf8.encode(source).length > WorkspaceCsvInput.maxSourceBytes) {
    throw const WorkspaceCsvException('workspace_csv.too_large');
  }
}
