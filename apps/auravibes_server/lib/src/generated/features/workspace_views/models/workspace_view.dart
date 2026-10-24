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

abstract class WorkspaceView
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  WorkspaceView._({
    this.id,
    required this.workspaceId,
    required this.stableId,
    required this.data,
    required this.revision,
    required this.history,
  });

  factory WorkspaceView({
    int? id,
    required int workspaceId,
    required String stableId,
    required String data,
    required int revision,
    required String history,
  }) = _WorkspaceViewImpl;

  factory WorkspaceView.fromJson(Map<String, dynamic> jsonSerialization) {
    return WorkspaceView(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      stableId: jsonSerialization['stableId'] as String,
      data: jsonSerialization['data'] as String,
      revision: jsonSerialization['revision'] as int,
      history: jsonSerialization['history'] as String,
    );
  }

  static final t = WorkspaceViewTable();

  static const db = WorkspaceViewRepository._();

  @override
  int? id;

  int workspaceId;

  String stableId;

  String data;

  int revision;

  String history;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [WorkspaceView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  WorkspaceView copyWith({
    int? id,
    int? workspaceId,
    String? stableId,
    String? data,
    int? revision,
    String? history,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WorkspaceView',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'stableId': stableId,
      'data': data,
      'revision': revision,
      'history': history,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WorkspaceView',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'stableId': stableId,
      'data': data,
      'revision': revision,
      'history': history,
    };
  }

  static WorkspaceViewInclude include() {
    return WorkspaceViewInclude._();
  }

  static WorkspaceViewIncludeList includeList({
    _is.WhereExpressionBuilder<WorkspaceViewTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<WorkspaceViewTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceViewTable>? orderByList,
    WorkspaceViewInclude? include,
  }) {
    return WorkspaceViewIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WorkspaceView.t),
      orderByList: orderByList?.call(WorkspaceView.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WorkspaceViewImpl extends WorkspaceView {
  _WorkspaceViewImpl({
    int? id,
    required int workspaceId,
    required String stableId,
    required String data,
    required int revision,
    required String history,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         stableId: stableId,
         data: data,
         revision: revision,
         history: history,
       );

  /// Returns a shallow copy of this [WorkspaceView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  WorkspaceView copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    String? stableId,
    String? data,
    int? revision,
    String? history,
  }) {
    return WorkspaceView(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      stableId: stableId ?? this.stableId,
      data: data ?? this.data,
      revision: revision ?? this.revision,
      history: history ?? this.history,
    );
  }
}

class WorkspaceViewUpdateTable extends _is.UpdateTable<WorkspaceViewTable> {
  WorkspaceViewUpdateTable(super.table);

  _is.ColumnValue<int, int> workspaceId(int value) => _is.ColumnValue(
    table.workspaceId,
    value,
  );

  _is.ColumnValue<String, String> stableId(String value) => _is.ColumnValue(
    table.stableId,
    value,
  );

  _is.ColumnValue<String, String> data(String value) => _is.ColumnValue(
    table.data,
    value,
  );

  _is.ColumnValue<int, int> revision(int value) => _is.ColumnValue(
    table.revision,
    value,
  );

  _is.ColumnValue<String, String> history(String value) => _is.ColumnValue(
    table.history,
    value,
  );
}

class WorkspaceViewTable extends _is.Table<int?> {
  WorkspaceViewTable({super.tableRelation})
    : super(tableName: 'workspace_view') {
    updateTable = WorkspaceViewUpdateTable(this);
    workspaceId = _is.ColumnInt(
      'workspaceId',
      this,
    );
    stableId = _is.ColumnString(
      'stableId',
      this,
    );
    data = _is.ColumnString(
      'data',
      this,
    );
    revision = _is.ColumnInt(
      'revision',
      this,
    );
    history = _is.ColumnString(
      'history',
      this,
    );
  }

  late final WorkspaceViewUpdateTable updateTable;

  late final _is.ColumnInt workspaceId;

  late final _is.ColumnString stableId;

  late final _is.ColumnString data;

  late final _is.ColumnInt revision;

  late final _is.ColumnString history;

  @override
  List<_is.Column> get columns => [
    id,
    workspaceId,
    stableId,
    data,
    revision,
    history,
  ];
}

class WorkspaceViewInclude extends _is.IncludeObject {
  WorkspaceViewInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => WorkspaceView.t;
}

class WorkspaceViewIncludeList extends _is.IncludeList {
  WorkspaceViewIncludeList._({
    _is.WhereExpressionBuilder<WorkspaceViewTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(WorkspaceView.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => WorkspaceView.t;
}

class WorkspaceViewRepository {
  const WorkspaceViewRepository._();

  /// Returns a list of [WorkspaceView]s matching the given query parameters.
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
  Future<List<WorkspaceView>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<WorkspaceViewTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<WorkspaceViewTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceViewTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<WorkspaceView>(
      where: where?.call(WorkspaceView.t),
      orderBy: orderBy?.call(WorkspaceView.t),
      orderByList: orderByList?.call(WorkspaceView.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [WorkspaceView] matching the given query parameters.
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
  Future<WorkspaceView?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<WorkspaceViewTable>? where,
    int? offset,
    _is.OrderByBuilder<WorkspaceViewTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceViewTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<WorkspaceView>(
      where: where?.call(WorkspaceView.t),
      orderBy: orderBy?.call(WorkspaceView.t),
      orderByList: orderByList?.call(WorkspaceView.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [WorkspaceView] by its [id] or null if no such row exists.
  Future<WorkspaceView?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<WorkspaceView>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [WorkspaceView]s in the list and returns the inserted rows.
  ///
  /// The returned [WorkspaceView]s will have their `id` fields set.
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
  Future<List<WorkspaceView>> insert(
    _is.DatabaseSession session,
    List<WorkspaceView> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<WorkspaceView>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [WorkspaceView] and returns the inserted row.
  ///
  /// The returned [WorkspaceView] will have its `id` field set.
  Future<WorkspaceView> insertRow(
    _is.DatabaseSession session,
    WorkspaceView row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<WorkspaceView>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [WorkspaceView]s in the list and returns the resulting rows.
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
  /// The returned [WorkspaceView]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WorkspaceView>> upsert(
    _is.DatabaseSession session,
    List<WorkspaceView> rows, {
    required _is.ColumnSelections<WorkspaceViewTable> conflictColumns,
    _is.ColumnSelections<WorkspaceViewTable>? updateColumns,
    _is.WhereExpressionBuilder<WorkspaceViewTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<WorkspaceView>(
      rows,
      conflictColumns: conflictColumns(WorkspaceView.t),
      updateColumns: updateColumns?.call(WorkspaceView.t),
      updateWhere: updateWhere?.call(WorkspaceView.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [WorkspaceView] and returns the resulting row.
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
  /// The returned [WorkspaceView] will have its `id` field set.
  Future<WorkspaceView?> upsertRow(
    _is.DatabaseSession session,
    WorkspaceView row, {
    required _is.ColumnSelections<WorkspaceViewTable> conflictColumns,
    _is.ColumnSelections<WorkspaceViewTable>? updateColumns,
    _is.WhereExpressionBuilder<WorkspaceViewTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<WorkspaceView>(
      row,
      conflictColumns: conflictColumns(WorkspaceView.t),
      updateColumns: updateColumns?.call(WorkspaceView.t),
      updateWhere: updateWhere?.call(WorkspaceView.t),
      transaction: transaction,
    );
  }

  /// Updates all [WorkspaceView]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WorkspaceView>> update(
    _is.DatabaseSession session,
    List<WorkspaceView> rows, {
    _is.ColumnSelections<WorkspaceViewTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<WorkspaceView>(
      rows,
      columns: columns?.call(WorkspaceView.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [WorkspaceView]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<WorkspaceView> updateRow(
    _is.DatabaseSession session,
    WorkspaceView row, {
    _is.ColumnSelections<WorkspaceViewTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<WorkspaceView>(
      row,
      columns: columns?.call(WorkspaceView.t),
      transaction: transaction,
    );
  }

  /// Updates a single [WorkspaceView] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<WorkspaceView?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<WorkspaceViewUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<WorkspaceView>(
      id,
      columnValues: columnValues(WorkspaceView.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [WorkspaceView]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WorkspaceView>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<WorkspaceViewUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<WorkspaceViewTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<WorkspaceViewTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceViewTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<WorkspaceView>(
      columnValues: columnValues(WorkspaceView.t.updateTable),
      where: where(WorkspaceView.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WorkspaceView.t),
      orderByList: orderByList?.call(WorkspaceView.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [WorkspaceView]s in the list and returns the deleted rows.
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
  Future<List<WorkspaceView>> delete(
    _is.DatabaseSession session,
    List<WorkspaceView> rows, {
    _is.OrderByBuilder<WorkspaceViewTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceViewTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<WorkspaceView>(
      rows,
      orderBy: orderBy?.call(WorkspaceView.t),
      orderByList: orderByList?.call(WorkspaceView.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [WorkspaceView].
  Future<WorkspaceView> deleteRow(
    _is.DatabaseSession session,
    WorkspaceView row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<WorkspaceView>(
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
  Future<List<WorkspaceView>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<WorkspaceViewTable> where,
    _is.OrderByBuilder<WorkspaceViewTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceViewTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<WorkspaceView>(
      where: where(WorkspaceView.t),
      orderBy: orderBy?.call(WorkspaceView.t),
      orderByList: orderByList?.call(WorkspaceView.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<WorkspaceViewTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<WorkspaceView>(
      where: where?.call(WorkspaceView.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [WorkspaceView] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<WorkspaceViewTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<WorkspaceView>(
      where: where(WorkspaceView.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
