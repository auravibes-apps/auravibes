import 'package:drift/drift.dart';
import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_reference_value.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';

class const LocalWorkspaceReferenceValidation(
  final AppDatabase database,
  final String workspaceId,
) {
  Future<void> columns(List<WorkspaceColumn> columns) async {
    for (final column in columns.where((column) => column.type == .reference)) {
      await _table(
        column.targetTableId ?? (throw const WorkspaceTableException()),
      );
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
      ..where(
        (row) =>
            row.id.equals(id) &
            row.workspaceId.equals(workspaceId) &
            row.deletedAt.isNull(),
      );
    if (await query.getSingleOrNull() == null)
      throw const WorkspaceTableException();
  }

  Future<void> _record(String tableId, String id) async {
    final query = database.select(database.workspaceTableRecords)
      ..where(
        (row) =>
            row.id.equals(id) &
            row.workspaceId.equals(workspaceId) &
            row.tableId.equals(tableId) &
            row.deletedAt.isNull(),
      );
    if (await query.getSingleOrNull() == null)
      throw const WorkspaceTableException();
  }
}
