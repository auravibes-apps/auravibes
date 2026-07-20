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

abstract class RecurringWorkerSchedule
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  RecurringWorkerSchedule._({
    this.id,
    required this.workerKey,
    required this.nextRunAt,
    this.runToken,
    this.leaderFencingToken,
    this.runLeaseExpiresAt,
    required this.updatedAt,
  });

  factory RecurringWorkerSchedule({
    int? id,
    required String workerKey,
    required DateTime nextRunAt,
    String? runToken,
    int? leaderFencingToken,
    DateTime? runLeaseExpiresAt,
    required DateTime updatedAt,
  }) = _RecurringWorkerScheduleImpl;

  factory RecurringWorkerSchedule.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return RecurringWorkerSchedule(
      id: jsonSerialization['id'] as int?,
      workerKey: jsonSerialization['workerKey'] as String,
      nextRunAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['nextRunAt'],
      ),
      runToken: jsonSerialization['runToken'] as String?,
      leaderFencingToken: jsonSerialization['leaderFencingToken'] as int?,
      runLeaseExpiresAt: jsonSerialization['runLeaseExpiresAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['runLeaseExpiresAt'],
            ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  static final t = RecurringWorkerScheduleTable();

  static const db = RecurringWorkerScheduleRepository._();

  @override
  int? id;

  String workerKey;

  DateTime nextRunAt;

  String? runToken;

  int? leaderFencingToken;

  DateTime? runLeaseExpiresAt;

  DateTime updatedAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [RecurringWorkerSchedule]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  RecurringWorkerSchedule copyWith({
    int? id,
    String? workerKey,
    DateTime? nextRunAt,
    String? runToken,
    int? leaderFencingToken,
    DateTime? runLeaseExpiresAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RecurringWorkerSchedule',
      if (id != null) 'id': id,
      'workerKey': workerKey,
      'nextRunAt': nextRunAt.toJson(),
      if (runToken != null) 'runToken': runToken,
      if (leaderFencingToken != null) 'leaderFencingToken': leaderFencingToken,
      if (runLeaseExpiresAt != null)
        'runLeaseExpiresAt': runLeaseExpiresAt?.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'RecurringWorkerSchedule',
      if (id != null) 'id': id,
      'workerKey': workerKey,
      'nextRunAt': nextRunAt.toJson(),
      if (runToken != null) 'runToken': runToken,
      if (leaderFencingToken != null) 'leaderFencingToken': leaderFencingToken,
      if (runLeaseExpiresAt != null)
        'runLeaseExpiresAt': runLeaseExpiresAt?.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  static RecurringWorkerScheduleInclude include() {
    return RecurringWorkerScheduleInclude._();
  }

  static RecurringWorkerScheduleIncludeList includeList({
    _i1.WhereExpressionBuilder<RecurringWorkerScheduleTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<RecurringWorkerScheduleTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<RecurringWorkerScheduleTable>? orderByList,
    RecurringWorkerScheduleInclude? include,
  }) {
    return RecurringWorkerScheduleIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(RecurringWorkerSchedule.t),
      orderDescending: // ignore: deprecated_member_use_from_same_package
          orderDescending,
      orderByList: orderByList?.call(RecurringWorkerSchedule.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _RecurringWorkerScheduleImpl extends RecurringWorkerSchedule {
  _RecurringWorkerScheduleImpl({
    int? id,
    required String workerKey,
    required DateTime nextRunAt,
    String? runToken,
    int? leaderFencingToken,
    DateTime? runLeaseExpiresAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         workerKey: workerKey,
         nextRunAt: nextRunAt,
         runToken: runToken,
         leaderFencingToken: leaderFencingToken,
         runLeaseExpiresAt: runLeaseExpiresAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [RecurringWorkerSchedule]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  RecurringWorkerSchedule copyWith({
    Object? id = _Undefined,
    String? workerKey,
    DateTime? nextRunAt,
    Object? runToken = _Undefined,
    Object? leaderFencingToken = _Undefined,
    Object? runLeaseExpiresAt = _Undefined,
    DateTime? updatedAt,
  }) {
    return RecurringWorkerSchedule(
      id: id is int? ? id : this.id,
      workerKey: workerKey ?? this.workerKey,
      nextRunAt: nextRunAt ?? this.nextRunAt,
      runToken: runToken is String? ? runToken : this.runToken,
      leaderFencingToken: leaderFencingToken is int?
          ? leaderFencingToken
          : this.leaderFencingToken,
      runLeaseExpiresAt: runLeaseExpiresAt is DateTime?
          ? runLeaseExpiresAt
          : this.runLeaseExpiresAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class RecurringWorkerScheduleUpdateTable
    extends _i1.UpdateTable<RecurringWorkerScheduleTable> {
  RecurringWorkerScheduleUpdateTable(super.table);

  _i1.ColumnValue<String, String> workerKey(String value) => _i1.ColumnValue(
    table.workerKey,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> nextRunAt(DateTime value) =>
      _i1.ColumnValue(
        table.nextRunAt,
        value,
      );

  _i1.ColumnValue<String, String> runToken(String? value) => _i1.ColumnValue(
    table.runToken,
    value,
  );

  _i1.ColumnValue<int, int> leaderFencingToken(int? value) => _i1.ColumnValue(
    table.leaderFencingToken,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> runLeaseExpiresAt(DateTime? value) =>
      _i1.ColumnValue(
        table.runLeaseExpiresAt,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> updatedAt(DateTime value) =>
      _i1.ColumnValue(
        table.updatedAt,
        value,
      );
}

class RecurringWorkerScheduleTable extends _i1.Table<int?> {
  RecurringWorkerScheduleTable({super.tableRelation})
    : super(tableName: 'recurring_worker_schedule') {
    updateTable = RecurringWorkerScheduleUpdateTable(this);
    workerKey = _i1.ColumnString(
      'workerKey',
      this,
    );
    nextRunAt = _i1.ColumnDateTime(
      'nextRunAt',
      this,
    );
    runToken = _i1.ColumnString(
      'runToken',
      this,
    );
    leaderFencingToken = _i1.ColumnInt(
      'leaderFencingToken',
      this,
    );
    runLeaseExpiresAt = _i1.ColumnDateTime(
      'runLeaseExpiresAt',
      this,
    );
    updatedAt = _i1.ColumnDateTime(
      'updatedAt',
      this,
    );
  }

  late final RecurringWorkerScheduleUpdateTable updateTable;

  late final _i1.ColumnString workerKey;

  late final _i1.ColumnDateTime nextRunAt;

  late final _i1.ColumnString runToken;

  late final _i1.ColumnInt leaderFencingToken;

  late final _i1.ColumnDateTime runLeaseExpiresAt;

  late final _i1.ColumnDateTime updatedAt;

  @override
  List<_i1.Column> get columns => [
    id,
    workerKey,
    nextRunAt,
    runToken,
    leaderFencingToken,
    runLeaseExpiresAt,
    updatedAt,
  ];
}

class RecurringWorkerScheduleInclude extends _i1.IncludeObject {
  RecurringWorkerScheduleInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => RecurringWorkerSchedule.t;
}

class RecurringWorkerScheduleIncludeList extends _i1.IncludeList {
  RecurringWorkerScheduleIncludeList._({
    _i1.WhereExpressionBuilder<RecurringWorkerScheduleTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(RecurringWorkerSchedule.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => RecurringWorkerSchedule.t;
}

class RecurringWorkerScheduleRepository {
  const RecurringWorkerScheduleRepository._();

  /// Returns a list of [RecurringWorkerSchedule]s matching the given query parameters.
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
  Future<List<RecurringWorkerSchedule>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<RecurringWorkerScheduleTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<RecurringWorkerScheduleTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<RecurringWorkerScheduleTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<RecurringWorkerSchedule>(
      where: where?.call(RecurringWorkerSchedule.t),
      orderBy: orderBy?.call(RecurringWorkerSchedule.t),
      orderByList: orderByList?.call(RecurringWorkerSchedule.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [RecurringWorkerSchedule] matching the given query parameters.
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
  Future<RecurringWorkerSchedule?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<RecurringWorkerScheduleTable>? where,
    int? offset,
    _i1.OrderByBuilder<RecurringWorkerScheduleTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<RecurringWorkerScheduleTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<RecurringWorkerSchedule>(
      where: where?.call(RecurringWorkerSchedule.t),
      orderBy: orderBy?.call(RecurringWorkerSchedule.t),
      orderByList: orderByList?.call(RecurringWorkerSchedule.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [RecurringWorkerSchedule] by its [id] or null if no such row exists.
  Future<RecurringWorkerSchedule?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<RecurringWorkerSchedule>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [RecurringWorkerSchedule]s in the list and returns the inserted rows.
  ///
  /// The returned [RecurringWorkerSchedule]s will have their `id` fields set.
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
  Future<List<RecurringWorkerSchedule>> insert(
    _i1.DatabaseSession session,
    List<RecurringWorkerSchedule> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<RecurringWorkerSchedule>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [RecurringWorkerSchedule] and returns the inserted row.
  ///
  /// The returned [RecurringWorkerSchedule] will have its `id` field set.
  Future<RecurringWorkerSchedule> insertRow(
    _i1.DatabaseSession session,
    RecurringWorkerSchedule row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<RecurringWorkerSchedule>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [RecurringWorkerSchedule]s in the list and returns the resulting rows.
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
  /// The returned [RecurringWorkerSchedule]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<RecurringWorkerSchedule>> upsert(
    _i1.DatabaseSession session,
    List<RecurringWorkerSchedule> rows, {
    required _i1.ColumnSelections<RecurringWorkerScheduleTable> conflictColumns,
    _i1.ColumnSelections<RecurringWorkerScheduleTable>? updateColumns,
    _i1.WhereExpressionBuilder<RecurringWorkerScheduleTable>? updateWhere,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<RecurringWorkerSchedule>(
      rows,
      conflictColumns: conflictColumns(RecurringWorkerSchedule.t),
      updateColumns: updateColumns?.call(RecurringWorkerSchedule.t),
      updateWhere: updateWhere?.call(RecurringWorkerSchedule.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [RecurringWorkerSchedule] and returns the resulting row.
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
  /// The returned [RecurringWorkerSchedule] will have its `id` field set.
  Future<RecurringWorkerSchedule?> upsertRow(
    _i1.DatabaseSession session,
    RecurringWorkerSchedule row, {
    required _i1.ColumnSelections<RecurringWorkerScheduleTable> conflictColumns,
    _i1.ColumnSelections<RecurringWorkerScheduleTable>? updateColumns,
    _i1.WhereExpressionBuilder<RecurringWorkerScheduleTable>? updateWhere,
    _i1.Transaction? transaction,
  }) async {
    return session.db.upsertRow<RecurringWorkerSchedule>(
      row,
      conflictColumns: conflictColumns(RecurringWorkerSchedule.t),
      updateColumns: updateColumns?.call(RecurringWorkerSchedule.t),
      updateWhere: updateWhere?.call(RecurringWorkerSchedule.t),
      transaction: transaction,
    );
  }

  /// Updates all [RecurringWorkerSchedule]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<RecurringWorkerSchedule>> update(
    _i1.DatabaseSession session,
    List<RecurringWorkerSchedule> rows, {
    _i1.ColumnSelections<RecurringWorkerScheduleTable>? columns,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<RecurringWorkerSchedule>(
      rows,
      columns: columns?.call(RecurringWorkerSchedule.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [RecurringWorkerSchedule]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<RecurringWorkerSchedule> updateRow(
    _i1.DatabaseSession session,
    RecurringWorkerSchedule row, {
    _i1.ColumnSelections<RecurringWorkerScheduleTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<RecurringWorkerSchedule>(
      row,
      columns: columns?.call(RecurringWorkerSchedule.t),
      transaction: transaction,
    );
  }

  /// Updates a single [RecurringWorkerSchedule] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<RecurringWorkerSchedule?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<RecurringWorkerScheduleUpdateTable>
    columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<RecurringWorkerSchedule>(
      id,
      columnValues: columnValues(RecurringWorkerSchedule.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [RecurringWorkerSchedule]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<RecurringWorkerSchedule>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<RecurringWorkerScheduleUpdateTable>
    columnValues,
    required _i1.WhereExpressionBuilder<RecurringWorkerScheduleTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<RecurringWorkerScheduleTable>? orderBy,
    _i1.OrderByListBuilder<RecurringWorkerScheduleTable>? orderByList,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<RecurringWorkerSchedule>(
      columnValues: columnValues(RecurringWorkerSchedule.t.updateTable),
      where: where(RecurringWorkerSchedule.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(RecurringWorkerSchedule.t),
      orderByList: orderByList?.call(RecurringWorkerSchedule.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [RecurringWorkerSchedule]s in the list and returns the deleted rows.
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
  Future<List<RecurringWorkerSchedule>> delete(
    _i1.DatabaseSession session,
    List<RecurringWorkerSchedule> rows, {
    _i1.OrderByBuilder<RecurringWorkerScheduleTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<RecurringWorkerScheduleTable>? orderByList,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<RecurringWorkerSchedule>(
      rows,
      orderBy: orderBy?.call(RecurringWorkerSchedule.t),
      orderByList: orderByList?.call(RecurringWorkerSchedule.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [RecurringWorkerSchedule].
  Future<RecurringWorkerSchedule> deleteRow(
    _i1.DatabaseSession session,
    RecurringWorkerSchedule row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<RecurringWorkerSchedule>(
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
  Future<List<RecurringWorkerSchedule>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<RecurringWorkerScheduleTable> where,
    _i1.OrderByBuilder<RecurringWorkerScheduleTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<RecurringWorkerScheduleTable>? orderByList,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<RecurringWorkerSchedule>(
      where: where(RecurringWorkerSchedule.t),
      orderBy: orderBy?.call(RecurringWorkerSchedule.t),
      orderByList: orderByList?.call(RecurringWorkerSchedule.t),
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
    _i1.WhereExpressionBuilder<RecurringWorkerScheduleTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<RecurringWorkerSchedule>(
      where: where?.call(RecurringWorkerSchedule.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [RecurringWorkerSchedule] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<RecurringWorkerScheduleTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<RecurringWorkerSchedule>(
      where: where(RecurringWorkerSchedule.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
