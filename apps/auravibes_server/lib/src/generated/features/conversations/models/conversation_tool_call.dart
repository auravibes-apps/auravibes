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

abstract class ConversationToolCall
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  ConversationToolCall._({
    this.id,
    required this.workspaceId,
    required this.conversationId,
    required this.turnId,
    required this.messageId,
    required this.stableId,
    required this.name,
    required this.argumentsJson,
    required this.argumentsDigest,
    required this.status,
    this.decision,
    this.decisionByUserId,
    this.decisionAt,
    this.resultJson,
    required this.revision,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ConversationToolCall({
    int? id,
    required int workspaceId,
    required int conversationId,
    required int turnId,
    required int messageId,
    required String stableId,
    required String name,
    required String argumentsJson,
    required String argumentsDigest,
    required String status,
    String? decision,
    String? decisionByUserId,
    DateTime? decisionAt,
    String? resultJson,
    required int revision,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ConversationToolCallImpl;

  factory ConversationToolCall.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ConversationToolCall(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      conversationId: jsonSerialization['conversationId'] as int,
      turnId: jsonSerialization['turnId'] as int,
      messageId: jsonSerialization['messageId'] as int,
      stableId: jsonSerialization['stableId'] as String,
      name: jsonSerialization['name'] as String,
      argumentsJson: jsonSerialization['argumentsJson'] as String,
      argumentsDigest: jsonSerialization['argumentsDigest'] as String,
      status: jsonSerialization['status'] as String,
      decision: jsonSerialization['decision'] as String?,
      decisionByUserId: jsonSerialization['decisionByUserId'] as String?,
      decisionAt: jsonSerialization['decisionAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['decisionAt']),
      resultJson: jsonSerialization['resultJson'] as String?,
      revision: jsonSerialization['revision'] as int,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  static final t = ConversationToolCallTable();

  static const db = ConversationToolCallRepository._();

  @override
  int? id;

  int workspaceId;

  int conversationId;

  int turnId;

  int messageId;

  String stableId;

  String name;

  String argumentsJson;

  String argumentsDigest;

  String status;

  String? decision;

  String? decisionByUserId;

  DateTime? decisionAt;

  String? resultJson;

  int revision;

  DateTime createdAt;

  DateTime updatedAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [ConversationToolCall]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ConversationToolCall copyWith({
    int? id,
    int? workspaceId,
    int? conversationId,
    int? turnId,
    int? messageId,
    String? stableId,
    String? name,
    String? argumentsJson,
    String? argumentsDigest,
    String? status,
    String? decision,
    String? decisionByUserId,
    DateTime? decisionAt,
    String? resultJson,
    int? revision,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ConversationToolCall',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'conversationId': conversationId,
      'turnId': turnId,
      'messageId': messageId,
      'stableId': stableId,
      'name': name,
      'argumentsJson': argumentsJson,
      'argumentsDigest': argumentsDigest,
      'status': status,
      if (decision != null) 'decision': decision,
      if (decisionByUserId != null) 'decisionByUserId': decisionByUserId,
      if (decisionAt != null) 'decisionAt': decisionAt?.toJson(),
      if (resultJson != null) 'resultJson': resultJson,
      'revision': revision,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ConversationToolCall',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'conversationId': conversationId,
      'turnId': turnId,
      'messageId': messageId,
      'stableId': stableId,
      'name': name,
      'argumentsJson': argumentsJson,
      'argumentsDigest': argumentsDigest,
      'status': status,
      if (decision != null) 'decision': decision,
      if (decisionByUserId != null) 'decisionByUserId': decisionByUserId,
      if (decisionAt != null) 'decisionAt': decisionAt?.toJson(),
      if (resultJson != null) 'resultJson': resultJson,
      'revision': revision,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  static ConversationToolCallInclude include() {
    return ConversationToolCallInclude._();
  }

  static ConversationToolCallIncludeList includeList({
    _i1.WhereExpressionBuilder<ConversationToolCallTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ConversationToolCallTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<ConversationToolCallTable>? orderByList,
    ConversationToolCallInclude? include,
  }) {
    return ConversationToolCallIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ConversationToolCall.t),
      orderDescending: // ignore: deprecated_member_use_from_same_package
          orderDescending,
      orderByList: orderByList?.call(ConversationToolCall.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ConversationToolCallImpl extends ConversationToolCall {
  _ConversationToolCallImpl({
    int? id,
    required int workspaceId,
    required int conversationId,
    required int turnId,
    required int messageId,
    required String stableId,
    required String name,
    required String argumentsJson,
    required String argumentsDigest,
    required String status,
    String? decision,
    String? decisionByUserId,
    DateTime? decisionAt,
    String? resultJson,
    required int revision,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         conversationId: conversationId,
         turnId: turnId,
         messageId: messageId,
         stableId: stableId,
         name: name,
         argumentsJson: argumentsJson,
         argumentsDigest: argumentsDigest,
         status: status,
         decision: decision,
         decisionByUserId: decisionByUserId,
         decisionAt: decisionAt,
         resultJson: resultJson,
         revision: revision,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [ConversationToolCall]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ConversationToolCall copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    int? conversationId,
    int? turnId,
    int? messageId,
    String? stableId,
    String? name,
    String? argumentsJson,
    String? argumentsDigest,
    String? status,
    Object? decision = _Undefined,
    Object? decisionByUserId = _Undefined,
    Object? decisionAt = _Undefined,
    Object? resultJson = _Undefined,
    int? revision,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ConversationToolCall(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      conversationId: conversationId ?? this.conversationId,
      turnId: turnId ?? this.turnId,
      messageId: messageId ?? this.messageId,
      stableId: stableId ?? this.stableId,
      name: name ?? this.name,
      argumentsJson: argumentsJson ?? this.argumentsJson,
      argumentsDigest: argumentsDigest ?? this.argumentsDigest,
      status: status ?? this.status,
      decision: decision is String? ? decision : this.decision,
      decisionByUserId: decisionByUserId is String?
          ? decisionByUserId
          : this.decisionByUserId,
      decisionAt: decisionAt is DateTime? ? decisionAt : this.decisionAt,
      resultJson: resultJson is String? ? resultJson : this.resultJson,
      revision: revision ?? this.revision,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ConversationToolCallUpdateTable
    extends _i1.UpdateTable<ConversationToolCallTable> {
  ConversationToolCallUpdateTable(super.table);

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

  _i1.ColumnValue<int, int> messageId(int value) => _i1.ColumnValue(
    table.messageId,
    value,
  );

  _i1.ColumnValue<String, String> stableId(String value) => _i1.ColumnValue(
    table.stableId,
    value,
  );

  _i1.ColumnValue<String, String> name(String value) => _i1.ColumnValue(
    table.name,
    value,
  );

  _i1.ColumnValue<String, String> argumentsJson(String value) =>
      _i1.ColumnValue(
        table.argumentsJson,
        value,
      );

  _i1.ColumnValue<String, String> argumentsDigest(String value) =>
      _i1.ColumnValue(
        table.argumentsDigest,
        value,
      );

  _i1.ColumnValue<String, String> status(String value) => _i1.ColumnValue(
    table.status,
    value,
  );

  _i1.ColumnValue<String, String> decision(String? value) => _i1.ColumnValue(
    table.decision,
    value,
  );

  _i1.ColumnValue<String, String> decisionByUserId(String? value) =>
      _i1.ColumnValue(
        table.decisionByUserId,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> decisionAt(DateTime? value) =>
      _i1.ColumnValue(
        table.decisionAt,
        value,
      );

  _i1.ColumnValue<String, String> resultJson(String? value) => _i1.ColumnValue(
    table.resultJson,
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
}

class ConversationToolCallTable extends _i1.Table<int?> {
  ConversationToolCallTable({super.tableRelation})
    : super(tableName: 'conversation_tool_call') {
    updateTable = ConversationToolCallUpdateTable(this);
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
    messageId = _i1.ColumnInt(
      'messageId',
      this,
    );
    stableId = _i1.ColumnString(
      'stableId',
      this,
    );
    name = _i1.ColumnString(
      'name',
      this,
    );
    argumentsJson = _i1.ColumnString(
      'argumentsJson',
      this,
    );
    argumentsDigest = _i1.ColumnString(
      'argumentsDigest',
      this,
    );
    status = _i1.ColumnString(
      'status',
      this,
    );
    decision = _i1.ColumnString(
      'decision',
      this,
    );
    decisionByUserId = _i1.ColumnString(
      'decisionByUserId',
      this,
    );
    decisionAt = _i1.ColumnDateTime(
      'decisionAt',
      this,
    );
    resultJson = _i1.ColumnString(
      'resultJson',
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
  }

  late final ConversationToolCallUpdateTable updateTable;

  late final _i1.ColumnInt workspaceId;

  late final _i1.ColumnInt conversationId;

  late final _i1.ColumnInt turnId;

  late final _i1.ColumnInt messageId;

  late final _i1.ColumnString stableId;

  late final _i1.ColumnString name;

  late final _i1.ColumnString argumentsJson;

  late final _i1.ColumnString argumentsDigest;

  late final _i1.ColumnString status;

  late final _i1.ColumnString decision;

  late final _i1.ColumnString decisionByUserId;

  late final _i1.ColumnDateTime decisionAt;

  late final _i1.ColumnString resultJson;

  late final _i1.ColumnInt revision;

  late final _i1.ColumnDateTime createdAt;

  late final _i1.ColumnDateTime updatedAt;

  @override
  List<_i1.Column> get columns => [
    id,
    workspaceId,
    conversationId,
    turnId,
    messageId,
    stableId,
    name,
    argumentsJson,
    argumentsDigest,
    status,
    decision,
    decisionByUserId,
    decisionAt,
    resultJson,
    revision,
    createdAt,
    updatedAt,
  ];
}

class ConversationToolCallInclude extends _i1.IncludeObject {
  ConversationToolCallInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => ConversationToolCall.t;
}

class ConversationToolCallIncludeList extends _i1.IncludeList {
  ConversationToolCallIncludeList._({
    _i1.WhereExpressionBuilder<ConversationToolCallTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ConversationToolCall.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => ConversationToolCall.t;
}

class ConversationToolCallRepository {
  const ConversationToolCallRepository._();

  /// Returns a list of [ConversationToolCall]s matching the given query parameters.
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
  Future<List<ConversationToolCall>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<ConversationToolCallTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ConversationToolCallTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<ConversationToolCallTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ConversationToolCall>(
      where: where?.call(ConversationToolCall.t),
      orderBy: orderBy?.call(ConversationToolCall.t),
      orderByList: orderByList?.call(ConversationToolCall.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [ConversationToolCall] matching the given query parameters.
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
  Future<ConversationToolCall?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<ConversationToolCallTable>? where,
    int? offset,
    _i1.OrderByBuilder<ConversationToolCallTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<ConversationToolCallTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ConversationToolCall>(
      where: where?.call(ConversationToolCall.t),
      orderBy: orderBy?.call(ConversationToolCall.t),
      orderByList: orderByList?.call(ConversationToolCall.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ConversationToolCall] by its [id] or null if no such row exists.
  Future<ConversationToolCall?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ConversationToolCall>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ConversationToolCall]s in the list and returns the inserted rows.
  ///
  /// The returned [ConversationToolCall]s will have their `id` fields set.
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
  Future<List<ConversationToolCall>> insert(
    _i1.DatabaseSession session,
    List<ConversationToolCall> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<ConversationToolCall>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [ConversationToolCall] and returns the inserted row.
  ///
  /// The returned [ConversationToolCall] will have its `id` field set.
  Future<ConversationToolCall> insertRow(
    _i1.DatabaseSession session,
    ConversationToolCall row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<ConversationToolCall>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [ConversationToolCall]s in the list and returns the resulting rows.
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
  /// The returned [ConversationToolCall]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ConversationToolCall>> upsert(
    _i1.DatabaseSession session,
    List<ConversationToolCall> rows, {
    required _i1.ColumnSelections<ConversationToolCallTable> conflictColumns,
    _i1.ColumnSelections<ConversationToolCallTable>? updateColumns,
    _i1.WhereExpressionBuilder<ConversationToolCallTable>? updateWhere,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<ConversationToolCall>(
      rows,
      conflictColumns: conflictColumns(ConversationToolCall.t),
      updateColumns: updateColumns?.call(ConversationToolCall.t),
      updateWhere: updateWhere?.call(ConversationToolCall.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [ConversationToolCall] and returns the resulting row.
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
  /// The returned [ConversationToolCall] will have its `id` field set.
  Future<ConversationToolCall?> upsertRow(
    _i1.DatabaseSession session,
    ConversationToolCall row, {
    required _i1.ColumnSelections<ConversationToolCallTable> conflictColumns,
    _i1.ColumnSelections<ConversationToolCallTable>? updateColumns,
    _i1.WhereExpressionBuilder<ConversationToolCallTable>? updateWhere,
    _i1.Transaction? transaction,
  }) async {
    return session.db.upsertRow<ConversationToolCall>(
      row,
      conflictColumns: conflictColumns(ConversationToolCall.t),
      updateColumns: updateColumns?.call(ConversationToolCall.t),
      updateWhere: updateWhere?.call(ConversationToolCall.t),
      transaction: transaction,
    );
  }

  /// Updates all [ConversationToolCall]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ConversationToolCall>> update(
    _i1.DatabaseSession session,
    List<ConversationToolCall> rows, {
    _i1.ColumnSelections<ConversationToolCallTable>? columns,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<ConversationToolCall>(
      rows,
      columns: columns?.call(ConversationToolCall.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [ConversationToolCall]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ConversationToolCall> updateRow(
    _i1.DatabaseSession session,
    ConversationToolCall row, {
    _i1.ColumnSelections<ConversationToolCallTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<ConversationToolCall>(
      row,
      columns: columns?.call(ConversationToolCall.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ConversationToolCall] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ConversationToolCall?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<ConversationToolCallUpdateTable>
    columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<ConversationToolCall>(
      id,
      columnValues: columnValues(ConversationToolCall.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ConversationToolCall]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ConversationToolCall>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<ConversationToolCallUpdateTable>
    columnValues,
    required _i1.WhereExpressionBuilder<ConversationToolCallTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ConversationToolCallTable>? orderBy,
    _i1.OrderByListBuilder<ConversationToolCallTable>? orderByList,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<ConversationToolCall>(
      columnValues: columnValues(ConversationToolCall.t.updateTable),
      where: where(ConversationToolCall.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ConversationToolCall.t),
      orderByList: orderByList?.call(ConversationToolCall.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [ConversationToolCall]s in the list and returns the deleted rows.
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
  Future<List<ConversationToolCall>> delete(
    _i1.DatabaseSession session,
    List<ConversationToolCall> rows, {
    _i1.OrderByBuilder<ConversationToolCallTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<ConversationToolCallTable>? orderByList,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<ConversationToolCall>(
      rows,
      orderBy: orderBy?.call(ConversationToolCall.t),
      orderByList: orderByList?.call(ConversationToolCall.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [ConversationToolCall].
  Future<ConversationToolCall> deleteRow(
    _i1.DatabaseSession session,
    ConversationToolCall row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ConversationToolCall>(
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
  Future<List<ConversationToolCall>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<ConversationToolCallTable> where,
    _i1.OrderByBuilder<ConversationToolCallTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<ConversationToolCallTable>? orderByList,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<ConversationToolCall>(
      where: where(ConversationToolCall.t),
      orderBy: orderBy?.call(ConversationToolCall.t),
      orderByList: orderByList?.call(ConversationToolCall.t),
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
    _i1.WhereExpressionBuilder<ConversationToolCallTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<ConversationToolCall>(
      where: where?.call(ConversationToolCall.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ConversationToolCall] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<ConversationToolCallTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ConversationToolCall>(
      where: where(ConversationToolCall.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
