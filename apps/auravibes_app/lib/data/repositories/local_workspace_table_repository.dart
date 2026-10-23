import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_column_validation.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:drift/drift.dart';
import 'package:uuid/v7.dart';

class const LocalWorkspaceTableRepository(
  final AppDatabase _database,
  final String _workspaceId,
) implements WorkspaceTableRepository {
  @override
  Future<List<WorkspaceTable>> list({String? parentId}) async {
    final rows =
        await (_database.select(_database.workspaceTables)
              ..where(
                (row) =>
                    row.workspaceId.equals(_workspaceId) &
                    row.deletedAt.isNull() &
                    (parentId == null
                        ? row.parentId.isNull()
                        : row.parentId.equals(parentId)),
              )
              ..orderBy([(row) => OrderingTerm.asc(row.name)]))
            .get();

    return rows.map(_table).toList();
  }

  @override
  Future<WorkspaceTable> table(String id) async => _table(await _tableRow(id));
  @override
  Future<WorkspaceTable> create({
    required String name,
    required String labelName,
    String? parentId,
  }) => _database.transaction(() async {
    final workspace = await (_database.select(
      _database.workspaces,
    )..where((row) => row.id.equals(_workspaceId))).getSingleOrNull();
    if (workspace == null || workspace.type != .local) {
      throw const WorkspaceTableException();
    }
    if (parentId != null) {
      final parent =
          await (_database.select(_database.workspaceFolders)..where(
                (row) =>
                    row.id.equals(parentId) &
                    row.workspaceId.equals(_workspaceId) &
                    row.deletedAt.isNull(),
              ))
              .getSingleOrNull();
      if (parent == null) {
        throw const WorkspaceTableException();
      }
    }
    final id = const UuidV7().generate();
    final columnId = const UuidV7().generate();
    final _ = await _database
        .into(_database.workspaceTables)
        .insert(
          WorkspaceTablesCompanion.insert(
            id: .new(id),
            workspaceId: _workspaceId,
            name: name,
            parentId: .new(parentId),
            columnsJson: jsonEncode([
              {'id': columnId, 'name': labelName, 'type': 'text'},
            ]),
            labelColumnId: columnId,
          ),
        );

    return await table(id);
  });
  @override
  Future<WorkspaceTable> renameLabel({
    required WorkspaceTable table,
    required String name,
  }) => saveColumn(
    table: table,
    column: .new(id: table.labelColumnId, name: name),
  );

  @override
  Future<WorkspaceTable> saveColumn({
    required WorkspaceTable table,
    required WorkspaceColumn column,
  }) => _database.transaction(() async {
    final current = await _tableRow(table.id);
    if (current.revision != table.revision ||
        current.schemaRevision != table.schemaRevision) {
      throw const WorkspaceTableException(conflict: true);
    }
    final existing = _table(current);
    final columns = [
      for (final value in existing.columns)
        if (value.id == column.id) column else value,
      if (!existing.columns.any((value) => value.id == column.id)) column,
    ];
    WorkspaceColumnValidation.columns(columns, existing.labelColumnId);
    for (final record in await records(table.id)) {
      WorkspaceColumnValidation.values(columns, record.values);
    }
    final _ =
        await (_database.update(_database.workspaceTables)..where(
              (row) =>
                  row.id.equals(current.id) &
                  row.workspaceId.equals(_workspaceId),
            ))
            .write(
              WorkspaceTablesCompanion(
                columnsJson: .new(
                  jsonEncode(columns.map((column) => column.toJson()).toList()),
                ),
                revision: .new(current.revision + 1),
                schemaRevision: .new(current.schemaRevision + 1),
              ),
            );

    return await this.table(table.id);
  });

  @override
  Future<List<WorkspaceRecord>> records(String tableId) async {
    final _ = await _tableRow(tableId);
    final rows =
        await (_database.select(_database.workspaceTableRecords)
              ..where(
                (row) =>
                    row.tableId.equals(tableId) &
                    row.workspaceId.equals(_workspaceId) &
                    row.deletedAt.isNull(),
              )
              ..orderBy([
                (row) => OrderingTerm.asc(row.createdAt),
                (row) => OrderingTerm.asc(row.id),
              ]))
            .get();

    return rows.map(_record).toList();
  }

  @override
  Future<WorkspaceRecord> record(String tableId, String id) async {
    final _ = await _tableRow(tableId);
    final row =
        await (_database.select(_database.workspaceTableRecords)..where(
              (row) =>
                  row.id.equals(id) &
                  row.tableId.equals(tableId) &
                  row.workspaceId.equals(_workspaceId) &
                  row.deletedAt.isNull(),
            ))
            .getSingleOrNull();
    if (row == null) {
      throw const WorkspaceTableException();
    }

    return _record(row);
  }

  @override
  Future<WorkspaceRecord> createRecord({
    required WorkspaceTable table,
    required Map<String, Object?> values,
  }) => _database.transaction(() async {
    await _checkSchema(table, values);
    final id = const UuidV7().generate();
    final _ = await _database
        .into(_database.workspaceTableRecords)
        .insert(
          WorkspaceTableRecordsCompanion.insert(
            id: .new(id),
            workspaceId: _workspaceId,
            tableId: table.id,
            valuesJson: jsonEncode(values),
          ),
        );

    return await record(table.id, id);
  });
  @override
  Future<WorkspaceRecord> updateRecord({
    required WorkspaceTable table,
    required WorkspaceRecord record,
    required Map<String, Object?> values,
  }) => _database.transaction(() async {
    await _checkSchema(table, values);
    final current = await this.record(table.id, record.id);
    if (current.revision != record.revision) {
      throw const WorkspaceTableException(conflict: true);
    }
    final _ =
        await (_database.update(_database.workspaceTableRecords)..where(
              (row) =>
                  row.id.equals(record.id) &
                  row.tableId.equals(table.id) &
                  row.workspaceId.equals(_workspaceId),
            ))
            .write(
              WorkspaceTableRecordsCompanion(
                valuesJson: .new(jsonEncode(values)),
                revision: .new(current.revision + 1),
              ),
            );

    return await this.record(table.id, record.id);
  });
  Future<WorkspaceTableRow> _tableRow(String id) async {
    final row =
        await (_database.select(_database.workspaceTables)..where(
              (row) =>
                  row.id.equals(id) &
                  row.workspaceId.equals(_workspaceId) &
                  row.deletedAt.isNull(),
            ))
            .getSingleOrNull();
    if (row == null) {
      throw const WorkspaceTableException();
    }

    return row;
  }

  Future<void> _checkSchema(
    WorkspaceTable table,
    Map<String, Object?> values,
  ) async {
    final current = await _tableRow(table.id);
    WorkspaceColumnValidation.values(_table(current).columns, values);
    if (current.schemaRevision != table.schemaRevision) {
      throw const WorkspaceTableException(conflict: true);
    }
  }

  WorkspaceTable _table(WorkspaceTableRow row) => WorkspaceTable(
    id: row.id,
    name: row.name,
    labelColumnId: row.labelColumnId,
    columns: [
      for (final column in (jsonDecode(
        row.columnsJson,
      ) as List<dynamic>).cast<Map<String, dynamic>>())
        WorkspaceColumn.fromJson(column),
    ],
    revision: row.revision,
    schemaRevision: row.schemaRevision,
    parentId: row.parentId,
  );
  WorkspaceRecord _record(WorkspaceTableRecordRow row) => WorkspaceRecord(
    id: row.id,
    tableId: row.tableId,
    values: (jsonDecode(row.valuesJson) as Map<String, dynamic>)
        .cast<String, Object?>(),
    revision: row.revision,
  );
}
