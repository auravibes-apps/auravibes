/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/serverpod.dart' as _is;

abstract class WorkspaceTrashBatch
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  WorkspaceTrashBatch._({
    this.id,
    required this.workspaceId,
    required this.batchId,
    required this.targetJson,
    required this.name,
    required this.membersJson,
    required this.createdAt,
    this.restoredAt,
    this.restoredResultJson,
  });

  factory WorkspaceTrashBatch({
    int? id,
    required int workspaceId,
    required String batchId,
    required String targetJson,
    required String name,
    required String membersJson,
    required DateTime createdAt,
    DateTime? restoredAt,
    String? restoredResultJson,
  }) = _WorkspaceTrashBatchImpl;

  factory WorkspaceTrashBatch.fromJson(Map<String, dynamic> jsonSerialization) {
    return WorkspaceTrashBatch(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      batchId: jsonSerialization['batchId'] as String,
      targetJson: jsonSerialization['targetJson'] as String,
      name: jsonSerialization['name'] as String,
      membersJson: jsonSerialization['membersJson'] as String,
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      restoredAt: jsonSerialization['restoredAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['restoredAt']),
      restoredResultJson: jsonSerialization['restoredResultJson'] as String?,
    );
  }

  static final t = WorkspaceTrashBatchTable();

  static const db = WorkspaceTrashBatchRepository._();

  @override
  int? id;

  int workspaceId;

  String batchId;

  String targetJson;

  String name;

  String membersJson;

  DateTime createdAt;

  DateTime? restoredAt;

  String? restoredResultJson;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [WorkspaceTrashBatch]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  WorkspaceTrashBatch copyWith({
    int? id,
    int? workspaceId,
    String? batchId,
    String? targetJson,
    String? name,
    String? membersJson,
    DateTime? createdAt,
    DateTime? restoredAt,
    String? restoredResultJson,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WorkspaceTrashBatch',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'batchId': batchId,
      'targetJson': targetJson,
      'name': name,
      'membersJson': membersJson,
      'createdAt': createdAt.toJson(),
      if (restoredAt != null) 'restoredAt': restoredAt?.toJson(),
      if (restoredResultJson != null) 'restoredResultJson': restoredResultJson,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WorkspaceTrashBatch',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'batchId': batchId,
      'targetJson': targetJson,
      'name': name,
      'membersJson': membersJson,
      'createdAt': createdAt.toJson(),
      if (restoredAt != null) 'restoredAt': restoredAt?.toJson(),
      if (restoredResultJson != null) 'restoredResultJson': restoredResultJson,
    };
  }

  static WorkspaceTrashBatchInclude include() {
    return WorkspaceTrashBatchInclude._();
  }

  static WorkspaceTrashBatchIncludeList includeList({
    _is.WhereExpressionBuilder<WorkspaceTrashBatchTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<WorkspaceTrashBatchTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceTrashBatchTable>? orderByList,
    WorkspaceTrashBatchInclude? include,
  }) {
    return WorkspaceTrashBatchIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WorkspaceTrashBatch.t),
      orderByList: orderByList?.call(WorkspaceTrashBatch.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WorkspaceTrashBatchImpl extends WorkspaceTrashBatch {
  _WorkspaceTrashBatchImpl({
    int? id,
    required int workspaceId,
    required String batchId,
    required String targetJson,
    required String name,
    required String membersJson,
    required DateTime createdAt,
    DateTime? restoredAt,
    String? restoredResultJson,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         batchId: batchId,
         targetJson: targetJson,
         name: name,
         membersJson: membersJson,
         createdAt: createdAt,
         restoredAt: restoredAt,
         restoredResultJson: restoredResultJson,
       );

  /// Returns a shallow copy of this [WorkspaceTrashBatch]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  WorkspaceTrashBatch copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    String? batchId,
    String? targetJson,
    String? name,
    String? membersJson,
    DateTime? createdAt,
    Object? restoredAt = _Undefined,
    Object? restoredResultJson = _Undefined,
  }) {
    return WorkspaceTrashBatch(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      batchId: batchId ?? this.batchId,
      targetJson: targetJson ?? this.targetJson,
      name: name ?? this.name,
      membersJson: membersJson ?? this.membersJson,
      createdAt: createdAt ?? this.createdAt,
      restoredAt: restoredAt is DateTime? ? restoredAt : this.restoredAt,
      restoredResultJson: restoredResultJson is String?
          ? restoredResultJson
          : this.restoredResultJson,
    );
  }
}

class WorkspaceTrashBatchUpdateTable
    extends _is.UpdateTable<WorkspaceTrashBatchTable> {
  WorkspaceTrashBatchUpdateTable(super.table);

  _is.ColumnValue<int, int> workspaceId(int value) => _is.ColumnValue(
    table.workspaceId,
    value,
  );

  _is.ColumnValue<String, String> batchId(String value) => _is.ColumnValue(
    table.batchId,
    value,
  );

  _is.ColumnValue<String, String> targetJson(String value) => _is.ColumnValue(
    table.targetJson,
    value,
  );

  _is.ColumnValue<String, String> name(String value) => _is.ColumnValue(
    table.name,
    value,
  );

  _is.ColumnValue<String, String> membersJson(String value) => _is.ColumnValue(
    table.membersJson,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> restoredAt(DateTime? value) =>
      _is.ColumnValue(
        table.restoredAt,
        value,
      );

  _is.ColumnValue<String, String> restoredResultJson(String? value) =>
      _is.ColumnValue(
        table.restoredResultJson,
        value,
      );
}

class WorkspaceTrashBatchTable extends _is.Table<int?> {
  WorkspaceTrashBatchTable({super.tableRelation})
    : super(tableName: 'workspace_trash_batch') {
    updateTable = WorkspaceTrashBatchUpdateTable(this);
    workspaceId = _is.ColumnInt(
      'workspaceId',
      this,
    );
    batchId = _is.ColumnString(
      'batchId',
      this,
    );
    targetJson = _is.ColumnString(
      'targetJson',
      this,
    );
    name = _is.ColumnString(
      'name',
      this,
    );
    membersJson = _is.ColumnString(
      'membersJson',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
    restoredAt = _is.ColumnDateTime(
      'restoredAt',
      this,
    );
    restoredResultJson = _is.ColumnString(
      'restoredResultJson',
      this,
    );
  }

  late final WorkspaceTrashBatchUpdateTable updateTable;

  late final _is.ColumnInt workspaceId;

  late final _is.ColumnString batchId;

  late final _is.ColumnString targetJson;

  late final _is.ColumnString name;

  late final _is.ColumnString membersJson;

  late final _is.ColumnDateTime createdAt;

  late final _is.ColumnDateTime restoredAt;

  late final _is.ColumnString restoredResultJson;

  @override
  List<_is.Column> get columns => [
    id,
    workspaceId,
    batchId,
    targetJson,
    name,
    membersJson,
    createdAt,
    restoredAt,
    restoredResultJson,
  ];
}

class WorkspaceTrashBatchInclude extends _is.IncludeObject {
  WorkspaceTrashBatchInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => WorkspaceTrashBatch.t;
}

class WorkspaceTrashBatchIncludeList extends _is.IncludeList {
  WorkspaceTrashBatchIncludeList._({
    _is.WhereExpressionBuilder<WorkspaceTrashBatchTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(WorkspaceTrashBatch.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => WorkspaceTrashBatch.t;
}

class WorkspaceTrashBatchRepository {
  const WorkspaceTrashBatchRepository._();

  /// Returns a list of [WorkspaceTrashBatch]s matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// ```dart
  /// var persons = await Persons.db.find(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// );
  /// ```
  Future<List<WorkspaceTrashBatch>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<WorkspaceTrashBatchTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<WorkspaceTrashBatchTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceTrashBatchTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<WorkspaceTrashBatch>(
      where: where?.call(WorkspaceTrashBatch.t),
      orderBy: orderBy?.call(WorkspaceTrashBatch.t),
      orderByList: orderByList?.call(WorkspaceTrashBatch.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [WorkspaceTrashBatch] matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// [offset] defines how many items to skip, after which the next one will be picked.
  ///
  /// ```dart
  /// var youngestPerson = await Persons.db.findFirstRow(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.age,
  /// );
  /// ```
  Future<WorkspaceTrashBatch?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<WorkspaceTrashBatchTable>? where,
    int? offset,
    _is.OrderByBuilder<WorkspaceTrashBatchTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceTrashBatchTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<WorkspaceTrashBatch>(
      where: where?.call(WorkspaceTrashBatch.t),
      orderBy: orderBy?.call(WorkspaceTrashBatch.t),
      orderByList: orderByList?.call(WorkspaceTrashBatch.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [WorkspaceTrashBatch] by its [id] or null if no such row exists.
  Future<WorkspaceTrashBatch?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<WorkspaceTrashBatch>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [WorkspaceTrashBatch]s in the list and returns the inserted rows.
  ///
  /// The returned [WorkspaceTrashBatch]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  ///
  /// If [noReturn] is set to `true`, the inserted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WorkspaceTrashBatch>> insert(
    _is.DatabaseSession session,
    List<WorkspaceTrashBatch> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<WorkspaceTrashBatch>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [WorkspaceTrashBatch] and returns the inserted row.
  ///
  /// The returned [WorkspaceTrashBatch] will have its `id` field set.
  Future<WorkspaceTrashBatch> insertRow(
    _is.DatabaseSession session,
    WorkspaceTrashBatch row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<WorkspaceTrashBatch>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [WorkspaceTrashBatch]s in the list and returns the resulting rows.
  ///
  /// If a row conflicts on the given [conflictColumns], the existing row is
  /// updated with the new values. Otherwise, a new row is inserted.
  ///
  /// If [updateColumns] is provided, only those columns will be updated on
  /// conflict. If null, all non-conflict, non-id columns are updated.
  ///
  /// If [updateWhere] is provided, the update only applies to rows matching the
  /// given expression. Conflicting rows that don't match are skipped and not
  /// returned, so the resulting list may be shorter than [rows].
  ///
  /// The returned [WorkspaceTrashBatch]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WorkspaceTrashBatch>> upsert(
    _is.DatabaseSession session,
    List<WorkspaceTrashBatch> rows, {
    required _is.ColumnSelections<WorkspaceTrashBatchTable> conflictColumns,
    _is.ColumnSelections<WorkspaceTrashBatchTable>? updateColumns,
    _is.WhereExpressionBuilder<WorkspaceTrashBatchTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<WorkspaceTrashBatch>(
      rows,
      conflictColumns: conflictColumns(WorkspaceTrashBatch.t),
      updateColumns: updateColumns?.call(WorkspaceTrashBatch.t),
      updateWhere: updateWhere?.call(WorkspaceTrashBatch.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [WorkspaceTrashBatch] and returns the resulting row.
  ///
  /// If the row conflicts on the given [conflictColumns], the existing row is
  /// updated. Otherwise, a new row is inserted.
  ///
  /// If [updateColumns] is provided, only those columns will be updated on
  /// conflict. If null, all non-conflict, non-id columns are updated.
  ///
  /// If [updateWhere] is provided, the update only applies when the existing
  /// row matches the expression. Returns `null` if no row was affected — for
  /// example when [updateWhere] does not match the conflicting row.
  ///
  /// The returned [WorkspaceTrashBatch] will have its `id` field set.
  Future<WorkspaceTrashBatch?> upsertRow(
    _is.DatabaseSession session,
    WorkspaceTrashBatch row, {
    required _is.ColumnSelections<WorkspaceTrashBatchTable> conflictColumns,
    _is.ColumnSelections<WorkspaceTrashBatchTable>? updateColumns,
    _is.WhereExpressionBuilder<WorkspaceTrashBatchTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<WorkspaceTrashBatch>(
      row,
      conflictColumns: conflictColumns(WorkspaceTrashBatch.t),
      updateColumns: updateColumns?.call(WorkspaceTrashBatch.t),
      updateWhere: updateWhere?.call(WorkspaceTrashBatch.t),
      transaction: transaction,
    );
  }

  /// Updates all [WorkspaceTrashBatch]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WorkspaceTrashBatch>> update(
    _is.DatabaseSession session,
    List<WorkspaceTrashBatch> rows, {
    _is.ColumnSelections<WorkspaceTrashBatchTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<WorkspaceTrashBatch>(
      rows,
      columns: columns?.call(WorkspaceTrashBatch.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [WorkspaceTrashBatch]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<WorkspaceTrashBatch> updateRow(
    _is.DatabaseSession session,
    WorkspaceTrashBatch row, {
    _is.ColumnSelections<WorkspaceTrashBatchTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<WorkspaceTrashBatch>(
      row,
      columns: columns?.call(WorkspaceTrashBatch.t),
      transaction: transaction,
    );
  }

  /// Updates a single [WorkspaceTrashBatch] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<WorkspaceTrashBatch?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<WorkspaceTrashBatchUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<WorkspaceTrashBatch>(
      id,
      columnValues: columnValues(WorkspaceTrashBatch.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [WorkspaceTrashBatch]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WorkspaceTrashBatch>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<WorkspaceTrashBatchUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<WorkspaceTrashBatchTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<WorkspaceTrashBatchTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceTrashBatchTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<WorkspaceTrashBatch>(
      columnValues: columnValues(WorkspaceTrashBatch.t.updateTable),
      where: where(WorkspaceTrashBatch.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WorkspaceTrashBatch.t),
      orderByList: orderByList?.call(WorkspaceTrashBatch.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [WorkspaceTrashBatch]s in the list and returns the deleted rows.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WorkspaceTrashBatch>> delete(
    _is.DatabaseSession session,
    List<WorkspaceTrashBatch> rows, {
    _is.OrderByBuilder<WorkspaceTrashBatchTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceTrashBatchTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<WorkspaceTrashBatch>(
      rows,
      orderBy: orderBy?.call(WorkspaceTrashBatch.t),
      orderByList: orderByList?.call(WorkspaceTrashBatch.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [WorkspaceTrashBatch].
  Future<WorkspaceTrashBatch> deleteRow(
    _is.DatabaseSession session,
    WorkspaceTrashBatch row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<WorkspaceTrashBatch>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WorkspaceTrashBatch>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<WorkspaceTrashBatchTable> where,
    _is.OrderByBuilder<WorkspaceTrashBatchTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceTrashBatchTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<WorkspaceTrashBatch>(
      where: where(WorkspaceTrashBatch.t),
      orderBy: orderBy?.call(WorkspaceTrashBatch.t),
      orderByList: orderByList?.call(WorkspaceTrashBatch.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<WorkspaceTrashBatchTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<WorkspaceTrashBatch>(
      where: where?.call(WorkspaceTrashBatch.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [WorkspaceTrashBatch] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<WorkspaceTrashBatchTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<WorkspaceTrashBatch>(
      where: where(WorkspaceTrashBatch.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
