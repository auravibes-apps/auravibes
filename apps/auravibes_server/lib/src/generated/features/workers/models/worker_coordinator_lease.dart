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

abstract class WorkerCoordinatorLease
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  WorkerCoordinatorLease._({
    this.id,
    required this.key,
    required this.ownerId,
    required this.fencingToken,
    required this.expiresAt,
  });

  factory WorkerCoordinatorLease({
    int? id,
    required String key,
    required String ownerId,
    required int fencingToken,
    required DateTime expiresAt,
  }) = _WorkerCoordinatorLeaseImpl;

  factory WorkerCoordinatorLease.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return WorkerCoordinatorLease(
      id: jsonSerialization['id'] as int?,
      key: jsonSerialization['key'] as String,
      ownerId: jsonSerialization['ownerId'] as String,
      fencingToken: jsonSerialization['fencingToken'] as int,
      expiresAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
    );
  }

  static final t = WorkerCoordinatorLeaseTable();

  static const db = WorkerCoordinatorLeaseRepository._();

  @override
  int? id;

  String key;

  String ownerId;

  int fencingToken;

  DateTime expiresAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [WorkerCoordinatorLease]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  WorkerCoordinatorLease copyWith({
    int? id,
    String? key,
    String? ownerId,
    int? fencingToken,
    DateTime? expiresAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WorkerCoordinatorLease',
      if (id != null) 'id': id,
      'key': key,
      'ownerId': ownerId,
      'fencingToken': fencingToken,
      'expiresAt': expiresAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WorkerCoordinatorLease',
      if (id != null) 'id': id,
      'key': key,
      'ownerId': ownerId,
      'fencingToken': fencingToken,
      'expiresAt': expiresAt.toJson(),
    };
  }

  static WorkerCoordinatorLeaseInclude include() {
    return WorkerCoordinatorLeaseInclude._();
  }

  static WorkerCoordinatorLeaseIncludeList includeList({
    _i1.WhereExpressionBuilder<WorkerCoordinatorLeaseTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<WorkerCoordinatorLeaseTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<WorkerCoordinatorLeaseTable>? orderByList,
    WorkerCoordinatorLeaseInclude? include,
  }) {
    return WorkerCoordinatorLeaseIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WorkerCoordinatorLease.t),
      orderDescending: // ignore: deprecated_member_use_from_same_package
          orderDescending,
      orderByList: orderByList?.call(WorkerCoordinatorLease.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WorkerCoordinatorLeaseImpl extends WorkerCoordinatorLease {
  _WorkerCoordinatorLeaseImpl({
    int? id,
    required String key,
    required String ownerId,
    required int fencingToken,
    required DateTime expiresAt,
  }) : super._(
         id: id,
         key: key,
         ownerId: ownerId,
         fencingToken: fencingToken,
         expiresAt: expiresAt,
       );

  /// Returns a shallow copy of this [WorkerCoordinatorLease]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  WorkerCoordinatorLease copyWith({
    Object? id = _Undefined,
    String? key,
    String? ownerId,
    int? fencingToken,
    DateTime? expiresAt,
  }) {
    return WorkerCoordinatorLease(
      id: id is int? ? id : this.id,
      key: key ?? this.key,
      ownerId: ownerId ?? this.ownerId,
      fencingToken: fencingToken ?? this.fencingToken,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}

class WorkerCoordinatorLeaseUpdateTable
    extends _i1.UpdateTable<WorkerCoordinatorLeaseTable> {
  WorkerCoordinatorLeaseUpdateTable(super.table);

  _i1.ColumnValue<String, String> key(String value) => _i1.ColumnValue(
    table.key,
    value,
  );

  _i1.ColumnValue<String, String> ownerId(String value) => _i1.ColumnValue(
    table.ownerId,
    value,
  );

  _i1.ColumnValue<int, int> fencingToken(int value) => _i1.ColumnValue(
    table.fencingToken,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> expiresAt(DateTime value) =>
      _i1.ColumnValue(
        table.expiresAt,
        value,
      );
}

class WorkerCoordinatorLeaseTable extends _i1.Table<int?> {
  WorkerCoordinatorLeaseTable({super.tableRelation})
    : super(tableName: 'worker_coordinator_lease') {
    updateTable = WorkerCoordinatorLeaseUpdateTable(this);
    key = _i1.ColumnString(
      'key',
      this,
    );
    ownerId = _i1.ColumnString(
      'ownerId',
      this,
    );
    fencingToken = _i1.ColumnInt(
      'fencingToken',
      this,
    );
    expiresAt = _i1.ColumnDateTime(
      'expiresAt',
      this,
    );
  }

  late final WorkerCoordinatorLeaseUpdateTable updateTable;

  late final _i1.ColumnString key;

  late final _i1.ColumnString ownerId;

  late final _i1.ColumnInt fencingToken;

  late final _i1.ColumnDateTime expiresAt;

  @override
  List<_i1.Column> get columns => [
    id,
    key,
    ownerId,
    fencingToken,
    expiresAt,
  ];
}

class WorkerCoordinatorLeaseInclude extends _i1.IncludeObject {
  WorkerCoordinatorLeaseInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => WorkerCoordinatorLease.t;
}

class WorkerCoordinatorLeaseIncludeList extends _i1.IncludeList {
  WorkerCoordinatorLeaseIncludeList._({
    _i1.WhereExpressionBuilder<WorkerCoordinatorLeaseTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(WorkerCoordinatorLease.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => WorkerCoordinatorLease.t;
}

class WorkerCoordinatorLeaseRepository {
  const WorkerCoordinatorLeaseRepository._();

  /// Returns a list of [WorkerCoordinatorLease]s matching the given query parameters.
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
  Future<List<WorkerCoordinatorLease>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<WorkerCoordinatorLeaseTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<WorkerCoordinatorLeaseTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<WorkerCoordinatorLeaseTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<WorkerCoordinatorLease>(
      where: where?.call(WorkerCoordinatorLease.t),
      orderBy: orderBy?.call(WorkerCoordinatorLease.t),
      orderByList: orderByList?.call(WorkerCoordinatorLease.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [WorkerCoordinatorLease] matching the given query parameters.
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
  Future<WorkerCoordinatorLease?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<WorkerCoordinatorLeaseTable>? where,
    int? offset,
    _i1.OrderByBuilder<WorkerCoordinatorLeaseTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<WorkerCoordinatorLeaseTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<WorkerCoordinatorLease>(
      where: where?.call(WorkerCoordinatorLease.t),
      orderBy: orderBy?.call(WorkerCoordinatorLease.t),
      orderByList: orderByList?.call(WorkerCoordinatorLease.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [WorkerCoordinatorLease] by its [id] or null if no such row exists.
  Future<WorkerCoordinatorLease?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<WorkerCoordinatorLease>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [WorkerCoordinatorLease]s in the list and returns the inserted rows.
  ///
  /// The returned [WorkerCoordinatorLease]s will have their `id` fields set.
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
  Future<List<WorkerCoordinatorLease>> insert(
    _i1.DatabaseSession session,
    List<WorkerCoordinatorLease> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<WorkerCoordinatorLease>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [WorkerCoordinatorLease] and returns the inserted row.
  ///
  /// The returned [WorkerCoordinatorLease] will have its `id` field set.
  Future<WorkerCoordinatorLease> insertRow(
    _i1.DatabaseSession session,
    WorkerCoordinatorLease row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<WorkerCoordinatorLease>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [WorkerCoordinatorLease]s in the list and returns the resulting rows.
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
  /// The returned [WorkerCoordinatorLease]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WorkerCoordinatorLease>> upsert(
    _i1.DatabaseSession session,
    List<WorkerCoordinatorLease> rows, {
    required _i1.ColumnSelections<WorkerCoordinatorLeaseTable> conflictColumns,
    _i1.ColumnSelections<WorkerCoordinatorLeaseTable>? updateColumns,
    _i1.WhereExpressionBuilder<WorkerCoordinatorLeaseTable>? updateWhere,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<WorkerCoordinatorLease>(
      rows,
      conflictColumns: conflictColumns(WorkerCoordinatorLease.t),
      updateColumns: updateColumns?.call(WorkerCoordinatorLease.t),
      updateWhere: updateWhere?.call(WorkerCoordinatorLease.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [WorkerCoordinatorLease] and returns the resulting row.
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
  /// The returned [WorkerCoordinatorLease] will have its `id` field set.
  Future<WorkerCoordinatorLease?> upsertRow(
    _i1.DatabaseSession session,
    WorkerCoordinatorLease row, {
    required _i1.ColumnSelections<WorkerCoordinatorLeaseTable> conflictColumns,
    _i1.ColumnSelections<WorkerCoordinatorLeaseTable>? updateColumns,
    _i1.WhereExpressionBuilder<WorkerCoordinatorLeaseTable>? updateWhere,
    _i1.Transaction? transaction,
  }) async {
    return session.db.upsertRow<WorkerCoordinatorLease>(
      row,
      conflictColumns: conflictColumns(WorkerCoordinatorLease.t),
      updateColumns: updateColumns?.call(WorkerCoordinatorLease.t),
      updateWhere: updateWhere?.call(WorkerCoordinatorLease.t),
      transaction: transaction,
    );
  }

  /// Updates all [WorkerCoordinatorLease]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WorkerCoordinatorLease>> update(
    _i1.DatabaseSession session,
    List<WorkerCoordinatorLease> rows, {
    _i1.ColumnSelections<WorkerCoordinatorLeaseTable>? columns,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<WorkerCoordinatorLease>(
      rows,
      columns: columns?.call(WorkerCoordinatorLease.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [WorkerCoordinatorLease]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<WorkerCoordinatorLease> updateRow(
    _i1.DatabaseSession session,
    WorkerCoordinatorLease row, {
    _i1.ColumnSelections<WorkerCoordinatorLeaseTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<WorkerCoordinatorLease>(
      row,
      columns: columns?.call(WorkerCoordinatorLease.t),
      transaction: transaction,
    );
  }

  /// Updates a single [WorkerCoordinatorLease] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<WorkerCoordinatorLease?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<WorkerCoordinatorLeaseUpdateTable>
    columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<WorkerCoordinatorLease>(
      id,
      columnValues: columnValues(WorkerCoordinatorLease.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [WorkerCoordinatorLease]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WorkerCoordinatorLease>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<WorkerCoordinatorLeaseUpdateTable>
    columnValues,
    required _i1.WhereExpressionBuilder<WorkerCoordinatorLeaseTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<WorkerCoordinatorLeaseTable>? orderBy,
    _i1.OrderByListBuilder<WorkerCoordinatorLeaseTable>? orderByList,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<WorkerCoordinatorLease>(
      columnValues: columnValues(WorkerCoordinatorLease.t.updateTable),
      where: where(WorkerCoordinatorLease.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WorkerCoordinatorLease.t),
      orderByList: orderByList?.call(WorkerCoordinatorLease.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [WorkerCoordinatorLease]s in the list and returns the deleted rows.
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
  Future<List<WorkerCoordinatorLease>> delete(
    _i1.DatabaseSession session,
    List<WorkerCoordinatorLease> rows, {
    _i1.OrderByBuilder<WorkerCoordinatorLeaseTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<WorkerCoordinatorLeaseTable>? orderByList,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<WorkerCoordinatorLease>(
      rows,
      orderBy: orderBy?.call(WorkerCoordinatorLease.t),
      orderByList: orderByList?.call(WorkerCoordinatorLease.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [WorkerCoordinatorLease].
  Future<WorkerCoordinatorLease> deleteRow(
    _i1.DatabaseSession session,
    WorkerCoordinatorLease row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<WorkerCoordinatorLease>(
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
  Future<List<WorkerCoordinatorLease>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<WorkerCoordinatorLeaseTable> where,
    _i1.OrderByBuilder<WorkerCoordinatorLeaseTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<WorkerCoordinatorLeaseTable>? orderByList,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<WorkerCoordinatorLease>(
      where: where(WorkerCoordinatorLease.t),
      orderBy: orderBy?.call(WorkerCoordinatorLease.t),
      orderByList: orderByList?.call(WorkerCoordinatorLease.t),
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
    _i1.WhereExpressionBuilder<WorkerCoordinatorLeaseTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<WorkerCoordinatorLease>(
      where: where?.call(WorkerCoordinatorLease.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [WorkerCoordinatorLease] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<WorkerCoordinatorLeaseTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<WorkerCoordinatorLease>(
      where: where(WorkerCoordinatorLease.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
