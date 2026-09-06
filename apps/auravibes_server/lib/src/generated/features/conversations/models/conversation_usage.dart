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

abstract class ConversationUsage
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  ConversationUsage._({
    this.id,
    required this.workspaceId,
    required this.conversationId,
    required this.turnId,
    required this.inputTokens,
    required this.outputTokens,
    required this.totalTokens,
    required this.createdAt,
  });

  factory ConversationUsage({
    int? id,
    required int workspaceId,
    required int conversationId,
    required int turnId,
    required int inputTokens,
    required int outputTokens,
    required int totalTokens,
    required DateTime createdAt,
  }) = _ConversationUsageImpl;

  factory ConversationUsage.fromJson(Map<String, dynamic> jsonSerialization) {
    return ConversationUsage(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      conversationId: jsonSerialization['conversationId'] as int,
      turnId: jsonSerialization['turnId'] as int,
      inputTokens: jsonSerialization['inputTokens'] as int,
      outputTokens: jsonSerialization['outputTokens'] as int,
      totalTokens: jsonSerialization['totalTokens'] as int,
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  static final t = ConversationUsageTable();

  static const db = ConversationUsageRepository._();

  @override
  int? id;

  int workspaceId;

  int conversationId;

  int turnId;

  int inputTokens;

  int outputTokens;

  int totalTokens;

  DateTime createdAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [ConversationUsage]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ConversationUsage copyWith({
    int? id,
    int? workspaceId,
    int? conversationId,
    int? turnId,
    int? inputTokens,
    int? outputTokens,
    int? totalTokens,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ConversationUsage',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'conversationId': conversationId,
      'turnId': turnId,
      'inputTokens': inputTokens,
      'outputTokens': outputTokens,
      'totalTokens': totalTokens,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ConversationUsage',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'conversationId': conversationId,
      'turnId': turnId,
      'inputTokens': inputTokens,
      'outputTokens': outputTokens,
      'totalTokens': totalTokens,
      'createdAt': createdAt.toJson(),
    };
  }

  static ConversationUsageInclude include() {
    return ConversationUsageInclude._();
  }

  static ConversationUsageIncludeList includeList({
    _is.WhereExpressionBuilder<ConversationUsageTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ConversationUsageTable>? orderBy,
    _is.OrderByListBuilder<ConversationUsageTable>? orderByList,
    ConversationUsageInclude? include,
  }) {
    return ConversationUsageIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ConversationUsage.t),
      orderByList: orderByList?.call(ConversationUsage.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ConversationUsageImpl extends ConversationUsage {
  _ConversationUsageImpl({
    int? id,
    required int workspaceId,
    required int conversationId,
    required int turnId,
    required int inputTokens,
    required int outputTokens,
    required int totalTokens,
    required DateTime createdAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         conversationId: conversationId,
         turnId: turnId,
         inputTokens: inputTokens,
         outputTokens: outputTokens,
         totalTokens: totalTokens,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [ConversationUsage]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ConversationUsage copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    int? conversationId,
    int? turnId,
    int? inputTokens,
    int? outputTokens,
    int? totalTokens,
    DateTime? createdAt,
  }) {
    return ConversationUsage(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      conversationId: conversationId ?? this.conversationId,
      turnId: turnId ?? this.turnId,
      inputTokens: inputTokens ?? this.inputTokens,
      outputTokens: outputTokens ?? this.outputTokens,
      totalTokens: totalTokens ?? this.totalTokens,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class ConversationUsageUpdateTable
    extends _is.UpdateTable<ConversationUsageTable> {
  ConversationUsageUpdateTable(super.table);

  _is.ColumnValue<int, int> workspaceId(int value) => _is.ColumnValue(
    table.workspaceId,
    value,
  );

  _is.ColumnValue<int, int> conversationId(int value) => _is.ColumnValue(
    table.conversationId,
    value,
  );

  _is.ColumnValue<int, int> turnId(int value) => _is.ColumnValue(
    table.turnId,
    value,
  );

  _is.ColumnValue<int, int> inputTokens(int value) => _is.ColumnValue(
    table.inputTokens,
    value,
  );

  _is.ColumnValue<int, int> outputTokens(int value) => _is.ColumnValue(
    table.outputTokens,
    value,
  );

  _is.ColumnValue<int, int> totalTokens(int value) => _is.ColumnValue(
    table.totalTokens,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class ConversationUsageTable extends _is.Table<int?> {
  ConversationUsageTable({super.tableRelation})
    : super(tableName: 'conversation_usage') {
    updateTable = ConversationUsageUpdateTable(this);
    workspaceId = _is.ColumnInt(
      'workspaceId',
      this,
    );
    conversationId = _is.ColumnInt(
      'conversationId',
      this,
    );
    turnId = _is.ColumnInt(
      'turnId',
      this,
    );
    inputTokens = _is.ColumnInt(
      'inputTokens',
      this,
    );
    outputTokens = _is.ColumnInt(
      'outputTokens',
      this,
    );
    totalTokens = _is.ColumnInt(
      'totalTokens',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final ConversationUsageUpdateTable updateTable;

  late final _is.ColumnInt workspaceId;

  late final _is.ColumnInt conversationId;

  late final _is.ColumnInt turnId;

  late final _is.ColumnInt inputTokens;

  late final _is.ColumnInt outputTokens;

  late final _is.ColumnInt totalTokens;

  late final _is.ColumnDateTime createdAt;

  @override
  List<_is.Column> get columns => [
    id,
    workspaceId,
    conversationId,
    turnId,
    inputTokens,
    outputTokens,
    totalTokens,
    createdAt,
  ];
}

class ConversationUsageInclude extends _is.IncludeObject {
  ConversationUsageInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => ConversationUsage.t;
}

class ConversationUsageIncludeList extends _is.IncludeList {
  ConversationUsageIncludeList._({
    _is.WhereExpressionBuilder<ConversationUsageTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ConversationUsage.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => ConversationUsage.t;
}

class ConversationUsageRepository {
  const ConversationUsageRepository._();

  /// Returns a list of [ConversationUsage]s matching the given query parameters.
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
  Future<List<ConversationUsage>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ConversationUsageTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ConversationUsageTable>? orderBy,
    _is.OrderByListBuilder<ConversationUsageTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ConversationUsage>(
      where: where?.call(ConversationUsage.t),
      orderBy: orderBy?.call(ConversationUsage.t),
      orderByList: orderByList?.call(ConversationUsage.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [ConversationUsage] matching the given query parameters.
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
  Future<ConversationUsage?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ConversationUsageTable>? where,
    int? offset,
    _is.OrderByBuilder<ConversationUsageTable>? orderBy,
    _is.OrderByListBuilder<ConversationUsageTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ConversationUsage>(
      where: where?.call(ConversationUsage.t),
      orderBy: orderBy?.call(ConversationUsage.t),
      orderByList: orderByList?.call(ConversationUsage.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ConversationUsage] by its [id] or null if no such row exists.
  Future<ConversationUsage?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ConversationUsage>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ConversationUsage]s in the list and returns the inserted rows.
  ///
  /// The returned [ConversationUsage]s will have their `id` fields set.
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
  Future<List<ConversationUsage>> insert(
    _is.DatabaseSession session,
    List<ConversationUsage> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<ConversationUsage>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [ConversationUsage] and returns the inserted row.
  ///
  /// The returned [ConversationUsage] will have its `id` field set.
  Future<ConversationUsage> insertRow(
    _is.DatabaseSession session,
    ConversationUsage row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<ConversationUsage>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [ConversationUsage]s in the list and returns the resulting rows.
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
  /// The returned [ConversationUsage]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ConversationUsage>> upsert(
    _is.DatabaseSession session,
    List<ConversationUsage> rows, {
    required _is.ColumnSelections<ConversationUsageTable> conflictColumns,
    _is.ColumnSelections<ConversationUsageTable>? updateColumns,
    _is.WhereExpressionBuilder<ConversationUsageTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<ConversationUsage>(
      rows,
      conflictColumns: conflictColumns(ConversationUsage.t),
      updateColumns: updateColumns?.call(ConversationUsage.t),
      updateWhere: updateWhere?.call(ConversationUsage.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [ConversationUsage] and returns the resulting row.
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
  /// The returned [ConversationUsage] will have its `id` field set.
  Future<ConversationUsage?> upsertRow(
    _is.DatabaseSession session,
    ConversationUsage row, {
    required _is.ColumnSelections<ConversationUsageTable> conflictColumns,
    _is.ColumnSelections<ConversationUsageTable>? updateColumns,
    _is.WhereExpressionBuilder<ConversationUsageTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<ConversationUsage>(
      row,
      conflictColumns: conflictColumns(ConversationUsage.t),
      updateColumns: updateColumns?.call(ConversationUsage.t),
      updateWhere: updateWhere?.call(ConversationUsage.t),
      transaction: transaction,
    );
  }

  /// Updates all [ConversationUsage]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ConversationUsage>> update(
    _is.DatabaseSession session,
    List<ConversationUsage> rows, {
    _is.ColumnSelections<ConversationUsageTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<ConversationUsage>(
      rows,
      columns: columns?.call(ConversationUsage.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [ConversationUsage]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ConversationUsage> updateRow(
    _is.DatabaseSession session,
    ConversationUsage row, {
    _is.ColumnSelections<ConversationUsageTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<ConversationUsage>(
      row,
      columns: columns?.call(ConversationUsage.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ConversationUsage] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ConversationUsage?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<ConversationUsageUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<ConversationUsage>(
      id,
      columnValues: columnValues(ConversationUsage.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ConversationUsage]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ConversationUsage>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<ConversationUsageUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<ConversationUsageTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ConversationUsageTable>? orderBy,
    _is.OrderByListBuilder<ConversationUsageTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<ConversationUsage>(
      columnValues: columnValues(ConversationUsage.t.updateTable),
      where: where(ConversationUsage.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ConversationUsage.t),
      orderByList: orderByList?.call(ConversationUsage.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [ConversationUsage]s in the list and returns the deleted rows.
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
  Future<List<ConversationUsage>> delete(
    _is.DatabaseSession session,
    List<ConversationUsage> rows, {
    _is.OrderByBuilder<ConversationUsageTable>? orderBy,
    _is.OrderByListBuilder<ConversationUsageTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<ConversationUsage>(
      rows,
      orderBy: orderBy?.call(ConversationUsage.t),
      orderByList: orderByList?.call(ConversationUsage.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [ConversationUsage].
  Future<ConversationUsage> deleteRow(
    _is.DatabaseSession session,
    ConversationUsage row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ConversationUsage>(
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
  Future<List<ConversationUsage>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ConversationUsageTable> where,
    _is.OrderByBuilder<ConversationUsageTable>? orderBy,
    _is.OrderByListBuilder<ConversationUsageTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<ConversationUsage>(
      where: where(ConversationUsage.t),
      orderBy: orderBy?.call(ConversationUsage.t),
      orderByList: orderByList?.call(ConversationUsage.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ConversationUsageTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<ConversationUsage>(
      where: where?.call(ConversationUsage.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ConversationUsage] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ConversationUsageTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ConversationUsage>(
      where: where(ConversationUsage.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
