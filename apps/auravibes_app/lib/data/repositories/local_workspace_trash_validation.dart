import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/local_trash_node.dart';
import 'package:auravibes_app/data/repositories/local_workspace_reference_validation.dart';
import 'package:auravibes_app/data/repositories/local_workspace_table_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_view_mapper.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table_constraints.dart';
import 'package:auravibes_app/features/workspaces/usecases/workspace_view_validation.dart';
import 'package:drift/drift.dart';

class const LocalWorkspaceTrashValidation(
  final AppDatabase database,
  final String workspaceId,
) {
  Future<bool> tables(Set<String> ids) async {
    var unresolved = false;
    for (final id in ids) {
      unresolved |= await _table(id);
    }

    return unresolved;
  }

  Future<bool> views(List<LocalTrashNode> members) async {
    for (final node in members.where((node) => node.kind == .view)) {
      if (await _view(node.id)) return true;
    }

    return false;
  }

  Future<bool> _table(String id) async {
    final table = await _tableRow(id);
    final rows = await _records(id);
    final columns = _columns(table.columnsJson);
    WorkspaceTableConstraints.records(columns, rows.map(_record));

    return await _unresolvedRows(columns, rows);
  }

  Future<WorkspaceTableRow> _tableRow(String id) async {
    final row =
        await (database.select(database.workspaceTables)..where(
              (row) => row.workspaceId.equals(workspaceId) & row.id.equals(id),
            ))
            .getSingle();
    if (row.deletedAt != null) throw const WorkspaceTableException();

    return row;
  }

  Future<List<WorkspaceTableRecordRow>> _records(String id) =>
      (database.select(database.workspaceTableRecords)..where(
            (row) =>
                row.workspaceId.equals(workspaceId) &
                row.tableId.equals(id) &
                row.deletedAt.isNull(),
          ))
          .get();
  Future<bool> _unresolvedRows(
    List<WorkspaceColumn> columns,
    List<WorkspaceTableRecordRow> rows,
  ) async {
    for (final row in rows) {
      try {
        await LocalWorkspaceReferenceValidation(
          database,
          workspaceId,
        ).values(columns, _values(row));
      } on WorkspaceTableException {
        return true;
      }
    }

    return false;
  }

  Future<bool> _view(String id) async {
    final row = await _viewRow(id);
    try {
      final view = WorkspaceViewMapper.fromJson(_decode(row.data));
      final table = await LocalWorkspaceTableRepository(
        database,
        workspaceId,
      ).table(view.tableId);

      return WorkspaceViewValidation.needsRepair(view, table);
    } on WorkspaceTableException {
      return true;
    }
  }

  Future<WorkspaceViewRow> _viewRow(String id) =>
      (database.select(database.workspaceViews)..where(
            (row) => row.workspaceId.equals(workspaceId) & row.id.equals(id),
          ))
          .getSingle();
}

List<WorkspaceColumn> _columns(String encoded) =>
    (jsonDecode(encoded) as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(WorkspaceColumn.fromJson)
        .toList();
WorkspaceRecord _record(WorkspaceTableRecordRow row) => .new(
  id: row.id,
  tableId: row.tableId,
  revision: row.revision,
  values: _values(row),
);
Map<String, dynamic> _decode(String encoded) =>
    jsonDecode(encoded) as Map<String, dynamic>;
Map<String, Object?> _values(WorkspaceTableRecordRow row) =>
    _decode(row.valuesJson).cast<String, Object?>();
