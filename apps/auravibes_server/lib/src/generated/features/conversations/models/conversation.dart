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

abstract class Conversation
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  Conversation._({
    this.id,
    required this.workspaceId,
    required this.stableId,
    this.title,
    required this.isPinned,
    this.modelId,
    this.agentId,
    this.parentConversationStableId,
    required this.revision,
    int? projectionRevision,
    int? eventSequence,
    String? executionState,
    this.activeExecutionId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  }) : projectionRevision = projectionRevision ?? 1,
       eventSequence = eventSequence ?? 0,
       executionState = executionState ?? 'idle';

  factory Conversation({
    int? id,
    required int workspaceId,
    required String stableId,
    String? title,
    required bool isPinned,
    String? modelId,
    String? agentId,
    String? parentConversationStableId,
    required int revision,
    int? projectionRevision,
    int? eventSequence,
    String? executionState,
    int? activeExecutionId,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
  }) = _ConversationImpl;

  factory Conversation.fromJson(Map<String, dynamic> jsonSerialization) {
    return Conversation(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      stableId: jsonSerialization['stableId'] as String,
      title: jsonSerialization['title'] as String?,
      isPinned: _is.BoolJsonExtension.fromJson(jsonSerialization['isPinned']),
      modelId: jsonSerialization['modelId'] as String?,
      agentId: jsonSerialization['agentId'] as String?,
      parentConversationStableId:
          jsonSerialization['parentConversationStableId'] as String?,
      revision: jsonSerialization['revision'] as int,
      projectionRevision: jsonSerialization['projectionRevision'] as int?,
      eventSequence: jsonSerialization['eventSequence'] as int?,
      executionState: jsonSerialization['executionState'] as String?,
      activeExecutionId: jsonSerialization['activeExecutionId'] as int?,
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
      deletedAt: jsonSerialization['deletedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['deletedAt']),
    );
  }

  static final t = ConversationTable();

  static const db = ConversationRepository._();

  @override
  int? id;

  int workspaceId;

  String stableId;

  String? title;

  bool isPinned;

  String? modelId;

  String? agentId;

  String? parentConversationStableId;

  int revision;

  int projectionRevision;

  int eventSequence;

  String executionState;

  int? activeExecutionId;

  DateTime createdAt;

  DateTime updatedAt;

  DateTime? deletedAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [Conversation]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  Conversation copyWith({
    int? id,
    int? workspaceId,
    String? stableId,
    String? title,
    bool? isPinned,
    String? modelId,
    String? agentId,
    String? parentConversationStableId,
    int? revision,
    int? projectionRevision,
    int? eventSequence,
    String? executionState,
    int? activeExecutionId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Conversation',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'stableId': stableId,
      if (title != null) 'title': title,
      'isPinned': isPinned,
      if (modelId != null) 'modelId': modelId,
      if (agentId != null) 'agentId': agentId,
      if (parentConversationStableId != null)
        'parentConversationStableId': parentConversationStableId,
      'revision': revision,
      'projectionRevision': projectionRevision,
      'eventSequence': eventSequence,
      'executionState': executionState,
      if (activeExecutionId != null) 'activeExecutionId': activeExecutionId,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      if (deletedAt != null) 'deletedAt': deletedAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Conversation',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'stableId': stableId,
      if (title != null) 'title': title,
      'isPinned': isPinned,
      if (modelId != null) 'modelId': modelId,
      if (agentId != null) 'agentId': agentId,
      if (parentConversationStableId != null)
        'parentConversationStableId': parentConversationStableId,
      'revision': revision,
      'projectionRevision': projectionRevision,
      'eventSequence': eventSequence,
      'executionState': executionState,
      if (activeExecutionId != null) 'activeExecutionId': activeExecutionId,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      if (deletedAt != null) 'deletedAt': deletedAt?.toJson(),
    };
  }

  static ConversationInclude include() {
    return ConversationInclude._();
  }

  static ConversationIncludeList includeList({
    _is.WhereExpressionBuilder<ConversationTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ConversationTable>? orderBy,
    _is.OrderByListBuilder<ConversationTable>? orderByList,
    ConversationInclude? include,
  }) {
    return ConversationIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Conversation.t),
      orderByList: orderByList?.call(Conversation.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ConversationImpl extends Conversation {
  _ConversationImpl({
    int? id,
    required int workspaceId,
    required String stableId,
    String? title,
    required bool isPinned,
    String? modelId,
    String? agentId,
    String? parentConversationStableId,
    required int revision,
    int? projectionRevision,
    int? eventSequence,
    String? executionState,
    int? activeExecutionId,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         stableId: stableId,
         title: title,
         isPinned: isPinned,
         modelId: modelId,
         agentId: agentId,
         parentConversationStableId: parentConversationStableId,
         revision: revision,
         projectionRevision: projectionRevision,
         eventSequence: eventSequence,
         executionState: executionState,
         activeExecutionId: activeExecutionId,
         createdAt: createdAt,
         updatedAt: updatedAt,
         deletedAt: deletedAt,
       );

  /// Returns a shallow copy of this [Conversation]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  Conversation copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    String? stableId,
    Object? title = _Undefined,
    bool? isPinned,
    Object? modelId = _Undefined,
    Object? agentId = _Undefined,
    Object? parentConversationStableId = _Undefined,
    int? revision,
    int? projectionRevision,
    int? eventSequence,
    String? executionState,
    Object? activeExecutionId = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? deletedAt = _Undefined,
  }) {
    return Conversation(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      stableId: stableId ?? this.stableId,
      title: title is String? ? title : this.title,
      isPinned: isPinned ?? this.isPinned,
      modelId: modelId is String? ? modelId : this.modelId,
      agentId: agentId is String? ? agentId : this.agentId,
      parentConversationStableId: parentConversationStableId is String?
          ? parentConversationStableId
          : this.parentConversationStableId,
      revision: revision ?? this.revision,
      projectionRevision: projectionRevision ?? this.projectionRevision,
      eventSequence: eventSequence ?? this.eventSequence,
      executionState: executionState ?? this.executionState,
      activeExecutionId: activeExecutionId is int?
          ? activeExecutionId
          : this.activeExecutionId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt is DateTime? ? deletedAt : this.deletedAt,
    );
  }
}

class ConversationUpdateTable extends _is.UpdateTable<ConversationTable> {
  ConversationUpdateTable(super.table);

  _is.ColumnValue<int, int> workspaceId(int value) => _is.ColumnValue(
    table.workspaceId,
    value,
  );

  _is.ColumnValue<String, String> stableId(String value) => _is.ColumnValue(
    table.stableId,
    value,
  );

  _is.ColumnValue<String, String> title(String? value) => _is.ColumnValue(
    table.title,
    value,
  );

  _is.ColumnValue<bool, bool> isPinned(bool value) => _is.ColumnValue(
    table.isPinned,
    value,
  );

  _is.ColumnValue<String, String> modelId(String? value) => _is.ColumnValue(
    table.modelId,
    value,
  );

  _is.ColumnValue<String, String> agentId(String? value) => _is.ColumnValue(
    table.agentId,
    value,
  );

  _is.ColumnValue<String, String> parentConversationStableId(String? value) =>
      _is.ColumnValue(
        table.parentConversationStableId,
        value,
      );

  _is.ColumnValue<int, int> revision(int value) => _is.ColumnValue(
    table.revision,
    value,
  );

  _is.ColumnValue<int, int> projectionRevision(int value) => _is.ColumnValue(
    table.projectionRevision,
    value,
  );

  _is.ColumnValue<int, int> eventSequence(int value) => _is.ColumnValue(
    table.eventSequence,
    value,
  );

  _is.ColumnValue<String, String> executionState(String value) =>
      _is.ColumnValue(
        table.executionState,
        value,
      );

  _is.ColumnValue<int, int> activeExecutionId(int? value) => _is.ColumnValue(
    table.activeExecutionId,
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

  _is.ColumnValue<DateTime, DateTime> deletedAt(DateTime? value) =>
      _is.ColumnValue(
        table.deletedAt,
        value,
      );
}

class ConversationTable extends _is.Table<int?> {
  ConversationTable({super.tableRelation}) : super(tableName: 'conversation') {
    updateTable = ConversationUpdateTable(this);
    workspaceId = _is.ColumnInt(
      'workspaceId',
      this,
    );
    stableId = _is.ColumnString(
      'stableId',
      this,
    );
    title = _is.ColumnString(
      'title',
      this,
    );
    isPinned = _is.ColumnBool(
      'isPinned',
      this,
    );
    modelId = _is.ColumnString(
      'modelId',
      this,
    );
    agentId = _is.ColumnString(
      'agentId',
      this,
    );
    parentConversationStableId = _is.ColumnString(
      'parentConversationStableId',
      this,
    );
    revision = _is.ColumnInt(
      'revision',
      this,
    );
    projectionRevision = _is.ColumnInt(
      'projectionRevision',
      this,
      hasDefault: true,
    );
    eventSequence = _is.ColumnInt(
      'eventSequence',
      this,
      hasDefault: true,
    );
    executionState = _is.ColumnString(
      'executionState',
      this,
      hasDefault: true,
    );
    activeExecutionId = _is.ColumnInt(
      'activeExecutionId',
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
    deletedAt = _is.ColumnDateTime(
      'deletedAt',
      this,
    );
  }

  late final ConversationUpdateTable updateTable;

  late final _is.ColumnInt workspaceId;

  late final _is.ColumnString stableId;

  late final _is.ColumnString title;

  late final _is.ColumnBool isPinned;

  late final _is.ColumnString modelId;

  late final _is.ColumnString agentId;

  late final _is.ColumnString parentConversationStableId;

  late final _is.ColumnInt revision;

  late final _is.ColumnInt projectionRevision;

  late final _is.ColumnInt eventSequence;

  late final _is.ColumnString executionState;

  late final _is.ColumnInt activeExecutionId;

  late final _is.ColumnDateTime createdAt;

  late final _is.ColumnDateTime updatedAt;

  late final _is.ColumnDateTime deletedAt;

  @override
  List<_is.Column> get columns => [
    id,
    workspaceId,
    stableId,
    title,
    isPinned,
    modelId,
    agentId,
    parentConversationStableId,
    revision,
    projectionRevision,
    eventSequence,
    executionState,
    activeExecutionId,
    createdAt,
    updatedAt,
    deletedAt,
  ];
}

class ConversationInclude extends _is.IncludeObject {
  ConversationInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => Conversation.t;
}

class ConversationIncludeList extends _is.IncludeList {
  ConversationIncludeList._({
    _is.WhereExpressionBuilder<ConversationTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Conversation.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => Conversation.t;
}

class ConversationRepository {
  const ConversationRepository._();

  /// Returns a list of [Conversation]s matching the given query parameters.
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
  Future<List<Conversation>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ConversationTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ConversationTable>? orderBy,
    _is.OrderByListBuilder<ConversationTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<Conversation>(
      where: where?.call(Conversation.t),
      orderBy: orderBy?.call(Conversation.t),
      orderByList: orderByList?.call(Conversation.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [Conversation] matching the given query parameters.
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
  Future<Conversation?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ConversationTable>? where,
    int? offset,
    _is.OrderByBuilder<ConversationTable>? orderBy,
    _is.OrderByListBuilder<ConversationTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<Conversation>(
      where: where?.call(Conversation.t),
      orderBy: orderBy?.call(Conversation.t),
      orderByList: orderByList?.call(Conversation.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [Conversation] by its [id] or null if no such row exists.
  Future<Conversation?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<Conversation>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [Conversation]s in the list and returns the inserted rows.
  ///
  /// The returned [Conversation]s will have their `id` fields set.
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
  Future<List<Conversation>> insert(
    _is.DatabaseSession session,
    List<Conversation> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<Conversation>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [Conversation] and returns the inserted row.
  ///
  /// The returned [Conversation] will have its `id` field set.
  Future<Conversation> insertRow(
    _is.DatabaseSession session,
    Conversation row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<Conversation>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [Conversation]s in the list and returns the resulting rows.
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
  /// The returned [Conversation]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Conversation>> upsert(
    _is.DatabaseSession session,
    List<Conversation> rows, {
    required _is.ColumnSelections<ConversationTable> conflictColumns,
    _is.ColumnSelections<ConversationTable>? updateColumns,
    _is.WhereExpressionBuilder<ConversationTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<Conversation>(
      rows,
      conflictColumns: conflictColumns(Conversation.t),
      updateColumns: updateColumns?.call(Conversation.t),
      updateWhere: updateWhere?.call(Conversation.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [Conversation] and returns the resulting row.
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
  /// The returned [Conversation] will have its `id` field set.
  Future<Conversation?> upsertRow(
    _is.DatabaseSession session,
    Conversation row, {
    required _is.ColumnSelections<ConversationTable> conflictColumns,
    _is.ColumnSelections<ConversationTable>? updateColumns,
    _is.WhereExpressionBuilder<ConversationTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<Conversation>(
      row,
      conflictColumns: conflictColumns(Conversation.t),
      updateColumns: updateColumns?.call(Conversation.t),
      updateWhere: updateWhere?.call(Conversation.t),
      transaction: transaction,
    );
  }

  /// Updates all [Conversation]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Conversation>> update(
    _is.DatabaseSession session,
    List<Conversation> rows, {
    _is.ColumnSelections<ConversationTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<Conversation>(
      rows,
      columns: columns?.call(Conversation.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [Conversation]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Conversation> updateRow(
    _is.DatabaseSession session,
    Conversation row, {
    _is.ColumnSelections<ConversationTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<Conversation>(
      row,
      columns: columns?.call(Conversation.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Conversation] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Conversation?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<ConversationUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<Conversation>(
      id,
      columnValues: columnValues(Conversation.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Conversation]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Conversation>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<ConversationUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<ConversationTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ConversationTable>? orderBy,
    _is.OrderByListBuilder<ConversationTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<Conversation>(
      columnValues: columnValues(Conversation.t.updateTable),
      where: where(Conversation.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Conversation.t),
      orderByList: orderByList?.call(Conversation.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [Conversation]s in the list and returns the deleted rows.
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
  Future<List<Conversation>> delete(
    _is.DatabaseSession session,
    List<Conversation> rows, {
    _is.OrderByBuilder<ConversationTable>? orderBy,
    _is.OrderByListBuilder<ConversationTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<Conversation>(
      rows,
      orderBy: orderBy?.call(Conversation.t),
      orderByList: orderByList?.call(Conversation.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [Conversation].
  Future<Conversation> deleteRow(
    _is.DatabaseSession session,
    Conversation row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Conversation>(
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
  Future<List<Conversation>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ConversationTable> where,
    _is.OrderByBuilder<ConversationTable>? orderBy,
    _is.OrderByListBuilder<ConversationTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<Conversation>(
      where: where(Conversation.t),
      orderBy: orderBy?.call(Conversation.t),
      orderByList: orderByList?.call(Conversation.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ConversationTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<Conversation>(
      where: where?.call(Conversation.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [Conversation] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ConversationTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<Conversation>(
      where: where(Conversation.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
