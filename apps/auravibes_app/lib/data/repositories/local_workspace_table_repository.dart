import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/workspace_tables.dart';
import 'package:auravibes_app/data/repositories/local_workspace_purge_guard.dart';
import 'package:auravibes_app/data/repositories/local_workspace_record_batch_receipt.dart';
import 'package:auravibes_app/data/repositories/local_workspace_reference_validation.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_column_validation.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_item_duplication.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_record_change.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table_constraints.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:uuid/v7.dart';

class const LocalWorkspaceTableRepository(
  final AppDatabase _database,
  final String _workspaceId,
) implements WorkspaceTableRepository {
  Future<WorkspaceTable> duplicate(WorkspaceItemDuplication request) =>
      _TableDuplicator(_database, _workspaceId).copy(request);

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
    column: table.columns
        .firstWhere((column) => column.id == table.labelColumnId)
        .renamed(name),
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
  schemaRevision: .new(
    WorkspaceTableConstraints.schemaRevision(_table(row), columns),
  ),
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
  _RecordChange input,
) async {
  final current = await _tableRow(database, workspaceId, input.table.id);
  final columns = _schemaColumns(current, input.table.schemaRevision);
  WorkspaceColumnValidation.values(columns, input.values);
  await LocalWorkspaceReferenceValidation(
    database,
    workspaceId,
  ).values(columns, input.values, previous: input.previous);
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
  WorkspaceTableConstraints.records(columns, records);
}

Future<String> _insertTable(
  AppDatabase db,
  WorkspaceTablesCompanion row,
) async {
  await LocalWorkspacePurgeGuard(
    db,
    row.workspaceId.value,
  ).resource('table', row.id.value);
  final _ = await db.into(db.workspaceTables).insert(row);

  return row.id.value;
}

Future<String> _insertRecord(
  AppDatabase db,
  WorkspaceTableRecordsCompanion row,
) async {
  await LocalWorkspacePurgeGuard(
    db,
    row.workspaceId.value,
  ).resource('record', row.id.value);
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
  LocalWorkspaceReferenceValidation get _references =>
      LocalWorkspaceReferenceValidation(_database, _workspaceId);
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
    await _references.columns(columns);
    await _checkRecords(table.id, columns);
    await _writeColumns(_database, row, columns);
    await _references.allDependencies();

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
    for (final row in rows) {
      await LocalWorkspaceReferenceValidation(
        _database,
        _workspaceId,
      ).values(columns, _record(row).values);
    }
  }
}

class const _RecordWriter(
  final AppDatabase _database,
  final String _workspaceId,
) {
  Future<WorkspaceRecord> create(
    WorkspaceTable table,
    Map<String, Object?> values, {
    bool applyDefaults = true,
  }) => _database.transaction(
    () async => await _insert(
      table.id,
      await _prepare(table, values, applyDefaults: applyDefaults),
    ),
  );

  Future<WorkspaceRecord> update(
    WorkspaceTable table,
    WorkspaceRecord record,
    Map<String, Object?> values,
  ) => _database.transaction(() => _update(table, record, values));

  Future<Map<String, Object?>> _prepare(
    WorkspaceTable table,
    Map<String, Object?> values, {
    bool applyDefaults = true,
  }) async {
    final normalized = applyDefaults ? await _defaults(table, values) : values;
    await _checkSchema(_database, _workspaceId, (
      table: table,
      values: normalized,
      previous: <String, Object?>{},
    ));
    await _checkUnique(table, normalized);

    return normalized;
  }

  Future<Map<String, Object?>> _defaults(
    WorkspaceTable table,
    Map<String, Object?> values,
  ) async {
    final current = _table(await _tableRow(_database, _workspaceId, table.id));

    return WorkspaceTableConstraints.defaults(current.columns, values);
  }

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
    final current = await _read(table.id, record.id);
    final change = (table: table, values: values, previous: current.values);
    await _checkSchema(_database, _workspaceId, change);
    _checkRecordRevision(current, record);
    await _checkUnique(table, values, exceptId: current.id);

    return await _replace(current, values);
  }

  Future<WorkspaceRecord> _replace(
    WorkspaceRecord current,
    Map<String, Object?> values,
  ) async {
    final target = (workspaceId: _workspaceId, record: current);
    await _writeRecord(_database, target, values);
    await LocalWorkspaceReferenceValidation(
      _database,
      _workspaceId,
    ).allDependencies();

    return await _read(current.tableId, current.id);
  }

  Future<void> _checkUnique(
    WorkspaceTable table,
    Map<String, Object?> values, {
    String? exceptId,
  }) async {
    final others = await _otherRecords(table.id, exceptId);
    final current = _table(await _tableRow(_database, _workspaceId, table.id));
    WorkspaceTableConstraints.records(current.columns, [
      ...others,
      WorkspaceRecord(id: '', tableId: table.id, values: values, revision: 1),
    ]);
  }

  Future<List<WorkspaceRecord>> _otherRecords(
    String tableId,
    String? exceptId,
  ) async {
    final rows = await _records(_database, _workspaceId, tableId).get();

    return rows.where((row) => row.id != exceptId).map(_record).toList();
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

typedef _RecordChange = ({
  WorkspaceTable table,
  Map<String, Object?> values,
  Map<String, Object?> previous,
});

List<WorkspaceColumn> _schemaColumns(WorkspaceTableRow row, int revision) {
  if (row.schemaRevision != revision) {
    throw const WorkspaceTableException(conflict: true);
  }

  return _table(row).columns;
}

class const LocalWorkspaceRecordBatchRepository(
  final AppDatabase database,
  final String workspaceId,
) implements WorkspaceRecordBatchRepository {
  @override
  Future<void> apply(
    List<WorkspaceRecordChange> changes, {
    required String requestId,
  }) {
    WorkspaceRecordChange.validate(changes);
    if (requestId.isEmpty) throw const WorkspaceTableException();

    final snapshot = List<WorkspaceRecordChange>.unmodifiable(changes);
    final request = (
      id: requestId,
      digest: LocalWorkspaceRecordBatchReceipt.digest(snapshot),
    );

    return database.transaction(() => _run(snapshot, request));
  }

  Future<void> _run(
    List<WorkspaceRecordChange> changes,
    ({String id, String digest}) request,
  ) async {
    await _checkLocalWorkspace(database, workspaceId);
    final receipts = LocalWorkspaceRecordBatchReceipt(database, workspaceId);
    if (await receipts.replayed(request.id, request.digest)) return;
    await _commit(changes);
    await receipts.save(request.id, request.digest);
  }

  Future<void> _commit(List<WorkspaceRecordChange> changes) async {
    final previous = await _stageAll(changes);
    await _validateAll(changes, previous);
    await LocalWorkspaceReferenceValidation(
      database,
      workspaceId,
    ).allDependencies();
  }

  Future<List<WorkspaceRecord>> _stageAll(
    List<WorkspaceRecordChange> changes,
  ) async {
    final previous = <WorkspaceRecord>[];
    for (final change in changes) {
      previous.add(await _stage(change));
    }

    return previous;
  }

  Future<void> _validateAll(
    List<WorkspaceRecordChange> changes,
    List<WorkspaceRecord> previous,
  ) async {
    for (var i = 0; i < changes.length; i++) {
      await _validate(changes[i], previous[i].values);
    }
  }

  Future<WorkspaceRecord> _current(WorkspaceRecordChange change) async {
    final tables = LocalWorkspaceTableRepository(database, workspaceId);
    final table = await tables.table(change.table.id);
    final _ = _schemaColumns(
      await _tableRow(database, workspaceId, table.id),
      change.table.schemaRevision,
    );

    return await tables.record(table.id, change.record.id);
  }

  Future<WorkspaceRecord> _stage(WorkspaceRecordChange change) async {
    final current = await _current(change);
    _checkRecordRevision(current, change.record);
    WorkspaceColumnValidation.values(change.table.columns, change.values);
    final target = (workspaceId: workspaceId, record: current);
    await _writeRecord(database, target, change.values);

    return current;
  }

  Future<void> _validate(
    WorkspaceRecordChange change,
    Map<String, Object?> previous,
  ) async {
    await _checkSchema(database, workspaceId, (
      table: change.table,
      values: change.values,
      previous: previous,
    ));
    await _unique(change.table.id);
  }

  Future<void> _unique(String id) async {
    final tables = LocalWorkspaceTableRepository(database, workspaceId);
    final table = await tables.table(id);
    _validateRecords(table.columns, await tables.records(id));
  }
}

class const _TableDuplicator(final AppDatabase db, final String workspaceId) {
  LocalWorkspaceRecordBatchReceipt get _receipts => .new(db, workspaceId);
  Future<WorkspaceTable> copy(WorkspaceItemDuplication input) =>
      db.transaction(() => _run(input));

  Future<WorkspaceTable> _run(WorkspaceItemDuplication input) async {
    final source = await _source(input);
    if (await _receipts.replayed(input.requestId, _copyDigest(input))) {
      return await _read(input.targetId);
    }
    final table = await _copyNew(source, input);
    await _receipts.save(input.requestId, _copyDigest(input));

    return table;
  }

  Future<WorkspaceTable> _source(WorkspaceItemDuplication input) async {
    input.validate();
    if (input.kind != .table) throw const WorkspaceTableException();
    await _checkLocalWorkspace(db, workspaceId);

    return await _read(input.sourceId);
  }

  Future<WorkspaceTable> _read(String id) async =>
      _table(await _tableRow(db, workspaceId, id));

  Future<WorkspaceTable> _copyNew(
    WorkspaceTable source,
    WorkspaceItemDuplication input,
  ) async {
    if (source.revision != input.expectedRevision) {
      throw const WorkspaceTableException(conflict: true);
    }
    await _checkParent(db, workspaceId, input.parentId);
    final table = await _insert(source, input);
    if (input.copyRecords) await _copyRecords(source, table);
    await LocalWorkspaceReferenceValidation(db, workspaceId).allDependencies();

    return table;
  }

  Future<WorkspaceTable> _insert(
    WorkspaceTable source,
    WorkspaceItemDuplication input,
  ) async {
    await _checkIdentity(input.targetId);
    final ids = _copyColumnIds(source, input.targetId);
    final columns = await _columns(source, ids);
    final _ = await _insertTable(
      db,
      _companion(input, columns, ids[source.labelColumnId]!),
    );

    return await _read(input.targetId);
  }

  Future<List<WorkspaceColumn>> _columns(
    WorkspaceTable source,
    Map<String, String> ids,
  ) async {
    final columns = _validatedCopyColumns(source, ids);
    await LocalWorkspaceReferenceValidation(db, workspaceId).columns(columns);

    return columns;
  }

  Future<void> _checkIdentity(String id) async {
    final existing = await (db.select(
      db.workspaceTables,
    )..where((row) => row.id.equals(id))).getSingleOrNull();
    if (existing != null) throw const WorkspaceTableException(conflict: true);
  }

  WorkspaceTablesCompanion _companion(
    WorkspaceItemDuplication input,
    List<WorkspaceColumn> columns,
    String labelId,
  ) => .insert(
    id: .new(input.targetId),
    workspaceId: workspaceId,
    name: input.name.trim(),
    parentId: .new(input.parentId),
    columnsJson: _encodeColumns(columns),
    labelColumnId: labelId,
  );

  Future<void> _copyRecords(
    WorkspaceTable source,
    WorkspaceTable target,
  ) async {
    final originals = await LocalWorkspaceTableRepository(
      db,
      workspaceId,
    ).records(source.id);
    _checkCopyRecordCount(originals.length);
    final ids = _copyColumnIds(source, target.id);
    for (final record in originals) {
      final _ = await _RecordWriter(
        db,
        workspaceId,
      ).create(target, _copyValues(record.values, ids), applyDefaults: false);
    }
  }
}

const _maximumCopyRecords = 49;
String _copyDigest(WorkspaceItemDuplication request) =>
    sha256.convert(utf8.encode(jsonEncode(request.toJson()))).toString();
String _encodeColumns(List<WorkspaceColumn> columns) =>
    jsonEncode(columns.map((column) => column.toJson()).toList());
Map<String, String> _copyColumnIds(WorkspaceTable source, String targetId) => {
  for (var i = 0; i < source.columns.length; i++)
    source.columns[i].id: '$targetId-c$i',
};
List<WorkspaceColumn> _validatedCopyColumns(
  WorkspaceTable source,
  Map<String, String> ids,
) {
  final columns = _copyColumns(source, ids);
  WorkspaceColumnValidation.columns(columns, ids[source.labelColumnId]!);

  return columns;
}

List<WorkspaceColumn> _copyColumns(
  WorkspaceTable source,
  Map<String, String> ids,
) => source.columns.map((column) => _copyColumn(column, ids)).toList();
WorkspaceColumn _copyColumn(WorkspaceColumn column, Map<String, String> ids) =>
    .fromJson({
      ...column.toJson(),
      'id': ids[column.id],
      if (column.dependsOnColumnId != null)
        'dependsOnColumnId': ids[column.dependsOnColumnId],
    });
Map<String, Object?> _copyValues(
  Map<String, Object?> values,
  Map<String, String> ids,
) => {for (final entry in values.entries) ids[entry.key]!: entry.value};

void _checkCopyRecordCount(int count) {
  if (count > _maximumCopyRecords) throw const WorkspaceTableException();
}
