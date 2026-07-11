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

abstract class WorkspaceMember
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  WorkspaceMember._({
    this.id,
    required this.workspaceId,
    required this.userId,
    required this.role,
    required this.createdAt,
    this.removedAt,
  });

  factory WorkspaceMember({
    int? id,
    required int workspaceId,
    required String userId,
    required String role,
    required DateTime createdAt,
    DateTime? removedAt,
  }) = _WorkspaceMemberImpl;

  factory WorkspaceMember.fromJson(Map<String, dynamic> jsonSerialization) {
    return WorkspaceMember(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      userId: jsonSerialization['userId'] as String,
      role: jsonSerialization['role'] as String,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      removedAt: jsonSerialization['removedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['removedAt']),
    );
  }

  static final t = WorkspaceMemberTable();

  static const db = WorkspaceMemberRepository._();

  @override
  int? id;

  int workspaceId;

  String userId;

  String role;

  DateTime createdAt;

  DateTime? removedAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [WorkspaceMember]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  WorkspaceMember copyWith({
    int? id,
    int? workspaceId,
    String? userId,
    String? role,
    DateTime? createdAt,
    DateTime? removedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WorkspaceMember',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'userId': userId,
      'role': role,
      'createdAt': createdAt.toJson(),
      if (removedAt != null) 'removedAt': removedAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WorkspaceMember',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'userId': userId,
      'role': role,
      'createdAt': createdAt.toJson(),
      if (removedAt != null) 'removedAt': removedAt?.toJson(),
    };
  }

  static WorkspaceMemberInclude include() {
    return WorkspaceMemberInclude._();
  }

  static WorkspaceMemberIncludeList includeList({
    _i1.WhereExpressionBuilder<WorkspaceMemberTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<WorkspaceMemberTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<WorkspaceMemberTable>? orderByList,
    WorkspaceMemberInclude? include,
  }) {
    return WorkspaceMemberIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WorkspaceMember.t),
      orderDescending: // ignore: deprecated_member_use_from_same_package
          orderDescending,
      orderByList: orderByList?.call(WorkspaceMember.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WorkspaceMemberImpl extends WorkspaceMember {
  _WorkspaceMemberImpl({
    int? id,
    required int workspaceId,
    required String userId,
    required String role,
    required DateTime createdAt,
    DateTime? removedAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         userId: userId,
         role: role,
         createdAt: createdAt,
         removedAt: removedAt,
       );

  /// Returns a shallow copy of this [WorkspaceMember]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  WorkspaceMember copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    String? userId,
    String? role,
    DateTime? createdAt,
    Object? removedAt = _Undefined,
  }) {
    return WorkspaceMember(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      removedAt: removedAt is DateTime? ? removedAt : this.removedAt,
    );
  }
}

class WorkspaceMemberUpdateTable extends _i1.UpdateTable<WorkspaceMemberTable> {
  WorkspaceMemberUpdateTable(super.table);

  _i1.ColumnValue<int, int> workspaceId(int value) => _i1.ColumnValue(
    table.workspaceId,
    value,
  );

  _i1.ColumnValue<String, String> userId(String value) => _i1.ColumnValue(
    table.userId,
    value,
  );

  _i1.ColumnValue<String, String> role(String value) => _i1.ColumnValue(
    table.role,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(
        table.createdAt,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> removedAt(DateTime? value) =>
      _i1.ColumnValue(
        table.removedAt,
        value,
      );
}

class WorkspaceMemberTable extends _i1.Table<int?> {
  WorkspaceMemberTable({super.tableRelation})
    : super(tableName: 'workspace_member') {
    updateTable = WorkspaceMemberUpdateTable(this);
    workspaceId = _i1.ColumnInt(
      'workspaceId',
      this,
    );
    userId = _i1.ColumnString(
      'userId',
      this,
    );
    role = _i1.ColumnString(
      'role',
      this,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
    removedAt = _i1.ColumnDateTime(
      'removedAt',
      this,
    );
  }

  late final WorkspaceMemberUpdateTable updateTable;

  late final _i1.ColumnInt workspaceId;

  late final _i1.ColumnString userId;

  late final _i1.ColumnString role;

  late final _i1.ColumnDateTime createdAt;

  late final _i1.ColumnDateTime removedAt;

  @override
  List<_i1.Column> get columns => [
    id,
    workspaceId,
    userId,
    role,
    createdAt,
    removedAt,
  ];
}

class WorkspaceMemberInclude extends _i1.IncludeObject {
  WorkspaceMemberInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => WorkspaceMember.t;
}

class WorkspaceMemberIncludeList extends _i1.IncludeList {
  WorkspaceMemberIncludeList._({
    _i1.WhereExpressionBuilder<WorkspaceMemberTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(WorkspaceMember.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => WorkspaceMember.t;
}

class WorkspaceMemberRepository {
  const WorkspaceMemberRepository._();

  /// Returns a list of [WorkspaceMember]s matching the given query parameters.
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
  Future<List<WorkspaceMember>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<WorkspaceMemberTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<WorkspaceMemberTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<WorkspaceMemberTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<WorkspaceMember>(
      where: where?.call(WorkspaceMember.t),
      orderBy: orderBy?.call(WorkspaceMember.t),
      orderByList: orderByList?.call(WorkspaceMember.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [WorkspaceMember] matching the given query parameters.
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
  Future<WorkspaceMember?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<WorkspaceMemberTable>? where,
    int? offset,
    _i1.OrderByBuilder<WorkspaceMemberTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<WorkspaceMemberTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<WorkspaceMember>(
      where: where?.call(WorkspaceMember.t),
      orderBy: orderBy?.call(WorkspaceMember.t),
      orderByList: orderByList?.call(WorkspaceMember.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [WorkspaceMember] by its [id] or null if no such row exists.
  Future<WorkspaceMember?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<WorkspaceMember>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [WorkspaceMember]s in the list and returns the inserted rows.
  ///
  /// The returned [WorkspaceMember]s will have their `id` fields set.
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
  Future<List<WorkspaceMember>> insert(
    _i1.DatabaseSession session,
    List<WorkspaceMember> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<WorkspaceMember>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [WorkspaceMember] and returns the inserted row.
  ///
  /// The returned [WorkspaceMember] will have its `id` field set.
  Future<WorkspaceMember> insertRow(
    _i1.DatabaseSession session,
    WorkspaceMember row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<WorkspaceMember>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [WorkspaceMember]s in the list and returns the resulting rows.
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
  /// The returned [WorkspaceMember]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WorkspaceMember>> upsert(
    _i1.DatabaseSession session,
    List<WorkspaceMember> rows, {
    required _i1.ColumnSelections<WorkspaceMemberTable> conflictColumns,
    _i1.ColumnSelections<WorkspaceMemberTable>? updateColumns,
    _i1.WhereExpressionBuilder<WorkspaceMemberTable>? updateWhere,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<WorkspaceMember>(
      rows,
      conflictColumns: conflictColumns(WorkspaceMember.t),
      updateColumns: updateColumns?.call(WorkspaceMember.t),
      updateWhere: updateWhere?.call(WorkspaceMember.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [WorkspaceMember] and returns the resulting row.
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
  /// The returned [WorkspaceMember] will have its `id` field set.
  Future<WorkspaceMember?> upsertRow(
    _i1.DatabaseSession session,
    WorkspaceMember row, {
    required _i1.ColumnSelections<WorkspaceMemberTable> conflictColumns,
    _i1.ColumnSelections<WorkspaceMemberTable>? updateColumns,
    _i1.WhereExpressionBuilder<WorkspaceMemberTable>? updateWhere,
    _i1.Transaction? transaction,
  }) async {
    return session.db.upsertRow<WorkspaceMember>(
      row,
      conflictColumns: conflictColumns(WorkspaceMember.t),
      updateColumns: updateColumns?.call(WorkspaceMember.t),
      updateWhere: updateWhere?.call(WorkspaceMember.t),
      transaction: transaction,
    );
  }

  /// Updates all [WorkspaceMember]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WorkspaceMember>> update(
    _i1.DatabaseSession session,
    List<WorkspaceMember> rows, {
    _i1.ColumnSelections<WorkspaceMemberTable>? columns,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<WorkspaceMember>(
      rows,
      columns: columns?.call(WorkspaceMember.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [WorkspaceMember]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<WorkspaceMember> updateRow(
    _i1.DatabaseSession session,
    WorkspaceMember row, {
    _i1.ColumnSelections<WorkspaceMemberTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<WorkspaceMember>(
      row,
      columns: columns?.call(WorkspaceMember.t),
      transaction: transaction,
    );
  }

  /// Updates a single [WorkspaceMember] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<WorkspaceMember?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<WorkspaceMemberUpdateTable>
    columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<WorkspaceMember>(
      id,
      columnValues: columnValues(WorkspaceMember.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [WorkspaceMember]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WorkspaceMember>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<WorkspaceMemberUpdateTable>
    columnValues,
    required _i1.WhereExpressionBuilder<WorkspaceMemberTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<WorkspaceMemberTable>? orderBy,
    _i1.OrderByListBuilder<WorkspaceMemberTable>? orderByList,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<WorkspaceMember>(
      columnValues: columnValues(WorkspaceMember.t.updateTable),
      where: where(WorkspaceMember.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WorkspaceMember.t),
      orderByList: orderByList?.call(WorkspaceMember.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [WorkspaceMember]s in the list and returns the deleted rows.
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
  Future<List<WorkspaceMember>> delete(
    _i1.DatabaseSession session,
    List<WorkspaceMember> rows, {
    _i1.OrderByBuilder<WorkspaceMemberTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<WorkspaceMemberTable>? orderByList,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<WorkspaceMember>(
      rows,
      orderBy: orderBy?.call(WorkspaceMember.t),
      orderByList: orderByList?.call(WorkspaceMember.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [WorkspaceMember].
  Future<WorkspaceMember> deleteRow(
    _i1.DatabaseSession session,
    WorkspaceMember row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<WorkspaceMember>(
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
  Future<List<WorkspaceMember>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<WorkspaceMemberTable> where,
    _i1.OrderByBuilder<WorkspaceMemberTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<WorkspaceMemberTable>? orderByList,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<WorkspaceMember>(
      where: where(WorkspaceMember.t),
      orderBy: orderBy?.call(WorkspaceMember.t),
      orderByList: orderByList?.call(WorkspaceMember.t),
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
    _i1.WhereExpressionBuilder<WorkspaceMemberTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<WorkspaceMember>(
      where: where?.call(WorkspaceMember.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [WorkspaceMember] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<WorkspaceMemberTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<WorkspaceMember>(
      where: where(WorkspaceMember.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
