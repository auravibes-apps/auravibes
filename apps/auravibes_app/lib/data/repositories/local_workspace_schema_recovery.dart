import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/local_workspace_asset_values.dart';
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
    final current = await _current(target);
    final previous = await _storedColumns(current.id);
    final columns = await _restoreDefaults(data, previous);
    await _validate(current, columns, previous);
    await _write(current, columns);
    await _references.allDependencies();
  }

  Future<WorkspaceTable> _current(WorkspaceTrashTarget target) async {
    final table = await _tables.table(target.id);
    WorkspaceRecoveryValidation.revision(table.revision, target.revision);

    return table;
  }

  Future<List<WorkspaceColumn>> _restoreDefaults(
    Map<String, dynamic> data,
    List<WorkspaceColumn> previous,
  ) => LocalWorkspaceAssetValues(
    database,
    workspaceId,
  ).preserveDefaults(_columns(data), previous);

  Future<void> _validate(
    WorkspaceTable table,
    List<WorkspaceColumn> columns,
    List<WorkspaceColumn> previous,
  ) async {
    WorkspaceColumnValidation.columns(columns, table.labelColumnId);
    final records = await _records(table.id);
    WorkspaceTableConstraints.records(columns, records);
    await _references.columns(columns, previous: previous);
    await _validateRecords(columns, records, previous);
  }

  Future<void> _validateRecords(
    List<WorkspaceColumn> columns,
    List<WorkspaceRecord> records,
    List<WorkspaceColumn> previous,
  ) async {
    for (final record in records) {
      await _references.values(
        columns,
        record.values,
        previous: LocalWorkspaceAssetValues.retained(previous, record.values),
      );
    }
  }

  Future<List<WorkspaceColumn>> _storedColumns(String id) async {
    final query = database.select(database.workspaceTables)
      ..where((row) => row.workspaceId.equals(workspaceId) & row.id.equals(id));
    final row = await query.getSingle();

    return _columns({'columns': jsonDecode(row.columnsJson)});
  }

  Future<List<WorkspaceRecord>> _records(String tableId) async {
    final query = database.select(database.workspaceTableRecords)
      ..where((row) => _activeRecord(row, workspaceId, tableId));
    final rows = await query.get();

    return rows.map(_record).toList();
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

WorkspaceRecord _record(WorkspaceTableRecordRow row) => WorkspaceRecord(
  id: row.id,
  tableId: row.tableId,
  values: jsonDecode(row.valuesJson) as Map<String, dynamic>,
  revision: row.revision,
);

Expression<bool> _activeRecord(
  $WorkspaceTableRecordsTable row,
  String workspaceId,
  String tableId,
) =>
    row.workspaceId.equals(workspaceId) &
    row.tableId.equals(tableId) &
    row.deletedAt.isNull();
