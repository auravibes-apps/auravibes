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
    try {
      final rows = _decodeWith(normalized, '\r\n');
      if (rows.length > 1) return rows;
    } on FormatException {
      // Retry strict LF parsing; quoted CRLF content remains untouched.
    }

    return _decodeWith(normalized, '\n');
  }

  List<List<dynamic>> _decodeWith(String source, String eol) =>
      CsvToListConverter(
        eol: eol,
        shouldParseNumbers: false,
        allowInvalid: false,
      ).convert(source);

  void _validate(List<List<dynamic>> rows, int length) {
    if (rows.length < 2 || rows.skip(1).any((row) => row.length != length)) {
      throw const WorkspaceCsvException('workspace_csv.invalid_file');
    }
  }
}

void _sourceSize(String source) {
  if (utf8.encode(source).length > WorkspaceCsvInput.maxSourceBytes) {
    throw const WorkspaceCsvException('workspace_csv.too_large');
  }
}
