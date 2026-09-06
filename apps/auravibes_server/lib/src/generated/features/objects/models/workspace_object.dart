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

abstract class WorkspaceObject
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  WorkspaceObject._({
    this.id,
    required this.workspaceId,
    required this.objectKey,
    required this.purpose,
    required this.displayName,
    required this.mimeType,
    required this.sizeBytes,
    required this.checksumSha256,
    required this.status,
    required this.revision,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory WorkspaceObject({
    int? id,
    required int workspaceId,
    required String objectKey,
    required String purpose,
    required String displayName,
    required String mimeType,
    required int sizeBytes,
    required String checksumSha256,
    required String status,
    required int revision,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
  }) = _WorkspaceObjectImpl;

  factory WorkspaceObject.fromJson(Map<String, dynamic> jsonSerialization) {
    return WorkspaceObject(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      objectKey: jsonSerialization['objectKey'] as String,
      purpose: jsonSerialization['purpose'] as String,
      displayName: jsonSerialization['displayName'] as String,
      mimeType: jsonSerialization['mimeType'] as String,
      sizeBytes: jsonSerialization['sizeBytes'] as int,
      checksumSha256: jsonSerialization['checksumSha256'] as String,
      status: jsonSerialization['status'] as String,
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

  static final t = WorkspaceObjectTable();

  static const db = WorkspaceObjectRepository._();

  @override
  int? id;

  int workspaceId;

  String objectKey;

  String purpose;

  String displayName;

  String mimeType;

  int sizeBytes;

  String checksumSha256;

  String status;

  int revision;

  DateTime createdAt;

  DateTime updatedAt;

  DateTime? deletedAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [WorkspaceObject]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  WorkspaceObject copyWith({
    int? id,
    int? workspaceId,
    String? objectKey,
    String? purpose,
    String? displayName,
    String? mimeType,
    int? sizeBytes,
    String? checksumSha256,
    String? status,
    int? revision,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WorkspaceObject',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'objectKey': objectKey,
      'purpose': purpose,
      'displayName': displayName,
      'mimeType': mimeType,
      'sizeBytes': sizeBytes,
      'checksumSha256': checksumSha256,
      'status': status,
      'revision': revision,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      if (deletedAt != null) 'deletedAt': deletedAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WorkspaceObject',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'objectKey': objectKey,
      'purpose': purpose,
      'displayName': displayName,
      'mimeType': mimeType,
      'sizeBytes': sizeBytes,
      'checksumSha256': checksumSha256,
      'status': status,
      'revision': revision,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      if (deletedAt != null) 'deletedAt': deletedAt?.toJson(),
    };
  }

  static WorkspaceObjectInclude include() {
    return WorkspaceObjectInclude._();
  }

  static WorkspaceObjectIncludeList includeList({
    _is.WhereExpressionBuilder<WorkspaceObjectTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<WorkspaceObjectTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceObjectTable>? orderByList,
    WorkspaceObjectInclude? include,
  }) {
    return WorkspaceObjectIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WorkspaceObject.t),
      orderByList: orderByList?.call(WorkspaceObject.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WorkspaceObjectImpl extends WorkspaceObject {
  _WorkspaceObjectImpl({
    int? id,
    required int workspaceId,
    required String objectKey,
    required String purpose,
    required String displayName,
    required String mimeType,
    required int sizeBytes,
    required String checksumSha256,
    required String status,
    required int revision,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         objectKey: objectKey,
         purpose: purpose,
         displayName: displayName,
         mimeType: mimeType,
         sizeBytes: sizeBytes,
         checksumSha256: checksumSha256,
         status: status,
         revision: revision,
         createdAt: createdAt,
         updatedAt: updatedAt,
         deletedAt: deletedAt,
       );

  /// Returns a shallow copy of this [WorkspaceObject]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  WorkspaceObject copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    String? objectKey,
    String? purpose,
    String? displayName,
    String? mimeType,
    int? sizeBytes,
    String? checksumSha256,
    String? status,
    int? revision,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? deletedAt = _Undefined,
  }) {
    return WorkspaceObject(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      objectKey: objectKey ?? this.objectKey,
      purpose: purpose ?? this.purpose,
      displayName: displayName ?? this.displayName,
      mimeType: mimeType ?? this.mimeType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      checksumSha256: checksumSha256 ?? this.checksumSha256,
      status: status ?? this.status,
      revision: revision ?? this.revision,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt is DateTime? ? deletedAt : this.deletedAt,
    );
  }
}

class WorkspaceObjectUpdateTable extends _is.UpdateTable<WorkspaceObjectTable> {
  WorkspaceObjectUpdateTable(super.table);

  _is.ColumnValue<int, int> workspaceId(int value) => _is.ColumnValue(
    table.workspaceId,
    value,
  );

  _is.ColumnValue<String, String> objectKey(String value) => _is.ColumnValue(
    table.objectKey,
    value,
  );

  _is.ColumnValue<String, String> purpose(String value) => _is.ColumnValue(
    table.purpose,
    value,
  );

  _is.ColumnValue<String, String> displayName(String value) => _is.ColumnValue(
    table.displayName,
    value,
  );

  _is.ColumnValue<String, String> mimeType(String value) => _is.ColumnValue(
    table.mimeType,
    value,
  );

  _is.ColumnValue<int, int> sizeBytes(int value) => _is.ColumnValue(
    table.sizeBytes,
    value,
  );

  _is.ColumnValue<String, String> checksumSha256(String value) =>
      _is.ColumnValue(
        table.checksumSha256,
        value,
      );

  _is.ColumnValue<String, String> status(String value) => _is.ColumnValue(
    table.status,
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

class WorkspaceObjectTable extends _is.Table<int?> {
  WorkspaceObjectTable({super.tableRelation})
    : super(tableName: 'workspace_object') {
    updateTable = WorkspaceObjectUpdateTable(this);
    workspaceId = _is.ColumnInt(
      'workspaceId',
      this,
    );
    objectKey = _is.ColumnString(
      'objectKey',
      this,
    );
    purpose = _is.ColumnString(
      'purpose',
      this,
    );
    displayName = _is.ColumnString(
      'displayName',
      this,
    );
    mimeType = _is.ColumnString(
      'mimeType',
      this,
    );
    sizeBytes = _is.ColumnInt(
      'sizeBytes',
      this,
    );
    checksumSha256 = _is.ColumnString(
      'checksumSha256',
      this,
    );
    status = _is.ColumnString(
      'status',
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

  late final WorkspaceObjectUpdateTable updateTable;

  late final _is.ColumnInt workspaceId;

  late final _is.ColumnString objectKey;

  late final _is.ColumnString purpose;

  late final _is.ColumnString displayName;

  late final _is.ColumnString mimeType;

  late final _is.ColumnInt sizeBytes;

  late final _is.ColumnString checksumSha256;

  late final _is.ColumnString status;

  late final _is.ColumnInt revision;

  late final _is.ColumnDateTime createdAt;

  late final _is.ColumnDateTime updatedAt;

  late final _is.ColumnDateTime deletedAt;

  @override
  List<_is.Column> get columns => [
    id,
    workspaceId,
    objectKey,
    purpose,
    displayName,
    mimeType,
    sizeBytes,
    checksumSha256,
    status,
    revision,
    createdAt,
    updatedAt,
    deletedAt,
  ];
}

class WorkspaceObjectInclude extends _is.IncludeObject {
  WorkspaceObjectInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => WorkspaceObject.t;
}

class WorkspaceObjectIncludeList extends _is.IncludeList {
  WorkspaceObjectIncludeList._({
    _is.WhereExpressionBuilder<WorkspaceObjectTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(WorkspaceObject.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => WorkspaceObject.t;
}

class WorkspaceObjectRepository {
  const WorkspaceObjectRepository._();

  /// Returns a list of [WorkspaceObject]s matching the given query parameters.
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
  Future<List<WorkspaceObject>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<WorkspaceObjectTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<WorkspaceObjectTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceObjectTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<WorkspaceObject>(
      where: where?.call(WorkspaceObject.t),
      orderBy: orderBy?.call(WorkspaceObject.t),
      orderByList: orderByList?.call(WorkspaceObject.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [WorkspaceObject] matching the given query parameters.
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
  Future<WorkspaceObject?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<WorkspaceObjectTable>? where,
    int? offset,
    _is.OrderByBuilder<WorkspaceObjectTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceObjectTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<WorkspaceObject>(
      where: where?.call(WorkspaceObject.t),
      orderBy: orderBy?.call(WorkspaceObject.t),
      orderByList: orderByList?.call(WorkspaceObject.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [WorkspaceObject] by its [id] or null if no such row exists.
  Future<WorkspaceObject?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<WorkspaceObject>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [WorkspaceObject]s in the list and returns the inserted rows.
  ///
  /// The returned [WorkspaceObject]s will have their `id` fields set.
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
  Future<List<WorkspaceObject>> insert(
    _is.DatabaseSession session,
    List<WorkspaceObject> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<WorkspaceObject>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [WorkspaceObject] and returns the inserted row.
  ///
  /// The returned [WorkspaceObject] will have its `id` field set.
  Future<WorkspaceObject> insertRow(
    _is.DatabaseSession session,
    WorkspaceObject row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<WorkspaceObject>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [WorkspaceObject]s in the list and returns the resulting rows.
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
  /// The returned [WorkspaceObject]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WorkspaceObject>> upsert(
    _is.DatabaseSession session,
    List<WorkspaceObject> rows, {
    required _is.ColumnSelections<WorkspaceObjectTable> conflictColumns,
    _is.ColumnSelections<WorkspaceObjectTable>? updateColumns,
    _is.WhereExpressionBuilder<WorkspaceObjectTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<WorkspaceObject>(
      rows,
      conflictColumns: conflictColumns(WorkspaceObject.t),
      updateColumns: updateColumns?.call(WorkspaceObject.t),
      updateWhere: updateWhere?.call(WorkspaceObject.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [WorkspaceObject] and returns the resulting row.
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
  /// The returned [WorkspaceObject] will have its `id` field set.
  Future<WorkspaceObject?> upsertRow(
    _is.DatabaseSession session,
    WorkspaceObject row, {
    required _is.ColumnSelections<WorkspaceObjectTable> conflictColumns,
    _is.ColumnSelections<WorkspaceObjectTable>? updateColumns,
    _is.WhereExpressionBuilder<WorkspaceObjectTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<WorkspaceObject>(
      row,
      conflictColumns: conflictColumns(WorkspaceObject.t),
      updateColumns: updateColumns?.call(WorkspaceObject.t),
      updateWhere: updateWhere?.call(WorkspaceObject.t),
      transaction: transaction,
    );
  }

  /// Updates all [WorkspaceObject]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WorkspaceObject>> update(
    _is.DatabaseSession session,
    List<WorkspaceObject> rows, {
    _is.ColumnSelections<WorkspaceObjectTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<WorkspaceObject>(
      rows,
      columns: columns?.call(WorkspaceObject.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [WorkspaceObject]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<WorkspaceObject> updateRow(
    _is.DatabaseSession session,
    WorkspaceObject row, {
    _is.ColumnSelections<WorkspaceObjectTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<WorkspaceObject>(
      row,
      columns: columns?.call(WorkspaceObject.t),
      transaction: transaction,
    );
  }

  /// Updates a single [WorkspaceObject] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<WorkspaceObject?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<WorkspaceObjectUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<WorkspaceObject>(
      id,
      columnValues: columnValues(WorkspaceObject.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [WorkspaceObject]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WorkspaceObject>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<WorkspaceObjectUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<WorkspaceObjectTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<WorkspaceObjectTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceObjectTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<WorkspaceObject>(
      columnValues: columnValues(WorkspaceObject.t.updateTable),
      where: where(WorkspaceObject.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WorkspaceObject.t),
      orderByList: orderByList?.call(WorkspaceObject.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [WorkspaceObject]s in the list and returns the deleted rows.
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
  Future<List<WorkspaceObject>> delete(
    _is.DatabaseSession session,
    List<WorkspaceObject> rows, {
    _is.OrderByBuilder<WorkspaceObjectTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceObjectTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<WorkspaceObject>(
      rows,
      orderBy: orderBy?.call(WorkspaceObject.t),
      orderByList: orderByList?.call(WorkspaceObject.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [WorkspaceObject].
  Future<WorkspaceObject> deleteRow(
    _is.DatabaseSession session,
    WorkspaceObject row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<WorkspaceObject>(
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
  Future<List<WorkspaceObject>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<WorkspaceObjectTable> where,
    _is.OrderByBuilder<WorkspaceObjectTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceObjectTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<WorkspaceObject>(
      where: where(WorkspaceObject.t),
      orderBy: orderBy?.call(WorkspaceObject.t),
      orderByList: orderByList?.call(WorkspaceObject.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<WorkspaceObjectTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<WorkspaceObject>(
      where: where?.call(WorkspaceObject.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [WorkspaceObject] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<WorkspaceObjectTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<WorkspaceObject>(
      where: where(WorkspaceObject.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
