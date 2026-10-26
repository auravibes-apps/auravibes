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

import '../../../features/workspace_state/models/workspace_resource_kind.dart'
    as _iz7spkcy;

abstract class WorkspaceRevision
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  WorkspaceRevision._({
    this.id,
    required this.workspaceId,
    required this.resourceKind,
    required this.resourceId,
    required this.revision,
    required this.data,
    required this.capturedAt,
    this.actorUserId,
    this.aiInvolved,
    this.operation,
    this.conversationId,
  });

  factory WorkspaceRevision({
    int? id,
    required int workspaceId,
    required _iz7spkcy.WorkspaceResourceKind resourceKind,
    required String resourceId,
    required int revision,
    required String data,
    required DateTime capturedAt,
    String? actorUserId,
    bool? aiInvolved,
    String? operation,
    String? conversationId,
  }) = _WorkspaceRevisionImpl;

  factory WorkspaceRevision.fromJson(Map<String, dynamic> jsonSerialization) {
    return WorkspaceRevision(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      resourceKind: _iz7spkcy.WorkspaceResourceKind.fromJson(
        (jsonSerialization['resourceKind'] as String),
      ),
      resourceId: jsonSerialization['resourceId'] as String,
      revision: jsonSerialization['revision'] as int,
      data: jsonSerialization['data'] as String,
      capturedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['capturedAt'],
      ),
      actorUserId: jsonSerialization['actorUserId'] as String?,
      aiInvolved: jsonSerialization['aiInvolved'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['aiInvolved']),
      operation: jsonSerialization['operation'] as String?,
      conversationId: jsonSerialization['conversationId'] as String?,
    );
  }

  static final t = WorkspaceRevisionTable();

  static const db = WorkspaceRevisionRepository._();

  @override
  int? id;

  int workspaceId;

  _iz7spkcy.WorkspaceResourceKind resourceKind;

  String resourceId;

  int revision;

  String data;

  DateTime capturedAt;

  String? actorUserId;

  bool? aiInvolved;

  String? operation;

  String? conversationId;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [WorkspaceRevision]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  WorkspaceRevision copyWith({
    int? id,
    int? workspaceId,
    _iz7spkcy.WorkspaceResourceKind? resourceKind,
    String? resourceId,
    int? revision,
    String? data,
    DateTime? capturedAt,
    String? actorUserId,
    bool? aiInvolved,
    String? operation,
    String? conversationId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WorkspaceRevision',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'resourceKind': resourceKind.toJson(),
      'resourceId': resourceId,
      'revision': revision,
      'data': data,
      'capturedAt': capturedAt.toJson(),
      if (actorUserId != null) 'actorUserId': actorUserId,
      if (aiInvolved != null) 'aiInvolved': aiInvolved,
      if (operation != null) 'operation': operation,
      if (conversationId != null) 'conversationId': conversationId,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WorkspaceRevision',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'resourceKind': resourceKind.toJson(),
      'resourceId': resourceId,
      'revision': revision,
      'data': data,
      'capturedAt': capturedAt.toJson(),
      if (actorUserId != null) 'actorUserId': actorUserId,
      if (aiInvolved != null) 'aiInvolved': aiInvolved,
      if (operation != null) 'operation': operation,
      if (conversationId != null) 'conversationId': conversationId,
    };
  }

  static WorkspaceRevisionInclude include() {
    return WorkspaceRevisionInclude._();
  }

  static WorkspaceRevisionIncludeList includeList({
    _is.WhereExpressionBuilder<WorkspaceRevisionTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<WorkspaceRevisionTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceRevisionTable>? orderByList,
    WorkspaceRevisionInclude? include,
  }) {
    return WorkspaceRevisionIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WorkspaceRevision.t),
      orderByList: orderByList?.call(WorkspaceRevision.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WorkspaceRevisionImpl extends WorkspaceRevision {
  _WorkspaceRevisionImpl({
    int? id,
    required int workspaceId,
    required _iz7spkcy.WorkspaceResourceKind resourceKind,
    required String resourceId,
    required int revision,
    required String data,
    required DateTime capturedAt,
    String? actorUserId,
    bool? aiInvolved,
    String? operation,
    String? conversationId,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         resourceKind: resourceKind,
         resourceId: resourceId,
         revision: revision,
         data: data,
         capturedAt: capturedAt,
         actorUserId: actorUserId,
         aiInvolved: aiInvolved,
         operation: operation,
         conversationId: conversationId,
       );

  /// Returns a shallow copy of this [WorkspaceRevision]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  WorkspaceRevision copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    _iz7spkcy.WorkspaceResourceKind? resourceKind,
    String? resourceId,
    int? revision,
    String? data,
    DateTime? capturedAt,
    Object? actorUserId = _Undefined,
    Object? aiInvolved = _Undefined,
    Object? operation = _Undefined,
    Object? conversationId = _Undefined,
  }) {
    return WorkspaceRevision(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      resourceKind: resourceKind ?? this.resourceKind,
      resourceId: resourceId ?? this.resourceId,
      revision: revision ?? this.revision,
      data: data ?? this.data,
      capturedAt: capturedAt ?? this.capturedAt,
      actorUserId: actorUserId is String? ? actorUserId : this.actorUserId,
      aiInvolved: aiInvolved is bool? ? aiInvolved : this.aiInvolved,
      operation: operation is String? ? operation : this.operation,
      conversationId: conversationId is String?
          ? conversationId
          : this.conversationId,
    );
  }
}

class WorkspaceRevisionUpdateTable
    extends _is.UpdateTable<WorkspaceRevisionTable> {
  WorkspaceRevisionUpdateTable(super.table);

  _is.ColumnValue<int, int> workspaceId(int value) => _is.ColumnValue(
    table.workspaceId,
    value,
  );

  _is.ColumnValue<
    _iz7spkcy.WorkspaceResourceKind,
    _iz7spkcy.WorkspaceResourceKind
  >
  resourceKind(_iz7spkcy.WorkspaceResourceKind value) => _is.ColumnValue(
    table.resourceKind,
    value,
  );

  _is.ColumnValue<String, String> resourceId(String value) => _is.ColumnValue(
    table.resourceId,
    value,
  );

  _is.ColumnValue<int, int> revision(int value) => _is.ColumnValue(
    table.revision,
    value,
  );

  _is.ColumnValue<String, String> data(String value) => _is.ColumnValue(
    table.data,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> capturedAt(DateTime value) =>
      _is.ColumnValue(
        table.capturedAt,
        value,
      );

  _is.ColumnValue<String, String> actorUserId(String? value) => _is.ColumnValue(
    table.actorUserId,
    value,
  );

  _is.ColumnValue<bool, bool> aiInvolved(bool? value) => _is.ColumnValue(
    table.aiInvolved,
    value,
  );

  _is.ColumnValue<String, String> operation(String? value) => _is.ColumnValue(
    table.operation,
    value,
  );

  _is.ColumnValue<String, String> conversationId(String? value) =>
      _is.ColumnValue(
        table.conversationId,
        value,
      );
}

class WorkspaceRevisionTable extends _is.Table<int?> {
  WorkspaceRevisionTable({super.tableRelation})
    : super(tableName: 'workspace_revision') {
    updateTable = WorkspaceRevisionUpdateTable(this);
    workspaceId = _is.ColumnInt(
      'workspaceId',
      this,
    );
    resourceKind = _is.ColumnEnum(
      'resourceKind',
      this,
      _is.EnumSerialization.byName,
    );
    resourceId = _is.ColumnString(
      'resourceId',
      this,
    );
    revision = _is.ColumnInt(
      'revision',
      this,
    );
    data = _is.ColumnString(
      'data',
      this,
    );
    capturedAt = _is.ColumnDateTime(
      'capturedAt',
      this,
    );
    actorUserId = _is.ColumnString(
      'actorUserId',
      this,
    );
    aiInvolved = _is.ColumnBool(
      'aiInvolved',
      this,
    );
    operation = _is.ColumnString(
      'operation',
      this,
    );
    conversationId = _is.ColumnString(
      'conversationId',
      this,
    );
  }

  late final WorkspaceRevisionUpdateTable updateTable;

  late final _is.ColumnInt workspaceId;

  late final _is.ColumnEnum<_iz7spkcy.WorkspaceResourceKind> resourceKind;

  late final _is.ColumnString resourceId;

  late final _is.ColumnInt revision;

  late final _is.ColumnString data;

  late final _is.ColumnDateTime capturedAt;

  late final _is.ColumnString actorUserId;

  late final _is.ColumnBool aiInvolved;

  late final _is.ColumnString operation;

  late final _is.ColumnString conversationId;

  @override
  List<_is.Column> get columns => [
    id,
    workspaceId,
    resourceKind,
    resourceId,
    revision,
    data,
    capturedAt,
    actorUserId,
    aiInvolved,
    operation,
    conversationId,
  ];
}

class WorkspaceRevisionInclude extends _is.IncludeObject {
  WorkspaceRevisionInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => WorkspaceRevision.t;
}

class WorkspaceRevisionIncludeList extends _is.IncludeList {
  WorkspaceRevisionIncludeList._({
    _is.WhereExpressionBuilder<WorkspaceRevisionTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(WorkspaceRevision.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => WorkspaceRevision.t;
}

class WorkspaceRevisionRepository {
  const WorkspaceRevisionRepository._();

  /// Returns a list of [WorkspaceRevision]s matching the given query parameters.
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
  Future<List<WorkspaceRevision>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<WorkspaceRevisionTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<WorkspaceRevisionTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceRevisionTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<WorkspaceRevision>(
      where: where?.call(WorkspaceRevision.t),
      orderBy: orderBy?.call(WorkspaceRevision.t),
      orderByList: orderByList?.call(WorkspaceRevision.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [WorkspaceRevision] matching the given query parameters.
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
  Future<WorkspaceRevision?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<WorkspaceRevisionTable>? where,
    int? offset,
    _is.OrderByBuilder<WorkspaceRevisionTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceRevisionTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<WorkspaceRevision>(
      where: where?.call(WorkspaceRevision.t),
      orderBy: orderBy?.call(WorkspaceRevision.t),
      orderByList: orderByList?.call(WorkspaceRevision.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [WorkspaceRevision] by its [id] or null if no such row exists.
  Future<WorkspaceRevision?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<WorkspaceRevision>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [WorkspaceRevision]s in the list and returns the inserted rows.
  ///
  /// The returned [WorkspaceRevision]s will have their `id` fields set.
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
  Future<List<WorkspaceRevision>> insert(
    _is.DatabaseSession session,
    List<WorkspaceRevision> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<WorkspaceRevision>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [WorkspaceRevision] and returns the inserted row.
  ///
  /// The returned [WorkspaceRevision] will have its `id` field set.
  Future<WorkspaceRevision> insertRow(
    _is.DatabaseSession session,
    WorkspaceRevision row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<WorkspaceRevision>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [WorkspaceRevision]s in the list and returns the resulting rows.
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
  /// The returned [WorkspaceRevision]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WorkspaceRevision>> upsert(
    _is.DatabaseSession session,
    List<WorkspaceRevision> rows, {
    required _is.ColumnSelections<WorkspaceRevisionTable> conflictColumns,
    _is.ColumnSelections<WorkspaceRevisionTable>? updateColumns,
    _is.WhereExpressionBuilder<WorkspaceRevisionTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<WorkspaceRevision>(
      rows,
      conflictColumns: conflictColumns(WorkspaceRevision.t),
      updateColumns: updateColumns?.call(WorkspaceRevision.t),
      updateWhere: updateWhere?.call(WorkspaceRevision.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [WorkspaceRevision] and returns the resulting row.
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
  /// The returned [WorkspaceRevision] will have its `id` field set.
  Future<WorkspaceRevision?> upsertRow(
    _is.DatabaseSession session,
    WorkspaceRevision row, {
    required _is.ColumnSelections<WorkspaceRevisionTable> conflictColumns,
    _is.ColumnSelections<WorkspaceRevisionTable>? updateColumns,
    _is.WhereExpressionBuilder<WorkspaceRevisionTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<WorkspaceRevision>(
      row,
      conflictColumns: conflictColumns(WorkspaceRevision.t),
      updateColumns: updateColumns?.call(WorkspaceRevision.t),
      updateWhere: updateWhere?.call(WorkspaceRevision.t),
      transaction: transaction,
    );
  }

  /// Updates all [WorkspaceRevision]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WorkspaceRevision>> update(
    _is.DatabaseSession session,
    List<WorkspaceRevision> rows, {
    _is.ColumnSelections<WorkspaceRevisionTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<WorkspaceRevision>(
      rows,
      columns: columns?.call(WorkspaceRevision.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [WorkspaceRevision]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<WorkspaceRevision> updateRow(
    _is.DatabaseSession session,
    WorkspaceRevision row, {
    _is.ColumnSelections<WorkspaceRevisionTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<WorkspaceRevision>(
      row,
      columns: columns?.call(WorkspaceRevision.t),
      transaction: transaction,
    );
  }

  /// Updates a single [WorkspaceRevision] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<WorkspaceRevision?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<WorkspaceRevisionUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<WorkspaceRevision>(
      id,
      columnValues: columnValues(WorkspaceRevision.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [WorkspaceRevision]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WorkspaceRevision>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<WorkspaceRevisionUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<WorkspaceRevisionTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<WorkspaceRevisionTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceRevisionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<WorkspaceRevision>(
      columnValues: columnValues(WorkspaceRevision.t.updateTable),
      where: where(WorkspaceRevision.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WorkspaceRevision.t),
      orderByList: orderByList?.call(WorkspaceRevision.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [WorkspaceRevision]s in the list and returns the deleted rows.
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
  Future<List<WorkspaceRevision>> delete(
    _is.DatabaseSession session,
    List<WorkspaceRevision> rows, {
    _is.OrderByBuilder<WorkspaceRevisionTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceRevisionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<WorkspaceRevision>(
      rows,
      orderBy: orderBy?.call(WorkspaceRevision.t),
      orderByList: orderByList?.call(WorkspaceRevision.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [WorkspaceRevision].
  Future<WorkspaceRevision> deleteRow(
    _is.DatabaseSession session,
    WorkspaceRevision row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<WorkspaceRevision>(
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
  Future<List<WorkspaceRevision>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<WorkspaceRevisionTable> where,
    _is.OrderByBuilder<WorkspaceRevisionTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceRevisionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<WorkspaceRevision>(
      where: where(WorkspaceRevision.t),
      orderBy: orderBy?.call(WorkspaceRevision.t),
      orderByList: orderByList?.call(WorkspaceRevision.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<WorkspaceRevisionTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<WorkspaceRevision>(
      where: where?.call(WorkspaceRevision.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [WorkspaceRevision] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<WorkspaceRevisionTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<WorkspaceRevision>(
      where: where(WorkspaceRevision.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
