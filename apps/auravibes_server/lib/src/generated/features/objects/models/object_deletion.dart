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

abstract class ObjectDeletion
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  ObjectDeletion._({
    this.id,
    required this.workspaceId,
    required this.objectId,
    required this.objectKey,
    required this.requestId,
    required this.expectedRevision,
    required this.requestedAt,
    this.completedAt,
    required this.attempts,
    required this.availableAt,
    this.lastError,
  });

  factory ObjectDeletion({
    int? id,
    required int workspaceId,
    required int objectId,
    required String objectKey,
    required String requestId,
    required int expectedRevision,
    required DateTime requestedAt,
    DateTime? completedAt,
    required int attempts,
    required DateTime availableAt,
    String? lastError,
  }) = _ObjectDeletionImpl;

  factory ObjectDeletion.fromJson(Map<String, dynamic> jsonSerialization) {
    return ObjectDeletion(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      objectId: jsonSerialization['objectId'] as int,
      objectKey: jsonSerialization['objectKey'] as String,
      requestId: jsonSerialization['requestId'] as String,
      expectedRevision: jsonSerialization['expectedRevision'] as int,
      requestedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['requestedAt'],
      ),
      completedAt: jsonSerialization['completedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['completedAt'],
            ),
      attempts: jsonSerialization['attempts'] as int,
      availableAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['availableAt'],
      ),
      lastError: jsonSerialization['lastError'] as String?,
    );
  }

  static final t = ObjectDeletionTable();

  static const db = ObjectDeletionRepository._();

  @override
  int? id;

  int workspaceId;

  int objectId;

  String objectKey;

  String requestId;

  int expectedRevision;

  DateTime requestedAt;

  DateTime? completedAt;

  int attempts;

  DateTime availableAt;

  String? lastError;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [ObjectDeletion]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ObjectDeletion copyWith({
    int? id,
    int? workspaceId,
    int? objectId,
    String? objectKey,
    String? requestId,
    int? expectedRevision,
    DateTime? requestedAt,
    DateTime? completedAt,
    int? attempts,
    DateTime? availableAt,
    String? lastError,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ObjectDeletion',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'objectId': objectId,
      'objectKey': objectKey,
      'requestId': requestId,
      'expectedRevision': expectedRevision,
      'requestedAt': requestedAt.toJson(),
      if (completedAt != null) 'completedAt': completedAt?.toJson(),
      'attempts': attempts,
      'availableAt': availableAt.toJson(),
      if (lastError != null) 'lastError': lastError,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ObjectDeletion',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'objectId': objectId,
      'objectKey': objectKey,
      'requestId': requestId,
      'expectedRevision': expectedRevision,
      'requestedAt': requestedAt.toJson(),
      if (completedAt != null) 'completedAt': completedAt?.toJson(),
      'attempts': attempts,
      'availableAt': availableAt.toJson(),
      if (lastError != null) 'lastError': lastError,
    };
  }

  static ObjectDeletionInclude include() {
    return ObjectDeletionInclude._();
  }

  static ObjectDeletionIncludeList includeList({
    _i1.WhereExpressionBuilder<ObjectDeletionTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ObjectDeletionTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<ObjectDeletionTable>? orderByList,
    ObjectDeletionInclude? include,
  }) {
    return ObjectDeletionIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ObjectDeletion.t),
      orderDescending: // ignore: deprecated_member_use_from_same_package
          orderDescending,
      orderByList: orderByList?.call(ObjectDeletion.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ObjectDeletionImpl extends ObjectDeletion {
  _ObjectDeletionImpl({
    int? id,
    required int workspaceId,
    required int objectId,
    required String objectKey,
    required String requestId,
    required int expectedRevision,
    required DateTime requestedAt,
    DateTime? completedAt,
    required int attempts,
    required DateTime availableAt,
    String? lastError,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         objectId: objectId,
         objectKey: objectKey,
         requestId: requestId,
         expectedRevision: expectedRevision,
         requestedAt: requestedAt,
         completedAt: completedAt,
         attempts: attempts,
         availableAt: availableAt,
         lastError: lastError,
       );

  /// Returns a shallow copy of this [ObjectDeletion]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ObjectDeletion copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    int? objectId,
    String? objectKey,
    String? requestId,
    int? expectedRevision,
    DateTime? requestedAt,
    Object? completedAt = _Undefined,
    int? attempts,
    DateTime? availableAt,
    Object? lastError = _Undefined,
  }) {
    return ObjectDeletion(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      objectId: objectId ?? this.objectId,
      objectKey: objectKey ?? this.objectKey,
      requestId: requestId ?? this.requestId,
      expectedRevision: expectedRevision ?? this.expectedRevision,
      requestedAt: requestedAt ?? this.requestedAt,
      completedAt: completedAt is DateTime? ? completedAt : this.completedAt,
      attempts: attempts ?? this.attempts,
      availableAt: availableAt ?? this.availableAt,
      lastError: lastError is String? ? lastError : this.lastError,
    );
  }
}

class ObjectDeletionUpdateTable extends _i1.UpdateTable<ObjectDeletionTable> {
  ObjectDeletionUpdateTable(super.table);

  _i1.ColumnValue<int, int> workspaceId(int value) => _i1.ColumnValue(
    table.workspaceId,
    value,
  );

  _i1.ColumnValue<int, int> objectId(int value) => _i1.ColumnValue(
    table.objectId,
    value,
  );

  _i1.ColumnValue<String, String> objectKey(String value) => _i1.ColumnValue(
    table.objectKey,
    value,
  );

  _i1.ColumnValue<String, String> requestId(String value) => _i1.ColumnValue(
    table.requestId,
    value,
  );

  _i1.ColumnValue<int, int> expectedRevision(int value) => _i1.ColumnValue(
    table.expectedRevision,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> requestedAt(DateTime value) =>
      _i1.ColumnValue(
        table.requestedAt,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> completedAt(DateTime? value) =>
      _i1.ColumnValue(
        table.completedAt,
        value,
      );

  _i1.ColumnValue<int, int> attempts(int value) => _i1.ColumnValue(
    table.attempts,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> availableAt(DateTime value) =>
      _i1.ColumnValue(
        table.availableAt,
        value,
      );

  _i1.ColumnValue<String, String> lastError(String? value) => _i1.ColumnValue(
    table.lastError,
    value,
  );
}

class ObjectDeletionTable extends _i1.Table<int?> {
  ObjectDeletionTable({super.tableRelation})
    : super(tableName: 'object_deletion') {
    updateTable = ObjectDeletionUpdateTable(this);
    workspaceId = _i1.ColumnInt(
      'workspaceId',
      this,
    );
    objectId = _i1.ColumnInt(
      'objectId',
      this,
    );
    objectKey = _i1.ColumnString(
      'objectKey',
      this,
    );
    requestId = _i1.ColumnString(
      'requestId',
      this,
    );
    expectedRevision = _i1.ColumnInt(
      'expectedRevision',
      this,
    );
    requestedAt = _i1.ColumnDateTime(
      'requestedAt',
      this,
    );
    completedAt = _i1.ColumnDateTime(
      'completedAt',
      this,
    );
    attempts = _i1.ColumnInt(
      'attempts',
      this,
    );
    availableAt = _i1.ColumnDateTime(
      'availableAt',
      this,
    );
    lastError = _i1.ColumnString(
      'lastError',
      this,
    );
  }

  late final ObjectDeletionUpdateTable updateTable;

  late final _i1.ColumnInt workspaceId;

  late final _i1.ColumnInt objectId;

  late final _i1.ColumnString objectKey;

  late final _i1.ColumnString requestId;

  late final _i1.ColumnInt expectedRevision;

  late final _i1.ColumnDateTime requestedAt;

  late final _i1.ColumnDateTime completedAt;

  late final _i1.ColumnInt attempts;

  late final _i1.ColumnDateTime availableAt;

  late final _i1.ColumnString lastError;

  @override
  List<_i1.Column> get columns => [
    id,
    workspaceId,
    objectId,
    objectKey,
    requestId,
    expectedRevision,
    requestedAt,
    completedAt,
    attempts,
    availableAt,
    lastError,
  ];
}

class ObjectDeletionInclude extends _i1.IncludeObject {
  ObjectDeletionInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => ObjectDeletion.t;
}

class ObjectDeletionIncludeList extends _i1.IncludeList {
  ObjectDeletionIncludeList._({
    _i1.WhereExpressionBuilder<ObjectDeletionTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ObjectDeletion.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => ObjectDeletion.t;
}

class ObjectDeletionRepository {
  const ObjectDeletionRepository._();

  /// Returns a list of [ObjectDeletion]s matching the given query parameters.
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
  Future<List<ObjectDeletion>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<ObjectDeletionTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ObjectDeletionTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<ObjectDeletionTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ObjectDeletion>(
      where: where?.call(ObjectDeletion.t),
      orderBy: orderBy?.call(ObjectDeletion.t),
      orderByList: orderByList?.call(ObjectDeletion.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [ObjectDeletion] matching the given query parameters.
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
  Future<ObjectDeletion?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<ObjectDeletionTable>? where,
    int? offset,
    _i1.OrderByBuilder<ObjectDeletionTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<ObjectDeletionTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ObjectDeletion>(
      where: where?.call(ObjectDeletion.t),
      orderBy: orderBy?.call(ObjectDeletion.t),
      orderByList: orderByList?.call(ObjectDeletion.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ObjectDeletion] by its [id] or null if no such row exists.
  Future<ObjectDeletion?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ObjectDeletion>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ObjectDeletion]s in the list and returns the inserted rows.
  ///
  /// The returned [ObjectDeletion]s will have their `id` fields set.
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
  Future<List<ObjectDeletion>> insert(
    _i1.DatabaseSession session,
    List<ObjectDeletion> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<ObjectDeletion>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [ObjectDeletion] and returns the inserted row.
  ///
  /// The returned [ObjectDeletion] will have its `id` field set.
  Future<ObjectDeletion> insertRow(
    _i1.DatabaseSession session,
    ObjectDeletion row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<ObjectDeletion>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [ObjectDeletion]s in the list and returns the resulting rows.
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
  /// The returned [ObjectDeletion]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ObjectDeletion>> upsert(
    _i1.DatabaseSession session,
    List<ObjectDeletion> rows, {
    required _i1.ColumnSelections<ObjectDeletionTable> conflictColumns,
    _i1.ColumnSelections<ObjectDeletionTable>? updateColumns,
    _i1.WhereExpressionBuilder<ObjectDeletionTable>? updateWhere,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<ObjectDeletion>(
      rows,
      conflictColumns: conflictColumns(ObjectDeletion.t),
      updateColumns: updateColumns?.call(ObjectDeletion.t),
      updateWhere: updateWhere?.call(ObjectDeletion.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [ObjectDeletion] and returns the resulting row.
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
  /// The returned [ObjectDeletion] will have its `id` field set.
  Future<ObjectDeletion?> upsertRow(
    _i1.DatabaseSession session,
    ObjectDeletion row, {
    required _i1.ColumnSelections<ObjectDeletionTable> conflictColumns,
    _i1.ColumnSelections<ObjectDeletionTable>? updateColumns,
    _i1.WhereExpressionBuilder<ObjectDeletionTable>? updateWhere,
    _i1.Transaction? transaction,
  }) async {
    return session.db.upsertRow<ObjectDeletion>(
      row,
      conflictColumns: conflictColumns(ObjectDeletion.t),
      updateColumns: updateColumns?.call(ObjectDeletion.t),
      updateWhere: updateWhere?.call(ObjectDeletion.t),
      transaction: transaction,
    );
  }

  /// Updates all [ObjectDeletion]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ObjectDeletion>> update(
    _i1.DatabaseSession session,
    List<ObjectDeletion> rows, {
    _i1.ColumnSelections<ObjectDeletionTable>? columns,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<ObjectDeletion>(
      rows,
      columns: columns?.call(ObjectDeletion.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [ObjectDeletion]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ObjectDeletion> updateRow(
    _i1.DatabaseSession session,
    ObjectDeletion row, {
    _i1.ColumnSelections<ObjectDeletionTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<ObjectDeletion>(
      row,
      columns: columns?.call(ObjectDeletion.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ObjectDeletion] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ObjectDeletion?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<ObjectDeletionUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<ObjectDeletion>(
      id,
      columnValues: columnValues(ObjectDeletion.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ObjectDeletion]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ObjectDeletion>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<ObjectDeletionUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<ObjectDeletionTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ObjectDeletionTable>? orderBy,
    _i1.OrderByListBuilder<ObjectDeletionTable>? orderByList,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<ObjectDeletion>(
      columnValues: columnValues(ObjectDeletion.t.updateTable),
      where: where(ObjectDeletion.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ObjectDeletion.t),
      orderByList: orderByList?.call(ObjectDeletion.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [ObjectDeletion]s in the list and returns the deleted rows.
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
  Future<List<ObjectDeletion>> delete(
    _i1.DatabaseSession session,
    List<ObjectDeletion> rows, {
    _i1.OrderByBuilder<ObjectDeletionTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<ObjectDeletionTable>? orderByList,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<ObjectDeletion>(
      rows,
      orderBy: orderBy?.call(ObjectDeletion.t),
      orderByList: orderByList?.call(ObjectDeletion.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [ObjectDeletion].
  Future<ObjectDeletion> deleteRow(
    _i1.DatabaseSession session,
    ObjectDeletion row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ObjectDeletion>(
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
  Future<List<ObjectDeletion>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<ObjectDeletionTable> where,
    _i1.OrderByBuilder<ObjectDeletionTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<ObjectDeletionTable>? orderByList,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<ObjectDeletion>(
      where: where(ObjectDeletion.t),
      orderBy: orderBy?.call(ObjectDeletion.t),
      orderByList: orderByList?.call(ObjectDeletion.t),
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
    _i1.WhereExpressionBuilder<ObjectDeletionTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<ObjectDeletion>(
      where: where?.call(ObjectDeletion.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ObjectDeletion] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<ObjectDeletionTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ObjectDeletion>(
      where: where(ObjectDeletion.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
