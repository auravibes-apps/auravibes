import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/workspace_tables.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_reference_value.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:drift/drift.dart';

class const LocalWorkspaceReferenceValidation(
  final AppDatabase database,
  final String workspaceId,
) {
  Future<void> columns(List<WorkspaceColumn> columns) async {
    for (final column in columns.where((column) => column.type == .reference)) {
      await _table(
        column.targetTableId ?? (throw const WorkspaceTableException()),
      );
      if (column.defaultValue != null) {
        await values([column], {column.id: column.defaultValue});
      }
    }
  }

  Future<void> values(
    List<WorkspaceColumn> columns,
    Map<String, Object?> values,
  ) async {
    for (final column in columns.where((column) => column.type == .reference)) {
      final ids = WorkspaceReferenceValue.ids(values[column.id]);
      for (final id in ids) {
        await _record(
          column.targetTableId ?? (throw const WorkspaceTableException()),
          id,
        );
      }
    }
  }

  Future<void> _table(String id) async {
    final query = database.select(database.workspaceTables)
      ..where((row) => _tableMatches(row, id));
    if (await query.getSingleOrNull() == null) {
      throw const WorkspaceTableException();
    }
  }

  Future<void> _record(String tableId, String id) async {
    final query = database.select(database.workspaceTableRecords)
      ..where((row) => _recordMatches(row, (id: id, tableId: tableId)));
    if (await query.getSingleOrNull() == null) {
      throw const WorkspaceTableException();
    }
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
