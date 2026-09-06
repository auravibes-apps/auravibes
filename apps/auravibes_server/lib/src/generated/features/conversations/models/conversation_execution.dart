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

abstract class ConversationExecution
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  ConversationExecution._({
    this.id,
    required this.workspaceId,
    required this.conversationId,
    required this.stableId,
    required this.status,
    required this.settingsJson,
    required this.claimedMessageIdsJson,
    this.assistantMessageId,
    required this.attempt,
    required this.createdByUserId,
    required this.createdAt,
    required this.updatedAt,
    this.terminalAt,
  });

  factory ConversationExecution({
    int? id,
    required int workspaceId,
    required int conversationId,
    required String stableId,
    required String status,
    required String settingsJson,
    required String claimedMessageIdsJson,
    int? assistantMessageId,
    required int attempt,
    required String createdByUserId,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? terminalAt,
  }) = _ConversationExecutionImpl;

  factory ConversationExecution.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ConversationExecution(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      conversationId: jsonSerialization['conversationId'] as int,
      stableId: jsonSerialization['stableId'] as String,
      status: jsonSerialization['status'] as String,
      settingsJson: jsonSerialization['settingsJson'] as String,
      claimedMessageIdsJson:
          jsonSerialization['claimedMessageIdsJson'] as String,
      assistantMessageId: jsonSerialization['assistantMessageId'] as int?,
      attempt: jsonSerialization['attempt'] as int,
      createdByUserId: jsonSerialization['createdByUserId'] as String,
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
      terminalAt: jsonSerialization['terminalAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['terminalAt']),
    );
  }

  static final t = ConversationExecutionTable();

  static const db = ConversationExecutionRepository._();

  @override
  int? id;

  int workspaceId;

  int conversationId;

  String stableId;

  String status;

  String settingsJson;

  String claimedMessageIdsJson;

  int? assistantMessageId;

  int attempt;

  String createdByUserId;

  DateTime createdAt;

  DateTime updatedAt;

  DateTime? terminalAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [ConversationExecution]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ConversationExecution copyWith({
    int? id,
    int? workspaceId,
    int? conversationId,
    String? stableId,
    String? status,
    String? settingsJson,
    String? claimedMessageIdsJson,
    int? assistantMessageId,
    int? attempt,
    String? createdByUserId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? terminalAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ConversationExecution',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'conversationId': conversationId,
      'stableId': stableId,
      'status': status,
      'settingsJson': settingsJson,
      'claimedMessageIdsJson': claimedMessageIdsJson,
      if (assistantMessageId != null) 'assistantMessageId': assistantMessageId,
      'attempt': attempt,
      'createdByUserId': createdByUserId,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      if (terminalAt != null) 'terminalAt': terminalAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ConversationExecution',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'conversationId': conversationId,
      'stableId': stableId,
      'status': status,
      'settingsJson': settingsJson,
      'claimedMessageIdsJson': claimedMessageIdsJson,
      if (assistantMessageId != null) 'assistantMessageId': assistantMessageId,
      'attempt': attempt,
      'createdByUserId': createdByUserId,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      if (terminalAt != null) 'terminalAt': terminalAt?.toJson(),
    };
  }

  static ConversationExecutionInclude include() {
    return ConversationExecutionInclude._();
  }

  static ConversationExecutionIncludeList includeList({
    _is.WhereExpressionBuilder<ConversationExecutionTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ConversationExecutionTable>? orderBy,
    _is.OrderByListBuilder<ConversationExecutionTable>? orderByList,
    ConversationExecutionInclude? include,
  }) {
    return ConversationExecutionIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ConversationExecution.t),
      orderByList: orderByList?.call(ConversationExecution.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ConversationExecutionImpl extends ConversationExecution {
  _ConversationExecutionImpl({
    int? id,
    required int workspaceId,
    required int conversationId,
    required String stableId,
    required String status,
    required String settingsJson,
    required String claimedMessageIdsJson,
    int? assistantMessageId,
    required int attempt,
    required String createdByUserId,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? terminalAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         conversationId: conversationId,
         stableId: stableId,
         status: status,
         settingsJson: settingsJson,
         claimedMessageIdsJson: claimedMessageIdsJson,
         assistantMessageId: assistantMessageId,
         attempt: attempt,
         createdByUserId: createdByUserId,
         createdAt: createdAt,
         updatedAt: updatedAt,
         terminalAt: terminalAt,
       );

  /// Returns a shallow copy of this [ConversationExecution]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ConversationExecution copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    int? conversationId,
    String? stableId,
    String? status,
    String? settingsJson,
    String? claimedMessageIdsJson,
    Object? assistantMessageId = _Undefined,
    int? attempt,
    String? createdByUserId,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? terminalAt = _Undefined,
  }) {
    return ConversationExecution(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      conversationId: conversationId ?? this.conversationId,
      stableId: stableId ?? this.stableId,
      status: status ?? this.status,
      settingsJson: settingsJson ?? this.settingsJson,
      claimedMessageIdsJson:
          claimedMessageIdsJson ?? this.claimedMessageIdsJson,
      assistantMessageId: assistantMessageId is int?
          ? assistantMessageId
          : this.assistantMessageId,
      attempt: attempt ?? this.attempt,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      terminalAt: terminalAt is DateTime? ? terminalAt : this.terminalAt,
    );
  }
}

class ConversationExecutionUpdateTable
    extends _is.UpdateTable<ConversationExecutionTable> {
  ConversationExecutionUpdateTable(super.table);

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

  _is.ColumnValue<String, String> status(String value) => _is.ColumnValue(
    table.status,
    value,
  );

  _is.ColumnValue<String, String> settingsJson(String value) => _is.ColumnValue(
    table.settingsJson,
    value,
  );

  _is.ColumnValue<String, String> claimedMessageIdsJson(String value) =>
      _is.ColumnValue(
        table.claimedMessageIdsJson,
        value,
      );

  _is.ColumnValue<int, int> assistantMessageId(int? value) => _is.ColumnValue(
    table.assistantMessageId,
    value,
  );

  _is.ColumnValue<int, int> attempt(int value) => _is.ColumnValue(
    table.attempt,
    value,
  );

  _is.ColumnValue<String, String> createdByUserId(String value) =>
      _is.ColumnValue(
        table.createdByUserId,
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

  _is.ColumnValue<DateTime, DateTime> terminalAt(DateTime? value) =>
      _is.ColumnValue(
        table.terminalAt,
        value,
      );
}

class ConversationExecutionTable extends _is.Table<int?> {
  ConversationExecutionTable({super.tableRelation})
    : super(tableName: 'conversation_execution') {
    updateTable = ConversationExecutionUpdateTable(this);
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
    status = _is.ColumnString(
      'status',
      this,
    );
    settingsJson = _is.ColumnString(
      'settingsJson',
      this,
    );
    claimedMessageIdsJson = _is.ColumnString(
      'claimedMessageIdsJson',
      this,
    );
    assistantMessageId = _is.ColumnInt(
      'assistantMessageId',
      this,
    );
    attempt = _is.ColumnInt(
      'attempt',
      this,
    );
    createdByUserId = _is.ColumnString(
      'createdByUserId',
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
    terminalAt = _is.ColumnDateTime(
      'terminalAt',
      this,
    );
  }

  late final ConversationExecutionUpdateTable updateTable;

  late final _is.ColumnInt workspaceId;

  late final _is.ColumnInt conversationId;

  late final _is.ColumnString stableId;

  late final _is.ColumnString status;

  late final _is.ColumnString settingsJson;

  late final _is.ColumnString claimedMessageIdsJson;

  late final _is.ColumnInt assistantMessageId;

  late final _is.ColumnInt attempt;

  late final _is.ColumnString createdByUserId;

  late final _is.ColumnDateTime createdAt;

  late final _is.ColumnDateTime updatedAt;

  late final _is.ColumnDateTime terminalAt;

  @override
  List<_is.Column> get columns => [
    id,
    workspaceId,
    conversationId,
    stableId,
    status,
    settingsJson,
    claimedMessageIdsJson,
    assistantMessageId,
    attempt,
    createdByUserId,
    createdAt,
    updatedAt,
    terminalAt,
  ];
}

class ConversationExecutionInclude extends _is.IncludeObject {
  ConversationExecutionInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => ConversationExecution.t;
}

class ConversationExecutionIncludeList extends _is.IncludeList {
  ConversationExecutionIncludeList._({
    _is.WhereExpressionBuilder<ConversationExecutionTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ConversationExecution.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => ConversationExecution.t;
}

class ConversationExecutionRepository {
  const ConversationExecutionRepository._();

  /// Returns a list of [ConversationExecution]s matching the given query parameters.
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
  Future<List<ConversationExecution>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ConversationExecutionTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ConversationExecutionTable>? orderBy,
    _is.OrderByListBuilder<ConversationExecutionTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ConversationExecution>(
      where: where?.call(ConversationExecution.t),
      orderBy: orderBy?.call(ConversationExecution.t),
      orderByList: orderByList?.call(ConversationExecution.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [ConversationExecution] matching the given query parameters.
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
  Future<ConversationExecution?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ConversationExecutionTable>? where,
    int? offset,
    _is.OrderByBuilder<ConversationExecutionTable>? orderBy,
    _is.OrderByListBuilder<ConversationExecutionTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ConversationExecution>(
      where: where?.call(ConversationExecution.t),
      orderBy: orderBy?.call(ConversationExecution.t),
      orderByList: orderByList?.call(ConversationExecution.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ConversationExecution] by its [id] or null if no such row exists.
  Future<ConversationExecution?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ConversationExecution>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ConversationExecution]s in the list and returns the inserted rows.
  ///
  /// The returned [ConversationExecution]s will have their `id` fields set.
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
  Future<List<ConversationExecution>> insert(
    _is.DatabaseSession session,
    List<ConversationExecution> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<ConversationExecution>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [ConversationExecution] and returns the inserted row.
  ///
  /// The returned [ConversationExecution] will have its `id` field set.
  Future<ConversationExecution> insertRow(
    _is.DatabaseSession session,
    ConversationExecution row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<ConversationExecution>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [ConversationExecution]s in the list and returns the resulting rows.
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
  /// The returned [ConversationExecution]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ConversationExecution>> upsert(
    _is.DatabaseSession session,
    List<ConversationExecution> rows, {
    required _is.ColumnSelections<ConversationExecutionTable> conflictColumns,
    _is.ColumnSelections<ConversationExecutionTable>? updateColumns,
    _is.WhereExpressionBuilder<ConversationExecutionTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<ConversationExecution>(
      rows,
      conflictColumns: conflictColumns(ConversationExecution.t),
      updateColumns: updateColumns?.call(ConversationExecution.t),
      updateWhere: updateWhere?.call(ConversationExecution.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [ConversationExecution] and returns the resulting row.
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
  /// The returned [ConversationExecution] will have its `id` field set.
  Future<ConversationExecution?> upsertRow(
    _is.DatabaseSession session,
    ConversationExecution row, {
    required _is.ColumnSelections<ConversationExecutionTable> conflictColumns,
    _is.ColumnSelections<ConversationExecutionTable>? updateColumns,
    _is.WhereExpressionBuilder<ConversationExecutionTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<ConversationExecution>(
      row,
      conflictColumns: conflictColumns(ConversationExecution.t),
      updateColumns: updateColumns?.call(ConversationExecution.t),
      updateWhere: updateWhere?.call(ConversationExecution.t),
      transaction: transaction,
    );
  }

  /// Updates all [ConversationExecution]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ConversationExecution>> update(
    _is.DatabaseSession session,
    List<ConversationExecution> rows, {
    _is.ColumnSelections<ConversationExecutionTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<ConversationExecution>(
      rows,
      columns: columns?.call(ConversationExecution.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [ConversationExecution]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ConversationExecution> updateRow(
    _is.DatabaseSession session,
    ConversationExecution row, {
    _is.ColumnSelections<ConversationExecutionTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<ConversationExecution>(
      row,
      columns: columns?.call(ConversationExecution.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ConversationExecution] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ConversationExecution?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<ConversationExecutionUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<ConversationExecution>(
      id,
      columnValues: columnValues(ConversationExecution.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ConversationExecution]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ConversationExecution>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<ConversationExecutionUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<ConversationExecutionTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ConversationExecutionTable>? orderBy,
    _is.OrderByListBuilder<ConversationExecutionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<ConversationExecution>(
      columnValues: columnValues(ConversationExecution.t.updateTable),
      where: where(ConversationExecution.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ConversationExecution.t),
      orderByList: orderByList?.call(ConversationExecution.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [ConversationExecution]s in the list and returns the deleted rows.
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
  Future<List<ConversationExecution>> delete(
    _is.DatabaseSession session,
    List<ConversationExecution> rows, {
    _is.OrderByBuilder<ConversationExecutionTable>? orderBy,
    _is.OrderByListBuilder<ConversationExecutionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<ConversationExecution>(
      rows,
      orderBy: orderBy?.call(ConversationExecution.t),
      orderByList: orderByList?.call(ConversationExecution.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [ConversationExecution].
  Future<ConversationExecution> deleteRow(
    _is.DatabaseSession session,
    ConversationExecution row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ConversationExecution>(
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
  Future<List<ConversationExecution>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ConversationExecutionTable> where,
    _is.OrderByBuilder<ConversationExecutionTable>? orderBy,
    _is.OrderByListBuilder<ConversationExecutionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<ConversationExecution>(
      where: where(ConversationExecution.t),
      orderBy: orderBy?.call(ConversationExecution.t),
      orderByList: orderByList?.call(ConversationExecution.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ConversationExecutionTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<ConversationExecution>(
      where: where?.call(ConversationExecution.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ConversationExecution] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ConversationExecutionTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ConversationExecution>(
      where: where(ConversationExecution.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
