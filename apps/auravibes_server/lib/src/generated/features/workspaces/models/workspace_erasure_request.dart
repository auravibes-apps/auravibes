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

abstract class WorkspaceErasureRequest
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  WorkspaceErasureRequest._({
    this.id,
    required this.workspaceId,
    required this.workspaceName,
    required this.ownerUserId,
    required this.requestId,
    required this.requestHash,
    required this.state,
    required this.requestedAt,
    this.completedAt,
    this.failureReason,
  });

  factory WorkspaceErasureRequest({
    int? id,
    required int workspaceId,
    required String workspaceName,
    required String ownerUserId,
    required String requestId,
    required String requestHash,
    required String state,
    required DateTime requestedAt,
    DateTime? completedAt,
    String? failureReason,
  }) = _WorkspaceErasureRequestImpl;

  factory WorkspaceErasureRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return WorkspaceErasureRequest(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      workspaceName: jsonSerialization['workspaceName'] as String,
      ownerUserId: jsonSerialization['ownerUserId'] as String,
      requestId: jsonSerialization['requestId'] as String,
      requestHash: jsonSerialization['requestHash'] as String,
      state: jsonSerialization['state'] as String,
      requestedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['requestedAt'],
      ),
      completedAt: jsonSerialization['completedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['completedAt'],
            ),
      failureReason: jsonSerialization['failureReason'] as String?,
    );
  }

  static final t = WorkspaceErasureRequestTable();

  static const db = WorkspaceErasureRequestRepository._();

  @override
  int? id;

  int workspaceId;

  String workspaceName;

  String ownerUserId;

  String requestId;

  String requestHash;

  String state;

  DateTime requestedAt;

  DateTime? completedAt;

  String? failureReason;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [WorkspaceErasureRequest]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  WorkspaceErasureRequest copyWith({
    int? id,
    int? workspaceId,
    String? workspaceName,
    String? ownerUserId,
    String? requestId,
    String? requestHash,
    String? state,
    DateTime? requestedAt,
    DateTime? completedAt,
    String? failureReason,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WorkspaceErasureRequest',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'workspaceName': workspaceName,
      'ownerUserId': ownerUserId,
      'requestId': requestId,
      'requestHash': requestHash,
      'state': state,
      'requestedAt': requestedAt.toJson(),
      if (completedAt != null) 'completedAt': completedAt?.toJson(),
      if (failureReason != null) 'failureReason': failureReason,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WorkspaceErasureRequest',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'workspaceName': workspaceName,
      'ownerUserId': ownerUserId,
      'requestId': requestId,
      'requestHash': requestHash,
      'state': state,
      'requestedAt': requestedAt.toJson(),
      if (completedAt != null) 'completedAt': completedAt?.toJson(),
      if (failureReason != null) 'failureReason': failureReason,
    };
  }

  static WorkspaceErasureRequestInclude include() {
    return WorkspaceErasureRequestInclude._();
  }

  static WorkspaceErasureRequestIncludeList includeList({
    _is.WhereExpressionBuilder<WorkspaceErasureRequestTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<WorkspaceErasureRequestTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceErasureRequestTable>? orderByList,
    WorkspaceErasureRequestInclude? include,
  }) {
    return WorkspaceErasureRequestIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WorkspaceErasureRequest.t),
      orderByList: orderByList?.call(WorkspaceErasureRequest.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WorkspaceErasureRequestImpl extends WorkspaceErasureRequest {
  _WorkspaceErasureRequestImpl({
    int? id,
    required int workspaceId,
    required String workspaceName,
    required String ownerUserId,
    required String requestId,
    required String requestHash,
    required String state,
    required DateTime requestedAt,
    DateTime? completedAt,
    String? failureReason,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         workspaceName: workspaceName,
         ownerUserId: ownerUserId,
         requestId: requestId,
         requestHash: requestHash,
         state: state,
         requestedAt: requestedAt,
         completedAt: completedAt,
         failureReason: failureReason,
       );

  /// Returns a shallow copy of this [WorkspaceErasureRequest]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  WorkspaceErasureRequest copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    String? workspaceName,
    String? ownerUserId,
    String? requestId,
    String? requestHash,
    String? state,
    DateTime? requestedAt,
    Object? completedAt = _Undefined,
    Object? failureReason = _Undefined,
  }) {
    return WorkspaceErasureRequest(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      workspaceName: workspaceName ?? this.workspaceName,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      requestId: requestId ?? this.requestId,
      requestHash: requestHash ?? this.requestHash,
      state: state ?? this.state,
      requestedAt: requestedAt ?? this.requestedAt,
      completedAt: completedAt is DateTime? ? completedAt : this.completedAt,
      failureReason: failureReason is String?
          ? failureReason
          : this.failureReason,
    );
  }
}

class WorkspaceErasureRequestUpdateTable
    extends _is.UpdateTable<WorkspaceErasureRequestTable> {
  WorkspaceErasureRequestUpdateTable(super.table);

  _is.ColumnValue<int, int> workspaceId(int value) => _is.ColumnValue(
    table.workspaceId,
    value,
  );

  _is.ColumnValue<String, String> workspaceName(String value) =>
      _is.ColumnValue(
        table.workspaceName,
        value,
      );

  _is.ColumnValue<String, String> ownerUserId(String value) => _is.ColumnValue(
    table.ownerUserId,
    value,
  );

  _is.ColumnValue<String, String> requestId(String value) => _is.ColumnValue(
    table.requestId,
    value,
  );

  _is.ColumnValue<String, String> requestHash(String value) => _is.ColumnValue(
    table.requestHash,
    value,
  );

  _is.ColumnValue<String, String> state(String value) => _is.ColumnValue(
    table.state,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> requestedAt(DateTime value) =>
      _is.ColumnValue(
        table.requestedAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> completedAt(DateTime? value) =>
      _is.ColumnValue(
        table.completedAt,
        value,
      );

  _is.ColumnValue<String, String> failureReason(String? value) =>
      _is.ColumnValue(
        table.failureReason,
        value,
      );
}

class WorkspaceErasureRequestTable extends _is.Table<int?> {
  WorkspaceErasureRequestTable({super.tableRelation})
    : super(tableName: 'workspace_erasure_request') {
    updateTable = WorkspaceErasureRequestUpdateTable(this);
    workspaceId = _is.ColumnInt(
      'workspaceId',
      this,
    );
    workspaceName = _is.ColumnString(
      'workspaceName',
      this,
    );
    ownerUserId = _is.ColumnString(
      'ownerUserId',
      this,
    );
    requestId = _is.ColumnString(
      'requestId',
      this,
    );
    requestHash = _is.ColumnString(
      'requestHash',
      this,
    );
    state = _is.ColumnString(
      'state',
      this,
    );
    requestedAt = _is.ColumnDateTime(
      'requestedAt',
      this,
    );
    completedAt = _is.ColumnDateTime(
      'completedAt',
      this,
    );
    failureReason = _is.ColumnString(
      'failureReason',
      this,
    );
  }

  late final WorkspaceErasureRequestUpdateTable updateTable;

  late final _is.ColumnInt workspaceId;

  late final _is.ColumnString workspaceName;

  late final _is.ColumnString ownerUserId;

  late final _is.ColumnString requestId;

  late final _is.ColumnString requestHash;

  late final _is.ColumnString state;

  late final _is.ColumnDateTime requestedAt;

  late final _is.ColumnDateTime completedAt;

  late final _is.ColumnString failureReason;

  @override
  List<_is.Column> get columns => [
    id,
    workspaceId,
    workspaceName,
    ownerUserId,
    requestId,
    requestHash,
    state,
    requestedAt,
    completedAt,
    failureReason,
  ];
}

class WorkspaceErasureRequestInclude extends _is.IncludeObject {
  WorkspaceErasureRequestInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => WorkspaceErasureRequest.t;
}

class WorkspaceErasureRequestIncludeList extends _is.IncludeList {
  WorkspaceErasureRequestIncludeList._({
    _is.WhereExpressionBuilder<WorkspaceErasureRequestTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(WorkspaceErasureRequest.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => WorkspaceErasureRequest.t;
}

class WorkspaceErasureRequestRepository {
  const WorkspaceErasureRequestRepository._();

  /// Returns a list of [WorkspaceErasureRequest]s matching the given query parameters.
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
  Future<List<WorkspaceErasureRequest>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<WorkspaceErasureRequestTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<WorkspaceErasureRequestTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceErasureRequestTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<WorkspaceErasureRequest>(
      where: where?.call(WorkspaceErasureRequest.t),
      orderBy: orderBy?.call(WorkspaceErasureRequest.t),
      orderByList: orderByList?.call(WorkspaceErasureRequest.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [WorkspaceErasureRequest] matching the given query parameters.
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
  Future<WorkspaceErasureRequest?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<WorkspaceErasureRequestTable>? where,
    int? offset,
    _is.OrderByBuilder<WorkspaceErasureRequestTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceErasureRequestTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<WorkspaceErasureRequest>(
      where: where?.call(WorkspaceErasureRequest.t),
      orderBy: orderBy?.call(WorkspaceErasureRequest.t),
      orderByList: orderByList?.call(WorkspaceErasureRequest.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [WorkspaceErasureRequest] by its [id] or null if no such row exists.
  Future<WorkspaceErasureRequest?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<WorkspaceErasureRequest>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [WorkspaceErasureRequest]s in the list and returns the inserted rows.
  ///
  /// The returned [WorkspaceErasureRequest]s will have their `id` fields set.
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
  Future<List<WorkspaceErasureRequest>> insert(
    _is.DatabaseSession session,
    List<WorkspaceErasureRequest> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<WorkspaceErasureRequest>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [WorkspaceErasureRequest] and returns the inserted row.
  ///
  /// The returned [WorkspaceErasureRequest] will have its `id` field set.
  Future<WorkspaceErasureRequest> insertRow(
    _is.DatabaseSession session,
    WorkspaceErasureRequest row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<WorkspaceErasureRequest>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [WorkspaceErasureRequest]s in the list and returns the resulting rows.
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
  /// The returned [WorkspaceErasureRequest]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WorkspaceErasureRequest>> upsert(
    _is.DatabaseSession session,
    List<WorkspaceErasureRequest> rows, {
    required _is.ColumnSelections<WorkspaceErasureRequestTable> conflictColumns,
    _is.ColumnSelections<WorkspaceErasureRequestTable>? updateColumns,
    _is.WhereExpressionBuilder<WorkspaceErasureRequestTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<WorkspaceErasureRequest>(
      rows,
      conflictColumns: conflictColumns(WorkspaceErasureRequest.t),
      updateColumns: updateColumns?.call(WorkspaceErasureRequest.t),
      updateWhere: updateWhere?.call(WorkspaceErasureRequest.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [WorkspaceErasureRequest] and returns the resulting row.
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
  /// The returned [WorkspaceErasureRequest] will have its `id` field set.
  Future<WorkspaceErasureRequest?> upsertRow(
    _is.DatabaseSession session,
    WorkspaceErasureRequest row, {
    required _is.ColumnSelections<WorkspaceErasureRequestTable> conflictColumns,
    _is.ColumnSelections<WorkspaceErasureRequestTable>? updateColumns,
    _is.WhereExpressionBuilder<WorkspaceErasureRequestTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<WorkspaceErasureRequest>(
      row,
      conflictColumns: conflictColumns(WorkspaceErasureRequest.t),
      updateColumns: updateColumns?.call(WorkspaceErasureRequest.t),
      updateWhere: updateWhere?.call(WorkspaceErasureRequest.t),
      transaction: transaction,
    );
  }

  /// Updates all [WorkspaceErasureRequest]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WorkspaceErasureRequest>> update(
    _is.DatabaseSession session,
    List<WorkspaceErasureRequest> rows, {
    _is.ColumnSelections<WorkspaceErasureRequestTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<WorkspaceErasureRequest>(
      rows,
      columns: columns?.call(WorkspaceErasureRequest.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [WorkspaceErasureRequest]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<WorkspaceErasureRequest> updateRow(
    _is.DatabaseSession session,
    WorkspaceErasureRequest row, {
    _is.ColumnSelections<WorkspaceErasureRequestTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<WorkspaceErasureRequest>(
      row,
      columns: columns?.call(WorkspaceErasureRequest.t),
      transaction: transaction,
    );
  }

  /// Updates a single [WorkspaceErasureRequest] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<WorkspaceErasureRequest?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<WorkspaceErasureRequestUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<WorkspaceErasureRequest>(
      id,
      columnValues: columnValues(WorkspaceErasureRequest.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [WorkspaceErasureRequest]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WorkspaceErasureRequest>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<WorkspaceErasureRequestUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<WorkspaceErasureRequestTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<WorkspaceErasureRequestTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceErasureRequestTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<WorkspaceErasureRequest>(
      columnValues: columnValues(WorkspaceErasureRequest.t.updateTable),
      where: where(WorkspaceErasureRequest.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WorkspaceErasureRequest.t),
      orderByList: orderByList?.call(WorkspaceErasureRequest.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [WorkspaceErasureRequest]s in the list and returns the deleted rows.
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
  Future<List<WorkspaceErasureRequest>> delete(
    _is.DatabaseSession session,
    List<WorkspaceErasureRequest> rows, {
    _is.OrderByBuilder<WorkspaceErasureRequestTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceErasureRequestTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<WorkspaceErasureRequest>(
      rows,
      orderBy: orderBy?.call(WorkspaceErasureRequest.t),
      orderByList: orderByList?.call(WorkspaceErasureRequest.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [WorkspaceErasureRequest].
  Future<WorkspaceErasureRequest> deleteRow(
    _is.DatabaseSession session,
    WorkspaceErasureRequest row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<WorkspaceErasureRequest>(
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
  Future<List<WorkspaceErasureRequest>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<WorkspaceErasureRequestTable> where,
    _is.OrderByBuilder<WorkspaceErasureRequestTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceErasureRequestTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<WorkspaceErasureRequest>(
      where: where(WorkspaceErasureRequest.t),
      orderBy: orderBy?.call(WorkspaceErasureRequest.t),
      orderByList: orderByList?.call(WorkspaceErasureRequest.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<WorkspaceErasureRequestTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<WorkspaceErasureRequest>(
      where: where?.call(WorkspaceErasureRequest.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [WorkspaceErasureRequest] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<WorkspaceErasureRequestTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<WorkspaceErasureRequest>(
      where: where(WorkspaceErasureRequest.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
