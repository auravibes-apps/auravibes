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

abstract class WorkspaceModelConnection
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  WorkspaceModelConnection._({
    this.id,
    required this.workspaceId,
    required this.connectionId,
    required this.providerId,
    required this.name,
    this.url,
    this.keySuffix,
    required this.hasSecret,
    required this.revision,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory WorkspaceModelConnection({
    int? id,
    required int workspaceId,
    required String connectionId,
    required String providerId,
    required String name,
    String? url,
    String? keySuffix,
    required bool hasSecret,
    required int revision,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
  }) = _WorkspaceModelConnectionImpl;

  factory WorkspaceModelConnection.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return WorkspaceModelConnection(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      connectionId: jsonSerialization['connectionId'] as String,
      providerId: jsonSerialization['providerId'] as String,
      name: jsonSerialization['name'] as String,
      url: jsonSerialization['url'] as String?,
      keySuffix: jsonSerialization['keySuffix'] as String?,
      hasSecret: _is.BoolJsonExtension.fromJson(jsonSerialization['hasSecret']),
      revision: jsonSerialization['revision'] as int,
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
      deletedAt: jsonSerialization['deletedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['deletedAt']),
    );
  }

  static final t = WorkspaceModelConnectionTable();

  static const db = WorkspaceModelConnectionRepository._();

  @override
  int? id;

  int workspaceId;

  String connectionId;

  String providerId;

  String name;

  String? url;

  String? keySuffix;

  bool hasSecret;

  int revision;

  DateTime createdAt;

  DateTime updatedAt;

  DateTime? deletedAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [WorkspaceModelConnection]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  WorkspaceModelConnection copyWith({
    int? id,
    int? workspaceId,
    String? connectionId,
    String? providerId,
    String? name,
    String? url,
    String? keySuffix,
    bool? hasSecret,
    int? revision,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WorkspaceModelConnection',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'connectionId': connectionId,
      'providerId': providerId,
      'name': name,
      if (url != null) 'url': url,
      if (keySuffix != null) 'keySuffix': keySuffix,
      'hasSecret': hasSecret,
      'revision': revision,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      if (deletedAt != null) 'deletedAt': deletedAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WorkspaceModelConnection',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'connectionId': connectionId,
      'providerId': providerId,
      'name': name,
      if (url != null) 'url': url,
      if (keySuffix != null) 'keySuffix': keySuffix,
      'hasSecret': hasSecret,
      'revision': revision,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      if (deletedAt != null) 'deletedAt': deletedAt?.toJson(),
    };
  }

  static WorkspaceModelConnectionInclude include() {
    return WorkspaceModelConnectionInclude._();
  }

  static WorkspaceModelConnectionIncludeList includeList({
    _is.WhereExpressionBuilder<WorkspaceModelConnectionTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<WorkspaceModelConnectionTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceModelConnectionTable>? orderByList,
    WorkspaceModelConnectionInclude? include,
  }) {
    return WorkspaceModelConnectionIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WorkspaceModelConnection.t),
      orderByList: orderByList?.call(WorkspaceModelConnection.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WorkspaceModelConnectionImpl extends WorkspaceModelConnection {
  _WorkspaceModelConnectionImpl({
    int? id,
    required int workspaceId,
    required String connectionId,
    required String providerId,
    required String name,
    String? url,
    String? keySuffix,
    required bool hasSecret,
    required int revision,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         connectionId: connectionId,
         providerId: providerId,
         name: name,
         url: url,
         keySuffix: keySuffix,
         hasSecret: hasSecret,
         revision: revision,
         createdAt: createdAt,
         updatedAt: updatedAt,
         deletedAt: deletedAt,
       );

  /// Returns a shallow copy of this [WorkspaceModelConnection]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  WorkspaceModelConnection copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    String? connectionId,
    String? providerId,
    String? name,
    Object? url = _Undefined,
    Object? keySuffix = _Undefined,
    bool? hasSecret,
    int? revision,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? deletedAt = _Undefined,
  }) {
    return WorkspaceModelConnection(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      connectionId: connectionId ?? this.connectionId,
      providerId: providerId ?? this.providerId,
      name: name ?? this.name,
      url: url is String? ? url : this.url,
      keySuffix: keySuffix is String? ? keySuffix : this.keySuffix,
      hasSecret: hasSecret ?? this.hasSecret,
      revision: revision ?? this.revision,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt is DateTime? ? deletedAt : this.deletedAt,
    );
  }
}

class WorkspaceModelConnectionUpdateTable
    extends _is.UpdateTable<WorkspaceModelConnectionTable> {
  WorkspaceModelConnectionUpdateTable(super.table);

  _is.ColumnValue<int, int> workspaceId(int value) => _is.ColumnValue(
    table.workspaceId,
    value,
  );

  _is.ColumnValue<String, String> connectionId(String value) => _is.ColumnValue(
    table.connectionId,
    value,
  );

  _is.ColumnValue<String, String> providerId(String value) => _is.ColumnValue(
    table.providerId,
    value,
  );

  _is.ColumnValue<String, String> name(String value) => _is.ColumnValue(
    table.name,
    value,
  );

  _is.ColumnValue<String, String> url(String? value) => _is.ColumnValue(
    table.url,
    value,
  );

  _is.ColumnValue<String, String> keySuffix(String? value) => _is.ColumnValue(
    table.keySuffix,
    value,
  );

  _is.ColumnValue<bool, bool> hasSecret(bool value) => _is.ColumnValue(
    table.hasSecret,
    value,
  );

  _is.ColumnValue<int, int> revision(int value) => _is.ColumnValue(
    table.revision,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> updatedAt(DateTime value) =>
      _is.ColumnValue(
        table.updatedAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> deletedAt(DateTime? value) =>
      _is.ColumnValue(
        table.deletedAt,
        value,
      );
}

class WorkspaceModelConnectionTable extends _is.Table<int?> {
  WorkspaceModelConnectionTable({super.tableRelation})
    : super(tableName: 'workspace_model_connection') {
    updateTable = WorkspaceModelConnectionUpdateTable(this);
    workspaceId = _is.ColumnInt(
      'workspaceId',
      this,
    );
    connectionId = _is.ColumnString(
      'connectionId',
      this,
    );
    providerId = _is.ColumnString(
      'providerId',
      this,
    );
    name = _is.ColumnString(
      'name',
      this,
    );
    url = _is.ColumnString(
      'url',
      this,
    );
    keySuffix = _is.ColumnString(
      'keySuffix',
      this,
    );
    hasSecret = _is.ColumnBool(
      'hasSecret',
      this,
    );
    revision = _is.ColumnInt(
      'revision',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
    updatedAt = _is.ColumnDateTime(
      'updatedAt',
      this,
    );
    deletedAt = _is.ColumnDateTime(
      'deletedAt',
      this,
    );
  }

  late final WorkspaceModelConnectionUpdateTable updateTable;

  late final _is.ColumnInt workspaceId;

  late final _is.ColumnString connectionId;

  late final _is.ColumnString providerId;

  late final _is.ColumnString name;

  late final _is.ColumnString url;

  late final _is.ColumnString keySuffix;

  late final _is.ColumnBool hasSecret;

  late final _is.ColumnInt revision;

  late final _is.ColumnDateTime createdAt;

  late final _is.ColumnDateTime updatedAt;

  late final _is.ColumnDateTime deletedAt;

  @override
  List<_is.Column> get columns => [
    id,
    workspaceId,
    connectionId,
    providerId,
    name,
    url,
    keySuffix,
    hasSecret,
    revision,
    createdAt,
    updatedAt,
    deletedAt,
  ];
}

class WorkspaceModelConnectionInclude extends _is.IncludeObject {
  WorkspaceModelConnectionInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => WorkspaceModelConnection.t;
}

class WorkspaceModelConnectionIncludeList extends _is.IncludeList {
  WorkspaceModelConnectionIncludeList._({
    _is.WhereExpressionBuilder<WorkspaceModelConnectionTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(WorkspaceModelConnection.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => WorkspaceModelConnection.t;
}

class WorkspaceModelConnectionRepository {
  const WorkspaceModelConnectionRepository._();

  /// Returns a list of [WorkspaceModelConnection]s matching the given query parameters.
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
  Future<List<WorkspaceModelConnection>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<WorkspaceModelConnectionTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<WorkspaceModelConnectionTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceModelConnectionTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<WorkspaceModelConnection>(
      where: where?.call(WorkspaceModelConnection.t),
      orderBy: orderBy?.call(WorkspaceModelConnection.t),
      orderByList: orderByList?.call(WorkspaceModelConnection.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [WorkspaceModelConnection] matching the given query parameters.
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
  Future<WorkspaceModelConnection?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<WorkspaceModelConnectionTable>? where,
    int? offset,
    _is.OrderByBuilder<WorkspaceModelConnectionTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceModelConnectionTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<WorkspaceModelConnection>(
      where: where?.call(WorkspaceModelConnection.t),
      orderBy: orderBy?.call(WorkspaceModelConnection.t),
      orderByList: orderByList?.call(WorkspaceModelConnection.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [WorkspaceModelConnection] by its [id] or null if no such row exists.
  Future<WorkspaceModelConnection?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<WorkspaceModelConnection>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [WorkspaceModelConnection]s in the list and returns the inserted rows.
  ///
  /// The returned [WorkspaceModelConnection]s will have their `id` fields set.
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
  Future<List<WorkspaceModelConnection>> insert(
    _is.DatabaseSession session,
    List<WorkspaceModelConnection> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<WorkspaceModelConnection>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [WorkspaceModelConnection] and returns the inserted row.
  ///
  /// The returned [WorkspaceModelConnection] will have its `id` field set.
  Future<WorkspaceModelConnection> insertRow(
    _is.DatabaseSession session,
    WorkspaceModelConnection row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<WorkspaceModelConnection>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [WorkspaceModelConnection]s in the list and returns the resulting rows.
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
  /// The returned [WorkspaceModelConnection]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WorkspaceModelConnection>> upsert(
    _is.DatabaseSession session,
    List<WorkspaceModelConnection> rows, {
    required _is.ColumnSelections<WorkspaceModelConnectionTable>
    conflictColumns,
    _is.ColumnSelections<WorkspaceModelConnectionTable>? updateColumns,
    _is.WhereExpressionBuilder<WorkspaceModelConnectionTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<WorkspaceModelConnection>(
      rows,
      conflictColumns: conflictColumns(WorkspaceModelConnection.t),
      updateColumns: updateColumns?.call(WorkspaceModelConnection.t),
      updateWhere: updateWhere?.call(WorkspaceModelConnection.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [WorkspaceModelConnection] and returns the resulting row.
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
  /// The returned [WorkspaceModelConnection] will have its `id` field set.
  Future<WorkspaceModelConnection?> upsertRow(
    _is.DatabaseSession session,
    WorkspaceModelConnection row, {
    required _is.ColumnSelections<WorkspaceModelConnectionTable>
    conflictColumns,
    _is.ColumnSelections<WorkspaceModelConnectionTable>? updateColumns,
    _is.WhereExpressionBuilder<WorkspaceModelConnectionTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<WorkspaceModelConnection>(
      row,
      conflictColumns: conflictColumns(WorkspaceModelConnection.t),
      updateColumns: updateColumns?.call(WorkspaceModelConnection.t),
      updateWhere: updateWhere?.call(WorkspaceModelConnection.t),
      transaction: transaction,
    );
  }

  /// Updates all [WorkspaceModelConnection]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WorkspaceModelConnection>> update(
    _is.DatabaseSession session,
    List<WorkspaceModelConnection> rows, {
    _is.ColumnSelections<WorkspaceModelConnectionTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<WorkspaceModelConnection>(
      rows,
      columns: columns?.call(WorkspaceModelConnection.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [WorkspaceModelConnection]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<WorkspaceModelConnection> updateRow(
    _is.DatabaseSession session,
    WorkspaceModelConnection row, {
    _is.ColumnSelections<WorkspaceModelConnectionTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<WorkspaceModelConnection>(
      row,
      columns: columns?.call(WorkspaceModelConnection.t),
      transaction: transaction,
    );
  }

  /// Updates a single [WorkspaceModelConnection] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<WorkspaceModelConnection?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<WorkspaceModelConnectionUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<WorkspaceModelConnection>(
      id,
      columnValues: columnValues(WorkspaceModelConnection.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [WorkspaceModelConnection]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WorkspaceModelConnection>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<WorkspaceModelConnectionUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<WorkspaceModelConnectionTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<WorkspaceModelConnectionTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceModelConnectionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<WorkspaceModelConnection>(
      columnValues: columnValues(WorkspaceModelConnection.t.updateTable),
      where: where(WorkspaceModelConnection.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WorkspaceModelConnection.t),
      orderByList: orderByList?.call(WorkspaceModelConnection.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [WorkspaceModelConnection]s in the list and returns the deleted rows.
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
  Future<List<WorkspaceModelConnection>> delete(
    _is.DatabaseSession session,
    List<WorkspaceModelConnection> rows, {
    _is.OrderByBuilder<WorkspaceModelConnectionTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceModelConnectionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<WorkspaceModelConnection>(
      rows,
      orderBy: orderBy?.call(WorkspaceModelConnection.t),
      orderByList: orderByList?.call(WorkspaceModelConnection.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [WorkspaceModelConnection].
  Future<WorkspaceModelConnection> deleteRow(
    _is.DatabaseSession session,
    WorkspaceModelConnection row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<WorkspaceModelConnection>(
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
  Future<List<WorkspaceModelConnection>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<WorkspaceModelConnectionTable> where,
    _is.OrderByBuilder<WorkspaceModelConnectionTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceModelConnectionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<WorkspaceModelConnection>(
      where: where(WorkspaceModelConnection.t),
      orderBy: orderBy?.call(WorkspaceModelConnection.t),
      orderByList: orderByList?.call(WorkspaceModelConnection.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<WorkspaceModelConnectionTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<WorkspaceModelConnection>(
      where: where?.call(WorkspaceModelConnection.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [WorkspaceModelConnection] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<WorkspaceModelConnectionTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<WorkspaceModelConnection>(
      where: where(WorkspaceModelConnection.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
