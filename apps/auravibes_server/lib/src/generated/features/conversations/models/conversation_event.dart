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

import '../../../features/conversations/models/conversation_event_type.dart'
    as _iccy8d0z;

abstract class ConversationEvent
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
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
    required _iccy8d0z.ConversationEventType kind,
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
      kind: _iccy8d0z.ConversationEventType.fromJson(
        (jsonSerialization['kind'] as String),
      ),
      payloadJson: jsonSerialization['payloadJson'] as String,
      createdAt: _is.DateTimeJsonExtension.fromJson(
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

  _iccy8d0z.ConversationEventType kind;

  String payloadJson;

  DateTime createdAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [ConversationEvent]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ConversationEvent copyWith({
    int? id,
    int? workspaceId,
    int? conversationId,
    int? sequence,
    String? eventId,
    String? actorUserId,
    String? requestId,
    _iccy8d0z.ConversationEventType? kind,
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
    _is.WhereExpressionBuilder<ConversationEventTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ConversationEventTable>? orderBy,
    _is.OrderByListBuilder<ConversationEventTable>? orderByList,
    ConversationEventInclude? include,
  }) {
    return ConversationEventIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ConversationEvent.t),
      orderByList: orderByList?.call(ConversationEvent.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
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
    required _iccy8d0z.ConversationEventType kind,
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
  @_is.useResult
  @override
  ConversationEvent copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    int? conversationId,
    int? sequence,
    String? eventId,
    String? actorUserId,
    String? requestId,
    _iccy8d0z.ConversationEventType? kind,
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
    extends _is.UpdateTable<ConversationEventTable> {
  ConversationEventUpdateTable(super.table);

  _is.ColumnValue<int, int> workspaceId(int value) => _is.ColumnValue(
    table.workspaceId,
    value,
  );

  _is.ColumnValue<int, int> conversationId(int value) => _is.ColumnValue(
    table.conversationId,
    value,
  );

  _is.ColumnValue<int, int> sequence(int value) => _is.ColumnValue(
    table.sequence,
    value,
  );

  _is.ColumnValue<String, String> eventId(String value) => _is.ColumnValue(
    table.eventId,
    value,
  );

  _is.ColumnValue<String, String> actorUserId(String value) => _is.ColumnValue(
    table.actorUserId,
    value,
  );

  _is.ColumnValue<String, String> requestId(String value) => _is.ColumnValue(
    table.requestId,
    value,
  );

  _is.ColumnValue<
    _iccy8d0z.ConversationEventType,
    _iccy8d0z.ConversationEventType
  >
  kind(_iccy8d0z.ConversationEventType value) => _is.ColumnValue(
    table.kind,
    value,
  );

  _is.ColumnValue<String, String> payloadJson(String value) => _is.ColumnValue(
    table.payloadJson,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class ConversationEventTable extends _is.Table<int?> {
  ConversationEventTable({super.tableRelation})
    : super(tableName: 'conversation_event') {
    updateTable = ConversationEventUpdateTable(this);
    workspaceId = _is.ColumnInt(
      'workspaceId',
      this,
    );
    conversationId = _is.ColumnInt(
      'conversationId',
      this,
    );
    sequence = _is.ColumnInt(
      'sequence',
      this,
    );
    eventId = _is.ColumnString(
      'eventId',
      this,
    );
    actorUserId = _is.ColumnString(
      'actorUserId',
      this,
    );
    requestId = _is.ColumnString(
      'requestId',
      this,
    );
    kind = _is.ColumnEnum(
      'kind',
      this,
      _is.EnumSerialization.byName,
    );
    payloadJson = _is.ColumnString(
      'payloadJson',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final ConversationEventUpdateTable updateTable;

  late final _is.ColumnInt workspaceId;

  late final _is.ColumnInt conversationId;

  late final _is.ColumnInt sequence;

  late final _is.ColumnString eventId;

  late final _is.ColumnString actorUserId;

  late final _is.ColumnString requestId;

  late final _is.ColumnEnum<_iccy8d0z.ConversationEventType> kind;

  late final _is.ColumnString payloadJson;

  late final _is.ColumnDateTime createdAt;

  @override
  List<_is.Column> get columns => [
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

class ConversationEventInclude extends _is.IncludeObject {
  ConversationEventInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => ConversationEvent.t;
}

class ConversationEventIncludeList extends _is.IncludeList {
  ConversationEventIncludeList._({
    _is.WhereExpressionBuilder<ConversationEventTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ConversationEvent.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => ConversationEvent.t;
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
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ConversationEventTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ConversationEventTable>? orderBy,
    _is.OrderByListBuilder<ConversationEventTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ConversationEvent>(
      where: where?.call(ConversationEvent.t),
      orderBy: orderBy?.call(ConversationEvent.t),
      orderByList: orderByList?.call(ConversationEvent.t),
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
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ConversationEventTable>? where,
    int? offset,
    _is.OrderByBuilder<ConversationEventTable>? orderBy,
    _is.OrderByListBuilder<ConversationEventTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ConversationEvent>(
      where: where?.call(ConversationEvent.t),
      orderBy: orderBy?.call(ConversationEvent.t),
      orderByList: orderByList?.call(ConversationEvent.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ConversationEvent] by its [id] or null if no such row exists.
  Future<ConversationEvent?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
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
    _is.DatabaseSession session,
    List<ConversationEvent> rows, {
    _is.Transaction? transaction,
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
    _is.DatabaseSession session,
    ConversationEvent row, {
    _is.Transaction? transaction,
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
    _is.DatabaseSession session,
    List<ConversationEvent> rows, {
    required _is.ColumnSelections<ConversationEventTable> conflictColumns,
    _is.ColumnSelections<ConversationEventTable>? updateColumns,
    _is.WhereExpressionBuilder<ConversationEventTable>? updateWhere,
    _is.Transaction? transaction,
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
    _is.DatabaseSession session,
    ConversationEvent row, {
    required _is.ColumnSelections<ConversationEventTable> conflictColumns,
    _is.ColumnSelections<ConversationEventTable>? updateColumns,
    _is.WhereExpressionBuilder<ConversationEventTable>? updateWhere,
    _is.Transaction? transaction,
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
    _is.DatabaseSession session,
    List<ConversationEvent> rows, {
    _is.ColumnSelections<ConversationEventTable>? columns,
    _is.Transaction? transaction,
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
    _is.DatabaseSession session,
    ConversationEvent row, {
    _is.ColumnSelections<ConversationEventTable>? columns,
    _is.Transaction? transaction,
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
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<ConversationEventUpdateTable>
    columnValues,
    _is.Transaction? transaction,
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
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<ConversationEventUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<ConversationEventTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ConversationEventTable>? orderBy,
    _is.OrderByListBuilder<ConversationEventTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<ConversationEvent>(
      columnValues: columnValues(ConversationEvent.t.updateTable),
      where: where(ConversationEvent.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ConversationEvent.t),
      orderByList: orderByList?.call(ConversationEvent.t),
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
    _is.DatabaseSession session,
    List<ConversationEvent> rows, {
    _is.OrderByBuilder<ConversationEventTable>? orderBy,
    _is.OrderByListBuilder<ConversationEventTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<ConversationEvent>(
      rows,
      orderBy: orderBy?.call(ConversationEvent.t),
      orderByList: orderByList?.call(ConversationEvent.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [ConversationEvent].
  Future<ConversationEvent> deleteRow(
    _is.DatabaseSession session,
    ConversationEvent row, {
    _is.Transaction? transaction,
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
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ConversationEventTable> where,
    _is.OrderByBuilder<ConversationEventTable>? orderBy,
    _is.OrderByListBuilder<ConversationEventTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<ConversationEvent>(
      where: where(ConversationEvent.t),
      orderBy: orderBy?.call(ConversationEvent.t),
      orderByList: orderByList?.call(ConversationEvent.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ConversationEventTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<ConversationEvent>(
      where: where?.call(ConversationEvent.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ConversationEvent] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ConversationEventTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ConversationEvent>(
      where: where(ConversationEvent.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
