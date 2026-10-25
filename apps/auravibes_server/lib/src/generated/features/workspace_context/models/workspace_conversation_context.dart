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

abstract class WorkspaceConversationContext
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  WorkspaceConversationContext._({
    this.id,
    required this.workspaceId,
    required this.conversationId,
    required this.stableId,
    required this.actorUserId,
    this.selectionJson,
    required this.createdAt,
  });

  factory WorkspaceConversationContext({
    int? id,
    required int workspaceId,
    required int conversationId,
    required String stableId,
    required String actorUserId,
    String? selectionJson,
    required DateTime createdAt,
  }) = _WorkspaceConversationContextImpl;

  factory WorkspaceConversationContext.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return WorkspaceConversationContext(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      conversationId: jsonSerialization['conversationId'] as int,
      stableId: jsonSerialization['stableId'] as String,
      actorUserId: jsonSerialization['actorUserId'] as String,
      selectionJson: jsonSerialization['selectionJson'] as String?,
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  static final t = WorkspaceConversationContextTable();

  static const db = WorkspaceConversationContextRepository._();

  @override
  int? id;

  int workspaceId;

  int conversationId;

  String stableId;

  String actorUserId;

  String? selectionJson;

  DateTime createdAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [WorkspaceConversationContext]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  WorkspaceConversationContext copyWith({
    int? id,
    int? workspaceId,
    int? conversationId,
    String? stableId,
    String? actorUserId,
    String? selectionJson,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WorkspaceConversationContext',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'conversationId': conversationId,
      'stableId': stableId,
      'actorUserId': actorUserId,
      if (selectionJson != null) 'selectionJson': selectionJson,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WorkspaceConversationContext',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'conversationId': conversationId,
      'stableId': stableId,
      'actorUserId': actorUserId,
      if (selectionJson != null) 'selectionJson': selectionJson,
      'createdAt': createdAt.toJson(),
    };
  }

  static WorkspaceConversationContextInclude include() {
    return WorkspaceConversationContextInclude._();
  }

  static WorkspaceConversationContextIncludeList includeList({
    _is.WhereExpressionBuilder<WorkspaceConversationContextTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<WorkspaceConversationContextTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceConversationContextTable>? orderByList,
    WorkspaceConversationContextInclude? include,
  }) {
    return WorkspaceConversationContextIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WorkspaceConversationContext.t),
      orderByList: orderByList?.call(WorkspaceConversationContext.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WorkspaceConversationContextImpl extends WorkspaceConversationContext {
  _WorkspaceConversationContextImpl({
    int? id,
    required int workspaceId,
    required int conversationId,
    required String stableId,
    required String actorUserId,
    String? selectionJson,
    required DateTime createdAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         conversationId: conversationId,
         stableId: stableId,
         actorUserId: actorUserId,
         selectionJson: selectionJson,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [WorkspaceConversationContext]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  WorkspaceConversationContext copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    int? conversationId,
    String? stableId,
    String? actorUserId,
    Object? selectionJson = _Undefined,
    DateTime? createdAt,
  }) {
    return WorkspaceConversationContext(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      conversationId: conversationId ?? this.conversationId,
      stableId: stableId ?? this.stableId,
      actorUserId: actorUserId ?? this.actorUserId,
      selectionJson: selectionJson is String?
          ? selectionJson
          : this.selectionJson,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class WorkspaceConversationContextUpdateTable
    extends _is.UpdateTable<WorkspaceConversationContextTable> {
  WorkspaceConversationContextUpdateTable(super.table);

  _is.ColumnValue<int, int> workspaceId(int value) => _is.ColumnValue(
    table.workspaceId,
    value,
  );

  _is.ColumnValue<int, int> conversationId(int value) => _is.ColumnValue(
    table.conversationId,
    value,
  );

  _is.ColumnValue<String, String> stableId(String value) => _is.ColumnValue(
    table.stableId,
    value,
  );

  _is.ColumnValue<String, String> actorUserId(String value) => _is.ColumnValue(
    table.actorUserId,
    value,
  );

  _is.ColumnValue<String, String> selectionJson(String? value) =>
      _is.ColumnValue(
        table.selectionJson,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class WorkspaceConversationContextTable extends _is.Table<int?> {
  WorkspaceConversationContextTable({super.tableRelation})
    : super(tableName: 'workspace_conversation_context') {
    updateTable = WorkspaceConversationContextUpdateTable(this);
    workspaceId = _is.ColumnInt(
      'workspaceId',
      this,
    );
    conversationId = _is.ColumnInt(
      'conversationId',
      this,
    );
    stableId = _is.ColumnString(
      'stableId',
      this,
    );
    actorUserId = _is.ColumnString(
      'actorUserId',
      this,
    );
    selectionJson = _is.ColumnString(
      'selectionJson',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final WorkspaceConversationContextUpdateTable updateTable;

  late final _is.ColumnInt workspaceId;

  late final _is.ColumnInt conversationId;

  late final _is.ColumnString stableId;

  late final _is.ColumnString actorUserId;

  late final _is.ColumnString selectionJson;

  late final _is.ColumnDateTime createdAt;

  @override
  List<_is.Column> get columns => [
    id,
    workspaceId,
    conversationId,
    stableId,
    actorUserId,
    selectionJson,
    createdAt,
  ];
}

class WorkspaceConversationContextInclude extends _is.IncludeObject {
  WorkspaceConversationContextInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => WorkspaceConversationContext.t;
}

class WorkspaceConversationContextIncludeList extends _is.IncludeList {
  WorkspaceConversationContextIncludeList._({
    _is.WhereExpressionBuilder<WorkspaceConversationContextTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(WorkspaceConversationContext.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => WorkspaceConversationContext.t;
}

class WorkspaceConversationContextRepository {
  const WorkspaceConversationContextRepository._();

  /// Returns a list of [WorkspaceConversationContext]s matching the given query parameters.
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
  Future<List<WorkspaceConversationContext>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<WorkspaceConversationContextTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<WorkspaceConversationContextTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceConversationContextTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<WorkspaceConversationContext>(
      where: where?.call(WorkspaceConversationContext.t),
      orderBy: orderBy?.call(WorkspaceConversationContext.t),
      orderByList: orderByList?.call(WorkspaceConversationContext.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [WorkspaceConversationContext] matching the given query parameters.
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
  Future<WorkspaceConversationContext?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<WorkspaceConversationContextTable>? where,
    int? offset,
    _is.OrderByBuilder<WorkspaceConversationContextTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceConversationContextTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<WorkspaceConversationContext>(
      where: where?.call(WorkspaceConversationContext.t),
      orderBy: orderBy?.call(WorkspaceConversationContext.t),
      orderByList: orderByList?.call(WorkspaceConversationContext.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [WorkspaceConversationContext] by its [id] or null if no such row exists.
  Future<WorkspaceConversationContext?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<WorkspaceConversationContext>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [WorkspaceConversationContext]s in the list and returns the inserted rows.
  ///
  /// The returned [WorkspaceConversationContext]s will have their `id` fields set.
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
  Future<List<WorkspaceConversationContext>> insert(
    _is.DatabaseSession session,
    List<WorkspaceConversationContext> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<WorkspaceConversationContext>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [WorkspaceConversationContext] and returns the inserted row.
  ///
  /// The returned [WorkspaceConversationContext] will have its `id` field set.
  Future<WorkspaceConversationContext> insertRow(
    _is.DatabaseSession session,
    WorkspaceConversationContext row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<WorkspaceConversationContext>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [WorkspaceConversationContext]s in the list and returns the resulting rows.
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
  /// The returned [WorkspaceConversationContext]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WorkspaceConversationContext>> upsert(
    _is.DatabaseSession session,
    List<WorkspaceConversationContext> rows, {
    required _is.ColumnSelections<WorkspaceConversationContextTable>
    conflictColumns,
    _is.ColumnSelections<WorkspaceConversationContextTable>? updateColumns,
    _is.WhereExpressionBuilder<WorkspaceConversationContextTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<WorkspaceConversationContext>(
      rows,
      conflictColumns: conflictColumns(WorkspaceConversationContext.t),
      updateColumns: updateColumns?.call(WorkspaceConversationContext.t),
      updateWhere: updateWhere?.call(WorkspaceConversationContext.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [WorkspaceConversationContext] and returns the resulting row.
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
  /// The returned [WorkspaceConversationContext] will have its `id` field set.
  Future<WorkspaceConversationContext?> upsertRow(
    _is.DatabaseSession session,
    WorkspaceConversationContext row, {
    required _is.ColumnSelections<WorkspaceConversationContextTable>
    conflictColumns,
    _is.ColumnSelections<WorkspaceConversationContextTable>? updateColumns,
    _is.WhereExpressionBuilder<WorkspaceConversationContextTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<WorkspaceConversationContext>(
      row,
      conflictColumns: conflictColumns(WorkspaceConversationContext.t),
      updateColumns: updateColumns?.call(WorkspaceConversationContext.t),
      updateWhere: updateWhere?.call(WorkspaceConversationContext.t),
      transaction: transaction,
    );
  }

  /// Updates all [WorkspaceConversationContext]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WorkspaceConversationContext>> update(
    _is.DatabaseSession session,
    List<WorkspaceConversationContext> rows, {
    _is.ColumnSelections<WorkspaceConversationContextTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<WorkspaceConversationContext>(
      rows,
      columns: columns?.call(WorkspaceConversationContext.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [WorkspaceConversationContext]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<WorkspaceConversationContext> updateRow(
    _is.DatabaseSession session,
    WorkspaceConversationContext row, {
    _is.ColumnSelections<WorkspaceConversationContextTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<WorkspaceConversationContext>(
      row,
      columns: columns?.call(WorkspaceConversationContext.t),
      transaction: transaction,
    );
  }

  /// Updates a single [WorkspaceConversationContext] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<WorkspaceConversationContext?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<WorkspaceConversationContextUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<WorkspaceConversationContext>(
      id,
      columnValues: columnValues(WorkspaceConversationContext.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [WorkspaceConversationContext]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WorkspaceConversationContext>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<WorkspaceConversationContextUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<WorkspaceConversationContextTable>
    where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<WorkspaceConversationContextTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceConversationContextTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<WorkspaceConversationContext>(
      columnValues: columnValues(WorkspaceConversationContext.t.updateTable),
      where: where(WorkspaceConversationContext.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WorkspaceConversationContext.t),
      orderByList: orderByList?.call(WorkspaceConversationContext.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [WorkspaceConversationContext]s in the list and returns the deleted rows.
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
  Future<List<WorkspaceConversationContext>> delete(
    _is.DatabaseSession session,
    List<WorkspaceConversationContext> rows, {
    _is.OrderByBuilder<WorkspaceConversationContextTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceConversationContextTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<WorkspaceConversationContext>(
      rows,
      orderBy: orderBy?.call(WorkspaceConversationContext.t),
      orderByList: orderByList?.call(WorkspaceConversationContext.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [WorkspaceConversationContext].
  Future<WorkspaceConversationContext> deleteRow(
    _is.DatabaseSession session,
    WorkspaceConversationContext row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<WorkspaceConversationContext>(
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
  Future<List<WorkspaceConversationContext>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<WorkspaceConversationContextTable>
    where,
    _is.OrderByBuilder<WorkspaceConversationContextTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceConversationContextTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<WorkspaceConversationContext>(
      where: where(WorkspaceConversationContext.t),
      orderBy: orderBy?.call(WorkspaceConversationContext.t),
      orderByList: orderByList?.call(WorkspaceConversationContext.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<WorkspaceConversationContextTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<WorkspaceConversationContext>(
      where: where?.call(WorkspaceConversationContext.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [WorkspaceConversationContext] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<WorkspaceConversationContextTable>
    where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<WorkspaceConversationContext>(
      where: where(WorkspaceConversationContext.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
