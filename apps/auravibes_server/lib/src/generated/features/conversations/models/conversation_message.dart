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

abstract class ConversationMessage
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  ConversationMessage._({
    this.id,
    required this.workspaceId,
    required this.conversationId,
    required this.stableId,
    this.turnId,
    required this.role,
    required this.kind,
    required this.status,
    required this.content,
    this.metadataJson,
    this.compactedThroughMessageId,
    required this.revision,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ConversationMessage({
    int? id,
    required int workspaceId,
    required int conversationId,
    required String stableId,
    int? turnId,
    required String role,
    required String kind,
    required String status,
    required String content,
    String? metadataJson,
    int? compactedThroughMessageId,
    required int revision,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ConversationMessageImpl;

  factory ConversationMessage.fromJson(Map<String, dynamic> jsonSerialization) {
    return ConversationMessage(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      conversationId: jsonSerialization['conversationId'] as int,
      stableId: jsonSerialization['stableId'] as String,
      turnId: jsonSerialization['turnId'] as int?,
      role: jsonSerialization['role'] as String,
      kind: jsonSerialization['kind'] as String,
      status: jsonSerialization['status'] as String,
      content: jsonSerialization['content'] as String,
      metadataJson: jsonSerialization['metadataJson'] as String?,
      compactedThroughMessageId:
          jsonSerialization['compactedThroughMessageId'] as int?,
      revision: jsonSerialization['revision'] as int,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  static final t = ConversationMessageTable();

  static const db = ConversationMessageRepository._();

  @override
  int? id;

  int workspaceId;

  int conversationId;

  String stableId;

  int? turnId;

  String role;

  String kind;

  String status;

  String content;

  String? metadataJson;

  int? compactedThroughMessageId;

  int revision;

  DateTime createdAt;

  DateTime updatedAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [ConversationMessage]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ConversationMessage copyWith({
    int? id,
    int? workspaceId,
    int? conversationId,
    String? stableId,
    int? turnId,
    String? role,
    String? kind,
    String? status,
    String? content,
    String? metadataJson,
    int? compactedThroughMessageId,
    int? revision,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ConversationMessage',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'conversationId': conversationId,
      'stableId': stableId,
      if (turnId != null) 'turnId': turnId,
      'role': role,
      'kind': kind,
      'status': status,
      'content': content,
      if (metadataJson != null) 'metadataJson': metadataJson,
      if (compactedThroughMessageId != null)
        'compactedThroughMessageId': compactedThroughMessageId,
      'revision': revision,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ConversationMessage',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'conversationId': conversationId,
      'stableId': stableId,
      if (turnId != null) 'turnId': turnId,
      'role': role,
      'kind': kind,
      'status': status,
      'content': content,
      if (metadataJson != null) 'metadataJson': metadataJson,
      if (compactedThroughMessageId != null)
        'compactedThroughMessageId': compactedThroughMessageId,
      'revision': revision,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  static ConversationMessageInclude include() {
    return ConversationMessageInclude._();
  }

  static ConversationMessageIncludeList includeList({
    _i1.WhereExpressionBuilder<ConversationMessageTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ConversationMessageTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<ConversationMessageTable>? orderByList,
    ConversationMessageInclude? include,
  }) {
    return ConversationMessageIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ConversationMessage.t),
      orderDescending: // ignore: deprecated_member_use_from_same_package
          orderDescending,
      orderByList: orderByList?.call(ConversationMessage.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ConversationMessageImpl extends ConversationMessage {
  _ConversationMessageImpl({
    int? id,
    required int workspaceId,
    required int conversationId,
    required String stableId,
    int? turnId,
    required String role,
    required String kind,
    required String status,
    required String content,
    String? metadataJson,
    int? compactedThroughMessageId,
    required int revision,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         conversationId: conversationId,
         stableId: stableId,
         turnId: turnId,
         role: role,
         kind: kind,
         status: status,
         content: content,
         metadataJson: metadataJson,
         compactedThroughMessageId: compactedThroughMessageId,
         revision: revision,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [ConversationMessage]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ConversationMessage copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    int? conversationId,
    String? stableId,
    Object? turnId = _Undefined,
    String? role,
    String? kind,
    String? status,
    String? content,
    Object? metadataJson = _Undefined,
    Object? compactedThroughMessageId = _Undefined,
    int? revision,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ConversationMessage(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      conversationId: conversationId ?? this.conversationId,
      stableId: stableId ?? this.stableId,
      turnId: turnId is int? ? turnId : this.turnId,
      role: role ?? this.role,
      kind: kind ?? this.kind,
      status: status ?? this.status,
      content: content ?? this.content,
      metadataJson: metadataJson is String? ? metadataJson : this.metadataJson,
      compactedThroughMessageId: compactedThroughMessageId is int?
          ? compactedThroughMessageId
          : this.compactedThroughMessageId,
      revision: revision ?? this.revision,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ConversationMessageUpdateTable
    extends _i1.UpdateTable<ConversationMessageTable> {
  ConversationMessageUpdateTable(super.table);

  _i1.ColumnValue<int, int> workspaceId(int value) => _i1.ColumnValue(
    table.workspaceId,
    value,
  );

  _i1.ColumnValue<int, int> conversationId(int value) => _i1.ColumnValue(
    table.conversationId,
    value,
  );

  _i1.ColumnValue<String, String> stableId(String value) => _i1.ColumnValue(
    table.stableId,
    value,
  );

  _i1.ColumnValue<int, int> turnId(int? value) => _i1.ColumnValue(
    table.turnId,
    value,
  );

  _i1.ColumnValue<String, String> role(String value) => _i1.ColumnValue(
    table.role,
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

  _i1.ColumnValue<String, String> content(String value) => _i1.ColumnValue(
    table.content,
    value,
  );

  _i1.ColumnValue<String, String> metadataJson(String? value) =>
      _i1.ColumnValue(
        table.metadataJson,
        value,
      );

  _i1.ColumnValue<int, int> compactedThroughMessageId(int? value) =>
      _i1.ColumnValue(
        table.compactedThroughMessageId,
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

class ConversationMessageTable extends _i1.Table<int?> {
  ConversationMessageTable({super.tableRelation})
    : super(tableName: 'conversation_message') {
    updateTable = ConversationMessageUpdateTable(this);
    workspaceId = _i1.ColumnInt(
      'workspaceId',
      this,
    );
    conversationId = _i1.ColumnInt(
      'conversationId',
      this,
    );
    stableId = _i1.ColumnString(
      'stableId',
      this,
    );
    turnId = _i1.ColumnInt(
      'turnId',
      this,
    );
    role = _i1.ColumnString(
      'role',
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
    content = _i1.ColumnString(
      'content',
      this,
    );
    metadataJson = _i1.ColumnString(
      'metadataJson',
      this,
    );
    compactedThroughMessageId = _i1.ColumnInt(
      'compactedThroughMessageId',
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

  late final ConversationMessageUpdateTable updateTable;

  late final _i1.ColumnInt workspaceId;

  late final _i1.ColumnInt conversationId;

  late final _i1.ColumnString stableId;

  late final _i1.ColumnInt turnId;

  late final _i1.ColumnString role;

  late final _i1.ColumnString kind;

  late final _i1.ColumnString status;

  late final _i1.ColumnString content;

  late final _i1.ColumnString metadataJson;

  late final _i1.ColumnInt compactedThroughMessageId;

  late final _i1.ColumnInt revision;

  late final _i1.ColumnDateTime createdAt;

  late final _i1.ColumnDateTime updatedAt;

  @override
  List<_i1.Column> get columns => [
    id,
    workspaceId,
    conversationId,
    stableId,
    turnId,
    role,
    kind,
    status,
    content,
    metadataJson,
    compactedThroughMessageId,
    revision,
    createdAt,
    updatedAt,
  ];
}

class ConversationMessageInclude extends _i1.IncludeObject {
  ConversationMessageInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => ConversationMessage.t;
}

class ConversationMessageIncludeList extends _i1.IncludeList {
  ConversationMessageIncludeList._({
    _i1.WhereExpressionBuilder<ConversationMessageTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ConversationMessage.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => ConversationMessage.t;
}

class ConversationMessageRepository {
  const ConversationMessageRepository._();

  /// Returns a list of [ConversationMessage]s matching the given query parameters.
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
  Future<List<ConversationMessage>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<ConversationMessageTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ConversationMessageTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<ConversationMessageTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ConversationMessage>(
      where: where?.call(ConversationMessage.t),
      orderBy: orderBy?.call(ConversationMessage.t),
      orderByList: orderByList?.call(ConversationMessage.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [ConversationMessage] matching the given query parameters.
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
  Future<ConversationMessage?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<ConversationMessageTable>? where,
    int? offset,
    _i1.OrderByBuilder<ConversationMessageTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<ConversationMessageTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ConversationMessage>(
      where: where?.call(ConversationMessage.t),
      orderBy: orderBy?.call(ConversationMessage.t),
      orderByList: orderByList?.call(ConversationMessage.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ConversationMessage] by its [id] or null if no such row exists.
  Future<ConversationMessage?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ConversationMessage>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ConversationMessage]s in the list and returns the inserted rows.
  ///
  /// The returned [ConversationMessage]s will have their `id` fields set.
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
  Future<List<ConversationMessage>> insert(
    _i1.DatabaseSession session,
    List<ConversationMessage> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<ConversationMessage>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [ConversationMessage] and returns the inserted row.
  ///
  /// The returned [ConversationMessage] will have its `id` field set.
  Future<ConversationMessage> insertRow(
    _i1.DatabaseSession session,
    ConversationMessage row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<ConversationMessage>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [ConversationMessage]s in the list and returns the resulting rows.
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
  /// The returned [ConversationMessage]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ConversationMessage>> upsert(
    _i1.DatabaseSession session,
    List<ConversationMessage> rows, {
    required _i1.ColumnSelections<ConversationMessageTable> conflictColumns,
    _i1.ColumnSelections<ConversationMessageTable>? updateColumns,
    _i1.WhereExpressionBuilder<ConversationMessageTable>? updateWhere,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<ConversationMessage>(
      rows,
      conflictColumns: conflictColumns(ConversationMessage.t),
      updateColumns: updateColumns?.call(ConversationMessage.t),
      updateWhere: updateWhere?.call(ConversationMessage.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [ConversationMessage] and returns the resulting row.
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
  /// The returned [ConversationMessage] will have its `id` field set.
  Future<ConversationMessage?> upsertRow(
    _i1.DatabaseSession session,
    ConversationMessage row, {
    required _i1.ColumnSelections<ConversationMessageTable> conflictColumns,
    _i1.ColumnSelections<ConversationMessageTable>? updateColumns,
    _i1.WhereExpressionBuilder<ConversationMessageTable>? updateWhere,
    _i1.Transaction? transaction,
  }) async {
    return session.db.upsertRow<ConversationMessage>(
      row,
      conflictColumns: conflictColumns(ConversationMessage.t),
      updateColumns: updateColumns?.call(ConversationMessage.t),
      updateWhere: updateWhere?.call(ConversationMessage.t),
      transaction: transaction,
    );
  }

  /// Updates all [ConversationMessage]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ConversationMessage>> update(
    _i1.DatabaseSession session,
    List<ConversationMessage> rows, {
    _i1.ColumnSelections<ConversationMessageTable>? columns,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<ConversationMessage>(
      rows,
      columns: columns?.call(ConversationMessage.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [ConversationMessage]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ConversationMessage> updateRow(
    _i1.DatabaseSession session,
    ConversationMessage row, {
    _i1.ColumnSelections<ConversationMessageTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<ConversationMessage>(
      row,
      columns: columns?.call(ConversationMessage.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ConversationMessage] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ConversationMessage?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<ConversationMessageUpdateTable>
    columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<ConversationMessage>(
      id,
      columnValues: columnValues(ConversationMessage.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ConversationMessage]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ConversationMessage>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<ConversationMessageUpdateTable>
    columnValues,
    required _i1.WhereExpressionBuilder<ConversationMessageTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ConversationMessageTable>? orderBy,
    _i1.OrderByListBuilder<ConversationMessageTable>? orderByList,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<ConversationMessage>(
      columnValues: columnValues(ConversationMessage.t.updateTable),
      where: where(ConversationMessage.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ConversationMessage.t),
      orderByList: orderByList?.call(ConversationMessage.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [ConversationMessage]s in the list and returns the deleted rows.
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
  Future<List<ConversationMessage>> delete(
    _i1.DatabaseSession session,
    List<ConversationMessage> rows, {
    _i1.OrderByBuilder<ConversationMessageTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<ConversationMessageTable>? orderByList,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<ConversationMessage>(
      rows,
      orderBy: orderBy?.call(ConversationMessage.t),
      orderByList: orderByList?.call(ConversationMessage.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [ConversationMessage].
  Future<ConversationMessage> deleteRow(
    _i1.DatabaseSession session,
    ConversationMessage row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ConversationMessage>(
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
  Future<List<ConversationMessage>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<ConversationMessageTable> where,
    _i1.OrderByBuilder<ConversationMessageTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<ConversationMessageTable>? orderByList,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<ConversationMessage>(
      where: where(ConversationMessage.t),
      orderBy: orderBy?.call(ConversationMessage.t),
      orderByList: orderByList?.call(ConversationMessage.t),
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
    _i1.WhereExpressionBuilder<ConversationMessageTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<ConversationMessage>(
      where: where?.call(ConversationMessage.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ConversationMessage] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<ConversationMessageTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ConversationMessage>(
      where: where(ConversationMessage.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
