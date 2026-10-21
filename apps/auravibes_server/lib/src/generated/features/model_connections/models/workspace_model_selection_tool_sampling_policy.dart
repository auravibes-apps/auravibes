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

abstract class WorkspaceModelSelectionToolSamplingPolicy
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  WorkspaceModelSelectionToolSamplingPolicy._({
    this.id,
    required this.workspaceId,
    required this.connectionId,
    required this.modelId,
    required this.toolSamplingPolicy,
  });

  factory WorkspaceModelSelectionToolSamplingPolicy({
    int? id,
    required int workspaceId,
    required String connectionId,
    required String modelId,
    required String toolSamplingPolicy,
  }) = _WorkspaceModelSelectionToolSamplingPolicyImpl;

  factory WorkspaceModelSelectionToolSamplingPolicy.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return WorkspaceModelSelectionToolSamplingPolicy(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      connectionId: jsonSerialization['connectionId'] as String,
      modelId: jsonSerialization['modelId'] as String,
      toolSamplingPolicy: jsonSerialization['toolSamplingPolicy'] as String,
    );
  }

  static final t = WorkspaceModelSelectionToolSamplingPolicyTable();

  static const db = WorkspaceModelSelectionToolSamplingPolicyRepository._();

  @override
  int? id;

  int workspaceId;

  String connectionId;

  String modelId;

  String toolSamplingPolicy;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [WorkspaceModelSelectionToolSamplingPolicy]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  WorkspaceModelSelectionToolSamplingPolicy copyWith({
    int? id,
    int? workspaceId,
    String? connectionId,
    String? modelId,
    String? toolSamplingPolicy,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WorkspaceModelSelectionToolSamplingPolicy',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'connectionId': connectionId,
      'modelId': modelId,
      'toolSamplingPolicy': toolSamplingPolicy,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WorkspaceModelSelectionToolSamplingPolicy',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'connectionId': connectionId,
      'modelId': modelId,
      'toolSamplingPolicy': toolSamplingPolicy,
    };
  }

  static WorkspaceModelSelectionToolSamplingPolicyInclude include() {
    return WorkspaceModelSelectionToolSamplingPolicyInclude._();
  }

  static WorkspaceModelSelectionToolSamplingPolicyIncludeList includeList({
    _is.WhereExpressionBuilder<WorkspaceModelSelectionToolSamplingPolicyTable>?
    where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<WorkspaceModelSelectionToolSamplingPolicyTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceModelSelectionToolSamplingPolicyTable>?
    orderByList,
    WorkspaceModelSelectionToolSamplingPolicyInclude? include,
  }) {
    return WorkspaceModelSelectionToolSamplingPolicyIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WorkspaceModelSelectionToolSamplingPolicy.t),
      orderByList: orderByList?.call(
        WorkspaceModelSelectionToolSamplingPolicy.t,
      ),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WorkspaceModelSelectionToolSamplingPolicyImpl
    extends WorkspaceModelSelectionToolSamplingPolicy {
  _WorkspaceModelSelectionToolSamplingPolicyImpl({
    int? id,
    required int workspaceId,
    required String connectionId,
    required String modelId,
    required String toolSamplingPolicy,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         connectionId: connectionId,
         modelId: modelId,
         toolSamplingPolicy: toolSamplingPolicy,
       );

  /// Returns a shallow copy of this [WorkspaceModelSelectionToolSamplingPolicy]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  WorkspaceModelSelectionToolSamplingPolicy copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    String? connectionId,
    String? modelId,
    String? toolSamplingPolicy,
  }) {
    return WorkspaceModelSelectionToolSamplingPolicy(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      connectionId: connectionId ?? this.connectionId,
      modelId: modelId ?? this.modelId,
      toolSamplingPolicy: toolSamplingPolicy ?? this.toolSamplingPolicy,
    );
  }
}

class WorkspaceModelSelectionToolSamplingPolicyUpdateTable
    extends _is.UpdateTable<WorkspaceModelSelectionToolSamplingPolicyTable> {
  WorkspaceModelSelectionToolSamplingPolicyUpdateTable(super.table);

  _is.ColumnValue<int, int> workspaceId(int value) => _is.ColumnValue(
    table.workspaceId,
    value,
  );

  _is.ColumnValue<String, String> connectionId(String value) => _is.ColumnValue(
    table.connectionId,
    value,
  );

  _is.ColumnValue<String, String> modelId(String value) => _is.ColumnValue(
    table.modelId,
    value,
  );

  _is.ColumnValue<String, String> toolSamplingPolicy(String value) =>
      _is.ColumnValue(
        table.toolSamplingPolicy,
        value,
      );
}

class WorkspaceModelSelectionToolSamplingPolicyTable extends _is.Table<int?> {
  WorkspaceModelSelectionToolSamplingPolicyTable({super.tableRelation})
    : super(tableName: 'workspace_model_selection_tool_sampling_policy') {
    updateTable = WorkspaceModelSelectionToolSamplingPolicyUpdateTable(this);
    workspaceId = _is.ColumnInt(
      'workspaceId',
      this,
    );
    connectionId = _is.ColumnString(
      'connectionId',
      this,
    );
    modelId = _is.ColumnString(
      'modelId',
      this,
    );
    toolSamplingPolicy = _is.ColumnString(
      'toolSamplingPolicy',
      this,
    );
  }

  late final WorkspaceModelSelectionToolSamplingPolicyUpdateTable updateTable;

  late final _is.ColumnInt workspaceId;

  late final _is.ColumnString connectionId;

  late final _is.ColumnString modelId;

  late final _is.ColumnString toolSamplingPolicy;

  @override
  List<_is.Column> get columns => [
    id,
    workspaceId,
    connectionId,
    modelId,
    toolSamplingPolicy,
  ];
}

class WorkspaceModelSelectionToolSamplingPolicyInclude
    extends _is.IncludeObject {
  WorkspaceModelSelectionToolSamplingPolicyInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => WorkspaceModelSelectionToolSamplingPolicy.t;
}

class WorkspaceModelSelectionToolSamplingPolicyIncludeList
    extends _is.IncludeList {
  WorkspaceModelSelectionToolSamplingPolicyIncludeList._({
    _is.WhereExpressionBuilder<WorkspaceModelSelectionToolSamplingPolicyTable>?
    where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(WorkspaceModelSelectionToolSamplingPolicy.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => WorkspaceModelSelectionToolSamplingPolicy.t;
}

class WorkspaceModelSelectionToolSamplingPolicyRepository {
  const WorkspaceModelSelectionToolSamplingPolicyRepository._();

  /// Returns a list of [WorkspaceModelSelectionToolSamplingPolicy]s matching the given query parameters.
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
  Future<List<WorkspaceModelSelectionToolSamplingPolicy>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<WorkspaceModelSelectionToolSamplingPolicyTable>?
    where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<WorkspaceModelSelectionToolSamplingPolicyTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceModelSelectionToolSamplingPolicyTable>?
    orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<WorkspaceModelSelectionToolSamplingPolicy>(
      where: where?.call(WorkspaceModelSelectionToolSamplingPolicy.t),
      orderBy: orderBy?.call(WorkspaceModelSelectionToolSamplingPolicy.t),
      orderByList: orderByList?.call(
        WorkspaceModelSelectionToolSamplingPolicy.t,
      ),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [WorkspaceModelSelectionToolSamplingPolicy] matching the given query parameters.
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
  Future<WorkspaceModelSelectionToolSamplingPolicy?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<WorkspaceModelSelectionToolSamplingPolicyTable>?
    where,
    int? offset,
    _is.OrderByBuilder<WorkspaceModelSelectionToolSamplingPolicyTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceModelSelectionToolSamplingPolicyTable>?
    orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<WorkspaceModelSelectionToolSamplingPolicy>(
      where: where?.call(WorkspaceModelSelectionToolSamplingPolicy.t),
      orderBy: orderBy?.call(WorkspaceModelSelectionToolSamplingPolicy.t),
      orderByList: orderByList?.call(
        WorkspaceModelSelectionToolSamplingPolicy.t,
      ),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [WorkspaceModelSelectionToolSamplingPolicy] by its [id] or null if no such row exists.
  Future<WorkspaceModelSelectionToolSamplingPolicy?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<WorkspaceModelSelectionToolSamplingPolicy>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [WorkspaceModelSelectionToolSamplingPolicy]s in the list and returns the inserted rows.
  ///
  /// The returned [WorkspaceModelSelectionToolSamplingPolicy]s will have their `id` fields set.
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
  Future<List<WorkspaceModelSelectionToolSamplingPolicy>> insert(
    _is.DatabaseSession session,
    List<WorkspaceModelSelectionToolSamplingPolicy> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<WorkspaceModelSelectionToolSamplingPolicy>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [WorkspaceModelSelectionToolSamplingPolicy] and returns the inserted row.
  ///
  /// The returned [WorkspaceModelSelectionToolSamplingPolicy] will have its `id` field set.
  Future<WorkspaceModelSelectionToolSamplingPolicy> insertRow(
    _is.DatabaseSession session,
    WorkspaceModelSelectionToolSamplingPolicy row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<WorkspaceModelSelectionToolSamplingPolicy>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [WorkspaceModelSelectionToolSamplingPolicy]s in the list and returns the resulting rows.
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
  /// The returned [WorkspaceModelSelectionToolSamplingPolicy]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WorkspaceModelSelectionToolSamplingPolicy>> upsert(
    _is.DatabaseSession session,
    List<WorkspaceModelSelectionToolSamplingPolicy> rows, {
    required _is.ColumnSelections<
      WorkspaceModelSelectionToolSamplingPolicyTable
    >
    conflictColumns,
    _is.ColumnSelections<WorkspaceModelSelectionToolSamplingPolicyTable>?
    updateColumns,
    _is.WhereExpressionBuilder<WorkspaceModelSelectionToolSamplingPolicyTable>?
    updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<WorkspaceModelSelectionToolSamplingPolicy>(
      rows,
      conflictColumns: conflictColumns(
        WorkspaceModelSelectionToolSamplingPolicy.t,
      ),
      updateColumns: updateColumns?.call(
        WorkspaceModelSelectionToolSamplingPolicy.t,
      ),
      updateWhere: updateWhere?.call(
        WorkspaceModelSelectionToolSamplingPolicy.t,
      ),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [WorkspaceModelSelectionToolSamplingPolicy] and returns the resulting row.
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
  /// The returned [WorkspaceModelSelectionToolSamplingPolicy] will have its `id` field set.
  Future<WorkspaceModelSelectionToolSamplingPolicy?> upsertRow(
    _is.DatabaseSession session,
    WorkspaceModelSelectionToolSamplingPolicy row, {
    required _is.ColumnSelections<
      WorkspaceModelSelectionToolSamplingPolicyTable
    >
    conflictColumns,
    _is.ColumnSelections<WorkspaceModelSelectionToolSamplingPolicyTable>?
    updateColumns,
    _is.WhereExpressionBuilder<WorkspaceModelSelectionToolSamplingPolicyTable>?
    updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<WorkspaceModelSelectionToolSamplingPolicy>(
      row,
      conflictColumns: conflictColumns(
        WorkspaceModelSelectionToolSamplingPolicy.t,
      ),
      updateColumns: updateColumns?.call(
        WorkspaceModelSelectionToolSamplingPolicy.t,
      ),
      updateWhere: updateWhere?.call(
        WorkspaceModelSelectionToolSamplingPolicy.t,
      ),
      transaction: transaction,
    );
  }

  /// Updates all [WorkspaceModelSelectionToolSamplingPolicy]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WorkspaceModelSelectionToolSamplingPolicy>> update(
    _is.DatabaseSession session,
    List<WorkspaceModelSelectionToolSamplingPolicy> rows, {
    _is.ColumnSelections<WorkspaceModelSelectionToolSamplingPolicyTable>?
    columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<WorkspaceModelSelectionToolSamplingPolicy>(
      rows,
      columns: columns?.call(WorkspaceModelSelectionToolSamplingPolicy.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [WorkspaceModelSelectionToolSamplingPolicy]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<WorkspaceModelSelectionToolSamplingPolicy> updateRow(
    _is.DatabaseSession session,
    WorkspaceModelSelectionToolSamplingPolicy row, {
    _is.ColumnSelections<WorkspaceModelSelectionToolSamplingPolicyTable>?
    columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<WorkspaceModelSelectionToolSamplingPolicy>(
      row,
      columns: columns?.call(WorkspaceModelSelectionToolSamplingPolicy.t),
      transaction: transaction,
    );
  }

  /// Updates a single [WorkspaceModelSelectionToolSamplingPolicy] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<WorkspaceModelSelectionToolSamplingPolicy?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<
      WorkspaceModelSelectionToolSamplingPolicyUpdateTable
    >
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<WorkspaceModelSelectionToolSamplingPolicy>(
      id,
      columnValues: columnValues(
        WorkspaceModelSelectionToolSamplingPolicy.t.updateTable,
      ),
      transaction: transaction,
    );
  }

  /// Updates all [WorkspaceModelSelectionToolSamplingPolicy]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WorkspaceModelSelectionToolSamplingPolicy>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<
      WorkspaceModelSelectionToolSamplingPolicyUpdateTable
    >
    columnValues,
    required _is.WhereExpressionBuilder<
      WorkspaceModelSelectionToolSamplingPolicyTable
    >
    where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<WorkspaceModelSelectionToolSamplingPolicyTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceModelSelectionToolSamplingPolicyTable>?
    orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<WorkspaceModelSelectionToolSamplingPolicy>(
      columnValues: columnValues(
        WorkspaceModelSelectionToolSamplingPolicy.t.updateTable,
      ),
      where: where(WorkspaceModelSelectionToolSamplingPolicy.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WorkspaceModelSelectionToolSamplingPolicy.t),
      orderByList: orderByList?.call(
        WorkspaceModelSelectionToolSamplingPolicy.t,
      ),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [WorkspaceModelSelectionToolSamplingPolicy]s in the list and returns the deleted rows.
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
  Future<List<WorkspaceModelSelectionToolSamplingPolicy>> delete(
    _is.DatabaseSession session,
    List<WorkspaceModelSelectionToolSamplingPolicy> rows, {
    _is.OrderByBuilder<WorkspaceModelSelectionToolSamplingPolicyTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceModelSelectionToolSamplingPolicyTable>?
    orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<WorkspaceModelSelectionToolSamplingPolicy>(
      rows,
      orderBy: orderBy?.call(WorkspaceModelSelectionToolSamplingPolicy.t),
      orderByList: orderByList?.call(
        WorkspaceModelSelectionToolSamplingPolicy.t,
      ),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [WorkspaceModelSelectionToolSamplingPolicy].
  Future<WorkspaceModelSelectionToolSamplingPolicy> deleteRow(
    _is.DatabaseSession session,
    WorkspaceModelSelectionToolSamplingPolicy row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<WorkspaceModelSelectionToolSamplingPolicy>(
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
  Future<List<WorkspaceModelSelectionToolSamplingPolicy>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<
      WorkspaceModelSelectionToolSamplingPolicyTable
    >
    where,
    _is.OrderByBuilder<WorkspaceModelSelectionToolSamplingPolicyTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceModelSelectionToolSamplingPolicyTable>?
    orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<WorkspaceModelSelectionToolSamplingPolicy>(
      where: where(WorkspaceModelSelectionToolSamplingPolicy.t),
      orderBy: orderBy?.call(WorkspaceModelSelectionToolSamplingPolicy.t),
      orderByList: orderByList?.call(
        WorkspaceModelSelectionToolSamplingPolicy.t,
      ),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<WorkspaceModelSelectionToolSamplingPolicyTable>?
    where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<WorkspaceModelSelectionToolSamplingPolicy>(
      where: where?.call(WorkspaceModelSelectionToolSamplingPolicy.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [WorkspaceModelSelectionToolSamplingPolicy] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<
      WorkspaceModelSelectionToolSamplingPolicyTable
    >
    where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<WorkspaceModelSelectionToolSamplingPolicy>(
      where: where(WorkspaceModelSelectionToolSamplingPolicy.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
