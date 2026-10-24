import 'dart:convert';

import 'package:auravibes_app/features/workspaces/models/workspace_csv_input.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_reference_value.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/usecases/workspace_csv_records.dart';
import 'package:csv/csv.dart';

class const ExportWorkspaceCsvUsecase(
  final WorkspaceCsvRepository _repository,
) {
  Future<String> call(String tableId) async {
    final table = await _repository.table(tableId);
    final rows = <List<String>>[_headers(table)];
    await for (final record in WorkspaceCsvRecords(_repository)(tableId)) {
      rows.add(await _row(table, record));
    }

    return const ListToCsvConverter().convert(rows);
  }

  Future<List<String>> _row(
    WorkspaceTable table,
    WorkspaceRecord record,
  ) async {
    final row = <String>[_text(record.id)];
    for (final column in table.columns) {
      final value = _authorizedValue(record, column.id);
      row.add(_cell(column, value));
      if (column.type == .reference) {
        row.add(await _labels(column, value));
      }
    }

    return row;
  }

  Future<String> _labels(WorkspaceColumn column, Object? value) async {
    final ids = WorkspaceReferenceValue.ids(value);
    if (ids.isEmpty) return '';
    final target = await _labelTable(column.targetTableId);
    if (target == null) return '';
    final labels = await _Labels(_repository, target, ids).read();

    return column.referenceMultiple ? jsonEncode(labels) : _text(labels.single);
  }

  Future<WorkspaceTable?> _labelTable(String? id) async {
    if (id == null) throw const WorkspaceTableException();
    try {
      return await _repository.table(id);
    } on WorkspaceTableException catch (error) {
      if (error.denied || error.conflict) rethrow;

      return null;
    }
  }
}

String _cell(WorkspaceColumn column, Object? value) {
  if (value == null) return '';
  if (column.type == .reference && !column.referenceMultiple) {
    return _text(value as String);
  }

  return value is String ? _text(value) : jsonEncode(value);
}

List<String> _headers(WorkspaceTable table) => [
  'Record ID',
  for (final column in table.columns) ...[
    _text('${column.name} [${column.id}]'),
    if (column.type == .reference)
      _text('${column.name} labels [${column.id}]'),
  ],
];

String _text(String value) =>
    value.isEmpty ||
        value.startsWith('"') ||
        RegExp(r'^\s*[=+@-]').hasMatch(value)
    ? jsonEncode(value)
    : value;

Object? _authorizedValue(WorkspaceRecord record, String id) =>
    record.restrictedReferenceColumns.contains(id) ? null : record.values[id];

class _Labels(
  final WorkspaceCsvRepository repository,
  final WorkspaceTable table,
  final List<String> ids,
) {
  final found = <String, String>{};
  Future<List<String>> read() async {
    await for (final record in WorkspaceCsvRecords(repository)(table.id)) {
      _remember(record);
      if (found.length == ids.length) break;
    }

    return ids.map((id) => found[id] ?? '').toList();
  }

  void _remember(WorkspaceRecord record) {
    if (!ids.contains(record.id)) return;
    found[record.id] = record.values[table.labelColumnId] as String? ?? '';
  }
}
