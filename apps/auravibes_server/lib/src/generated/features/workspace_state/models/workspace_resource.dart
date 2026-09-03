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
import '../../../features/workspace_state/models/workspace_resource_kind.dart'
    as _i2;

abstract class WorkspaceResource
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  WorkspaceResource._({
    this.id,
    required this.workspaceId,
    required this.resourceKind,
    required this.resourceId,
    required this.data,
    required this.revision,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory WorkspaceResource({
    int? id,
    required int workspaceId,
    required _i2.WorkspaceResourceKind resourceKind,
    required String resourceId,
    required String data,
    required int revision,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
  }) = _WorkspaceResourceImpl;

  factory WorkspaceResource.fromJson(Map<String, dynamic> jsonSerialization) {
    return WorkspaceResource(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      resourceKind: _i2.WorkspaceResourceKind.fromJson(
        (jsonSerialization['resourceKind'] as String),
      ),
      resourceId: jsonSerialization['resourceId'] as String,
      data: jsonSerialization['data'] as String,
      revision: jsonSerialization['revision'] as int,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
      deletedAt: jsonSerialization['deletedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['deletedAt']),
    );
  }

  static final t = WorkspaceResourceTable();

  static const db = WorkspaceResourceRepository._();

  @override
  int? id;

  int workspaceId;

  _i2.WorkspaceResourceKind resourceKind;

  String resourceId;

  String data;

  int revision;

  DateTime createdAt;

  DateTime updatedAt;

  DateTime? deletedAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [WorkspaceResource]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  WorkspaceResource copyWith({
    int? id,
    int? workspaceId,
    _i2.WorkspaceResourceKind? resourceKind,
    String? resourceId,
    String? data,
    int? revision,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WorkspaceResource',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'resourceKind': resourceKind.toJson(),
      'resourceId': resourceId,
      'data': data,
      'revision': revision,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      if (deletedAt != null) 'deletedAt': deletedAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WorkspaceResource',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'resourceKind': resourceKind.toJson(),
      'resourceId': resourceId,
      'data': data,
      'revision': revision,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      if (deletedAt != null) 'deletedAt': deletedAt?.toJson(),
    };
  }

  static WorkspaceResourceInclude include() {
    return WorkspaceResourceInclude._();
  }

  static WorkspaceResourceIncludeList includeList({
    _i1.WhereExpressionBuilder<WorkspaceResourceTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<WorkspaceResourceTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<WorkspaceResourceTable>? orderByList,
    WorkspaceResourceInclude? include,
  }) {
    return WorkspaceResourceIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WorkspaceResource.t),
      orderDescending: // ignore: deprecated_member_use_from_same_package
          orderDescending,
      orderByList: orderByList?.call(WorkspaceResource.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WorkspaceResourceImpl extends WorkspaceResource {
  _WorkspaceResourceImpl({
    int? id,
    required int workspaceId,
    required _i2.WorkspaceResourceKind resourceKind,
    required String resourceId,
    required String data,
    required int revision,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         resourceKind: resourceKind,
         resourceId: resourceId,
         data: data,
         revision: revision,
         createdAt: createdAt,
         updatedAt: updatedAt,
         deletedAt: deletedAt,
       );

  /// Returns a shallow copy of this [WorkspaceResource]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  WorkspaceResource copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    _i2.WorkspaceResourceKind? resourceKind,
    String? resourceId,
    String? data,
    int? revision,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? deletedAt = _Undefined,
  }) {
    return WorkspaceResource(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      resourceKind: resourceKind ?? this.resourceKind,
      resourceId: resourceId ?? this.resourceId,
      data: data ?? this.data,
      revision: revision ?? this.revision,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt is DateTime? ? deletedAt : this.deletedAt,
    );
  }
}

class WorkspaceResourceUpdateTable
    extends _i1.UpdateTable<WorkspaceResourceTable> {
  WorkspaceResourceUpdateTable(super.table);

  _i1.ColumnValue<int, int> workspaceId(int value) => _i1.ColumnValue(
    table.workspaceId,
    value,
  );

  _i1.ColumnValue<_i2.WorkspaceResourceKind, _i2.WorkspaceResourceKind>
  resourceKind(_i2.WorkspaceResourceKind value) => _i1.ColumnValue(
    table.resourceKind,
    value,
  );

  _i1.ColumnValue<String, String> resourceId(String value) => _i1.ColumnValue(
    table.resourceId,
    value,
  );

  _i1.ColumnValue<String, String> data(String value) => _i1.ColumnValue(
    table.data,
    value,
  );

  _i1.ColumnValue<int, int> revision(int value) => _i1.ColumnValue(
    table.revision,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(
        table.createdAt,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> updatedAt(DateTime value) =>
      _i1.ColumnValue(
        table.updatedAt,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> deletedAt(DateTime? value) =>
      _i1.ColumnValue(
        table.deletedAt,
        value,
      );
}

class WorkspaceResourceTable extends _i1.Table<int?> {
  WorkspaceResourceTable({super.tableRelation})
    : super(tableName: 'workspace_resource') {
    updateTable = WorkspaceResourceUpdateTable(this);
    workspaceId = _i1.ColumnInt(
      'workspaceId',
      this,
    );
    resourceKind = _i1.ColumnEnum(
      'resourceKind',
      this,
      _i1.EnumSerialization.byName,
    );
    resourceId = _i1.ColumnString(
      'resourceId',
      this,
    );
    data = _i1.ColumnString(
      'data',
      this,
    );
    revision = _i1.ColumnInt(
      'revision',
      this,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
    updatedAt = _i1.ColumnDateTime(
      'updatedAt',
      this,
    );
    deletedAt = _i1.ColumnDateTime(
      'deletedAt',
      this,
    );
  }

  late final WorkspaceResourceUpdateTable updateTable;

  late final _i1.ColumnInt workspaceId;

  late final _i1.ColumnEnum<_i2.WorkspaceResourceKind> resourceKind;

  late final _i1.ColumnString resourceId;

  late final _i1.ColumnString data;

  late final _i1.ColumnInt revision;

  late final _i1.ColumnDateTime createdAt;

  late final _i1.ColumnDateTime updatedAt;

  late final _i1.ColumnDateTime deletedAt;

  @override
  List<_i1.Column> get columns => [
    id,
    workspaceId,
    resourceKind,
    resourceId,
    data,
    revision,
    createdAt,
    updatedAt,
    deletedAt,
  ];
}

class WorkspaceResourceInclude extends _i1.IncludeObject {
  WorkspaceResourceInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => WorkspaceResource.t;
}

class WorkspaceResourceIncludeList extends _i1.IncludeList {
  WorkspaceResourceIncludeList._({
    _i1.WhereExpressionBuilder<WorkspaceResourceTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(WorkspaceResource.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => WorkspaceResource.t;
}

class WorkspaceResourceRepository {
  const WorkspaceResourceRepository._();

  /// Returns a list of [WorkspaceResource]s matching the given query parameters.
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
  Future<List<WorkspaceResource>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<WorkspaceResourceTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<WorkspaceResourceTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<WorkspaceResourceTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<WorkspaceResource>(
      where: where?.call(WorkspaceResource.t),
      orderBy: orderBy?.call(WorkspaceResource.t),
      orderByList: orderByList?.call(WorkspaceResource.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [WorkspaceResource] matching the given query parameters.
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
  Future<WorkspaceResource?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<WorkspaceResourceTable>? where,
    int? offset,
    _i1.OrderByBuilder<WorkspaceResourceTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<WorkspaceResourceTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<WorkspaceResource>(
      where: where?.call(WorkspaceResource.t),
      orderBy: orderBy?.call(WorkspaceResource.t),
      orderByList: orderByList?.call(WorkspaceResource.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [WorkspaceResource] by its [id] or null if no such row exists.
  Future<WorkspaceResource?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<WorkspaceResource>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [WorkspaceResource]s in the list and returns the inserted rows.
  ///
  /// The returned [WorkspaceResource]s will have their `id` fields set.
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
  Future<List<WorkspaceResource>> insert(
    _i1.DatabaseSession session,
    List<WorkspaceResource> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<WorkspaceResource>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [WorkspaceResource] and returns the inserted row.
  ///
  /// The returned [WorkspaceResource] will have its `id` field set.
  Future<WorkspaceResource> insertRow(
    _i1.DatabaseSession session,
    WorkspaceResource row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<WorkspaceResource>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [WorkspaceResource]s in the list and returns the resulting rows.
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
  /// The returned [WorkspaceResource]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WorkspaceResource>> upsert(
    _i1.DatabaseSession session,
    List<WorkspaceResource> rows, {
    required _i1.ColumnSelections<WorkspaceResourceTable> conflictColumns,
    _i1.ColumnSelections<WorkspaceResourceTable>? updateColumns,
    _i1.WhereExpressionBuilder<WorkspaceResourceTable>? updateWhere,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<WorkspaceResource>(
      rows,
      conflictColumns: conflictColumns(WorkspaceResource.t),
      updateColumns: updateColumns?.call(WorkspaceResource.t),
      updateWhere: updateWhere?.call(WorkspaceResource.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [WorkspaceResource] and returns the resulting row.
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
  /// The returned [WorkspaceResource] will have its `id` field set.
  Future<WorkspaceResource?> upsertRow(
    _i1.DatabaseSession session,
    WorkspaceResource row, {
    required _i1.ColumnSelections<WorkspaceResourceTable> conflictColumns,
    _i1.ColumnSelections<WorkspaceResourceTable>? updateColumns,
    _i1.WhereExpressionBuilder<WorkspaceResourceTable>? updateWhere,
    _i1.Transaction? transaction,
  }) async {
    return session.db.upsertRow<WorkspaceResource>(
      row,
      conflictColumns: conflictColumns(WorkspaceResource.t),
      updateColumns: updateColumns?.call(WorkspaceResource.t),
      updateWhere: updateWhere?.call(WorkspaceResource.t),
      transaction: transaction,
    );
  }

  /// Updates all [WorkspaceResource]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WorkspaceResource>> update(
    _i1.DatabaseSession session,
    List<WorkspaceResource> rows, {
    _i1.ColumnSelections<WorkspaceResourceTable>? columns,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<WorkspaceResource>(
      rows,
      columns: columns?.call(WorkspaceResource.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [WorkspaceResource]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<WorkspaceResource> updateRow(
    _i1.DatabaseSession session,
    WorkspaceResource row, {
    _i1.ColumnSelections<WorkspaceResourceTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<WorkspaceResource>(
      row,
      columns: columns?.call(WorkspaceResource.t),
      transaction: transaction,
    );
  }

  /// Updates a single [WorkspaceResource] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<WorkspaceResource?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<WorkspaceResourceUpdateTable>
    columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<WorkspaceResource>(
      id,
      columnValues: columnValues(WorkspaceResource.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [WorkspaceResource]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WorkspaceResource>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<WorkspaceResourceUpdateTable>
    columnValues,
    required _i1.WhereExpressionBuilder<WorkspaceResourceTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<WorkspaceResourceTable>? orderBy,
    _i1.OrderByListBuilder<WorkspaceResourceTable>? orderByList,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<WorkspaceResource>(
      columnValues: columnValues(WorkspaceResource.t.updateTable),
      where: where(WorkspaceResource.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WorkspaceResource.t),
      orderByList: orderByList?.call(WorkspaceResource.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [WorkspaceResource]s in the list and returns the deleted rows.
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
  Future<List<WorkspaceResource>> delete(
    _i1.DatabaseSession session,
    List<WorkspaceResource> rows, {
    _i1.OrderByBuilder<WorkspaceResourceTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<WorkspaceResourceTable>? orderByList,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<WorkspaceResource>(
      rows,
      orderBy: orderBy?.call(WorkspaceResource.t),
      orderByList: orderByList?.call(WorkspaceResource.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [WorkspaceResource].
  Future<WorkspaceResource> deleteRow(
    _i1.DatabaseSession session,
    WorkspaceResource row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<WorkspaceResource>(
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
  Future<List<WorkspaceResource>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<WorkspaceResourceTable> where,
    _i1.OrderByBuilder<WorkspaceResourceTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<WorkspaceResourceTable>? orderByList,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<WorkspaceResource>(
      where: where(WorkspaceResource.t),
      orderBy: orderBy?.call(WorkspaceResource.t),
      orderByList: orderByList?.call(WorkspaceResource.t),
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
    _i1.WhereExpressionBuilder<WorkspaceResourceTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<WorkspaceResource>(
      where: where?.call(WorkspaceResource.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [WorkspaceResource] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<WorkspaceResourceTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<WorkspaceResource>(
      where: where(WorkspaceResource.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
