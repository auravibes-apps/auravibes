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
import 'package:serverpod/serverpod.dart' as _i1;

abstract class WorkspaceAuditRecord
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  WorkspaceAuditRecord._({
    this.id,
    required this.workspaceId,
    required this.sequence,
    required this.actorUserId,
    required this.operation,
    this.targetKind,
    this.targetId,
    required this.createdAt,
  });

  factory WorkspaceAuditRecord({
    int? id,
    required int workspaceId,
    required int sequence,
    required String actorUserId,
    required String operation,
    String? targetKind,
    String? targetId,
    required DateTime createdAt,
  }) = _WorkspaceAuditRecordImpl;

  factory WorkspaceAuditRecord.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return WorkspaceAuditRecord(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      sequence: jsonSerialization['sequence'] as int,
      actorUserId: jsonSerialization['actorUserId'] as String,
      operation: jsonSerialization['operation'] as String,
      targetKind: jsonSerialization['targetKind'] as String?,
      targetId: jsonSerialization['targetId'] as String?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  static final t = WorkspaceAuditRecordTable();

  static const db = WorkspaceAuditRecordRepository._();

  @override
  int? id;

  int workspaceId;

  int sequence;

  String actorUserId;

  String operation;

  String? targetKind;

  String? targetId;

  DateTime createdAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [WorkspaceAuditRecord]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  WorkspaceAuditRecord copyWith({
    int? id,
    int? workspaceId,
    int? sequence,
    String? actorUserId,
    String? operation,
    String? targetKind,
    String? targetId,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WorkspaceAuditRecord',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'sequence': sequence,
      'actorUserId': actorUserId,
      'operation': operation,
      if (targetKind != null) 'targetKind': targetKind,
      if (targetId != null) 'targetId': targetId,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WorkspaceAuditRecord',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'sequence': sequence,
      'actorUserId': actorUserId,
      'operation': operation,
      if (targetKind != null) 'targetKind': targetKind,
      if (targetId != null) 'targetId': targetId,
      'createdAt': createdAt.toJson(),
    };
  }

  static WorkspaceAuditRecordInclude include() {
    return WorkspaceAuditRecordInclude._();
  }

  static WorkspaceAuditRecordIncludeList includeList({
    _i1.WhereExpressionBuilder<WorkspaceAuditRecordTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<WorkspaceAuditRecordTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<WorkspaceAuditRecordTable>? orderByList,
    WorkspaceAuditRecordInclude? include,
  }) {
    return WorkspaceAuditRecordIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WorkspaceAuditRecord.t),
      orderDescending: // ignore: deprecated_member_use_from_same_package
          orderDescending,
      orderByList: orderByList?.call(WorkspaceAuditRecord.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WorkspaceAuditRecordImpl extends WorkspaceAuditRecord {
  _WorkspaceAuditRecordImpl({
    int? id,
    required int workspaceId,
    required int sequence,
    required String actorUserId,
    required String operation,
    String? targetKind,
    String? targetId,
    required DateTime createdAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         sequence: sequence,
         actorUserId: actorUserId,
         operation: operation,
         targetKind: targetKind,
         targetId: targetId,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [WorkspaceAuditRecord]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  WorkspaceAuditRecord copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    int? sequence,
    String? actorUserId,
    String? operation,
    Object? targetKind = _Undefined,
    Object? targetId = _Undefined,
    DateTime? createdAt,
  }) {
    return WorkspaceAuditRecord(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      sequence: sequence ?? this.sequence,
      actorUserId: actorUserId ?? this.actorUserId,
      operation: operation ?? this.operation,
      targetKind: targetKind is String? ? targetKind : this.targetKind,
      targetId: targetId is String? ? targetId : this.targetId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class WorkspaceAuditRecordUpdateTable
    extends _i1.UpdateTable<WorkspaceAuditRecordTable> {
  WorkspaceAuditRecordUpdateTable(super.table);

  _i1.ColumnValue<int, int> workspaceId(int value) => _i1.ColumnValue(
    table.workspaceId,
    value,
  );

  _i1.ColumnValue<int, int> sequence(int value) => _i1.ColumnValue(
    table.sequence,
    value,
  );

  _i1.ColumnValue<String, String> actorUserId(String value) => _i1.ColumnValue(
    table.actorUserId,
    value,
  );

  _i1.ColumnValue<String, String> operation(String value) => _i1.ColumnValue(
    table.operation,
    value,
  );

  _i1.ColumnValue<String, String> targetKind(String? value) => _i1.ColumnValue(
    table.targetKind,
    value,
  );

  _i1.ColumnValue<String, String> targetId(String? value) => _i1.ColumnValue(
    table.targetId,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(
        table.createdAt,
        value,
      );
}

class WorkspaceAuditRecordTable extends _i1.Table<int?> {
  WorkspaceAuditRecordTable({super.tableRelation})
    : super(tableName: 'workspace_audit_record') {
    updateTable = WorkspaceAuditRecordUpdateTable(this);
    workspaceId = _i1.ColumnInt(
      'workspaceId',
      this,
    );
    sequence = _i1.ColumnInt(
      'sequence',
      this,
    );
    actorUserId = _i1.ColumnString(
      'actorUserId',
      this,
    );
    operation = _i1.ColumnString(
      'operation',
      this,
    );
    targetKind = _i1.ColumnString(
      'targetKind',
      this,
    );
    targetId = _i1.ColumnString(
      'targetId',
      this,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final WorkspaceAuditRecordUpdateTable updateTable;

  late final _i1.ColumnInt workspaceId;

  late final _i1.ColumnInt sequence;

  late final _i1.ColumnString actorUserId;

  late final _i1.ColumnString operation;

  late final _i1.ColumnString targetKind;

  late final _i1.ColumnString targetId;

  late final _i1.ColumnDateTime createdAt;

  @override
  List<_i1.Column> get columns => [
    id,
    workspaceId,
    sequence,
    actorUserId,
    operation,
    targetKind,
    targetId,
    createdAt,
  ];
}

class WorkspaceAuditRecordInclude extends _i1.IncludeObject {
  WorkspaceAuditRecordInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => WorkspaceAuditRecord.t;
}

class WorkspaceAuditRecordIncludeList extends _i1.IncludeList {
  WorkspaceAuditRecordIncludeList._({
    _i1.WhereExpressionBuilder<WorkspaceAuditRecordTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(WorkspaceAuditRecord.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => WorkspaceAuditRecord.t;
}

class WorkspaceAuditRecordRepository {
  const WorkspaceAuditRecordRepository._();

  /// Returns a list of [WorkspaceAuditRecord]s matching the given query parameters.
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
  Future<List<WorkspaceAuditRecord>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<WorkspaceAuditRecordTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<WorkspaceAuditRecordTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<WorkspaceAuditRecordTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<WorkspaceAuditRecord>(
      where: where?.call(WorkspaceAuditRecord.t),
      orderBy: orderBy?.call(WorkspaceAuditRecord.t),
      orderByList: orderByList?.call(WorkspaceAuditRecord.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [WorkspaceAuditRecord] matching the given query parameters.
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
  Future<WorkspaceAuditRecord?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<WorkspaceAuditRecordTable>? where,
    int? offset,
    _i1.OrderByBuilder<WorkspaceAuditRecordTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<WorkspaceAuditRecordTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<WorkspaceAuditRecord>(
      where: where?.call(WorkspaceAuditRecord.t),
      orderBy: orderBy?.call(WorkspaceAuditRecord.t),
      orderByList: orderByList?.call(WorkspaceAuditRecord.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [WorkspaceAuditRecord] by its [id] or null if no such row exists.
  Future<WorkspaceAuditRecord?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<WorkspaceAuditRecord>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [WorkspaceAuditRecord]s in the list and returns the inserted rows.
  ///
  /// The returned [WorkspaceAuditRecord]s will have their `id` fields set.
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
  Future<List<WorkspaceAuditRecord>> insert(
    _i1.DatabaseSession session,
    List<WorkspaceAuditRecord> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<WorkspaceAuditRecord>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [WorkspaceAuditRecord] and returns the inserted row.
  ///
  /// The returned [WorkspaceAuditRecord] will have its `id` field set.
  Future<WorkspaceAuditRecord> insertRow(
    _i1.DatabaseSession session,
    WorkspaceAuditRecord row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<WorkspaceAuditRecord>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [WorkspaceAuditRecord]s in the list and returns the resulting rows.
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
  /// The returned [WorkspaceAuditRecord]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WorkspaceAuditRecord>> upsert(
    _i1.DatabaseSession session,
    List<WorkspaceAuditRecord> rows, {
    required _i1.ColumnSelections<WorkspaceAuditRecordTable> conflictColumns,
    _i1.ColumnSelections<WorkspaceAuditRecordTable>? updateColumns,
    _i1.WhereExpressionBuilder<WorkspaceAuditRecordTable>? updateWhere,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<WorkspaceAuditRecord>(
      rows,
      conflictColumns: conflictColumns(WorkspaceAuditRecord.t),
      updateColumns: updateColumns?.call(WorkspaceAuditRecord.t),
      updateWhere: updateWhere?.call(WorkspaceAuditRecord.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [WorkspaceAuditRecord] and returns the resulting row.
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
  /// The returned [WorkspaceAuditRecord] will have its `id` field set.
  Future<WorkspaceAuditRecord?> upsertRow(
    _i1.DatabaseSession session,
    WorkspaceAuditRecord row, {
    required _i1.ColumnSelections<WorkspaceAuditRecordTable> conflictColumns,
    _i1.ColumnSelections<WorkspaceAuditRecordTable>? updateColumns,
    _i1.WhereExpressionBuilder<WorkspaceAuditRecordTable>? updateWhere,
    _i1.Transaction? transaction,
  }) async {
    return session.db.upsertRow<WorkspaceAuditRecord>(
      row,
      conflictColumns: conflictColumns(WorkspaceAuditRecord.t),
      updateColumns: updateColumns?.call(WorkspaceAuditRecord.t),
      updateWhere: updateWhere?.call(WorkspaceAuditRecord.t),
      transaction: transaction,
    );
  }

  /// Updates all [WorkspaceAuditRecord]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WorkspaceAuditRecord>> update(
    _i1.DatabaseSession session,
    List<WorkspaceAuditRecord> rows, {
    _i1.ColumnSelections<WorkspaceAuditRecordTable>? columns,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<WorkspaceAuditRecord>(
      rows,
      columns: columns?.call(WorkspaceAuditRecord.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [WorkspaceAuditRecord]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<WorkspaceAuditRecord> updateRow(
    _i1.DatabaseSession session,
    WorkspaceAuditRecord row, {
    _i1.ColumnSelections<WorkspaceAuditRecordTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<WorkspaceAuditRecord>(
      row,
      columns: columns?.call(WorkspaceAuditRecord.t),
      transaction: transaction,
    );
  }

  /// Updates a single [WorkspaceAuditRecord] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<WorkspaceAuditRecord?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<WorkspaceAuditRecordUpdateTable>
    columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<WorkspaceAuditRecord>(
      id,
      columnValues: columnValues(WorkspaceAuditRecord.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [WorkspaceAuditRecord]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WorkspaceAuditRecord>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<WorkspaceAuditRecordUpdateTable>
    columnValues,
    required _i1.WhereExpressionBuilder<WorkspaceAuditRecordTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<WorkspaceAuditRecordTable>? orderBy,
    _i1.OrderByListBuilder<WorkspaceAuditRecordTable>? orderByList,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<WorkspaceAuditRecord>(
      columnValues: columnValues(WorkspaceAuditRecord.t.updateTable),
      where: where(WorkspaceAuditRecord.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WorkspaceAuditRecord.t),
      orderByList: orderByList?.call(WorkspaceAuditRecord.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [WorkspaceAuditRecord]s in the list and returns the deleted rows.
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
  Future<List<WorkspaceAuditRecord>> delete(
    _i1.DatabaseSession session,
    List<WorkspaceAuditRecord> rows, {
    _i1.OrderByBuilder<WorkspaceAuditRecordTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<WorkspaceAuditRecordTable>? orderByList,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<WorkspaceAuditRecord>(
      rows,
      orderBy: orderBy?.call(WorkspaceAuditRecord.t),
      orderByList: orderByList?.call(WorkspaceAuditRecord.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [WorkspaceAuditRecord].
  Future<WorkspaceAuditRecord> deleteRow(
    _i1.DatabaseSession session,
    WorkspaceAuditRecord row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<WorkspaceAuditRecord>(
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
  Future<List<WorkspaceAuditRecord>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<WorkspaceAuditRecordTable> where,
    _i1.OrderByBuilder<WorkspaceAuditRecordTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<WorkspaceAuditRecordTable>? orderByList,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<WorkspaceAuditRecord>(
      where: where(WorkspaceAuditRecord.t),
      orderBy: orderBy?.call(WorkspaceAuditRecord.t),
      orderByList: orderByList?.call(WorkspaceAuditRecord.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<WorkspaceAuditRecordTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<WorkspaceAuditRecord>(
      where: where?.call(WorkspaceAuditRecord.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [WorkspaceAuditRecord] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<WorkspaceAuditRecordTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<WorkspaceAuditRecord>(
      where: where(WorkspaceAuditRecord.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
