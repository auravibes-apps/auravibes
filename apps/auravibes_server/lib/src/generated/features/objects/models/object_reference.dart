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

abstract class ObjectReference
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  ObjectReference._({
    this.id,
    required this.workspaceId,
    required this.objectId,
    required this.messageId,
    required this.createdAt,
    this.deletedAt,
  });

  factory ObjectReference({
    int? id,
    required int workspaceId,
    required int objectId,
    required int messageId,
    required DateTime createdAt,
    DateTime? deletedAt,
  }) = _ObjectReferenceImpl;

  factory ObjectReference.fromJson(Map<String, dynamic> jsonSerialization) {
    return ObjectReference(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      objectId: jsonSerialization['objectId'] as int,
      messageId: jsonSerialization['messageId'] as int,
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      deletedAt: jsonSerialization['deletedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['deletedAt']),
    );
  }

  static final t = ObjectReferenceTable();

  static const db = ObjectReferenceRepository._();

  @override
  int? id;

  int workspaceId;

  int objectId;

  int messageId;

  DateTime createdAt;

  DateTime? deletedAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [ObjectReference]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ObjectReference copyWith({
    int? id,
    int? workspaceId,
    int? objectId,
    int? messageId,
    DateTime? createdAt,
    DateTime? deletedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ObjectReference',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'objectId': objectId,
      'messageId': messageId,
      'createdAt': createdAt.toJson(),
      if (deletedAt != null) 'deletedAt': deletedAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ObjectReference',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'objectId': objectId,
      'messageId': messageId,
      'createdAt': createdAt.toJson(),
      if (deletedAt != null) 'deletedAt': deletedAt?.toJson(),
    };
  }

  static ObjectReferenceInclude include() {
    return ObjectReferenceInclude._();
  }

  static ObjectReferenceIncludeList includeList({
    _is.WhereExpressionBuilder<ObjectReferenceTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ObjectReferenceTable>? orderBy,
    _is.OrderByListBuilder<ObjectReferenceTable>? orderByList,
    ObjectReferenceInclude? include,
  }) {
    return ObjectReferenceIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ObjectReference.t),
      orderByList: orderByList?.call(ObjectReference.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ObjectReferenceImpl extends ObjectReference {
  _ObjectReferenceImpl({
    int? id,
    required int workspaceId,
    required int objectId,
    required int messageId,
    required DateTime createdAt,
    DateTime? deletedAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         objectId: objectId,
         messageId: messageId,
         createdAt: createdAt,
         deletedAt: deletedAt,
       );

  /// Returns a shallow copy of this [ObjectReference]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ObjectReference copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    int? objectId,
    int? messageId,
    DateTime? createdAt,
    Object? deletedAt = _Undefined,
  }) {
    return ObjectReference(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      objectId: objectId ?? this.objectId,
      messageId: messageId ?? this.messageId,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt is DateTime? ? deletedAt : this.deletedAt,
    );
  }
}

class ObjectReferenceUpdateTable extends _is.UpdateTable<ObjectReferenceTable> {
  ObjectReferenceUpdateTable(super.table);

  _is.ColumnValue<int, int> workspaceId(int value) => _is.ColumnValue(
    table.workspaceId,
    value,
  );

  _is.ColumnValue<int, int> objectId(int value) => _is.ColumnValue(
    table.objectId,
    value,
  );

  _is.ColumnValue<int, int> messageId(int value) => _is.ColumnValue(
    table.messageId,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> deletedAt(DateTime? value) =>
      _is.ColumnValue(
        table.deletedAt,
        value,
      );
}

class ObjectReferenceTable extends _is.Table<int?> {
  ObjectReferenceTable({super.tableRelation})
    : super(tableName: 'object_reference') {
    updateTable = ObjectReferenceUpdateTable(this);
    workspaceId = _is.ColumnInt(
      'workspaceId',
      this,
    );
    objectId = _is.ColumnInt(
      'objectId',
      this,
    );
    messageId = _is.ColumnInt(
      'messageId',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
    deletedAt = _is.ColumnDateTime(
      'deletedAt',
      this,
    );
  }

  late final ObjectReferenceUpdateTable updateTable;

  late final _is.ColumnInt workspaceId;

  late final _is.ColumnInt objectId;

  late final _is.ColumnInt messageId;

  late final _is.ColumnDateTime createdAt;

  late final _is.ColumnDateTime deletedAt;

  @override
  List<_is.Column> get columns => [
    id,
    workspaceId,
    objectId,
    messageId,
    createdAt,
    deletedAt,
  ];
}

class ObjectReferenceInclude extends _is.IncludeObject {
  ObjectReferenceInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => ObjectReference.t;
}

class ObjectReferenceIncludeList extends _is.IncludeList {
  ObjectReferenceIncludeList._({
    _is.WhereExpressionBuilder<ObjectReferenceTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ObjectReference.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => ObjectReference.t;
}

class ObjectReferenceRepository {
  const ObjectReferenceRepository._();

  /// Returns a list of [ObjectReference]s matching the given query parameters.
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
  Future<List<ObjectReference>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ObjectReferenceTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ObjectReferenceTable>? orderBy,
    _is.OrderByListBuilder<ObjectReferenceTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ObjectReference>(
      where: where?.call(ObjectReference.t),
      orderBy: orderBy?.call(ObjectReference.t),
      orderByList: orderByList?.call(ObjectReference.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [ObjectReference] matching the given query parameters.
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
  Future<ObjectReference?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ObjectReferenceTable>? where,
    int? offset,
    _is.OrderByBuilder<ObjectReferenceTable>? orderBy,
    _is.OrderByListBuilder<ObjectReferenceTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ObjectReference>(
      where: where?.call(ObjectReference.t),
      orderBy: orderBy?.call(ObjectReference.t),
      orderByList: orderByList?.call(ObjectReference.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ObjectReference] by its [id] or null if no such row exists.
  Future<ObjectReference?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ObjectReference>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ObjectReference]s in the list and returns the inserted rows.
  ///
  /// The returned [ObjectReference]s will have their `id` fields set.
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
  Future<List<ObjectReference>> insert(
    _is.DatabaseSession session,
    List<ObjectReference> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<ObjectReference>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [ObjectReference] and returns the inserted row.
  ///
  /// The returned [ObjectReference] will have its `id` field set.
  Future<ObjectReference> insertRow(
    _is.DatabaseSession session,
    ObjectReference row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<ObjectReference>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [ObjectReference]s in the list and returns the resulting rows.
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
  /// The returned [ObjectReference]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ObjectReference>> upsert(
    _is.DatabaseSession session,
    List<ObjectReference> rows, {
    required _is.ColumnSelections<ObjectReferenceTable> conflictColumns,
    _is.ColumnSelections<ObjectReferenceTable>? updateColumns,
    _is.WhereExpressionBuilder<ObjectReferenceTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<ObjectReference>(
      rows,
      conflictColumns: conflictColumns(ObjectReference.t),
      updateColumns: updateColumns?.call(ObjectReference.t),
      updateWhere: updateWhere?.call(ObjectReference.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [ObjectReference] and returns the resulting row.
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
  /// The returned [ObjectReference] will have its `id` field set.
  Future<ObjectReference?> upsertRow(
    _is.DatabaseSession session,
    ObjectReference row, {
    required _is.ColumnSelections<ObjectReferenceTable> conflictColumns,
    _is.ColumnSelections<ObjectReferenceTable>? updateColumns,
    _is.WhereExpressionBuilder<ObjectReferenceTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<ObjectReference>(
      row,
      conflictColumns: conflictColumns(ObjectReference.t),
      updateColumns: updateColumns?.call(ObjectReference.t),
      updateWhere: updateWhere?.call(ObjectReference.t),
      transaction: transaction,
    );
  }

  /// Updates all [ObjectReference]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ObjectReference>> update(
    _is.DatabaseSession session,
    List<ObjectReference> rows, {
    _is.ColumnSelections<ObjectReferenceTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<ObjectReference>(
      rows,
      columns: columns?.call(ObjectReference.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [ObjectReference]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ObjectReference> updateRow(
    _is.DatabaseSession session,
    ObjectReference row, {
    _is.ColumnSelections<ObjectReferenceTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<ObjectReference>(
      row,
      columns: columns?.call(ObjectReference.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ObjectReference] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ObjectReference?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<ObjectReferenceUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<ObjectReference>(
      id,
      columnValues: columnValues(ObjectReference.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ObjectReference]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ObjectReference>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<ObjectReferenceUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<ObjectReferenceTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ObjectReferenceTable>? orderBy,
    _is.OrderByListBuilder<ObjectReferenceTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<ObjectReference>(
      columnValues: columnValues(ObjectReference.t.updateTable),
      where: where(ObjectReference.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ObjectReference.t),
      orderByList: orderByList?.call(ObjectReference.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [ObjectReference]s in the list and returns the deleted rows.
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
  Future<List<ObjectReference>> delete(
    _is.DatabaseSession session,
    List<ObjectReference> rows, {
    _is.OrderByBuilder<ObjectReferenceTable>? orderBy,
    _is.OrderByListBuilder<ObjectReferenceTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<ObjectReference>(
      rows,
      orderBy: orderBy?.call(ObjectReference.t),
      orderByList: orderByList?.call(ObjectReference.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [ObjectReference].
  Future<ObjectReference> deleteRow(
    _is.DatabaseSession session,
    ObjectReference row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ObjectReference>(
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
  Future<List<ObjectReference>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ObjectReferenceTable> where,
    _is.OrderByBuilder<ObjectReferenceTable>? orderBy,
    _is.OrderByListBuilder<ObjectReferenceTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<ObjectReference>(
      where: where(ObjectReference.t),
      orderBy: orderBy?.call(ObjectReference.t),
      orderByList: orderByList?.call(ObjectReference.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ObjectReferenceTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<ObjectReference>(
      where: where?.call(ObjectReference.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ObjectReference] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ObjectReferenceTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ObjectReference>(
      where: where(ObjectReference.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
