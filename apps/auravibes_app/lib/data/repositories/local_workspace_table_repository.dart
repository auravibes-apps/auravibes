import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/workspace_tables.dart';
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
    final query = _tables(_database, _workspaceId)
      ..where((row) => _parent(row, parentId))
      ..orderBy([_nameOrder]);
    final rows = await query.get();

    return rows.map(_table).toList();
  }

  @override
  Future<WorkspaceTable> table(String id) async =>
      _table(await _tableRow(_database, _workspaceId, id));
  @override
  Future<WorkspaceTable> create({
    required String name,
    required String labelName,
    String? parentId,
  }) => _TableWriter(_database, _workspaceId).create(name, labelName, parentId);
  @override
  Future<WorkspaceTable> updateMetadata({
    required WorkspaceTable table,
    required String name,
    required String? parentId,
  }) => _TableWriter(
    _database,
    _workspaceId,
  ).updateMetadata(table, name, parentId);

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
  }) => _TableWriter(_database, _workspaceId).saveColumn(table, column);

  @override
  Future<List<WorkspaceRecord>> records(String tableId) async {
    final _ = await _tableRow(_database, _workspaceId, tableId);
    final query = _records(_database, _workspaceId, tableId)
      ..orderBy([_createdOrder, _recordIdOrder]);
    final rows = await query.get();

    return rows.map(_record).toList();
  }

  @override
  Future<WorkspaceRecord> record(String tableId, String id) async {
    final _ = await _tableRow(_database, _workspaceId, tableId);
    final query = _records(_database, _workspaceId, tableId)
      ..where((row) => row.id.equals(id));
    final row = await query.getSingleOrNull();
    if (row == null) {
      throw const WorkspaceTableException();
    }

    return _record(row);
  }

  @override
  Future<WorkspaceRecord> createRecord({
    required WorkspaceTable table,
    required Map<String, Object?> values,
  }) => _RecordWriter(_database, _workspaceId).create(table, values);
  @override
  Future<WorkspaceRecord> updateRecord({
    required WorkspaceTable table,
    required WorkspaceRecord record,
    required Map<String, Object?> values,
  }) => _RecordWriter(_database, _workspaceId).update(table, record, values);
}

WorkspaceTable _table(WorkspaceTableRow row) => WorkspaceTable(
  id: row.id,
  name: row.name,
  labelColumnId: row.labelColumnId,
  columns: _columns(row.columnsJson),
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

List<WorkspaceColumn> _columns(String encoded) =>
    (jsonDecode(encoded) as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(WorkspaceColumn.fromJson)
        .toList();

SimpleSelectStatement<WorkspaceTables, WorkspaceTableRow> _tables(
  AppDatabase db,
  String workspaceId,
) => db.select(
  db.workspaceTables,
)..where((row) => row.workspaceId.equals(workspaceId) & row.deletedAt.isNull());

SimpleSelectStatement<WorkspaceTableRecords, WorkspaceTableRecordRow> _records(
  AppDatabase db,
  String workspaceId,
  String tableId,
) => db.select(db.workspaceTableRecords)
  ..where(
    (row) =>
        row.workspaceId.equals(workspaceId) &
        row.tableId.equals(tableId) &
        row.deletedAt.isNull(),
  );

Future<void> _checkLocalWorkspace(AppDatabase db, String workspaceId) async {
  final workspace = await (db.select(
    db.workspaces,
  )..where((row) => row.id.equals(workspaceId))).getSingleOrNull();
  if (workspace == null || workspace.type != .local) {
    throw const WorkspaceTableException();
  }
}

Future<void> _checkParent(
  AppDatabase db,
  String workspaceId,
  String? parentId,
) async {
  if (parentId == null) return;
  final query = db.select(db.workspaceFolders)
    ..where((row) => row.id.equals(parentId) & _activeFolder(row, workspaceId));
  if (await query.getSingleOrNull() == null) {
    throw const WorkspaceTableException();
  }
}

typedef _TableInput = ({
  String workspaceId,
  String name,
  String labelName,
  String? parentId,
});
WorkspaceTablesCompanion _newTable(
  String id,
  String columnId,
  _TableInput input,
) => WorkspaceTablesCompanion.insert(
  id: .new(id),
  workspaceId: input.workspaceId,
  name: input.name,
  parentId: .new(input.parentId),
  columnsJson: jsonEncode([
    WorkspaceColumn(id: columnId, name: input.labelName).toJson(),
  ]),
  labelColumnId: columnId,
);

Future<void> _writeColumns(
  AppDatabase db,
  WorkspaceTableRow row,
  List<WorkspaceColumn> columns,
) async {
  final update = db.update(db.workspaceTables)
    ..where((value) => _tableTarget(value, row));
  final _ = await update.write(_columnUpdate(row, columns));
}

WorkspaceTablesCompanion _columnUpdate(
  WorkspaceTableRow row,
  List<WorkspaceColumn> columns,
) => WorkspaceTablesCompanion(
  columnsJson: .new(
    jsonEncode(columns.map((column) => column.toJson()).toList()),
  ),
  revision: .new(row.revision + 1),
  schemaRevision: .new(row.schemaRevision + 1),
);

WorkspaceTableRecordsCompanion _newRecord(
  String id,
  String workspaceId,
  String tableId,
  Map<String, Object?> values,
) => WorkspaceTableRecordsCompanion.insert(
  id: .new(id),
  workspaceId: workspaceId,
  tableId: tableId,
  valuesJson: jsonEncode(values),
);
Future<void> _writeRecord(
  AppDatabase db,
  ({String workspaceId, WorkspaceRecord record}) target,
  Map<String, Object?> values,
) async {
  final update = db.update(db.workspaceTableRecords)
    ..where((row) => _recordTarget(row, target));
  final _ = await update.write(_recordUpdate(target.record, values));
}

Future<WorkspaceTableRow> _tableRow(
  AppDatabase database,
  String workspaceId,
  String id,
) async {
  final query = _tables(database, workspaceId)
    ..where((row) => row.id.equals(id));
  final row = await query.getSingleOrNull();
  if (row == null) {
    throw const WorkspaceTableException();
  }

  return row;
}

Future<void> _checkSchema(
  AppDatabase database,
  String workspaceId,
  ({WorkspaceTable table, Map<String, Object?> values}) input,
) async {
  final current = await _tableRow(database, workspaceId, input.table.id);
  WorkspaceColumnValidation.values(_table(current).columns, input.values);
  if (current.schemaRevision != input.table.schemaRevision) {
    throw const WorkspaceTableException(conflict: true);
  }
}

Expression<bool> _parent(WorkspaceTables row, String? parentId) =>
    parentId == null ? row.parentId.isNull() : row.parentId.equals(parentId);
OrderingTerm _nameOrder(WorkspaceTables row) => OrderingTerm.asc(row.name);
OrderingTerm _createdOrder(WorkspaceTableRecords row) =>
    OrderingTerm.asc(row.createdAt);
OrderingTerm _recordIdOrder(WorkspaceTableRecords row) =>
    OrderingTerm.asc(row.id);
void _checkTableRevision(WorkspaceTable current, WorkspaceTable expected) {
  if (current.revision != expected.revision ||
      current.schemaRevision != expected.schemaRevision) {
    throw const WorkspaceTableException(conflict: true);
  }
}

void _checkRecordRevision(WorkspaceRecord current, WorkspaceRecord expected) {
  if (current.revision != expected.revision) {
    throw const WorkspaceTableException(conflict: true);
  }
}

void _validateRecords(
  List<WorkspaceColumn> columns,
  List<WorkspaceRecord> records,
) {
  for (final record in records) {
    WorkspaceColumnValidation.values(columns, record.values);
  }
}

Future<String> _insertTable(
  AppDatabase db,
  WorkspaceTablesCompanion row,
) async {
  final _ = await db.into(db.workspaceTables).insert(row);

  return row.id.value;
}

Future<String> _insertRecord(
  AppDatabase db,
  WorkspaceTableRecordsCompanion row,
) async {
  final _ = await db.into(db.workspaceTableRecords).insert(row);

  return row.id.value;
}

Future<String> _createTable(AppDatabase db, _TableInput input) => _insertTable(
  db,
  _newTable(const UuidV7().generate(), const UuidV7().generate(), input),
);

List<WorkspaceColumn> _updatedColumns(
  WorkspaceTableRow row,
  WorkspaceTable expected,
  WorkspaceColumn column,
) {
  final current = _table(row);
  _checkTableRevision(current, expected);
  final columns = current.withColumn(column);
  WorkspaceColumnValidation.columns(columns, current.labelColumnId);

  return columns;
}

Future<String> _createRecord(
  AppDatabase db,
  String workspaceId,
  ({String tableId, Map<String, Object?> values}) input,
) => _insertRecord(
  db,
  _newRecord(
    const UuidV7().generate(),
    workspaceId,
    input.tableId,
    input.values,
  ),
);
WorkspaceTableRecordsCompanion _recordUpdate(
  WorkspaceRecord record,
  Map<String, Object?> values,
) => WorkspaceTableRecordsCompanion(
  valuesJson: .new(jsonEncode(values)),
  revision: .new(record.revision + 1),
);
Expression<bool> _recordTarget(
  WorkspaceTableRecords row,
  ({String workspaceId, WorkspaceRecord record}) target,
) =>
    row.id.equals(target.record.id) &
    row.tableId.equals(target.record.tableId) &
    row.workspaceId.equals(target.workspaceId);
Expression<bool> _tableTarget(WorkspaceTables value, WorkspaceTableRow row) =>
    value.id.equals(row.id) & value.workspaceId.equals(row.workspaceId);
Expression<bool> _activeFolder(
  $WorkspaceFoldersTable row,
  String workspaceId,
) => row.workspaceId.equals(workspaceId) & row.deletedAt.isNull();

class const _TableWriter(
  final AppDatabase _database,
  final String _workspaceId,
) {
  Future<WorkspaceTable> create(
    String name,
    String labelName,
    String? parentId,
  ) => _database.transaction(() async {
    await _checkLocalWorkspace(_database, _workspaceId);
    await _checkParent(_database, _workspaceId, parentId);

    return await _insert((
      name: name,
      labelName: labelName,
      parentId: parentId,
    ));
  });

  Future<WorkspaceTable> updateMetadata(
    WorkspaceTable table,
    String name,
    String? parentId,
  ) => _database.transaction(() async {
    final row = await _metadataTarget(table, parentId);
    await _writeMetadata(_database, row, (name: name, parentId: parentId));

    return await _read(table.id);
  });

  Future<WorkspaceTable> saveColumn(
    WorkspaceTable table,
    WorkspaceColumn column,
  ) => _database.transaction(() => _saveColumn(table, column));

  Future<WorkspaceTableRow> _metadataTarget(
    WorkspaceTable table,
    String? parentId,
  ) async {
    await _checkLocalWorkspace(_database, _workspaceId);
    final row = await _tableRow(_database, _workspaceId, table.id);
    _checkTableRevision(_table(row), table);
    await _checkParent(_database, _workspaceId, parentId);

    return row;
  }

  Future<WorkspaceTable> _insert(
    ({String name, String labelName, String? parentId}) input,
  ) async {
    final id = await _createTable(_database, (
      workspaceId: _workspaceId,
      name: input.name,
      labelName: input.labelName,
      parentId: input.parentId,
    ));

    return _table(await _tableRow(_database, _workspaceId, id));
  }

  Future<WorkspaceTable> _saveColumn(
    WorkspaceTable table,
    WorkspaceColumn column,
  ) async {
    final row = await _tableRow(_database, _workspaceId, table.id);
    final columns = _updatedColumns(row, table, column);
    await _checkRecords(table.id, columns);
    await _writeColumns(_database, row, columns);

    return await _read(table.id);
  }

  Future<WorkspaceTable> _read(String id) async =>
      _table(await _tableRow(_database, _workspaceId, id));

  Future<void> _checkRecords(
    String tableId,
    List<WorkspaceColumn> columns,
  ) async {
    final rows = await _records(_database, _workspaceId, tableId).get();
    _validateRecords(columns, rows.map(_record).toList());
  }
}

class const _RecordWriter(
  final AppDatabase _database,
  final String _workspaceId,
) {
  Future<WorkspaceRecord> create(
    WorkspaceTable table,
    Map<String, Object?> values,
  ) => _database.transaction(() async {
    await _checkSchema(_database, _workspaceId, (table: table, values: values));

    return await _insert(table.id, values);
  });

  Future<WorkspaceRecord> update(
    WorkspaceTable table,
    WorkspaceRecord record,
    Map<String, Object?> values,
  ) => _database.transaction(() => _update(table, record, values));

  Future<WorkspaceRecord> _insert(
    String tableId,
    Map<String, Object?> values,
  ) async {
    final id = await _createRecord(_database, _workspaceId, (
      tableId: tableId,
      values: values,
    ));

    return await _read(tableId, id);
  }

  Future<WorkspaceRecord> _update(
    WorkspaceTable table,
    WorkspaceRecord record,
    Map<String, Object?> values,
  ) async {
    await _checkSchema(_database, _workspaceId, (table: table, values: values));
    final current = await _read(table.id, record.id);
    _checkRecordRevision(current, record);
    final target = (workspaceId: _workspaceId, record: current);
    await _writeRecord(_database, target, values);

    return await _read(table.id, record.id);
  }

  Future<WorkspaceRecord> _read(String tableId, String id) async {
    final query = _records(_database, _workspaceId, tableId)
      ..where((row) => row.id.equals(id));

    final row = await query.getSingleOrNull();
    if (row == null) throw const WorkspaceTableException();

    return _record(row);
  }
}

Future<void> _writeMetadata(
  AppDatabase database,
  WorkspaceTableRow row,
  ({String name, String? parentId}) input,
) async {
  final update = database.update(database.workspaceTables)
    ..where((value) => _tableTarget(value, row));
  final _ = await update.write(_metadataChanges(row, input));
}

WorkspaceTablesCompanion _metadataChanges(
  WorkspaceTableRow row,
  ({String name, String? parentId}) input,
) => WorkspaceTablesCompanion(
  name: .new(input.name),
  parentId: .new(input.parentId),
  revision: .new(row.revision + 1),
);
