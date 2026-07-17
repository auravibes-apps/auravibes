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

abstract class Conversation
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
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
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

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
      isPinned: _i1.BoolJsonExtension.fromJson(jsonSerialization['isPinned']),
      modelId: jsonSerialization['modelId'] as String?,
      agentId: jsonSerialization['agentId'] as String?,
      parentConversationStableId:
          jsonSerialization['parentConversationStableId'] as String?,
      revision: jsonSerialization['revision'] as int,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
      deletedAt: jsonSerialization['deletedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['deletedAt']),
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

  DateTime createdAt;

  DateTime updatedAt;

  DateTime? deletedAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [Conversation]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
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
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      if (deletedAt != null) 'deletedAt': deletedAt?.toJson(),
    };
  }

  static ConversationInclude include() {
    return ConversationInclude._();
  }

  static ConversationIncludeList includeList({
    _i1.WhereExpressionBuilder<ConversationTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ConversationTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<ConversationTable>? orderByList,
    ConversationInclude? include,
  }) {
    return ConversationIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Conversation.t),
      orderDescending: // ignore: deprecated_member_use_from_same_package
          orderDescending,
      orderByList: orderByList?.call(Conversation.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
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
         createdAt: createdAt,
         updatedAt: updatedAt,
         deletedAt: deletedAt,
       );

  /// Returns a shallow copy of this [Conversation]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt is DateTime? ? deletedAt : this.deletedAt,
    );
  }
}

class ConversationUpdateTable extends _i1.UpdateTable<ConversationTable> {
  ConversationUpdateTable(super.table);

  _i1.ColumnValue<int, int> workspaceId(int value) => _i1.ColumnValue(
    table.workspaceId,
    value,
  );

  _i1.ColumnValue<String, String> stableId(String value) => _i1.ColumnValue(
    table.stableId,
    value,
  );

  _i1.ColumnValue<String, String> title(String? value) => _i1.ColumnValue(
    table.title,
    value,
  );

  _i1.ColumnValue<bool, bool> isPinned(bool value) => _i1.ColumnValue(
    table.isPinned,
    value,
  );

  _i1.ColumnValue<String, String> modelId(String? value) => _i1.ColumnValue(
    table.modelId,
    value,
  );

  _i1.ColumnValue<String, String> agentId(String? value) => _i1.ColumnValue(
    table.agentId,
    value,
  );

  _i1.ColumnValue<String, String> parentConversationStableId(String? value) =>
      _i1.ColumnValue(
        table.parentConversationStableId,
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

  _i1.ColumnValue<DateTime, DateTime> deletedAt(DateTime? value) =>
      _i1.ColumnValue(
        table.deletedAt,
        value,
      );
}

class ConversationTable extends _i1.Table<int?> {
  ConversationTable({super.tableRelation}) : super(tableName: 'conversation') {
    updateTable = ConversationUpdateTable(this);
    workspaceId = _i1.ColumnInt(
      'workspaceId',
      this,
    );
    stableId = _i1.ColumnString(
      'stableId',
      this,
    );
    title = _i1.ColumnString(
      'title',
      this,
    );
    isPinned = _i1.ColumnBool(
      'isPinned',
      this,
    );
    modelId = _i1.ColumnString(
      'modelId',
      this,
    );
    agentId = _i1.ColumnString(
      'agentId',
      this,
    );
    parentConversationStableId = _i1.ColumnString(
      'parentConversationStableId',
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
    deletedAt = _i1.ColumnDateTime(
      'deletedAt',
      this,
    );
  }

  late final ConversationUpdateTable updateTable;

  late final _i1.ColumnInt workspaceId;

  late final _i1.ColumnString stableId;

  late final _i1.ColumnString title;

  late final _i1.ColumnBool isPinned;

  late final _i1.ColumnString modelId;

  late final _i1.ColumnString agentId;

  late final _i1.ColumnString parentConversationStableId;

  late final _i1.ColumnInt revision;

  late final _i1.ColumnDateTime createdAt;

  late final _i1.ColumnDateTime updatedAt;

  late final _i1.ColumnDateTime deletedAt;

  @override
  List<_i1.Column> get columns => [
    id,
    workspaceId,
    stableId,
    title,
    isPinned,
    modelId,
    agentId,
    parentConversationStableId,
    revision,
    createdAt,
    updatedAt,
    deletedAt,
  ];
}

class ConversationInclude extends _i1.IncludeObject {
  ConversationInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => Conversation.t;
}

class ConversationIncludeList extends _i1.IncludeList {
  ConversationIncludeList._({
    _i1.WhereExpressionBuilder<ConversationTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Conversation.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => Conversation.t;
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
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<ConversationTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ConversationTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<ConversationTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<Conversation>(
      where: where?.call(Conversation.t),
      orderBy: orderBy?.call(Conversation.t),
      orderByList: orderByList?.call(Conversation.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
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
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<ConversationTable>? where,
    int? offset,
    _i1.OrderByBuilder<ConversationTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<ConversationTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<Conversation>(
      where: where?.call(Conversation.t),
      orderBy: orderBy?.call(Conversation.t),
      orderByList: orderByList?.call(Conversation.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [Conversation] by its [id] or null if no such row exists.
  Future<Conversation?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
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
    _i1.DatabaseSession session,
    List<Conversation> rows, {
    _i1.Transaction? transaction,
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
    _i1.DatabaseSession session,
    Conversation row, {
    _i1.Transaction? transaction,
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
    _i1.DatabaseSession session,
    List<Conversation> rows, {
    required _i1.ColumnSelections<ConversationTable> conflictColumns,
    _i1.ColumnSelections<ConversationTable>? updateColumns,
    _i1.WhereExpressionBuilder<ConversationTable>? updateWhere,
    _i1.Transaction? transaction,
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
    _i1.DatabaseSession session,
    Conversation row, {
    required _i1.ColumnSelections<ConversationTable> conflictColumns,
    _i1.ColumnSelections<ConversationTable>? updateColumns,
    _i1.WhereExpressionBuilder<ConversationTable>? updateWhere,
    _i1.Transaction? transaction,
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
    _i1.DatabaseSession session,
    List<Conversation> rows, {
    _i1.ColumnSelections<ConversationTable>? columns,
    _i1.Transaction? transaction,
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
    _i1.DatabaseSession session,
    Conversation row, {
    _i1.ColumnSelections<ConversationTable>? columns,
    _i1.Transaction? transaction,
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
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<ConversationUpdateTable> columnValues,
    _i1.Transaction? transaction,
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
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<ConversationUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<ConversationTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ConversationTable>? orderBy,
    _i1.OrderByListBuilder<ConversationTable>? orderByList,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<Conversation>(
      columnValues: columnValues(Conversation.t.updateTable),
      where: where(Conversation.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Conversation.t),
      orderByList: orderByList?.call(Conversation.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
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
    _i1.DatabaseSession session,
    List<Conversation> rows, {
    _i1.OrderByBuilder<ConversationTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<ConversationTable>? orderByList,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<Conversation>(
      rows,
      orderBy: orderBy?.call(Conversation.t),
      orderByList: orderByList?.call(Conversation.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [Conversation].
  Future<Conversation> deleteRow(
    _i1.DatabaseSession session,
    Conversation row, {
    _i1.Transaction? transaction,
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
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<ConversationTable> where,
    _i1.OrderByBuilder<ConversationTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<ConversationTable>? orderByList,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<Conversation>(
      where: where(Conversation.t),
      orderBy: orderBy?.call(Conversation.t),
      orderByList: orderByList?.call(Conversation.t),
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
    _i1.WhereExpressionBuilder<ConversationTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<Conversation>(
      where: where?.call(Conversation.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [Conversation] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<ConversationTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<Conversation>(
      where: where(Conversation.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
