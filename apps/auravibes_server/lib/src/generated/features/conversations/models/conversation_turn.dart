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

abstract class ConversationTurn
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  ConversationTurn._({
    this.id,
    required this.workspaceId,
    required this.conversationId,
    required this.requestId,
    required this.requestHash,
    required this.initiatorUserId,
    this.userMessageId,
    this.assistantMessageId,
    required this.status,
    required this.revision,
    required this.acceptedSequence,
    this.cancellationRequestedAt,
    this.terminalAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ConversationTurn({
    int? id,
    required int workspaceId,
    required int conversationId,
    required String requestId,
    required String requestHash,
    required String initiatorUserId,
    int? userMessageId,
    int? assistantMessageId,
    required String status,
    required int revision,
    required int acceptedSequence,
    DateTime? cancellationRequestedAt,
    DateTime? terminalAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ConversationTurnImpl;

  factory ConversationTurn.fromJson(Map<String, dynamic> jsonSerialization) {
    return ConversationTurn(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      conversationId: jsonSerialization['conversationId'] as int,
      requestId: jsonSerialization['requestId'] as String,
      requestHash: jsonSerialization['requestHash'] as String,
      initiatorUserId: jsonSerialization['initiatorUserId'] as String,
      userMessageId: jsonSerialization['userMessageId'] as int?,
      assistantMessageId: jsonSerialization['assistantMessageId'] as int?,
      status: jsonSerialization['status'] as String,
      revision: jsonSerialization['revision'] as int,
      acceptedSequence: jsonSerialization['acceptedSequence'] as int,
      cancellationRequestedAt:
          jsonSerialization['cancellationRequestedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['cancellationRequestedAt'],
            ),
      terminalAt: jsonSerialization['terminalAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['terminalAt']),
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  static final t = ConversationTurnTable();

  static const db = ConversationTurnRepository._();

  @override
  int? id;

  int workspaceId;

  int conversationId;

  String requestId;

  String requestHash;

  String initiatorUserId;

  int? userMessageId;

  int? assistantMessageId;

  String status;

  int revision;

  int acceptedSequence;

  DateTime? cancellationRequestedAt;

  DateTime? terminalAt;

  DateTime createdAt;

  DateTime updatedAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [ConversationTurn]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ConversationTurn copyWith({
    int? id,
    int? workspaceId,
    int? conversationId,
    String? requestId,
    String? requestHash,
    String? initiatorUserId,
    int? userMessageId,
    int? assistantMessageId,
    String? status,
    int? revision,
    int? acceptedSequence,
    DateTime? cancellationRequestedAt,
    DateTime? terminalAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ConversationTurn',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'conversationId': conversationId,
      'requestId': requestId,
      'requestHash': requestHash,
      'initiatorUserId': initiatorUserId,
      if (userMessageId != null) 'userMessageId': userMessageId,
      if (assistantMessageId != null) 'assistantMessageId': assistantMessageId,
      'status': status,
      'revision': revision,
      'acceptedSequence': acceptedSequence,
      if (cancellationRequestedAt != null)
        'cancellationRequestedAt': cancellationRequestedAt?.toJson(),
      if (terminalAt != null) 'terminalAt': terminalAt?.toJson(),
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ConversationTurn',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'conversationId': conversationId,
      'requestId': requestId,
      'requestHash': requestHash,
      'initiatorUserId': initiatorUserId,
      if (userMessageId != null) 'userMessageId': userMessageId,
      if (assistantMessageId != null) 'assistantMessageId': assistantMessageId,
      'status': status,
      'revision': revision,
      'acceptedSequence': acceptedSequence,
      if (cancellationRequestedAt != null)
        'cancellationRequestedAt': cancellationRequestedAt?.toJson(),
      if (terminalAt != null) 'terminalAt': terminalAt?.toJson(),
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  static ConversationTurnInclude include() {
    return ConversationTurnInclude._();
  }

  static ConversationTurnIncludeList includeList({
    _is.WhereExpressionBuilder<ConversationTurnTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ConversationTurnTable>? orderBy,
    _is.OrderByListBuilder<ConversationTurnTable>? orderByList,
    ConversationTurnInclude? include,
  }) {
    return ConversationTurnIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ConversationTurn.t),
      orderByList: orderByList?.call(ConversationTurn.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ConversationTurnImpl extends ConversationTurn {
  _ConversationTurnImpl({
    int? id,
    required int workspaceId,
    required int conversationId,
    required String requestId,
    required String requestHash,
    required String initiatorUserId,
    int? userMessageId,
    int? assistantMessageId,
    required String status,
    required int revision,
    required int acceptedSequence,
    DateTime? cancellationRequestedAt,
    DateTime? terminalAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         conversationId: conversationId,
         requestId: requestId,
         requestHash: requestHash,
         initiatorUserId: initiatorUserId,
         userMessageId: userMessageId,
         assistantMessageId: assistantMessageId,
         status: status,
         revision: revision,
         acceptedSequence: acceptedSequence,
         cancellationRequestedAt: cancellationRequestedAt,
         terminalAt: terminalAt,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [ConversationTurn]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ConversationTurn copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    int? conversationId,
    String? requestId,
    String? requestHash,
    String? initiatorUserId,
    Object? userMessageId = _Undefined,
    Object? assistantMessageId = _Undefined,
    String? status,
    int? revision,
    int? acceptedSequence,
    Object? cancellationRequestedAt = _Undefined,
    Object? terminalAt = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ConversationTurn(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      conversationId: conversationId ?? this.conversationId,
      requestId: requestId ?? this.requestId,
      requestHash: requestHash ?? this.requestHash,
      initiatorUserId: initiatorUserId ?? this.initiatorUserId,
      userMessageId: userMessageId is int? ? userMessageId : this.userMessageId,
      assistantMessageId: assistantMessageId is int?
          ? assistantMessageId
          : this.assistantMessageId,
      status: status ?? this.status,
      revision: revision ?? this.revision,
      acceptedSequence: acceptedSequence ?? this.acceptedSequence,
      cancellationRequestedAt: cancellationRequestedAt is DateTime?
          ? cancellationRequestedAt
          : this.cancellationRequestedAt,
      terminalAt: terminalAt is DateTime? ? terminalAt : this.terminalAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ConversationTurnUpdateTable
    extends _is.UpdateTable<ConversationTurnTable> {
  ConversationTurnUpdateTable(super.table);

  _is.ColumnValue<int, int> workspaceId(int value) => _is.ColumnValue(
    table.workspaceId,
    value,
  );

  _is.ColumnValue<int, int> conversationId(int value) => _is.ColumnValue(
    table.conversationId,
    value,
  );

  _is.ColumnValue<String, String> requestId(String value) => _is.ColumnValue(
    table.requestId,
    value,
  );

  _is.ColumnValue<String, String> requestHash(String value) => _is.ColumnValue(
    table.requestHash,
    value,
  );

  _is.ColumnValue<String, String> initiatorUserId(String value) =>
      _is.ColumnValue(
        table.initiatorUserId,
        value,
      );

  _is.ColumnValue<int, int> userMessageId(int? value) => _is.ColumnValue(
    table.userMessageId,
    value,
  );

  _is.ColumnValue<int, int> assistantMessageId(int? value) => _is.ColumnValue(
    table.assistantMessageId,
    value,
  );

  _is.ColumnValue<String, String> status(String value) => _is.ColumnValue(
    table.status,
    value,
  );

  _is.ColumnValue<int, int> revision(int value) => _is.ColumnValue(
    table.revision,
    value,
  );

  _is.ColumnValue<int, int> acceptedSequence(int value) => _is.ColumnValue(
    table.acceptedSequence,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> cancellationRequestedAt(
    DateTime? value,
  ) => _is.ColumnValue(
    table.cancellationRequestedAt,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> terminalAt(DateTime? value) =>
      _is.ColumnValue(
        table.terminalAt,
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
}

class ConversationTurnTable extends _is.Table<int?> {
  ConversationTurnTable({super.tableRelation})
    : super(tableName: 'conversation_turn') {
    updateTable = ConversationTurnUpdateTable(this);
    workspaceId = _is.ColumnInt(
      'workspaceId',
      this,
    );
    conversationId = _is.ColumnInt(
      'conversationId',
      this,
    );
    requestId = _is.ColumnString(
      'requestId',
      this,
    );
    requestHash = _is.ColumnString(
      'requestHash',
      this,
    );
    initiatorUserId = _is.ColumnString(
      'initiatorUserId',
      this,
    );
    userMessageId = _is.ColumnInt(
      'userMessageId',
      this,
    );
    assistantMessageId = _is.ColumnInt(
      'assistantMessageId',
      this,
    );
    status = _is.ColumnString(
      'status',
      this,
    );
    revision = _is.ColumnInt(
      'revision',
      this,
    );
    acceptedSequence = _is.ColumnInt(
      'acceptedSequence',
      this,
    );
    cancellationRequestedAt = _is.ColumnDateTime(
      'cancellationRequestedAt',
      this,
    );
    terminalAt = _is.ColumnDateTime(
      'terminalAt',
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
  }

  late final ConversationTurnUpdateTable updateTable;

  late final _is.ColumnInt workspaceId;

  late final _is.ColumnInt conversationId;

  late final _is.ColumnString requestId;

  late final _is.ColumnString requestHash;

  late final _is.ColumnString initiatorUserId;

  late final _is.ColumnInt userMessageId;

  late final _is.ColumnInt assistantMessageId;

  late final _is.ColumnString status;

  late final _is.ColumnInt revision;

  late final _is.ColumnInt acceptedSequence;

  late final _is.ColumnDateTime cancellationRequestedAt;

  late final _is.ColumnDateTime terminalAt;

  late final _is.ColumnDateTime createdAt;

  late final _is.ColumnDateTime updatedAt;

  @override
  List<_is.Column> get columns => [
    id,
    workspaceId,
    conversationId,
    requestId,
    requestHash,
    initiatorUserId,
    userMessageId,
    assistantMessageId,
    status,
    revision,
    acceptedSequence,
    cancellationRequestedAt,
    terminalAt,
    createdAt,
    updatedAt,
  ];
}

class ConversationTurnInclude extends _is.IncludeObject {
  ConversationTurnInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => ConversationTurn.t;
}

class ConversationTurnIncludeList extends _is.IncludeList {
  ConversationTurnIncludeList._({
    _is.WhereExpressionBuilder<ConversationTurnTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ConversationTurn.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => ConversationTurn.t;
}

class ConversationTurnRepository {
  const ConversationTurnRepository._();

  /// Returns a list of [ConversationTurn]s matching the given query parameters.
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
  Future<List<ConversationTurn>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ConversationTurnTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ConversationTurnTable>? orderBy,
    _is.OrderByListBuilder<ConversationTurnTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ConversationTurn>(
      where: where?.call(ConversationTurn.t),
      orderBy: orderBy?.call(ConversationTurn.t),
      orderByList: orderByList?.call(ConversationTurn.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [ConversationTurn] matching the given query parameters.
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
  Future<ConversationTurn?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ConversationTurnTable>? where,
    int? offset,
    _is.OrderByBuilder<ConversationTurnTable>? orderBy,
    _is.OrderByListBuilder<ConversationTurnTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ConversationTurn>(
      where: where?.call(ConversationTurn.t),
      orderBy: orderBy?.call(ConversationTurn.t),
      orderByList: orderByList?.call(ConversationTurn.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ConversationTurn] by its [id] or null if no such row exists.
  Future<ConversationTurn?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ConversationTurn>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ConversationTurn]s in the list and returns the inserted rows.
  ///
  /// The returned [ConversationTurn]s will have their `id` fields set.
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
  Future<List<ConversationTurn>> insert(
    _is.DatabaseSession session,
    List<ConversationTurn> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<ConversationTurn>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [ConversationTurn] and returns the inserted row.
  ///
  /// The returned [ConversationTurn] will have its `id` field set.
  Future<ConversationTurn> insertRow(
    _is.DatabaseSession session,
    ConversationTurn row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<ConversationTurn>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [ConversationTurn]s in the list and returns the resulting rows.
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
  /// The returned [ConversationTurn]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ConversationTurn>> upsert(
    _is.DatabaseSession session,
    List<ConversationTurn> rows, {
    required _is.ColumnSelections<ConversationTurnTable> conflictColumns,
    _is.ColumnSelections<ConversationTurnTable>? updateColumns,
    _is.WhereExpressionBuilder<ConversationTurnTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<ConversationTurn>(
      rows,
      conflictColumns: conflictColumns(ConversationTurn.t),
      updateColumns: updateColumns?.call(ConversationTurn.t),
      updateWhere: updateWhere?.call(ConversationTurn.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [ConversationTurn] and returns the resulting row.
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
  /// The returned [ConversationTurn] will have its `id` field set.
  Future<ConversationTurn?> upsertRow(
    _is.DatabaseSession session,
    ConversationTurn row, {
    required _is.ColumnSelections<ConversationTurnTable> conflictColumns,
    _is.ColumnSelections<ConversationTurnTable>? updateColumns,
    _is.WhereExpressionBuilder<ConversationTurnTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<ConversationTurn>(
      row,
      conflictColumns: conflictColumns(ConversationTurn.t),
      updateColumns: updateColumns?.call(ConversationTurn.t),
      updateWhere: updateWhere?.call(ConversationTurn.t),
      transaction: transaction,
    );
  }

  /// Updates all [ConversationTurn]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ConversationTurn>> update(
    _is.DatabaseSession session,
    List<ConversationTurn> rows, {
    _is.ColumnSelections<ConversationTurnTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<ConversationTurn>(
      rows,
      columns: columns?.call(ConversationTurn.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [ConversationTurn]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ConversationTurn> updateRow(
    _is.DatabaseSession session,
    ConversationTurn row, {
    _is.ColumnSelections<ConversationTurnTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<ConversationTurn>(
      row,
      columns: columns?.call(ConversationTurn.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ConversationTurn] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ConversationTurn?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<ConversationTurnUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<ConversationTurn>(
      id,
      columnValues: columnValues(ConversationTurn.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ConversationTurn]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ConversationTurn>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<ConversationTurnUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<ConversationTurnTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ConversationTurnTable>? orderBy,
    _is.OrderByListBuilder<ConversationTurnTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<ConversationTurn>(
      columnValues: columnValues(ConversationTurn.t.updateTable),
      where: where(ConversationTurn.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ConversationTurn.t),
      orderByList: orderByList?.call(ConversationTurn.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [ConversationTurn]s in the list and returns the deleted rows.
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
  Future<List<ConversationTurn>> delete(
    _is.DatabaseSession session,
    List<ConversationTurn> rows, {
    _is.OrderByBuilder<ConversationTurnTable>? orderBy,
    _is.OrderByListBuilder<ConversationTurnTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<ConversationTurn>(
      rows,
      orderBy: orderBy?.call(ConversationTurn.t),
      orderByList: orderByList?.call(ConversationTurn.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [ConversationTurn].
  Future<ConversationTurn> deleteRow(
    _is.DatabaseSession session,
    ConversationTurn row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ConversationTurn>(
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
  Future<List<ConversationTurn>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ConversationTurnTable> where,
    _is.OrderByBuilder<ConversationTurnTable>? orderBy,
    _is.OrderByListBuilder<ConversationTurnTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<ConversationTurn>(
      where: where(ConversationTurn.t),
      orderBy: orderBy?.call(ConversationTurn.t),
      orderByList: orderByList?.call(ConversationTurn.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ConversationTurnTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<ConversationTurn>(
      where: where?.call(ConversationTurn.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ConversationTurn] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ConversationTurnTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ConversationTurn>(
      where: where(ConversationTurn.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
