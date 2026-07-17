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

abstract class ConversationUsage
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
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
      createdAt: _i1.DateTimeJsonExtension.fromJson(
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
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [ConversationUsage]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
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
    _i1.WhereExpressionBuilder<ConversationUsageTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ConversationUsageTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<ConversationUsageTable>? orderByList,
    ConversationUsageInclude? include,
  }) {
    return ConversationUsageIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ConversationUsage.t),
      orderDescending: // ignore: deprecated_member_use_from_same_package
          orderDescending,
      orderByList: orderByList?.call(ConversationUsage.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
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
  @_i1.useResult
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
    extends _i1.UpdateTable<ConversationUsageTable> {
  ConversationUsageUpdateTable(super.table);

  _i1.ColumnValue<int, int> workspaceId(int value) => _i1.ColumnValue(
    table.workspaceId,
    value,
  );

  _i1.ColumnValue<int, int> conversationId(int value) => _i1.ColumnValue(
    table.conversationId,
    value,
  );

  _i1.ColumnValue<int, int> turnId(int value) => _i1.ColumnValue(
    table.turnId,
    value,
  );

  _i1.ColumnValue<int, int> inputTokens(int value) => _i1.ColumnValue(
    table.inputTokens,
    value,
  );

  _i1.ColumnValue<int, int> outputTokens(int value) => _i1.ColumnValue(
    table.outputTokens,
    value,
  );

  _i1.ColumnValue<int, int> totalTokens(int value) => _i1.ColumnValue(
    table.totalTokens,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(
        table.createdAt,
        value,
      );
}

class ConversationUsageTable extends _i1.Table<int?> {
  ConversationUsageTable({super.tableRelation})
    : super(tableName: 'conversation_usage') {
    updateTable = ConversationUsageUpdateTable(this);
    workspaceId = _i1.ColumnInt(
      'workspaceId',
      this,
    );
    conversationId = _i1.ColumnInt(
      'conversationId',
      this,
    );
    turnId = _i1.ColumnInt(
      'turnId',
      this,
    );
    inputTokens = _i1.ColumnInt(
      'inputTokens',
      this,
    );
    outputTokens = _i1.ColumnInt(
      'outputTokens',
      this,
    );
    totalTokens = _i1.ColumnInt(
      'totalTokens',
      this,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final ConversationUsageUpdateTable updateTable;

  late final _i1.ColumnInt workspaceId;

  late final _i1.ColumnInt conversationId;

  late final _i1.ColumnInt turnId;

  late final _i1.ColumnInt inputTokens;

  late final _i1.ColumnInt outputTokens;

  late final _i1.ColumnInt totalTokens;

  late final _i1.ColumnDateTime createdAt;

  @override
  List<_i1.Column> get columns => [
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

class ConversationUsageInclude extends _i1.IncludeObject {
  ConversationUsageInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => ConversationUsage.t;
}

class ConversationUsageIncludeList extends _i1.IncludeList {
  ConversationUsageIncludeList._({
    _i1.WhereExpressionBuilder<ConversationUsageTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ConversationUsage.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => ConversationUsage.t;
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
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<ConversationUsageTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ConversationUsageTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<ConversationUsageTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ConversationUsage>(
      where: where?.call(ConversationUsage.t),
      orderBy: orderBy?.call(ConversationUsage.t),
      orderByList: orderByList?.call(ConversationUsage.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
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
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<ConversationUsageTable>? where,
    int? offset,
    _i1.OrderByBuilder<ConversationUsageTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<ConversationUsageTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ConversationUsage>(
      where: where?.call(ConversationUsage.t),
      orderBy: orderBy?.call(ConversationUsage.t),
      orderByList: orderByList?.call(ConversationUsage.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ConversationUsage] by its [id] or null if no such row exists.
  Future<ConversationUsage?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
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
    _i1.DatabaseSession session,
    List<ConversationUsage> rows, {
    _i1.Transaction? transaction,
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
    _i1.DatabaseSession session,
    ConversationUsage row, {
    _i1.Transaction? transaction,
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
    _i1.DatabaseSession session,
    List<ConversationUsage> rows, {
    required _i1.ColumnSelections<ConversationUsageTable> conflictColumns,
    _i1.ColumnSelections<ConversationUsageTable>? updateColumns,
    _i1.WhereExpressionBuilder<ConversationUsageTable>? updateWhere,
    _i1.Transaction? transaction,
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
    _i1.DatabaseSession session,
    ConversationUsage row, {
    required _i1.ColumnSelections<ConversationUsageTable> conflictColumns,
    _i1.ColumnSelections<ConversationUsageTable>? updateColumns,
    _i1.WhereExpressionBuilder<ConversationUsageTable>? updateWhere,
    _i1.Transaction? transaction,
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
    _i1.DatabaseSession session,
    List<ConversationUsage> rows, {
    _i1.ColumnSelections<ConversationUsageTable>? columns,
    _i1.Transaction? transaction,
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
    _i1.DatabaseSession session,
    ConversationUsage row, {
    _i1.ColumnSelections<ConversationUsageTable>? columns,
    _i1.Transaction? transaction,
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
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<ConversationUsageUpdateTable>
    columnValues,
    _i1.Transaction? transaction,
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
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<ConversationUsageUpdateTable>
    columnValues,
    required _i1.WhereExpressionBuilder<ConversationUsageTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ConversationUsageTable>? orderBy,
    _i1.OrderByListBuilder<ConversationUsageTable>? orderByList,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<ConversationUsage>(
      columnValues: columnValues(ConversationUsage.t.updateTable),
      where: where(ConversationUsage.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ConversationUsage.t),
      orderByList: orderByList?.call(ConversationUsage.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
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
    _i1.DatabaseSession session,
    List<ConversationUsage> rows, {
    _i1.OrderByBuilder<ConversationUsageTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<ConversationUsageTable>? orderByList,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<ConversationUsage>(
      rows,
      orderBy: orderBy?.call(ConversationUsage.t),
      orderByList: orderByList?.call(ConversationUsage.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [ConversationUsage].
  Future<ConversationUsage> deleteRow(
    _i1.DatabaseSession session,
    ConversationUsage row, {
    _i1.Transaction? transaction,
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
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<ConversationUsageTable> where,
    _i1.OrderByBuilder<ConversationUsageTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<ConversationUsageTable>? orderByList,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<ConversationUsage>(
      where: where(ConversationUsage.t),
      orderBy: orderBy?.call(ConversationUsage.t),
      orderByList: orderByList?.call(ConversationUsage.t),
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
    _i1.WhereExpressionBuilder<ConversationUsageTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<ConversationUsage>(
      where: where?.call(ConversationUsage.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ConversationUsage] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<ConversationUsageTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ConversationUsage>(
      where: where(ConversationUsage.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
