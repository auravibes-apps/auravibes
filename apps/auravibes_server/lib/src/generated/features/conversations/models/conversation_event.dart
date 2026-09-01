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

import '../../../features/conversations/models/conversation_event_type.dart'
    as _i2;

abstract class ConversationEvent
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  ConversationEvent._({
    this.id,
    required this.workspaceId,
    required this.conversationId,
    required this.sequence,
    required this.eventId,
    required this.actorUserId,
    required this.requestId,
    required this.kind,
    required this.payloadJson,
    required this.createdAt,
  });

  factory ConversationEvent({
    int? id,
    required int workspaceId,
    required int conversationId,
    required int sequence,
    required String eventId,
    required String actorUserId,
    required String requestId,
    required _i2.ConversationEventType kind,
    required String payloadJson,
    required DateTime createdAt,
  }) = _ConversationEventImpl;

  factory ConversationEvent.fromJson(Map<String, dynamic> jsonSerialization) {
    return ConversationEvent(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      conversationId: jsonSerialization['conversationId'] as int,
      sequence: jsonSerialization['sequence'] as int,
      eventId: jsonSerialization['eventId'] as String,
      actorUserId: jsonSerialization['actorUserId'] as String,
      requestId: jsonSerialization['requestId'] as String,
      kind: _i2.ConversationEventType.fromJson(
        (jsonSerialization['kind'] as String),
      ),
      payloadJson: jsonSerialization['payloadJson'] as String,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  static final t = ConversationEventTable();

  static const db = ConversationEventRepository._();

  @override
  int? id;

  int workspaceId;

  int conversationId;

  int sequence;

  String eventId;

  String actorUserId;

  String requestId;

  _i2.ConversationEventType kind;

  String payloadJson;

  DateTime createdAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [ConversationEvent]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ConversationEvent copyWith({
    int? id,
    int? workspaceId,
    int? conversationId,
    int? sequence,
    String? eventId,
    String? actorUserId,
    String? requestId,
    _i2.ConversationEventType? kind,
    String? payloadJson,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ConversationEvent',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'conversationId': conversationId,
      'sequence': sequence,
      'eventId': eventId,
      'actorUserId': actorUserId,
      'requestId': requestId,
      'kind': kind.toJson(),
      'payloadJson': payloadJson,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ConversationEvent',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'conversationId': conversationId,
      'sequence': sequence,
      'eventId': eventId,
      'actorUserId': actorUserId,
      'requestId': requestId,
      'kind': kind.toJson(),
      'payloadJson': payloadJson,
      'createdAt': createdAt.toJson(),
    };
  }

  static ConversationEventInclude include() {
    return ConversationEventInclude._();
  }

  static ConversationEventIncludeList includeList({
    _i1.WhereExpressionBuilder<ConversationEventTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ConversationEventTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<ConversationEventTable>? orderByList,
    ConversationEventInclude? include,
  }) {
    return ConversationEventIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ConversationEvent.t),
      orderDescending: // ignore: deprecated_member_use_from_same_package
          orderDescending,
      orderByList: orderByList?.call(ConversationEvent.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ConversationEventImpl extends ConversationEvent {
  _ConversationEventImpl({
    int? id,
    required int workspaceId,
    required int conversationId,
    required int sequence,
    required String eventId,
    required String actorUserId,
    required String requestId,
    required _i2.ConversationEventType kind,
    required String payloadJson,
    required DateTime createdAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         conversationId: conversationId,
         sequence: sequence,
         eventId: eventId,
         actorUserId: actorUserId,
         requestId: requestId,
         kind: kind,
         payloadJson: payloadJson,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [ConversationEvent]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ConversationEvent copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    int? conversationId,
    int? sequence,
    String? eventId,
    String? actorUserId,
    String? requestId,
    _i2.ConversationEventType? kind,
    String? payloadJson,
    DateTime? createdAt,
  }) {
    return ConversationEvent(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      conversationId: conversationId ?? this.conversationId,
      sequence: sequence ?? this.sequence,
      eventId: eventId ?? this.eventId,
      actorUserId: actorUserId ?? this.actorUserId,
      requestId: requestId ?? this.requestId,
      kind: kind ?? this.kind,
      payloadJson: payloadJson ?? this.payloadJson,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class ConversationEventUpdateTable
    extends _i1.UpdateTable<ConversationEventTable> {
  ConversationEventUpdateTable(super.table);

  _i1.ColumnValue<int, int> workspaceId(int value) => _i1.ColumnValue(
    table.workspaceId,
    value,
  );

  _i1.ColumnValue<int, int> conversationId(int value) => _i1.ColumnValue(
    table.conversationId,
    value,
  );

  _i1.ColumnValue<int, int> sequence(int value) => _i1.ColumnValue(
    table.sequence,
    value,
  );

  _i1.ColumnValue<String, String> eventId(String value) => _i1.ColumnValue(
    table.eventId,
    value,
  );

  _i1.ColumnValue<String, String> actorUserId(String value) => _i1.ColumnValue(
    table.actorUserId,
    value,
  );

  _i1.ColumnValue<String, String> requestId(String value) => _i1.ColumnValue(
    table.requestId,
    value,
  );

  _i1.ColumnValue<_i2.ConversationEventType, _i2.ConversationEventType> kind(
    _i2.ConversationEventType value,
  ) => _i1.ColumnValue(
    table.kind,
    value,
  );

  _i1.ColumnValue<String, String> payloadJson(String value) => _i1.ColumnValue(
    table.payloadJson,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(
        table.createdAt,
        value,
      );
}

class ConversationEventTable extends _i1.Table<int?> {
  ConversationEventTable({super.tableRelation})
    : super(tableName: 'conversation_event') {
    updateTable = ConversationEventUpdateTable(this);
    workspaceId = _i1.ColumnInt(
      'workspaceId',
      this,
    );
    conversationId = _i1.ColumnInt(
      'conversationId',
      this,
    );
    sequence = _i1.ColumnInt(
      'sequence',
      this,
    );
    eventId = _i1.ColumnString(
      'eventId',
      this,
    );
    actorUserId = _i1.ColumnString(
      'actorUserId',
      this,
    );
    requestId = _i1.ColumnString(
      'requestId',
      this,
    );
    kind = _i1.ColumnEnum(
      'kind',
      this,
      _i1.EnumSerialization.byName,
    );
    payloadJson = _i1.ColumnString(
      'payloadJson',
      this,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final ConversationEventUpdateTable updateTable;

  late final _i1.ColumnInt workspaceId;

  late final _i1.ColumnInt conversationId;

  late final _i1.ColumnInt sequence;

  late final _i1.ColumnString eventId;

  late final _i1.ColumnString actorUserId;

  late final _i1.ColumnString requestId;

  late final _i1.ColumnEnum<_i2.ConversationEventType> kind;

  late final _i1.ColumnString payloadJson;

  late final _i1.ColumnDateTime createdAt;

  @override
  List<_i1.Column> get columns => [
    id,
    workspaceId,
    conversationId,
    sequence,
    eventId,
    actorUserId,
    requestId,
    kind,
    payloadJson,
    createdAt,
  ];
}

class ConversationEventInclude extends _i1.IncludeObject {
  ConversationEventInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => ConversationEvent.t;
}

class ConversationEventIncludeList extends _i1.IncludeList {
  ConversationEventIncludeList._({
    _i1.WhereExpressionBuilder<ConversationEventTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ConversationEvent.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => ConversationEvent.t;
}

class ConversationEventRepository {
  const ConversationEventRepository._();

  /// Returns a list of [ConversationEvent]s matching the given query parameters.
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
  Future<List<ConversationEvent>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<ConversationEventTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ConversationEventTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<ConversationEventTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ConversationEvent>(
      where: where?.call(ConversationEvent.t),
      orderBy: orderBy?.call(ConversationEvent.t),
      orderByList: orderByList?.call(ConversationEvent.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [ConversationEvent] matching the given query parameters.
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
  Future<ConversationEvent?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<ConversationEventTable>? where,
    int? offset,
    _i1.OrderByBuilder<ConversationEventTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<ConversationEventTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ConversationEvent>(
      where: where?.call(ConversationEvent.t),
      orderBy: orderBy?.call(ConversationEvent.t),
      orderByList: orderByList?.call(ConversationEvent.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ConversationEvent] by its [id] or null if no such row exists.
  Future<ConversationEvent?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ConversationEvent>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ConversationEvent]s in the list and returns the inserted rows.
  ///
  /// The returned [ConversationEvent]s will have their `id` fields set.
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
  Future<List<ConversationEvent>> insert(
    _i1.DatabaseSession session,
    List<ConversationEvent> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<ConversationEvent>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [ConversationEvent] and returns the inserted row.
  ///
  /// The returned [ConversationEvent] will have its `id` field set.
  Future<ConversationEvent> insertRow(
    _i1.DatabaseSession session,
    ConversationEvent row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<ConversationEvent>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [ConversationEvent]s in the list and returns the resulting rows.
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
  /// The returned [ConversationEvent]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ConversationEvent>> upsert(
    _i1.DatabaseSession session,
    List<ConversationEvent> rows, {
    required _i1.ColumnSelections<ConversationEventTable> conflictColumns,
    _i1.ColumnSelections<ConversationEventTable>? updateColumns,
    _i1.WhereExpressionBuilder<ConversationEventTable>? updateWhere,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<ConversationEvent>(
      rows,
      conflictColumns: conflictColumns(ConversationEvent.t),
      updateColumns: updateColumns?.call(ConversationEvent.t),
      updateWhere: updateWhere?.call(ConversationEvent.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [ConversationEvent] and returns the resulting row.
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
  /// The returned [ConversationEvent] will have its `id` field set.
  Future<ConversationEvent?> upsertRow(
    _i1.DatabaseSession session,
    ConversationEvent row, {
    required _i1.ColumnSelections<ConversationEventTable> conflictColumns,
    _i1.ColumnSelections<ConversationEventTable>? updateColumns,
    _i1.WhereExpressionBuilder<ConversationEventTable>? updateWhere,
    _i1.Transaction? transaction,
  }) async {
    return session.db.upsertRow<ConversationEvent>(
      row,
      conflictColumns: conflictColumns(ConversationEvent.t),
      updateColumns: updateColumns?.call(ConversationEvent.t),
      updateWhere: updateWhere?.call(ConversationEvent.t),
      transaction: transaction,
    );
  }

  /// Updates all [ConversationEvent]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ConversationEvent>> update(
    _i1.DatabaseSession session,
    List<ConversationEvent> rows, {
    _i1.ColumnSelections<ConversationEventTable>? columns,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<ConversationEvent>(
      rows,
      columns: columns?.call(ConversationEvent.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [ConversationEvent]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ConversationEvent> updateRow(
    _i1.DatabaseSession session,
    ConversationEvent row, {
    _i1.ColumnSelections<ConversationEventTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<ConversationEvent>(
      row,
      columns: columns?.call(ConversationEvent.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ConversationEvent] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ConversationEvent?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<ConversationEventUpdateTable>
    columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<ConversationEvent>(
      id,
      columnValues: columnValues(ConversationEvent.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ConversationEvent]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ConversationEvent>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<ConversationEventUpdateTable>
    columnValues,
    required _i1.WhereExpressionBuilder<ConversationEventTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ConversationEventTable>? orderBy,
    _i1.OrderByListBuilder<ConversationEventTable>? orderByList,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<ConversationEvent>(
      columnValues: columnValues(ConversationEvent.t.updateTable),
      where: where(ConversationEvent.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ConversationEvent.t),
      orderByList: orderByList?.call(ConversationEvent.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [ConversationEvent]s in the list and returns the deleted rows.
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
  Future<List<ConversationEvent>> delete(
    _i1.DatabaseSession session,
    List<ConversationEvent> rows, {
    _i1.OrderByBuilder<ConversationEventTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<ConversationEventTable>? orderByList,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<ConversationEvent>(
      rows,
      orderBy: orderBy?.call(ConversationEvent.t),
      orderByList: orderByList?.call(ConversationEvent.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [ConversationEvent].
  Future<ConversationEvent> deleteRow(
    _i1.DatabaseSession session,
    ConversationEvent row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ConversationEvent>(
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
  Future<List<ConversationEvent>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<ConversationEventTable> where,
    _i1.OrderByBuilder<ConversationEventTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<ConversationEventTable>? orderByList,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<ConversationEvent>(
      where: where(ConversationEvent.t),
      orderBy: orderBy?.call(ConversationEvent.t),
      orderByList: orderByList?.call(ConversationEvent.t),
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
    _i1.WhereExpressionBuilder<ConversationEventTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<ConversationEvent>(
      where: where?.call(ConversationEvent.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ConversationEvent] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<ConversationEventTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ConversationEvent>(
      where: where(ConversationEvent.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
