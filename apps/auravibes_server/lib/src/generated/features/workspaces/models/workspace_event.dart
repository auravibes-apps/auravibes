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

abstract class WorkspaceEvent
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  WorkspaceEvent._({
    this.id,
    required this.eventId,
    required this.workspaceId,
    required this.sequence,
    required this.actorUserId,
    required this.kind,
    required this.resourceKind,
    this.resourceId,
    this.payloadJson,
    required this.createdAt,
    this.publishedAt,
  });

  factory WorkspaceEvent({
    int? id,
    required String eventId,
    required int workspaceId,
    required int sequence,
    required String actorUserId,
    required String kind,
    required String resourceKind,
    String? resourceId,
    String? payloadJson,
    required DateTime createdAt,
    DateTime? publishedAt,
  }) = _WorkspaceEventImpl;

  factory WorkspaceEvent.fromJson(Map<String, dynamic> jsonSerialization) {
    return WorkspaceEvent(
      id: jsonSerialization['id'] as int?,
      eventId: jsonSerialization['eventId'] as String,
      workspaceId: jsonSerialization['workspaceId'] as int,
      sequence: jsonSerialization['sequence'] as int,
      actorUserId: jsonSerialization['actorUserId'] as String,
      kind: jsonSerialization['kind'] as String,
      resourceKind: jsonSerialization['resourceKind'] as String,
      resourceId: jsonSerialization['resourceId'] as String?,
      payloadJson: jsonSerialization['payloadJson'] as String?,
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      publishedAt: jsonSerialization['publishedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['publishedAt'],
            ),
    );
  }

  static final t = WorkspaceEventTable();

  static const db = WorkspaceEventRepository._();

  @override
  int? id;

  String eventId;

  int workspaceId;

  int sequence;

  String actorUserId;

  String kind;

  String resourceKind;

  String? resourceId;

  String? payloadJson;

  DateTime createdAt;

  DateTime? publishedAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [WorkspaceEvent]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  WorkspaceEvent copyWith({
    int? id,
    String? eventId,
    int? workspaceId,
    int? sequence,
    String? actorUserId,
    String? kind,
    String? resourceKind,
    String? resourceId,
    String? payloadJson,
    DateTime? createdAt,
    DateTime? publishedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WorkspaceEvent',
      if (id != null) 'id': id,
      'eventId': eventId,
      'workspaceId': workspaceId,
      'sequence': sequence,
      'actorUserId': actorUserId,
      'kind': kind,
      'resourceKind': resourceKind,
      if (resourceId != null) 'resourceId': resourceId,
      if (payloadJson != null) 'payloadJson': payloadJson,
      'createdAt': createdAt.toJson(),
      if (publishedAt != null) 'publishedAt': publishedAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WorkspaceEvent',
      if (id != null) 'id': id,
      'eventId': eventId,
      'workspaceId': workspaceId,
      'sequence': sequence,
      'actorUserId': actorUserId,
      'kind': kind,
      'resourceKind': resourceKind,
      if (resourceId != null) 'resourceId': resourceId,
      if (payloadJson != null) 'payloadJson': payloadJson,
      'createdAt': createdAt.toJson(),
      if (publishedAt != null) 'publishedAt': publishedAt?.toJson(),
    };
  }

  static WorkspaceEventInclude include() {
    return WorkspaceEventInclude._();
  }

  static WorkspaceEventIncludeList includeList({
    _is.WhereExpressionBuilder<WorkspaceEventTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<WorkspaceEventTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceEventTable>? orderByList,
    WorkspaceEventInclude? include,
  }) {
    return WorkspaceEventIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WorkspaceEvent.t),
      orderByList: orderByList?.call(WorkspaceEvent.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WorkspaceEventImpl extends WorkspaceEvent {
  _WorkspaceEventImpl({
    int? id,
    required String eventId,
    required int workspaceId,
    required int sequence,
    required String actorUserId,
    required String kind,
    required String resourceKind,
    String? resourceId,
    String? payloadJson,
    required DateTime createdAt,
    DateTime? publishedAt,
  }) : super._(
         id: id,
         eventId: eventId,
         workspaceId: workspaceId,
         sequence: sequence,
         actorUserId: actorUserId,
         kind: kind,
         resourceKind: resourceKind,
         resourceId: resourceId,
         payloadJson: payloadJson,
         createdAt: createdAt,
         publishedAt: publishedAt,
       );

  /// Returns a shallow copy of this [WorkspaceEvent]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  WorkspaceEvent copyWith({
    Object? id = _Undefined,
    String? eventId,
    int? workspaceId,
    int? sequence,
    String? actorUserId,
    String? kind,
    String? resourceKind,
    Object? resourceId = _Undefined,
    Object? payloadJson = _Undefined,
    DateTime? createdAt,
    Object? publishedAt = _Undefined,
  }) {
    return WorkspaceEvent(
      id: id is int? ? id : this.id,
      eventId: eventId ?? this.eventId,
      workspaceId: workspaceId ?? this.workspaceId,
      sequence: sequence ?? this.sequence,
      actorUserId: actorUserId ?? this.actorUserId,
      kind: kind ?? this.kind,
      resourceKind: resourceKind ?? this.resourceKind,
      resourceId: resourceId is String? ? resourceId : this.resourceId,
      payloadJson: payloadJson is String? ? payloadJson : this.payloadJson,
      createdAt: createdAt ?? this.createdAt,
      publishedAt: publishedAt is DateTime? ? publishedAt : this.publishedAt,
    );
  }
}

class WorkspaceEventUpdateTable extends _is.UpdateTable<WorkspaceEventTable> {
  WorkspaceEventUpdateTable(super.table);

  _is.ColumnValue<String, String> eventId(String value) => _is.ColumnValue(
    table.eventId,
    value,
  );

  _is.ColumnValue<int, int> workspaceId(int value) => _is.ColumnValue(
    table.workspaceId,
    value,
  );

  _is.ColumnValue<int, int> sequence(int value) => _is.ColumnValue(
    table.sequence,
    value,
  );

  _is.ColumnValue<String, String> actorUserId(String value) => _is.ColumnValue(
    table.actorUserId,
    value,
  );

  _is.ColumnValue<String, String> kind(String value) => _is.ColumnValue(
    table.kind,
    value,
  );

  _is.ColumnValue<String, String> resourceKind(String value) => _is.ColumnValue(
    table.resourceKind,
    value,
  );

  _is.ColumnValue<String, String> resourceId(String? value) => _is.ColumnValue(
    table.resourceId,
    value,
  );

  _is.ColumnValue<String, String> payloadJson(String? value) => _is.ColumnValue(
    table.payloadJson,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> publishedAt(DateTime? value) =>
      _is.ColumnValue(
        table.publishedAt,
        value,
      );
}

class WorkspaceEventTable extends _is.Table<int?> {
  WorkspaceEventTable({super.tableRelation})
    : super(tableName: 'workspace_event') {
    updateTable = WorkspaceEventUpdateTable(this);
    eventId = _is.ColumnString(
      'eventId',
      this,
    );
    workspaceId = _is.ColumnInt(
      'workspaceId',
      this,
    );
    sequence = _is.ColumnInt(
      'sequence',
      this,
    );
    actorUserId = _is.ColumnString(
      'actorUserId',
      this,
    );
    kind = _is.ColumnString(
      'kind',
      this,
    );
    resourceKind = _is.ColumnString(
      'resourceKind',
      this,
    );
    resourceId = _is.ColumnString(
      'resourceId',
      this,
    );
    payloadJson = _is.ColumnString(
      'payloadJson',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
    publishedAt = _is.ColumnDateTime(
      'publishedAt',
      this,
    );
  }

  late final WorkspaceEventUpdateTable updateTable;

  late final _is.ColumnString eventId;

  late final _is.ColumnInt workspaceId;

  late final _is.ColumnInt sequence;

  late final _is.ColumnString actorUserId;

  late final _is.ColumnString kind;

  late final _is.ColumnString resourceKind;

  late final _is.ColumnString resourceId;

  late final _is.ColumnString payloadJson;

  late final _is.ColumnDateTime createdAt;

  late final _is.ColumnDateTime publishedAt;

  @override
  List<_is.Column> get columns => [
    id,
    eventId,
    workspaceId,
    sequence,
    actorUserId,
    kind,
    resourceKind,
    resourceId,
    payloadJson,
    createdAt,
    publishedAt,
  ];
}

class WorkspaceEventInclude extends _is.IncludeObject {
  WorkspaceEventInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => WorkspaceEvent.t;
}

class WorkspaceEventIncludeList extends _is.IncludeList {
  WorkspaceEventIncludeList._({
    _is.WhereExpressionBuilder<WorkspaceEventTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(WorkspaceEvent.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => WorkspaceEvent.t;
}

class WorkspaceEventRepository {
  const WorkspaceEventRepository._();

  /// Returns a list of [WorkspaceEvent]s matching the given query parameters.
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
  Future<List<WorkspaceEvent>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<WorkspaceEventTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<WorkspaceEventTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceEventTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<WorkspaceEvent>(
      where: where?.call(WorkspaceEvent.t),
      orderBy: orderBy?.call(WorkspaceEvent.t),
      orderByList: orderByList?.call(WorkspaceEvent.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [WorkspaceEvent] matching the given query parameters.
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
  Future<WorkspaceEvent?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<WorkspaceEventTable>? where,
    int? offset,
    _is.OrderByBuilder<WorkspaceEventTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceEventTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<WorkspaceEvent>(
      where: where?.call(WorkspaceEvent.t),
      orderBy: orderBy?.call(WorkspaceEvent.t),
      orderByList: orderByList?.call(WorkspaceEvent.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [WorkspaceEvent] by its [id] or null if no such row exists.
  Future<WorkspaceEvent?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<WorkspaceEvent>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [WorkspaceEvent]s in the list and returns the inserted rows.
  ///
  /// The returned [WorkspaceEvent]s will have their `id` fields set.
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
  Future<List<WorkspaceEvent>> insert(
    _is.DatabaseSession session,
    List<WorkspaceEvent> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<WorkspaceEvent>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [WorkspaceEvent] and returns the inserted row.
  ///
  /// The returned [WorkspaceEvent] will have its `id` field set.
  Future<WorkspaceEvent> insertRow(
    _is.DatabaseSession session,
    WorkspaceEvent row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<WorkspaceEvent>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [WorkspaceEvent]s in the list and returns the resulting rows.
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
  /// The returned [WorkspaceEvent]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WorkspaceEvent>> upsert(
    _is.DatabaseSession session,
    List<WorkspaceEvent> rows, {
    required _is.ColumnSelections<WorkspaceEventTable> conflictColumns,
    _is.ColumnSelections<WorkspaceEventTable>? updateColumns,
    _is.WhereExpressionBuilder<WorkspaceEventTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<WorkspaceEvent>(
      rows,
      conflictColumns: conflictColumns(WorkspaceEvent.t),
      updateColumns: updateColumns?.call(WorkspaceEvent.t),
      updateWhere: updateWhere?.call(WorkspaceEvent.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [WorkspaceEvent] and returns the resulting row.
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
  /// The returned [WorkspaceEvent] will have its `id` field set.
  Future<WorkspaceEvent?> upsertRow(
    _is.DatabaseSession session,
    WorkspaceEvent row, {
    required _is.ColumnSelections<WorkspaceEventTable> conflictColumns,
    _is.ColumnSelections<WorkspaceEventTable>? updateColumns,
    _is.WhereExpressionBuilder<WorkspaceEventTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<WorkspaceEvent>(
      row,
      conflictColumns: conflictColumns(WorkspaceEvent.t),
      updateColumns: updateColumns?.call(WorkspaceEvent.t),
      updateWhere: updateWhere?.call(WorkspaceEvent.t),
      transaction: transaction,
    );
  }

  /// Updates all [WorkspaceEvent]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WorkspaceEvent>> update(
    _is.DatabaseSession session,
    List<WorkspaceEvent> rows, {
    _is.ColumnSelections<WorkspaceEventTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<WorkspaceEvent>(
      rows,
      columns: columns?.call(WorkspaceEvent.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [WorkspaceEvent]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<WorkspaceEvent> updateRow(
    _is.DatabaseSession session,
    WorkspaceEvent row, {
    _is.ColumnSelections<WorkspaceEventTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<WorkspaceEvent>(
      row,
      columns: columns?.call(WorkspaceEvent.t),
      transaction: transaction,
    );
  }

  /// Updates a single [WorkspaceEvent] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<WorkspaceEvent?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<WorkspaceEventUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<WorkspaceEvent>(
      id,
      columnValues: columnValues(WorkspaceEvent.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [WorkspaceEvent]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WorkspaceEvent>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<WorkspaceEventUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<WorkspaceEventTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<WorkspaceEventTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceEventTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<WorkspaceEvent>(
      columnValues: columnValues(WorkspaceEvent.t.updateTable),
      where: where(WorkspaceEvent.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WorkspaceEvent.t),
      orderByList: orderByList?.call(WorkspaceEvent.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [WorkspaceEvent]s in the list and returns the deleted rows.
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
  Future<List<WorkspaceEvent>> delete(
    _is.DatabaseSession session,
    List<WorkspaceEvent> rows, {
    _is.OrderByBuilder<WorkspaceEventTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceEventTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<WorkspaceEvent>(
      rows,
      orderBy: orderBy?.call(WorkspaceEvent.t),
      orderByList: orderByList?.call(WorkspaceEvent.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [WorkspaceEvent].
  Future<WorkspaceEvent> deleteRow(
    _is.DatabaseSession session,
    WorkspaceEvent row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<WorkspaceEvent>(
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
  Future<List<WorkspaceEvent>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<WorkspaceEventTable> where,
    _is.OrderByBuilder<WorkspaceEventTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceEventTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<WorkspaceEvent>(
      where: where(WorkspaceEvent.t),
      orderBy: orderBy?.call(WorkspaceEvent.t),
      orderByList: orderByList?.call(WorkspaceEvent.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<WorkspaceEventTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<WorkspaceEvent>(
      where: where?.call(WorkspaceEvent.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [WorkspaceEvent] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<WorkspaceEventTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<WorkspaceEvent>(
      where: where(WorkspaceEvent.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
