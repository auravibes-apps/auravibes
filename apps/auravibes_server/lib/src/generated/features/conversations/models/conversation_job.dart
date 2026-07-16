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

abstract class ConversationJob
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  ConversationJob._({
    this.id,
    required this.workspaceId,
    required this.conversationId,
    this.turnId,
    required this.requestId,
    required this.kind,
    required this.status,
    this.payloadJson,
    required this.attempt,
    required this.maxAttempts,
    required this.availableAt,
    this.leaseOwner,
    this.leaseToken,
    this.leaseExpiresAt,
    this.checkpointJson,
    this.lastErrorCode,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ConversationJob({
    int? id,
    required int workspaceId,
    required int conversationId,
    int? turnId,
    required String requestId,
    required String kind,
    required String status,
    String? payloadJson,
    required int attempt,
    required int maxAttempts,
    required DateTime availableAt,
    String? leaseOwner,
    String? leaseToken,
    DateTime? leaseExpiresAt,
    String? checkpointJson,
    String? lastErrorCode,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ConversationJobImpl;

  factory ConversationJob.fromJson(Map<String, dynamic> jsonSerialization) {
    return ConversationJob(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      conversationId: jsonSerialization['conversationId'] as int,
      turnId: jsonSerialization['turnId'] as int?,
      requestId: jsonSerialization['requestId'] as String,
      kind: jsonSerialization['kind'] as String,
      status: jsonSerialization['status'] as String,
      payloadJson: jsonSerialization['payloadJson'] as String?,
      attempt: jsonSerialization['attempt'] as int,
      maxAttempts: jsonSerialization['maxAttempts'] as int,
      availableAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['availableAt'],
      ),
      leaseOwner: jsonSerialization['leaseOwner'] as String?,
      leaseToken: jsonSerialization['leaseToken'] as String?,
      leaseExpiresAt: jsonSerialization['leaseExpiresAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['leaseExpiresAt'],
            ),
      checkpointJson: jsonSerialization['checkpointJson'] as String?,
      lastErrorCode: jsonSerialization['lastErrorCode'] as String?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  static final t = ConversationJobTable();

  static const db = ConversationJobRepository._();

  @override
  int? id;

  int workspaceId;

  int conversationId;

  int? turnId;

  String requestId;

  String kind;

  String status;

  String? payloadJson;

  int attempt;

  int maxAttempts;

  DateTime availableAt;

  String? leaseOwner;

  String? leaseToken;

  DateTime? leaseExpiresAt;

  String? checkpointJson;

  String? lastErrorCode;

  DateTime createdAt;

  DateTime updatedAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [ConversationJob]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ConversationJob copyWith({
    int? id,
    int? workspaceId,
    int? conversationId,
    int? turnId,
    String? requestId,
    String? kind,
    String? status,
    String? payloadJson,
    int? attempt,
    int? maxAttempts,
    DateTime? availableAt,
    String? leaseOwner,
    String? leaseToken,
    DateTime? leaseExpiresAt,
    String? checkpointJson,
    String? lastErrorCode,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ConversationJob',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'conversationId': conversationId,
      if (turnId != null) 'turnId': turnId,
      'requestId': requestId,
      'kind': kind,
      'status': status,
      if (payloadJson != null) 'payloadJson': payloadJson,
      'attempt': attempt,
      'maxAttempts': maxAttempts,
      'availableAt': availableAt.toJson(),
      if (leaseOwner != null) 'leaseOwner': leaseOwner,
      if (leaseToken != null) 'leaseToken': leaseToken,
      if (leaseExpiresAt != null) 'leaseExpiresAt': leaseExpiresAt?.toJson(),
      if (checkpointJson != null) 'checkpointJson': checkpointJson,
      if (lastErrorCode != null) 'lastErrorCode': lastErrorCode,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ConversationJob',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'conversationId': conversationId,
      if (turnId != null) 'turnId': turnId,
      'requestId': requestId,
      'kind': kind,
      'status': status,
      if (payloadJson != null) 'payloadJson': payloadJson,
      'attempt': attempt,
      'maxAttempts': maxAttempts,
      'availableAt': availableAt.toJson(),
      if (leaseOwner != null) 'leaseOwner': leaseOwner,
      if (leaseToken != null) 'leaseToken': leaseToken,
      if (leaseExpiresAt != null) 'leaseExpiresAt': leaseExpiresAt?.toJson(),
      if (checkpointJson != null) 'checkpointJson': checkpointJson,
      if (lastErrorCode != null) 'lastErrorCode': lastErrorCode,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  static ConversationJobInclude include() {
    return ConversationJobInclude._();
  }

  static ConversationJobIncludeList includeList({
    _i1.WhereExpressionBuilder<ConversationJobTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ConversationJobTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<ConversationJobTable>? orderByList,
    ConversationJobInclude? include,
  }) {
    return ConversationJobIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ConversationJob.t),
      orderDescending: // ignore: deprecated_member_use_from_same_package
          orderDescending,
      orderByList: orderByList?.call(ConversationJob.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ConversationJobImpl extends ConversationJob {
  _ConversationJobImpl({
    int? id,
    required int workspaceId,
    required int conversationId,
    int? turnId,
    required String requestId,
    required String kind,
    required String status,
    String? payloadJson,
    required int attempt,
    required int maxAttempts,
    required DateTime availableAt,
    String? leaseOwner,
    String? leaseToken,
    DateTime? leaseExpiresAt,
    String? checkpointJson,
    String? lastErrorCode,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         conversationId: conversationId,
         turnId: turnId,
         requestId: requestId,
         kind: kind,
         status: status,
         payloadJson: payloadJson,
         attempt: attempt,
         maxAttempts: maxAttempts,
         availableAt: availableAt,
         leaseOwner: leaseOwner,
         leaseToken: leaseToken,
         leaseExpiresAt: leaseExpiresAt,
         checkpointJson: checkpointJson,
         lastErrorCode: lastErrorCode,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [ConversationJob]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ConversationJob copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    int? conversationId,
    Object? turnId = _Undefined,
    String? requestId,
    String? kind,
    String? status,
    Object? payloadJson = _Undefined,
    int? attempt,
    int? maxAttempts,
    DateTime? availableAt,
    Object? leaseOwner = _Undefined,
    Object? leaseToken = _Undefined,
    Object? leaseExpiresAt = _Undefined,
    Object? checkpointJson = _Undefined,
    Object? lastErrorCode = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ConversationJob(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      conversationId: conversationId ?? this.conversationId,
      turnId: turnId is int? ? turnId : this.turnId,
      requestId: requestId ?? this.requestId,
      kind: kind ?? this.kind,
      status: status ?? this.status,
      payloadJson: payloadJson is String? ? payloadJson : this.payloadJson,
      attempt: attempt ?? this.attempt,
      maxAttempts: maxAttempts ?? this.maxAttempts,
      availableAt: availableAt ?? this.availableAt,
      leaseOwner: leaseOwner is String? ? leaseOwner : this.leaseOwner,
      leaseToken: leaseToken is String? ? leaseToken : this.leaseToken,
      leaseExpiresAt: leaseExpiresAt is DateTime?
          ? leaseExpiresAt
          : this.leaseExpiresAt,
      checkpointJson: checkpointJson is String?
          ? checkpointJson
          : this.checkpointJson,
      lastErrorCode: lastErrorCode is String?
          ? lastErrorCode
          : this.lastErrorCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ConversationJobUpdateTable extends _i1.UpdateTable<ConversationJobTable> {
  ConversationJobUpdateTable(super.table);

  _i1.ColumnValue<int, int> workspaceId(int value) => _i1.ColumnValue(
    table.workspaceId,
    value,
  );

  _i1.ColumnValue<int, int> conversationId(int value) => _i1.ColumnValue(
    table.conversationId,
    value,
  );

  _i1.ColumnValue<int, int> turnId(int? value) => _i1.ColumnValue(
    table.turnId,
    value,
  );

  _i1.ColumnValue<String, String> requestId(String value) => _i1.ColumnValue(
    table.requestId,
    value,
  );

  _i1.ColumnValue<String, String> kind(String value) => _i1.ColumnValue(
    table.kind,
    value,
  );

  _i1.ColumnValue<String, String> status(String value) => _i1.ColumnValue(
    table.status,
    value,
  );

  _i1.ColumnValue<String, String> payloadJson(String? value) => _i1.ColumnValue(
    table.payloadJson,
    value,
  );

  _i1.ColumnValue<int, int> attempt(int value) => _i1.ColumnValue(
    table.attempt,
    value,
  );

  _i1.ColumnValue<int, int> maxAttempts(int value) => _i1.ColumnValue(
    table.maxAttempts,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> availableAt(DateTime value) =>
      _i1.ColumnValue(
        table.availableAt,
        value,
      );

  _i1.ColumnValue<String, String> leaseOwner(String? value) => _i1.ColumnValue(
    table.leaseOwner,
    value,
  );

  _i1.ColumnValue<String, String> leaseToken(String? value) => _i1.ColumnValue(
    table.leaseToken,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> leaseExpiresAt(DateTime? value) =>
      _i1.ColumnValue(
        table.leaseExpiresAt,
        value,
      );

  _i1.ColumnValue<String, String> checkpointJson(String? value) =>
      _i1.ColumnValue(
        table.checkpointJson,
        value,
      );

  _i1.ColumnValue<String, String> lastErrorCode(String? value) =>
      _i1.ColumnValue(
        table.lastErrorCode,
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

class ConversationJobTable extends _i1.Table<int?> {
  ConversationJobTable({super.tableRelation})
    : super(tableName: 'conversation_job') {
    updateTable = ConversationJobUpdateTable(this);
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
    requestId = _i1.ColumnString(
      'requestId',
      this,
    );
    kind = _i1.ColumnString(
      'kind',
      this,
    );
    status = _i1.ColumnString(
      'status',
      this,
    );
    payloadJson = _i1.ColumnString(
      'payloadJson',
      this,
    );
    attempt = _i1.ColumnInt(
      'attempt',
      this,
    );
    maxAttempts = _i1.ColumnInt(
      'maxAttempts',
      this,
    );
    availableAt = _i1.ColumnDateTime(
      'availableAt',
      this,
    );
    leaseOwner = _i1.ColumnString(
      'leaseOwner',
      this,
    );
    leaseToken = _i1.ColumnString(
      'leaseToken',
      this,
    );
    leaseExpiresAt = _i1.ColumnDateTime(
      'leaseExpiresAt',
      this,
    );
    checkpointJson = _i1.ColumnString(
      'checkpointJson',
      this,
    );
    lastErrorCode = _i1.ColumnString(
      'lastErrorCode',
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

  late final ConversationJobUpdateTable updateTable;

  late final _i1.ColumnInt workspaceId;

  late final _i1.ColumnInt conversationId;

  late final _i1.ColumnInt turnId;

  late final _i1.ColumnString requestId;

  late final _i1.ColumnString kind;

  late final _i1.ColumnString status;

  late final _i1.ColumnString payloadJson;

  late final _i1.ColumnInt attempt;

  late final _i1.ColumnInt maxAttempts;

  late final _i1.ColumnDateTime availableAt;

  late final _i1.ColumnString leaseOwner;

  late final _i1.ColumnString leaseToken;

  late final _i1.ColumnDateTime leaseExpiresAt;

  late final _i1.ColumnString checkpointJson;

  late final _i1.ColumnString lastErrorCode;

  late final _i1.ColumnDateTime createdAt;

  late final _i1.ColumnDateTime updatedAt;

  @override
  List<_i1.Column> get columns => [
    id,
    workspaceId,
    conversationId,
    turnId,
    requestId,
    kind,
    status,
    payloadJson,
    attempt,
    maxAttempts,
    availableAt,
    leaseOwner,
    leaseToken,
    leaseExpiresAt,
    checkpointJson,
    lastErrorCode,
    createdAt,
    updatedAt,
  ];
}

class ConversationJobInclude extends _i1.IncludeObject {
  ConversationJobInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => ConversationJob.t;
}

class ConversationJobIncludeList extends _i1.IncludeList {
  ConversationJobIncludeList._({
    _i1.WhereExpressionBuilder<ConversationJobTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ConversationJob.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => ConversationJob.t;
}

class ConversationJobRepository {
  const ConversationJobRepository._();

  /// Returns a list of [ConversationJob]s matching the given query parameters.
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
  Future<List<ConversationJob>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<ConversationJobTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ConversationJobTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<ConversationJobTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ConversationJob>(
      where: where?.call(ConversationJob.t),
      orderBy: orderBy?.call(ConversationJob.t),
      orderByList: orderByList?.call(ConversationJob.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [ConversationJob] matching the given query parameters.
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
  Future<ConversationJob?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<ConversationJobTable>? where,
    int? offset,
    _i1.OrderByBuilder<ConversationJobTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<ConversationJobTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ConversationJob>(
      where: where?.call(ConversationJob.t),
      orderBy: orderBy?.call(ConversationJob.t),
      orderByList: orderByList?.call(ConversationJob.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ConversationJob] by its [id] or null if no such row exists.
  Future<ConversationJob?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ConversationJob>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ConversationJob]s in the list and returns the inserted rows.
  ///
  /// The returned [ConversationJob]s will have their `id` fields set.
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
  Future<List<ConversationJob>> insert(
    _i1.DatabaseSession session,
    List<ConversationJob> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<ConversationJob>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [ConversationJob] and returns the inserted row.
  ///
  /// The returned [ConversationJob] will have its `id` field set.
  Future<ConversationJob> insertRow(
    _i1.DatabaseSession session,
    ConversationJob row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<ConversationJob>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [ConversationJob]s in the list and returns the resulting rows.
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
  /// The returned [ConversationJob]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ConversationJob>> upsert(
    _i1.DatabaseSession session,
    List<ConversationJob> rows, {
    required _i1.ColumnSelections<ConversationJobTable> conflictColumns,
    _i1.ColumnSelections<ConversationJobTable>? updateColumns,
    _i1.WhereExpressionBuilder<ConversationJobTable>? updateWhere,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<ConversationJob>(
      rows,
      conflictColumns: conflictColumns(ConversationJob.t),
      updateColumns: updateColumns?.call(ConversationJob.t),
      updateWhere: updateWhere?.call(ConversationJob.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [ConversationJob] and returns the resulting row.
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
  /// The returned [ConversationJob] will have its `id` field set.
  Future<ConversationJob?> upsertRow(
    _i1.DatabaseSession session,
    ConversationJob row, {
    required _i1.ColumnSelections<ConversationJobTable> conflictColumns,
    _i1.ColumnSelections<ConversationJobTable>? updateColumns,
    _i1.WhereExpressionBuilder<ConversationJobTable>? updateWhere,
    _i1.Transaction? transaction,
  }) async {
    return session.db.upsertRow<ConversationJob>(
      row,
      conflictColumns: conflictColumns(ConversationJob.t),
      updateColumns: updateColumns?.call(ConversationJob.t),
      updateWhere: updateWhere?.call(ConversationJob.t),
      transaction: transaction,
    );
  }

  /// Updates all [ConversationJob]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ConversationJob>> update(
    _i1.DatabaseSession session,
    List<ConversationJob> rows, {
    _i1.ColumnSelections<ConversationJobTable>? columns,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<ConversationJob>(
      rows,
      columns: columns?.call(ConversationJob.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [ConversationJob]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ConversationJob> updateRow(
    _i1.DatabaseSession session,
    ConversationJob row, {
    _i1.ColumnSelections<ConversationJobTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<ConversationJob>(
      row,
      columns: columns?.call(ConversationJob.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ConversationJob] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ConversationJob?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<ConversationJobUpdateTable>
    columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<ConversationJob>(
      id,
      columnValues: columnValues(ConversationJob.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ConversationJob]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ConversationJob>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<ConversationJobUpdateTable>
    columnValues,
    required _i1.WhereExpressionBuilder<ConversationJobTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ConversationJobTable>? orderBy,
    _i1.OrderByListBuilder<ConversationJobTable>? orderByList,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<ConversationJob>(
      columnValues: columnValues(ConversationJob.t.updateTable),
      where: where(ConversationJob.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ConversationJob.t),
      orderByList: orderByList?.call(ConversationJob.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [ConversationJob]s in the list and returns the deleted rows.
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
  Future<List<ConversationJob>> delete(
    _i1.DatabaseSession session,
    List<ConversationJob> rows, {
    _i1.OrderByBuilder<ConversationJobTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<ConversationJobTable>? orderByList,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<ConversationJob>(
      rows,
      orderBy: orderBy?.call(ConversationJob.t),
      orderByList: orderByList?.call(ConversationJob.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [ConversationJob].
  Future<ConversationJob> deleteRow(
    _i1.DatabaseSession session,
    ConversationJob row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ConversationJob>(
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
  Future<List<ConversationJob>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<ConversationJobTable> where,
    _i1.OrderByBuilder<ConversationJobTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<ConversationJobTable>? orderByList,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<ConversationJob>(
      where: where(ConversationJob.t),
      orderBy: orderBy?.call(ConversationJob.t),
      orderByList: orderByList?.call(ConversationJob.t),
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
    _i1.WhereExpressionBuilder<ConversationJobTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<ConversationJob>(
      where: where?.call(ConversationJob.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ConversationJob] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<ConversationJobTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ConversationJob>(
      where: where(ConversationJob.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
