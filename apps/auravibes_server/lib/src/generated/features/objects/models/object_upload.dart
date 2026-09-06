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

abstract class ObjectUpload
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  ObjectUpload._({
    this.id,
    required this.workspaceId,
    required this.objectId,
    required this.actorUserId,
    required this.requestId,
    required this.requestHash,
    required this.expiresAt,
    this.completedAt,
    required this.createdAt,
  });

  factory ObjectUpload({
    int? id,
    required int workspaceId,
    required int objectId,
    required String actorUserId,
    required String requestId,
    required String requestHash,
    required DateTime expiresAt,
    DateTime? completedAt,
    required DateTime createdAt,
  }) = _ObjectUploadImpl;

  factory ObjectUpload.fromJson(Map<String, dynamic> jsonSerialization) {
    return ObjectUpload(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      objectId: jsonSerialization['objectId'] as int,
      actorUserId: jsonSerialization['actorUserId'] as String,
      requestId: jsonSerialization['requestId'] as String,
      requestHash: jsonSerialization['requestHash'] as String,
      expiresAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
      completedAt: jsonSerialization['completedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['completedAt'],
            ),
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  static final t = ObjectUploadTable();

  static const db = ObjectUploadRepository._();

  @override
  int? id;

  int workspaceId;

  int objectId;

  String actorUserId;

  String requestId;

  String requestHash;

  DateTime expiresAt;

  DateTime? completedAt;

  DateTime createdAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [ObjectUpload]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ObjectUpload copyWith({
    int? id,
    int? workspaceId,
    int? objectId,
    String? actorUserId,
    String? requestId,
    String? requestHash,
    DateTime? expiresAt,
    DateTime? completedAt,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ObjectUpload',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'objectId': objectId,
      'actorUserId': actorUserId,
      'requestId': requestId,
      'requestHash': requestHash,
      'expiresAt': expiresAt.toJson(),
      if (completedAt != null) 'completedAt': completedAt?.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ObjectUpload',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'objectId': objectId,
      'actorUserId': actorUserId,
      'requestId': requestId,
      'requestHash': requestHash,
      'expiresAt': expiresAt.toJson(),
      if (completedAt != null) 'completedAt': completedAt?.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  static ObjectUploadInclude include() {
    return ObjectUploadInclude._();
  }

  static ObjectUploadIncludeList includeList({
    _is.WhereExpressionBuilder<ObjectUploadTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ObjectUploadTable>? orderBy,
    _is.OrderByListBuilder<ObjectUploadTable>? orderByList,
    ObjectUploadInclude? include,
  }) {
    return ObjectUploadIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ObjectUpload.t),
      orderByList: orderByList?.call(ObjectUpload.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ObjectUploadImpl extends ObjectUpload {
  _ObjectUploadImpl({
    int? id,
    required int workspaceId,
    required int objectId,
    required String actorUserId,
    required String requestId,
    required String requestHash,
    required DateTime expiresAt,
    DateTime? completedAt,
    required DateTime createdAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         objectId: objectId,
         actorUserId: actorUserId,
         requestId: requestId,
         requestHash: requestHash,
         expiresAt: expiresAt,
         completedAt: completedAt,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [ObjectUpload]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ObjectUpload copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    int? objectId,
    String? actorUserId,
    String? requestId,
    String? requestHash,
    DateTime? expiresAt,
    Object? completedAt = _Undefined,
    DateTime? createdAt,
  }) {
    return ObjectUpload(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      objectId: objectId ?? this.objectId,
      actorUserId: actorUserId ?? this.actorUserId,
      requestId: requestId ?? this.requestId,
      requestHash: requestHash ?? this.requestHash,
      expiresAt: expiresAt ?? this.expiresAt,
      completedAt: completedAt is DateTime? ? completedAt : this.completedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class ObjectUploadUpdateTable extends _is.UpdateTable<ObjectUploadTable> {
  ObjectUploadUpdateTable(super.table);

  _is.ColumnValue<int, int> workspaceId(int value) => _is.ColumnValue(
    table.workspaceId,
    value,
  );

  _is.ColumnValue<int, int> objectId(int value) => _is.ColumnValue(
    table.objectId,
    value,
  );

  _is.ColumnValue<String, String> actorUserId(String value) => _is.ColumnValue(
    table.actorUserId,
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

  _is.ColumnValue<DateTime, DateTime> expiresAt(DateTime value) =>
      _is.ColumnValue(
        table.expiresAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> completedAt(DateTime? value) =>
      _is.ColumnValue(
        table.completedAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class ObjectUploadTable extends _is.Table<int?> {
  ObjectUploadTable({super.tableRelation}) : super(tableName: 'object_upload') {
    updateTable = ObjectUploadUpdateTable(this);
    workspaceId = _is.ColumnInt(
      'workspaceId',
      this,
    );
    objectId = _is.ColumnInt(
      'objectId',
      this,
    );
    actorUserId = _is.ColumnString(
      'actorUserId',
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
    expiresAt = _is.ColumnDateTime(
      'expiresAt',
      this,
    );
    completedAt = _is.ColumnDateTime(
      'completedAt',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final ObjectUploadUpdateTable updateTable;

  late final _is.ColumnInt workspaceId;

  late final _is.ColumnInt objectId;

  late final _is.ColumnString actorUserId;

  late final _is.ColumnString requestId;

  late final _is.ColumnString requestHash;

  late final _is.ColumnDateTime expiresAt;

  late final _is.ColumnDateTime completedAt;

  late final _is.ColumnDateTime createdAt;

  @override
  List<_is.Column> get columns => [
    id,
    workspaceId,
    objectId,
    actorUserId,
    requestId,
    requestHash,
    expiresAt,
    completedAt,
    createdAt,
  ];
}

class ObjectUploadInclude extends _is.IncludeObject {
  ObjectUploadInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => ObjectUpload.t;
}

class ObjectUploadIncludeList extends _is.IncludeList {
  ObjectUploadIncludeList._({
    _is.WhereExpressionBuilder<ObjectUploadTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ObjectUpload.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => ObjectUpload.t;
}

class ObjectUploadRepository {
  const ObjectUploadRepository._();

  /// Returns a list of [ObjectUpload]s matching the given query parameters.
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
  Future<List<ObjectUpload>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ObjectUploadTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ObjectUploadTable>? orderBy,
    _is.OrderByListBuilder<ObjectUploadTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ObjectUpload>(
      where: where?.call(ObjectUpload.t),
      orderBy: orderBy?.call(ObjectUpload.t),
      orderByList: orderByList?.call(ObjectUpload.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [ObjectUpload] matching the given query parameters.
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
  Future<ObjectUpload?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ObjectUploadTable>? where,
    int? offset,
    _is.OrderByBuilder<ObjectUploadTable>? orderBy,
    _is.OrderByListBuilder<ObjectUploadTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ObjectUpload>(
      where: where?.call(ObjectUpload.t),
      orderBy: orderBy?.call(ObjectUpload.t),
      orderByList: orderByList?.call(ObjectUpload.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ObjectUpload] by its [id] or null if no such row exists.
  Future<ObjectUpload?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ObjectUpload>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ObjectUpload]s in the list and returns the inserted rows.
  ///
  /// The returned [ObjectUpload]s will have their `id` fields set.
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
  Future<List<ObjectUpload>> insert(
    _is.DatabaseSession session,
    List<ObjectUpload> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<ObjectUpload>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [ObjectUpload] and returns the inserted row.
  ///
  /// The returned [ObjectUpload] will have its `id` field set.
  Future<ObjectUpload> insertRow(
    _is.DatabaseSession session,
    ObjectUpload row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<ObjectUpload>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [ObjectUpload]s in the list and returns the resulting rows.
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
  /// The returned [ObjectUpload]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ObjectUpload>> upsert(
    _is.DatabaseSession session,
    List<ObjectUpload> rows, {
    required _is.ColumnSelections<ObjectUploadTable> conflictColumns,
    _is.ColumnSelections<ObjectUploadTable>? updateColumns,
    _is.WhereExpressionBuilder<ObjectUploadTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<ObjectUpload>(
      rows,
      conflictColumns: conflictColumns(ObjectUpload.t),
      updateColumns: updateColumns?.call(ObjectUpload.t),
      updateWhere: updateWhere?.call(ObjectUpload.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [ObjectUpload] and returns the resulting row.
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
  /// The returned [ObjectUpload] will have its `id` field set.
  Future<ObjectUpload?> upsertRow(
    _is.DatabaseSession session,
    ObjectUpload row, {
    required _is.ColumnSelections<ObjectUploadTable> conflictColumns,
    _is.ColumnSelections<ObjectUploadTable>? updateColumns,
    _is.WhereExpressionBuilder<ObjectUploadTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<ObjectUpload>(
      row,
      conflictColumns: conflictColumns(ObjectUpload.t),
      updateColumns: updateColumns?.call(ObjectUpload.t),
      updateWhere: updateWhere?.call(ObjectUpload.t),
      transaction: transaction,
    );
  }

  /// Updates all [ObjectUpload]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ObjectUpload>> update(
    _is.DatabaseSession session,
    List<ObjectUpload> rows, {
    _is.ColumnSelections<ObjectUploadTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<ObjectUpload>(
      rows,
      columns: columns?.call(ObjectUpload.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [ObjectUpload]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ObjectUpload> updateRow(
    _is.DatabaseSession session,
    ObjectUpload row, {
    _is.ColumnSelections<ObjectUploadTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<ObjectUpload>(
      row,
      columns: columns?.call(ObjectUpload.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ObjectUpload] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ObjectUpload?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<ObjectUploadUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<ObjectUpload>(
      id,
      columnValues: columnValues(ObjectUpload.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ObjectUpload]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ObjectUpload>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<ObjectUploadUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<ObjectUploadTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ObjectUploadTable>? orderBy,
    _is.OrderByListBuilder<ObjectUploadTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<ObjectUpload>(
      columnValues: columnValues(ObjectUpload.t.updateTable),
      where: where(ObjectUpload.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ObjectUpload.t),
      orderByList: orderByList?.call(ObjectUpload.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [ObjectUpload]s in the list and returns the deleted rows.
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
  Future<List<ObjectUpload>> delete(
    _is.DatabaseSession session,
    List<ObjectUpload> rows, {
    _is.OrderByBuilder<ObjectUploadTable>? orderBy,
    _is.OrderByListBuilder<ObjectUploadTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<ObjectUpload>(
      rows,
      orderBy: orderBy?.call(ObjectUpload.t),
      orderByList: orderByList?.call(ObjectUpload.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [ObjectUpload].
  Future<ObjectUpload> deleteRow(
    _is.DatabaseSession session,
    ObjectUpload row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ObjectUpload>(
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
  Future<List<ObjectUpload>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ObjectUploadTable> where,
    _is.OrderByBuilder<ObjectUploadTable>? orderBy,
    _is.OrderByListBuilder<ObjectUploadTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<ObjectUpload>(
      where: where(ObjectUpload.t),
      orderBy: orderBy?.call(ObjectUpload.t),
      orderByList: orderByList?.call(ObjectUpload.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ObjectUploadTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<ObjectUpload>(
      where: where?.call(ObjectUpload.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ObjectUpload] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ObjectUploadTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ObjectUpload>(
      where: where(ObjectUpload.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
