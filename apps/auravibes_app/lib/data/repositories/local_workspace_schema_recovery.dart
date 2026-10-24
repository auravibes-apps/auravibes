import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/local_workspace_reference_validation.dart';
import 'package:auravibes_app/data/repositories/local_workspace_table_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_column_validation.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table_constraints.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_trash_target.dart';
import 'package:drift/drift.dart';

class const LocalWorkspaceSchemaRecovery(
  final AppDatabase database,
  final String workspaceId,
) {
  LocalWorkspaceTableRepository get _tables => .new(database, workspaceId);
  LocalWorkspaceReferenceValidation get _references =>
      .new(database, workspaceId);

  Future<void> restore(
    WorkspaceTrashTarget target,
    Map<String, dynamic> data,
  ) async {
    final current = await _tables.table(target.id);
    WorkspaceRecoveryValidation.revision(current.revision, target.revision);
    final columns = _columns(data);
    await _validate(current, columns);
    await _write(current, columns);
    await _references.allDependencies();
  }

  Future<void> _validate(
    WorkspaceTable table,
    List<WorkspaceColumn> columns,
  ) async {
    WorkspaceColumnValidation.columns(columns, table.labelColumnId);
    final records = await _tables.records(table.id);
    WorkspaceTableConstraints.records(columns, records);
    await _references.columns(columns);
    await _validateRecords(columns, records);
  }

  Future<void> _validateRecords(
    List<WorkspaceColumn> columns,
    List<WorkspaceRecord> records,
  ) async {
    for (final record in records) {
      await _references.values(columns, record.values);
    }
  }

  Future<void> _write(
    WorkspaceTable table,
    List<WorkspaceColumn> columns,
  ) async {
    final update = database.update(database.workspaceTables)
      ..where((row) => _matches(row, workspaceId, table.id));
    final _ = await update.write(_changes(table, columns));
  }
}

List<WorkspaceColumn> _columns(Map<String, dynamic> data) =>
    (data['columns'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(WorkspaceColumn.fromJson)
        .toList();
WorkspaceTablesCompanion _changes(
  WorkspaceTable current,
  List<WorkspaceColumn> columns,
) => WorkspaceTablesCompanion(
  columnsJson: .new(
    jsonEncode(columns.map((column) => column.toJson()).toList()),
  ),
  revision: .new(current.revision + 1),
  schemaRevision: .new(current.schemaRevision + 1),
);

abstract final class WorkspaceRecoveryValidation {
  static void revision(int actual, int expected) {
    if (actual != expected) throw const WorkspaceTableException(conflict: true);
  }
}

Expression<bool> _matches(
  $WorkspaceTablesTable row,
  String workspaceId,
  String id,
) => row.workspaceId.equals(workspaceId) & row.id.equals(id);
