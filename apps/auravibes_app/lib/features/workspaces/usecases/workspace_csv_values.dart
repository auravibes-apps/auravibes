import 'dart:convert';

import 'package:auravibes_app/features/workspaces/models/workspace_csv_input.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/usecases/workspace_csv_records.dart';

class const WorkspaceCsvValues(final WorkspaceCsvRepository repository) {
  Future<Object?> decode(WorkspaceColumn column, String value) async {
    if (column.type == .reference) return await _reference(column, value);

    return switch (column.type) {
      .number => num.parse(value),
      .checkbox => switch (value) {
        'true' => true,
        'false' => false,
        _ => throw const FormatException(),
      },
      .money || .multiSelect || .attachment => jsonDecode(value),
      _ => value.startsWith('"') ? jsonDecode(value) : value,
    };
  }

  Future<Object> _reference(WorkspaceColumn column, String value) async {
    final keys = column.referenceMultiple ? _keys(value) : [_key(value)];
    final ids = <String>[];
    for (final key in keys) {
      ids.add(
        await _resolve(
          column.targetTableId ?? (throw const WorkspaceTableException()),
          key,
        ),
      );
    }

    return column.referenceMultiple ? ids : ids.single;
  }

  Future<String> _resolve(String tableId, String key) async {
    final table = await repository.table(tableId);
    final matches = await _matches(table, key);
    if (matches.length != 1) throw const FormatException();

    return matches.single;
  }

  Future<List<String>> _matches(WorkspaceTable table, String key) async {
    final matches = <String>[];
    await for (final record in WorkspaceCsvRecords(repository)(table.id)) {
      if (record.id == key) return [record.id];
      if (record.values[table.labelColumnId] == key) matches.add(record.id);
    }

    return matches;
  }
}

List<String> _keys(String value) {
  final parsed = jsonDecode(value);
  if (parsed is! List || parsed.any((item) => item is! String)) {
    throw const FormatException();
  }

  return parsed.cast<String>();
}

String _key(String value) {
  final decoded = value.startsWith('"') ? jsonDecode(value) : value;
  if (decoded is! String) throw const FormatException();

  return decoded;
}
