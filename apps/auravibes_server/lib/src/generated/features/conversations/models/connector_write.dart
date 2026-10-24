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

abstract class ConnectorWrite
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  ConnectorWrite._({
    this.id,
    required this.workspaceId,
    required this.operationId,
    required this.requestDigest,
    required this.outcome,
    this.statusCode,
  });

  factory ConnectorWrite({
    int? id,
    required int workspaceId,
    required String operationId,
    required String requestDigest,
    required String outcome,
    int? statusCode,
  }) = _ConnectorWriteImpl;

  factory ConnectorWrite.fromJson(Map<String, dynamic> jsonSerialization) {
    return ConnectorWrite(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      operationId: jsonSerialization['operationId'] as String,
      requestDigest: jsonSerialization['requestDigest'] as String,
      outcome: jsonSerialization['outcome'] as String,
      statusCode: jsonSerialization['statusCode'] as int?,
    );
  }

  static final t = ConnectorWriteTable();

  static const db = ConnectorWriteRepository._();

  @override
  int? id;

  int workspaceId;

  String operationId;

  String requestDigest;

  String outcome;

  int? statusCode;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [ConnectorWrite]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ConnectorWrite copyWith({
    int? id,
    int? workspaceId,
    String? operationId,
    String? requestDigest,
    String? outcome,
    int? statusCode,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ConnectorWrite',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'operationId': operationId,
      'requestDigest': requestDigest,
      'outcome': outcome,
      if (statusCode != null) 'statusCode': statusCode,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ConnectorWrite',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'operationId': operationId,
      'requestDigest': requestDigest,
      'outcome': outcome,
      if (statusCode != null) 'statusCode': statusCode,
    };
  }

  static ConnectorWriteInclude include() {
    return ConnectorWriteInclude._();
  }

  static ConnectorWriteIncludeList includeList({
    _is.WhereExpressionBuilder<ConnectorWriteTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ConnectorWriteTable>? orderBy,
    _is.OrderByListBuilder<ConnectorWriteTable>? orderByList,
    ConnectorWriteInclude? include,
  }) {
    return ConnectorWriteIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ConnectorWrite.t),
      orderByList: orderByList?.call(ConnectorWrite.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ConnectorWriteImpl extends ConnectorWrite {
  _ConnectorWriteImpl({
    int? id,
    required int workspaceId,
    required String operationId,
    required String requestDigest,
    required String outcome,
    int? statusCode,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         operationId: operationId,
         requestDigest: requestDigest,
         outcome: outcome,
         statusCode: statusCode,
       );

  /// Returns a shallow copy of this [ConnectorWrite]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ConnectorWrite copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    String? operationId,
    String? requestDigest,
    String? outcome,
    Object? statusCode = _Undefined,
  }) {
    return ConnectorWrite(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      operationId: operationId ?? this.operationId,
      requestDigest: requestDigest ?? this.requestDigest,
      outcome: outcome ?? this.outcome,
      statusCode: statusCode is int? ? statusCode : this.statusCode,
    );
  }
}

class ConnectorWriteUpdateTable extends _is.UpdateTable<ConnectorWriteTable> {
  ConnectorWriteUpdateTable(super.table);

  _is.ColumnValue<int, int> workspaceId(int value) => _is.ColumnValue(
    table.workspaceId,
    value,
  );

  _is.ColumnValue<String, String> operationId(String value) => _is.ColumnValue(
    table.operationId,
    value,
  );

  _is.ColumnValue<String, String> requestDigest(String value) =>
      _is.ColumnValue(
        table.requestDigest,
        value,
      );

  _is.ColumnValue<String, String> outcome(String value) => _is.ColumnValue(
    table.outcome,
    value,
  );

  _is.ColumnValue<int, int> statusCode(int? value) => _is.ColumnValue(
    table.statusCode,
    value,
  );
}

class ConnectorWriteTable extends _is.Table<int?> {
  ConnectorWriteTable({super.tableRelation})
    : super(tableName: 'connector_write') {
    updateTable = ConnectorWriteUpdateTable(this);
    workspaceId = _is.ColumnInt(
      'workspaceId',
      this,
    );
    operationId = _is.ColumnString(
      'operationId',
      this,
    );
    requestDigest = _is.ColumnString(
      'requestDigest',
      this,
    );
    outcome = _is.ColumnString(
      'outcome',
      this,
    );
    statusCode = _is.ColumnInt(
      'statusCode',
      this,
    );
  }

  late final ConnectorWriteUpdateTable updateTable;

  late final _is.ColumnInt workspaceId;

  late final _is.ColumnString operationId;

  late final _is.ColumnString requestDigest;

  late final _is.ColumnString outcome;

  late final _is.ColumnInt statusCode;

  @override
  List<_is.Column> get columns => [
    id,
    workspaceId,
    operationId,
    requestDigest,
    outcome,
    statusCode,
  ];
}

class ConnectorWriteInclude extends _is.IncludeObject {
  ConnectorWriteInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => ConnectorWrite.t;
}

class ConnectorWriteIncludeList extends _is.IncludeList {
  ConnectorWriteIncludeList._({
    _is.WhereExpressionBuilder<ConnectorWriteTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ConnectorWrite.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => ConnectorWrite.t;
}

class ConnectorWriteRepository {
  const ConnectorWriteRepository._();

  /// Returns a list of [ConnectorWrite]s matching the given query parameters.
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
  Future<List<ConnectorWrite>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ConnectorWriteTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ConnectorWriteTable>? orderBy,
    _is.OrderByListBuilder<ConnectorWriteTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ConnectorWrite>(
      where: where?.call(ConnectorWrite.t),
      orderBy: orderBy?.call(ConnectorWrite.t),
      orderByList: orderByList?.call(ConnectorWrite.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [ConnectorWrite] matching the given query parameters.
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
  Future<ConnectorWrite?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ConnectorWriteTable>? where,
    int? offset,
    _is.OrderByBuilder<ConnectorWriteTable>? orderBy,
    _is.OrderByListBuilder<ConnectorWriteTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ConnectorWrite>(
      where: where?.call(ConnectorWrite.t),
      orderBy: orderBy?.call(ConnectorWrite.t),
      orderByList: orderByList?.call(ConnectorWrite.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ConnectorWrite] by its [id] or null if no such row exists.
  Future<ConnectorWrite?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ConnectorWrite>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ConnectorWrite]s in the list and returns the inserted rows.
  ///
  /// The returned [ConnectorWrite]s will have their `id` fields set.
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
  Future<List<ConnectorWrite>> insert(
    _is.DatabaseSession session,
    List<ConnectorWrite> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<ConnectorWrite>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [ConnectorWrite] and returns the inserted row.
  ///
  /// The returned [ConnectorWrite] will have its `id` field set.
  Future<ConnectorWrite> insertRow(
    _is.DatabaseSession session,
    ConnectorWrite row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<ConnectorWrite>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [ConnectorWrite]s in the list and returns the resulting rows.
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
  /// The returned [ConnectorWrite]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ConnectorWrite>> upsert(
    _is.DatabaseSession session,
    List<ConnectorWrite> rows, {
    required _is.ColumnSelections<ConnectorWriteTable> conflictColumns,
    _is.ColumnSelections<ConnectorWriteTable>? updateColumns,
    _is.WhereExpressionBuilder<ConnectorWriteTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<ConnectorWrite>(
      rows,
      conflictColumns: conflictColumns(ConnectorWrite.t),
      updateColumns: updateColumns?.call(ConnectorWrite.t),
      updateWhere: updateWhere?.call(ConnectorWrite.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [ConnectorWrite] and returns the resulting row.
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
  /// The returned [ConnectorWrite] will have its `id` field set.
  Future<ConnectorWrite?> upsertRow(
    _is.DatabaseSession session,
    ConnectorWrite row, {
    required _is.ColumnSelections<ConnectorWriteTable> conflictColumns,
    _is.ColumnSelections<ConnectorWriteTable>? updateColumns,
    _is.WhereExpressionBuilder<ConnectorWriteTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<ConnectorWrite>(
      row,
      conflictColumns: conflictColumns(ConnectorWrite.t),
      updateColumns: updateColumns?.call(ConnectorWrite.t),
      updateWhere: updateWhere?.call(ConnectorWrite.t),
      transaction: transaction,
    );
  }

  /// Updates all [ConnectorWrite]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ConnectorWrite>> update(
    _is.DatabaseSession session,
    List<ConnectorWrite> rows, {
    _is.ColumnSelections<ConnectorWriteTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<ConnectorWrite>(
      rows,
      columns: columns?.call(ConnectorWrite.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [ConnectorWrite]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ConnectorWrite> updateRow(
    _is.DatabaseSession session,
    ConnectorWrite row, {
    _is.ColumnSelections<ConnectorWriteTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<ConnectorWrite>(
      row,
      columns: columns?.call(ConnectorWrite.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ConnectorWrite] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ConnectorWrite?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<ConnectorWriteUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<ConnectorWrite>(
      id,
      columnValues: columnValues(ConnectorWrite.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ConnectorWrite]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ConnectorWrite>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<ConnectorWriteUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<ConnectorWriteTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ConnectorWriteTable>? orderBy,
    _is.OrderByListBuilder<ConnectorWriteTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<ConnectorWrite>(
      columnValues: columnValues(ConnectorWrite.t.updateTable),
      where: where(ConnectorWrite.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ConnectorWrite.t),
      orderByList: orderByList?.call(ConnectorWrite.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [ConnectorWrite]s in the list and returns the deleted rows.
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
  Future<List<ConnectorWrite>> delete(
    _is.DatabaseSession session,
    List<ConnectorWrite> rows, {
    _is.OrderByBuilder<ConnectorWriteTable>? orderBy,
    _is.OrderByListBuilder<ConnectorWriteTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<ConnectorWrite>(
      rows,
      orderBy: orderBy?.call(ConnectorWrite.t),
      orderByList: orderByList?.call(ConnectorWrite.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [ConnectorWrite].
  Future<ConnectorWrite> deleteRow(
    _is.DatabaseSession session,
    ConnectorWrite row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ConnectorWrite>(
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
  Future<List<ConnectorWrite>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ConnectorWriteTable> where,
    _is.OrderByBuilder<ConnectorWriteTable>? orderBy,
    _is.OrderByListBuilder<ConnectorWriteTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<ConnectorWrite>(
      where: where(ConnectorWrite.t),
      orderBy: orderBy?.call(ConnectorWrite.t),
      orderByList: orderByList?.call(ConnectorWrite.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ConnectorWriteTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<ConnectorWrite>(
      where: where?.call(ConnectorWrite.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ConnectorWrite] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ConnectorWriteTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ConnectorWrite>(
      where: where(ConnectorWrite.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
