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

abstract class ConversationLabelAssignment
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  ConversationLabelAssignment._({
    this.id,
    required this.workspaceId,
    required this.labelId,
    required this.conversationId,
    required this.createdAt,
  });

  factory ConversationLabelAssignment({
    int? id,
    required int workspaceId,
    required int labelId,
    required int conversationId,
    required DateTime createdAt,
  }) = _ConversationLabelAssignmentImpl;

  factory ConversationLabelAssignment.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ConversationLabelAssignment(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      labelId: jsonSerialization['labelId'] as int,
      conversationId: jsonSerialization['conversationId'] as int,
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  static final t = ConversationLabelAssignmentTable();

  static const db = ConversationLabelAssignmentRepository._();

  @override
  int? id;

  int workspaceId;

  int labelId;

  int conversationId;

  DateTime createdAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [ConversationLabelAssignment]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ConversationLabelAssignment copyWith({
    int? id,
    int? workspaceId,
    int? labelId,
    int? conversationId,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ConversationLabelAssignment',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'labelId': labelId,
      'conversationId': conversationId,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ConversationLabelAssignment',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'labelId': labelId,
      'conversationId': conversationId,
      'createdAt': createdAt.toJson(),
    };
  }

  static ConversationLabelAssignmentInclude include() {
    return ConversationLabelAssignmentInclude._();
  }

  static ConversationLabelAssignmentIncludeList includeList({
    _is.WhereExpressionBuilder<ConversationLabelAssignmentTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ConversationLabelAssignmentTable>? orderBy,
    _is.OrderByListBuilder<ConversationLabelAssignmentTable>? orderByList,
    ConversationLabelAssignmentInclude? include,
  }) {
    return ConversationLabelAssignmentIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ConversationLabelAssignment.t),
      orderByList: orderByList?.call(ConversationLabelAssignment.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ConversationLabelAssignmentImpl extends ConversationLabelAssignment {
  _ConversationLabelAssignmentImpl({
    int? id,
    required int workspaceId,
    required int labelId,
    required int conversationId,
    required DateTime createdAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         labelId: labelId,
         conversationId: conversationId,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [ConversationLabelAssignment]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ConversationLabelAssignment copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    int? labelId,
    int? conversationId,
    DateTime? createdAt,
  }) {
    return ConversationLabelAssignment(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      labelId: labelId ?? this.labelId,
      conversationId: conversationId ?? this.conversationId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class ConversationLabelAssignmentUpdateTable
    extends _is.UpdateTable<ConversationLabelAssignmentTable> {
  ConversationLabelAssignmentUpdateTable(super.table);

  _is.ColumnValue<int, int> workspaceId(int value) => _is.ColumnValue(
    table.workspaceId,
    value,
  );

  _is.ColumnValue<int, int> labelId(int value) => _is.ColumnValue(
    table.labelId,
    value,
  );

  _is.ColumnValue<int, int> conversationId(int value) => _is.ColumnValue(
    table.conversationId,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class ConversationLabelAssignmentTable extends _is.Table<int?> {
  ConversationLabelAssignmentTable({super.tableRelation})
    : super(tableName: 'conversation_label_assignment') {
    updateTable = ConversationLabelAssignmentUpdateTable(this);
    workspaceId = _is.ColumnInt(
      'workspaceId',
      this,
    );
    labelId = _is.ColumnInt(
      'labelId',
      this,
    );
    conversationId = _is.ColumnInt(
      'conversationId',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final ConversationLabelAssignmentUpdateTable updateTable;

  late final _is.ColumnInt workspaceId;

  late final _is.ColumnInt labelId;

  late final _is.ColumnInt conversationId;

  late final _is.ColumnDateTime createdAt;

  @override
  List<_is.Column> get columns => [
    id,
    workspaceId,
    labelId,
    conversationId,
    createdAt,
  ];
}

class ConversationLabelAssignmentInclude extends _is.IncludeObject {
  ConversationLabelAssignmentInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => ConversationLabelAssignment.t;
}

class ConversationLabelAssignmentIncludeList extends _is.IncludeList {
  ConversationLabelAssignmentIncludeList._({
    _is.WhereExpressionBuilder<ConversationLabelAssignmentTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ConversationLabelAssignment.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => ConversationLabelAssignment.t;
}

class ConversationLabelAssignmentRepository {
  const ConversationLabelAssignmentRepository._();

  /// Returns a list of [ConversationLabelAssignment]s matching the given query parameters.
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
  Future<List<ConversationLabelAssignment>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ConversationLabelAssignmentTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ConversationLabelAssignmentTable>? orderBy,
    _is.OrderByListBuilder<ConversationLabelAssignmentTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ConversationLabelAssignment>(
      where: where?.call(ConversationLabelAssignment.t),
      orderBy: orderBy?.call(ConversationLabelAssignment.t),
      orderByList: orderByList?.call(ConversationLabelAssignment.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [ConversationLabelAssignment] matching the given query parameters.
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
  Future<ConversationLabelAssignment?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ConversationLabelAssignmentTable>? where,
    int? offset,
    _is.OrderByBuilder<ConversationLabelAssignmentTable>? orderBy,
    _is.OrderByListBuilder<ConversationLabelAssignmentTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ConversationLabelAssignment>(
      where: where?.call(ConversationLabelAssignment.t),
      orderBy: orderBy?.call(ConversationLabelAssignment.t),
      orderByList: orderByList?.call(ConversationLabelAssignment.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ConversationLabelAssignment] by its [id] or null if no such row exists.
  Future<ConversationLabelAssignment?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ConversationLabelAssignment>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ConversationLabelAssignment]s in the list and returns the inserted rows.
  ///
  /// The returned [ConversationLabelAssignment]s will have their `id` fields set.
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
  Future<List<ConversationLabelAssignment>> insert(
    _is.DatabaseSession session,
    List<ConversationLabelAssignment> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<ConversationLabelAssignment>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [ConversationLabelAssignment] and returns the inserted row.
  ///
  /// The returned [ConversationLabelAssignment] will have its `id` field set.
  Future<ConversationLabelAssignment> insertRow(
    _is.DatabaseSession session,
    ConversationLabelAssignment row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<ConversationLabelAssignment>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [ConversationLabelAssignment]s in the list and returns the resulting rows.
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
  /// The returned [ConversationLabelAssignment]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ConversationLabelAssignment>> upsert(
    _is.DatabaseSession session,
    List<ConversationLabelAssignment> rows, {
    required _is.ColumnSelections<ConversationLabelAssignmentTable>
    conflictColumns,
    _is.ColumnSelections<ConversationLabelAssignmentTable>? updateColumns,
    _is.WhereExpressionBuilder<ConversationLabelAssignmentTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<ConversationLabelAssignment>(
      rows,
      conflictColumns: conflictColumns(ConversationLabelAssignment.t),
      updateColumns: updateColumns?.call(ConversationLabelAssignment.t),
      updateWhere: updateWhere?.call(ConversationLabelAssignment.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [ConversationLabelAssignment] and returns the resulting row.
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
  /// The returned [ConversationLabelAssignment] will have its `id` field set.
  Future<ConversationLabelAssignment?> upsertRow(
    _is.DatabaseSession session,
    ConversationLabelAssignment row, {
    required _is.ColumnSelections<ConversationLabelAssignmentTable>
    conflictColumns,
    _is.ColumnSelections<ConversationLabelAssignmentTable>? updateColumns,
    _is.WhereExpressionBuilder<ConversationLabelAssignmentTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<ConversationLabelAssignment>(
      row,
      conflictColumns: conflictColumns(ConversationLabelAssignment.t),
      updateColumns: updateColumns?.call(ConversationLabelAssignment.t),
      updateWhere: updateWhere?.call(ConversationLabelAssignment.t),
      transaction: transaction,
    );
  }

  /// Updates all [ConversationLabelAssignment]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ConversationLabelAssignment>> update(
    _is.DatabaseSession session,
    List<ConversationLabelAssignment> rows, {
    _is.ColumnSelections<ConversationLabelAssignmentTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<ConversationLabelAssignment>(
      rows,
      columns: columns?.call(ConversationLabelAssignment.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [ConversationLabelAssignment]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ConversationLabelAssignment> updateRow(
    _is.DatabaseSession session,
    ConversationLabelAssignment row, {
    _is.ColumnSelections<ConversationLabelAssignmentTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<ConversationLabelAssignment>(
      row,
      columns: columns?.call(ConversationLabelAssignment.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ConversationLabelAssignment] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ConversationLabelAssignment?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<ConversationLabelAssignmentUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<ConversationLabelAssignment>(
      id,
      columnValues: columnValues(ConversationLabelAssignment.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ConversationLabelAssignment]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ConversationLabelAssignment>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<ConversationLabelAssignmentUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<ConversationLabelAssignmentTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ConversationLabelAssignmentTable>? orderBy,
    _is.OrderByListBuilder<ConversationLabelAssignmentTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<ConversationLabelAssignment>(
      columnValues: columnValues(ConversationLabelAssignment.t.updateTable),
      where: where(ConversationLabelAssignment.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ConversationLabelAssignment.t),
      orderByList: orderByList?.call(ConversationLabelAssignment.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [ConversationLabelAssignment]s in the list and returns the deleted rows.
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
  Future<List<ConversationLabelAssignment>> delete(
    _is.DatabaseSession session,
    List<ConversationLabelAssignment> rows, {
    _is.OrderByBuilder<ConversationLabelAssignmentTable>? orderBy,
    _is.OrderByListBuilder<ConversationLabelAssignmentTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<ConversationLabelAssignment>(
      rows,
      orderBy: orderBy?.call(ConversationLabelAssignment.t),
      orderByList: orderByList?.call(ConversationLabelAssignment.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [ConversationLabelAssignment].
  Future<ConversationLabelAssignment> deleteRow(
    _is.DatabaseSession session,
    ConversationLabelAssignment row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ConversationLabelAssignment>(
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
  Future<List<ConversationLabelAssignment>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ConversationLabelAssignmentTable> where,
    _is.OrderByBuilder<ConversationLabelAssignmentTable>? orderBy,
    _is.OrderByListBuilder<ConversationLabelAssignmentTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<ConversationLabelAssignment>(
      where: where(ConversationLabelAssignment.t),
      orderBy: orderBy?.call(ConversationLabelAssignment.t),
      orderByList: orderByList?.call(ConversationLabelAssignment.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ConversationLabelAssignmentTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<ConversationLabelAssignment>(
      where: where?.call(ConversationLabelAssignment.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ConversationLabelAssignment] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ConversationLabelAssignmentTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ConversationLabelAssignment>(
      where: where(ConversationLabelAssignment.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
