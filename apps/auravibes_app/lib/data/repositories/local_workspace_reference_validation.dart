import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/workspace_tables.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_reference_value.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:drift/drift.dart';

class const LocalWorkspaceReferenceValidation(
  final AppDatabase database,
  final String workspaceId,
) {
  // Shortcut: Scan active links. Add indexes after #1680 measures capacity.
  Future<void> allDependencies() => _LocalDependencies(this).all();

  Future<void> columns(List<WorkspaceColumn> columns) async {
    for (final column in columns.where((column) => column.type == .reference)) {
      await _table(_targetId(column));
      await _LocalDependencies(this).column(columns, column);
      await _defaults(columns, column);
    }
  }

  Future<void> values(
    List<WorkspaceColumn> columns,
    Map<String, Object?> values,
  ) async {
    for (final column in columns.where((column) => column.type == .reference)) {
      final ids = WorkspaceReferenceValue.ids(values[column.id]);
      for (final id in ids) {
        final record = await _record(_targetId(column), id);
        _match(column, values, record);
      }
    }
  }

  Future<void> _defaults(
    List<WorkspaceColumn> columns,
    WorkspaceColumn column,
  ) async {
    if (column.defaultValue == null) return;
    for (final id in WorkspaceReferenceValue.ids(column.defaultValue)) {
      final _ = await _record(_targetId(column), id);
    }
    final defaults = _defaultsMap(columns);
    if (column.dependsOnColumnId != null &&
        defaults.containsKey(column.dependsOnColumnId)) {
      await values([column], defaults);
    }
  }

  Future<void> _table(String id) async {
    final query = database.select(database.workspaceTables)
      ..where((row) => _tableMatches(row, id));
    if (await query.getSingleOrNull() == null) {
      throw const WorkspaceTableException();
    }
  }

  Future<Map<String, Object?>> _record(String tableId, String id) async {
    final query = database.select(database.workspaceTableRecords)
      ..where((row) => _recordMatches(row, (id: id, tableId: tableId)));
    final row = await query.getSingleOrNull();
    if (row == null) throw const WorkspaceTableException();

    return _decode(row.valuesJson);
  }

  Expression<bool> _tableMatches(WorkspaceTables row, String id) =>
      row.id.equals(id) &
      row.workspaceId.equals(workspaceId) &
      row.deletedAt.isNull();
  Expression<bool> _recordMatches(
    WorkspaceTableRecords row,
    ({String id, String tableId}) target,
  ) =>
      row.id.equals(target.id) &
      row.workspaceId.equals(workspaceId) &
      row.tableId.equals(target.tableId) &
      row.deletedAt.isNull();
}

bool _parent(WorkspaceColumn column) =>
    column.type == .reference &&
    !column.referenceMultiple &&
    column.dependsOnColumnId == null;
void _match(
  WorkspaceColumn column,
  Map<String, Object?> values,
  Map<String, Object?> target,
) {
  if (column.dependsOnColumnId == null) return;
  final parent = values[column.dependsOnColumnId];
  if (parent is! String || target[column.targetMatchColumnId] != parent) {
    throw const WorkspaceTableException(incompatibleRelationship: true);
  }
}

String _targetId(WorkspaceColumn column) =>
    column.targetTableId ?? (throw const WorkspaceTableException());
Map<String, Object?> _decode(String value) =>
    (jsonDecode(value) as Map).cast<String, Object?>();
List<WorkspaceColumn> _decodeColumns(String value) =>
    (jsonDecode(value) as List)
        .map(
          (item) =>
              WorkspaceColumn.fromJson((item as Map).cast<String, Object?>()),
        )
        .toList();
WorkspaceColumn? _find(Iterable<WorkspaceColumn> columns, String? id) =>
    columns.where((column) => column.id == id).firstOrNull;
Map<String, Object?> _defaultsMap(List<WorkspaceColumn> columns) => {
  for (final column in columns)
    if (column.defaultValue != null) column.id: column.defaultValue,
};

class const _LocalDependencies(
  final LocalWorkspaceReferenceValidation references,
) {
  AppDatabase get _database => references.database;
  Future<void> all() async {
    final query = _database.select(_database.workspaceTables)
      ..where(_activeTable);
    for (final table in await query.get()) {
      await _table(table);
    }
  }

  Future<void> column(
    List<WorkspaceColumn> columns,
    WorkspaceColumn column,
  ) async {
    if (column.dependsOnColumnId == null &&
        column.targetMatchColumnId == null) {
      return;
    }
    final parent = _find(columns, column.dependsOnColumnId);
    final target = await _target(column);
    final match = _find(
      _decodeColumns(target.columnsJson),
      column.targetMatchColumnId,
    );
    if (!_compatible(parent, match, column.id)) {
      throw const WorkspaceTableException();
    }
  }

  Future<void> _table(WorkspaceTableRow table) async {
    final columns = _decodeColumns(table.columnsJson);
    if (!columns.any((column) => column.dependsOnColumnId != null)) return;
    await references.columns(columns);
    await _records(table.id, columns);
  }

  Future<void> _records(String tableId, List<WorkspaceColumn> columns) async {
    final query = _database.select(_database.workspaceTableRecords)
      ..where((row) => _activeRecord(row, tableId));
    for (final record in await query.get()) {
      await references.values(columns, _decode(record.valuesJson));
    }
  }

  Future<WorkspaceTableRow> _target(WorkspaceColumn column) {
    final query = _database.select(_database.workspaceTables)
      ..where((row) => references._tableMatches(row, _targetId(column)));

    return query.getSingle();
  }

  Expression<bool> _activeTable(WorkspaceTables row) =>
      row.workspaceId.equals(references.workspaceId) & row.deletedAt.isNull();
  Expression<bool> _activeRecord(WorkspaceTableRecords row, String tableId) =>
      row.workspaceId.equals(references.workspaceId) &
      row.tableId.equals(tableId) &
      row.deletedAt.isNull();
}

bool _compatible(WorkspaceColumn? parent, WorkspaceColumn? match, String id) {
  if (parent == null || match == null || parent.id == id) return false;

  return _parent(parent) &&
      _parent(match) &&
      parent.targetTableId == match.targetTableId;
}
