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

abstract class WorkspaceMutationReceipt
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  WorkspaceMutationReceipt._({
    this.id,
    this.workspaceId,
    required this.scopeKey,
    required this.actorUserId,
    required this.endpoint,
    required this.requestId,
    required this.requestHash,
    required this.responseJson,
    required this.createdAt,
  });

  factory WorkspaceMutationReceipt({
    int? id,
    int? workspaceId,
    required String scopeKey,
    required String actorUserId,
    required String endpoint,
    required String requestId,
    required String requestHash,
    required String responseJson,
    required DateTime createdAt,
  }) = _WorkspaceMutationReceiptImpl;

  factory WorkspaceMutationReceipt.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return WorkspaceMutationReceipt(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int?,
      scopeKey: jsonSerialization['scopeKey'] as String,
      actorUserId: jsonSerialization['actorUserId'] as String,
      endpoint: jsonSerialization['endpoint'] as String,
      requestId: jsonSerialization['requestId'] as String,
      requestHash: jsonSerialization['requestHash'] as String,
      responseJson: jsonSerialization['responseJson'] as String,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  static final t = WorkspaceMutationReceiptTable();

  static const db = WorkspaceMutationReceiptRepository._();

  @override
  int? id;

  int? workspaceId;

  String scopeKey;

  String actorUserId;

  String endpoint;

  String requestId;

  String requestHash;

  String responseJson;

  DateTime createdAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [WorkspaceMutationReceipt]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  WorkspaceMutationReceipt copyWith({
    int? id,
    int? workspaceId,
    String? scopeKey,
    String? actorUserId,
    String? endpoint,
    String? requestId,
    String? requestHash,
    String? responseJson,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WorkspaceMutationReceipt',
      if (id != null) 'id': id,
      if (workspaceId != null) 'workspaceId': workspaceId,
      'scopeKey': scopeKey,
      'actorUserId': actorUserId,
      'endpoint': endpoint,
      'requestId': requestId,
      'requestHash': requestHash,
      'responseJson': responseJson,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WorkspaceMutationReceipt',
      if (id != null) 'id': id,
      if (workspaceId != null) 'workspaceId': workspaceId,
      'scopeKey': scopeKey,
      'actorUserId': actorUserId,
      'endpoint': endpoint,
      'requestId': requestId,
      'requestHash': requestHash,
      'responseJson': responseJson,
      'createdAt': createdAt.toJson(),
    };
  }

  static WorkspaceMutationReceiptInclude include() {
    return WorkspaceMutationReceiptInclude._();
  }

  static WorkspaceMutationReceiptIncludeList includeList({
    _i1.WhereExpressionBuilder<WorkspaceMutationReceiptTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<WorkspaceMutationReceiptTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<WorkspaceMutationReceiptTable>? orderByList,
    WorkspaceMutationReceiptInclude? include,
  }) {
    return WorkspaceMutationReceiptIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WorkspaceMutationReceipt.t),
      orderDescending: // ignore: deprecated_member_use_from_same_package
          orderDescending,
      orderByList: orderByList?.call(WorkspaceMutationReceipt.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WorkspaceMutationReceiptImpl extends WorkspaceMutationReceipt {
  _WorkspaceMutationReceiptImpl({
    int? id,
    int? workspaceId,
    required String scopeKey,
    required String actorUserId,
    required String endpoint,
    required String requestId,
    required String requestHash,
    required String responseJson,
    required DateTime createdAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         scopeKey: scopeKey,
         actorUserId: actorUserId,
         endpoint: endpoint,
         requestId: requestId,
         requestHash: requestHash,
         responseJson: responseJson,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [WorkspaceMutationReceipt]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  WorkspaceMutationReceipt copyWith({
    Object? id = _Undefined,
    Object? workspaceId = _Undefined,
    String? scopeKey,
    String? actorUserId,
    String? endpoint,
    String? requestId,
    String? requestHash,
    String? responseJson,
    DateTime? createdAt,
  }) {
    return WorkspaceMutationReceipt(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId is int? ? workspaceId : this.workspaceId,
      scopeKey: scopeKey ?? this.scopeKey,
      actorUserId: actorUserId ?? this.actorUserId,
      endpoint: endpoint ?? this.endpoint,
      requestId: requestId ?? this.requestId,
      requestHash: requestHash ?? this.requestHash,
      responseJson: responseJson ?? this.responseJson,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class WorkspaceMutationReceiptUpdateTable
    extends _i1.UpdateTable<WorkspaceMutationReceiptTable> {
  WorkspaceMutationReceiptUpdateTable(super.table);

  _i1.ColumnValue<int, int> workspaceId(int? value) => _i1.ColumnValue(
    table.workspaceId,
    value,
  );

  _i1.ColumnValue<String, String> scopeKey(String value) => _i1.ColumnValue(
    table.scopeKey,
    value,
  );

  _i1.ColumnValue<String, String> actorUserId(String value) => _i1.ColumnValue(
    table.actorUserId,
    value,
  );

  _i1.ColumnValue<String, String> endpoint(String value) => _i1.ColumnValue(
    table.endpoint,
    value,
  );

  _i1.ColumnValue<String, String> requestId(String value) => _i1.ColumnValue(
    table.requestId,
    value,
  );

  _i1.ColumnValue<String, String> requestHash(String value) => _i1.ColumnValue(
    table.requestHash,
    value,
  );

  _i1.ColumnValue<String, String> responseJson(String value) => _i1.ColumnValue(
    table.responseJson,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(
        table.createdAt,
        value,
      );
}

class WorkspaceMutationReceiptTable extends _i1.Table<int?> {
  WorkspaceMutationReceiptTable({super.tableRelation})
    : super(tableName: 'workspace_mutation_receipt') {
    updateTable = WorkspaceMutationReceiptUpdateTable(this);
    workspaceId = _i1.ColumnInt(
      'workspaceId',
      this,
    );
    scopeKey = _i1.ColumnString(
      'scopeKey',
      this,
    );
    actorUserId = _i1.ColumnString(
      'actorUserId',
      this,
    );
    endpoint = _i1.ColumnString(
      'endpoint',
      this,
    );
    requestId = _i1.ColumnString(
      'requestId',
      this,
    );
    requestHash = _i1.ColumnString(
      'requestHash',
      this,
    );
    responseJson = _i1.ColumnString(
      'responseJson',
      this,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final WorkspaceMutationReceiptUpdateTable updateTable;

  late final _i1.ColumnInt workspaceId;

  late final _i1.ColumnString scopeKey;

  late final _i1.ColumnString actorUserId;

  late final _i1.ColumnString endpoint;

  late final _i1.ColumnString requestId;

  late final _i1.ColumnString requestHash;

  late final _i1.ColumnString responseJson;

  late final _i1.ColumnDateTime createdAt;

  @override
  List<_i1.Column> get columns => [
    id,
    workspaceId,
    scopeKey,
    actorUserId,
    endpoint,
    requestId,
    requestHash,
    responseJson,
    createdAt,
  ];
}

class WorkspaceMutationReceiptInclude extends _i1.IncludeObject {
  WorkspaceMutationReceiptInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => WorkspaceMutationReceipt.t;
}

class WorkspaceMutationReceiptIncludeList extends _i1.IncludeList {
  WorkspaceMutationReceiptIncludeList._({
    _i1.WhereExpressionBuilder<WorkspaceMutationReceiptTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(WorkspaceMutationReceipt.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => WorkspaceMutationReceipt.t;
}

class WorkspaceMutationReceiptRepository {
  const WorkspaceMutationReceiptRepository._();

  /// Returns a list of [WorkspaceMutationReceipt]s matching the given query parameters.
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
  Future<List<WorkspaceMutationReceipt>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<WorkspaceMutationReceiptTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<WorkspaceMutationReceiptTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<WorkspaceMutationReceiptTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<WorkspaceMutationReceipt>(
      where: where?.call(WorkspaceMutationReceipt.t),
      orderBy: orderBy?.call(WorkspaceMutationReceipt.t),
      orderByList: orderByList?.call(WorkspaceMutationReceipt.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [WorkspaceMutationReceipt] matching the given query parameters.
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
  Future<WorkspaceMutationReceipt?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<WorkspaceMutationReceiptTable>? where,
    int? offset,
    _i1.OrderByBuilder<WorkspaceMutationReceiptTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<WorkspaceMutationReceiptTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<WorkspaceMutationReceipt>(
      where: where?.call(WorkspaceMutationReceipt.t),
      orderBy: orderBy?.call(WorkspaceMutationReceipt.t),
      orderByList: orderByList?.call(WorkspaceMutationReceipt.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [WorkspaceMutationReceipt] by its [id] or null if no such row exists.
  Future<WorkspaceMutationReceipt?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<WorkspaceMutationReceipt>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [WorkspaceMutationReceipt]s in the list and returns the inserted rows.
  ///
  /// The returned [WorkspaceMutationReceipt]s will have their `id` fields set.
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
  Future<List<WorkspaceMutationReceipt>> insert(
    _i1.DatabaseSession session,
    List<WorkspaceMutationReceipt> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<WorkspaceMutationReceipt>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [WorkspaceMutationReceipt] and returns the inserted row.
  ///
  /// The returned [WorkspaceMutationReceipt] will have its `id` field set.
  Future<WorkspaceMutationReceipt> insertRow(
    _i1.DatabaseSession session,
    WorkspaceMutationReceipt row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<WorkspaceMutationReceipt>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [WorkspaceMutationReceipt]s in the list and returns the resulting rows.
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
  /// The returned [WorkspaceMutationReceipt]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WorkspaceMutationReceipt>> upsert(
    _i1.DatabaseSession session,
    List<WorkspaceMutationReceipt> rows, {
    required _i1.ColumnSelections<WorkspaceMutationReceiptTable>
    conflictColumns,
    _i1.ColumnSelections<WorkspaceMutationReceiptTable>? updateColumns,
    _i1.WhereExpressionBuilder<WorkspaceMutationReceiptTable>? updateWhere,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<WorkspaceMutationReceipt>(
      rows,
      conflictColumns: conflictColumns(WorkspaceMutationReceipt.t),
      updateColumns: updateColumns?.call(WorkspaceMutationReceipt.t),
      updateWhere: updateWhere?.call(WorkspaceMutationReceipt.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [WorkspaceMutationReceipt] and returns the resulting row.
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
  /// The returned [WorkspaceMutationReceipt] will have its `id` field set.
  Future<WorkspaceMutationReceipt?> upsertRow(
    _i1.DatabaseSession session,
    WorkspaceMutationReceipt row, {
    required _i1.ColumnSelections<WorkspaceMutationReceiptTable>
    conflictColumns,
    _i1.ColumnSelections<WorkspaceMutationReceiptTable>? updateColumns,
    _i1.WhereExpressionBuilder<WorkspaceMutationReceiptTable>? updateWhere,
    _i1.Transaction? transaction,
  }) async {
    return session.db.upsertRow<WorkspaceMutationReceipt>(
      row,
      conflictColumns: conflictColumns(WorkspaceMutationReceipt.t),
      updateColumns: updateColumns?.call(WorkspaceMutationReceipt.t),
      updateWhere: updateWhere?.call(WorkspaceMutationReceipt.t),
      transaction: transaction,
    );
  }

  /// Updates all [WorkspaceMutationReceipt]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WorkspaceMutationReceipt>> update(
    _i1.DatabaseSession session,
    List<WorkspaceMutationReceipt> rows, {
    _i1.ColumnSelections<WorkspaceMutationReceiptTable>? columns,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<WorkspaceMutationReceipt>(
      rows,
      columns: columns?.call(WorkspaceMutationReceipt.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [WorkspaceMutationReceipt]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<WorkspaceMutationReceipt> updateRow(
    _i1.DatabaseSession session,
    WorkspaceMutationReceipt row, {
    _i1.ColumnSelections<WorkspaceMutationReceiptTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<WorkspaceMutationReceipt>(
      row,
      columns: columns?.call(WorkspaceMutationReceipt.t),
      transaction: transaction,
    );
  }

  /// Updates a single [WorkspaceMutationReceipt] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<WorkspaceMutationReceipt?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<WorkspaceMutationReceiptUpdateTable>
    columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<WorkspaceMutationReceipt>(
      id,
      columnValues: columnValues(WorkspaceMutationReceipt.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [WorkspaceMutationReceipt]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WorkspaceMutationReceipt>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<WorkspaceMutationReceiptUpdateTable>
    columnValues,
    required _i1.WhereExpressionBuilder<WorkspaceMutationReceiptTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<WorkspaceMutationReceiptTable>? orderBy,
    _i1.OrderByListBuilder<WorkspaceMutationReceiptTable>? orderByList,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<WorkspaceMutationReceipt>(
      columnValues: columnValues(WorkspaceMutationReceipt.t.updateTable),
      where: where(WorkspaceMutationReceipt.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WorkspaceMutationReceipt.t),
      orderByList: orderByList?.call(WorkspaceMutationReceipt.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [WorkspaceMutationReceipt]s in the list and returns the deleted rows.
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
  Future<List<WorkspaceMutationReceipt>> delete(
    _i1.DatabaseSession session,
    List<WorkspaceMutationReceipt> rows, {
    _i1.OrderByBuilder<WorkspaceMutationReceiptTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<WorkspaceMutationReceiptTable>? orderByList,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<WorkspaceMutationReceipt>(
      rows,
      orderBy: orderBy?.call(WorkspaceMutationReceipt.t),
      orderByList: orderByList?.call(WorkspaceMutationReceipt.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [WorkspaceMutationReceipt].
  Future<WorkspaceMutationReceipt> deleteRow(
    _i1.DatabaseSession session,
    WorkspaceMutationReceipt row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<WorkspaceMutationReceipt>(
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
  Future<List<WorkspaceMutationReceipt>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<WorkspaceMutationReceiptTable> where,
    _i1.OrderByBuilder<WorkspaceMutationReceiptTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<WorkspaceMutationReceiptTable>? orderByList,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<WorkspaceMutationReceipt>(
      where: where(WorkspaceMutationReceipt.t),
      orderBy: orderBy?.call(WorkspaceMutationReceipt.t),
      orderByList: orderByList?.call(WorkspaceMutationReceipt.t),
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
    _i1.WhereExpressionBuilder<WorkspaceMutationReceiptTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<WorkspaceMutationReceipt>(
      where: where?.call(WorkspaceMutationReceipt.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [WorkspaceMutationReceipt] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<WorkspaceMutationReceiptTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<WorkspaceMutationReceipt>(
      where: where(WorkspaceMutationReceipt.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
