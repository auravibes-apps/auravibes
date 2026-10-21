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

abstract class MessageBookmark
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  MessageBookmark._({
    this.id,
    required this.workspaceId,
    required this.userId,
    required this.messageId,
    required this.createdAt,
  });

  factory MessageBookmark({
    int? id,
    required int workspaceId,
    required String userId,
    required int messageId,
    required DateTime createdAt,
  }) = _MessageBookmarkImpl;

  factory MessageBookmark.fromJson(Map<String, dynamic> jsonSerialization) {
    return MessageBookmark(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      userId: jsonSerialization['userId'] as String,
      messageId: jsonSerialization['messageId'] as int,
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  static final t = MessageBookmarkTable();

  static const db = MessageBookmarkRepository._();

  @override
  int? id;

  int workspaceId;

  String userId;

  int messageId;

  DateTime createdAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [MessageBookmark]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  MessageBookmark copyWith({
    int? id,
    int? workspaceId,
    String? userId,
    int? messageId,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MessageBookmark',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'userId': userId,
      'messageId': messageId,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'MessageBookmark',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'userId': userId,
      'messageId': messageId,
      'createdAt': createdAt.toJson(),
    };
  }

  static MessageBookmarkInclude include() {
    return MessageBookmarkInclude._();
  }

  static MessageBookmarkIncludeList includeList({
    _is.WhereExpressionBuilder<MessageBookmarkTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<MessageBookmarkTable>? orderBy,
    _is.OrderByListBuilder<MessageBookmarkTable>? orderByList,
    MessageBookmarkInclude? include,
  }) {
    return MessageBookmarkIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(MessageBookmark.t),
      orderByList: orderByList?.call(MessageBookmark.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _MessageBookmarkImpl extends MessageBookmark {
  _MessageBookmarkImpl({
    int? id,
    required int workspaceId,
    required String userId,
    required int messageId,
    required DateTime createdAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         userId: userId,
         messageId: messageId,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [MessageBookmark]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  MessageBookmark copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    String? userId,
    int? messageId,
    DateTime? createdAt,
  }) {
    return MessageBookmark(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      userId: userId ?? this.userId,
      messageId: messageId ?? this.messageId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class MessageBookmarkUpdateTable extends _is.UpdateTable<MessageBookmarkTable> {
  MessageBookmarkUpdateTable(super.table);

  _is.ColumnValue<int, int> workspaceId(int value) => _is.ColumnValue(
    table.workspaceId,
    value,
  );

  _is.ColumnValue<String, String> userId(String value) => _is.ColumnValue(
    table.userId,
    value,
  );

  _is.ColumnValue<int, int> messageId(int value) => _is.ColumnValue(
    table.messageId,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class MessageBookmarkTable extends _is.Table<int?> {
  MessageBookmarkTable({super.tableRelation})
    : super(tableName: 'message_bookmark') {
    updateTable = MessageBookmarkUpdateTable(this);
    workspaceId = _is.ColumnInt(
      'workspaceId',
      this,
    );
    userId = _is.ColumnString(
      'userId',
      this,
    );
    messageId = _is.ColumnInt(
      'messageId',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final MessageBookmarkUpdateTable updateTable;

  late final _is.ColumnInt workspaceId;

  late final _is.ColumnString userId;

  late final _is.ColumnInt messageId;

  late final _is.ColumnDateTime createdAt;

  @override
  List<_is.Column> get columns => [
    id,
    workspaceId,
    userId,
    messageId,
    createdAt,
  ];
}

class MessageBookmarkInclude extends _is.IncludeObject {
  MessageBookmarkInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => MessageBookmark.t;
}

class MessageBookmarkIncludeList extends _is.IncludeList {
  MessageBookmarkIncludeList._({
    _is.WhereExpressionBuilder<MessageBookmarkTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(MessageBookmark.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => MessageBookmark.t;
}

class MessageBookmarkRepository {
  const MessageBookmarkRepository._();

  /// Returns a list of [MessageBookmark]s matching the given query parameters.
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
  Future<List<MessageBookmark>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<MessageBookmarkTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<MessageBookmarkTable>? orderBy,
    _is.OrderByListBuilder<MessageBookmarkTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<MessageBookmark>(
      where: where?.call(MessageBookmark.t),
      orderBy: orderBy?.call(MessageBookmark.t),
      orderByList: orderByList?.call(MessageBookmark.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [MessageBookmark] matching the given query parameters.
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
  Future<MessageBookmark?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<MessageBookmarkTable>? where,
    int? offset,
    _is.OrderByBuilder<MessageBookmarkTable>? orderBy,
    _is.OrderByListBuilder<MessageBookmarkTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<MessageBookmark>(
      where: where?.call(MessageBookmark.t),
      orderBy: orderBy?.call(MessageBookmark.t),
      orderByList: orderByList?.call(MessageBookmark.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [MessageBookmark] by its [id] or null if no such row exists.
  Future<MessageBookmark?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<MessageBookmark>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [MessageBookmark]s in the list and returns the inserted rows.
  ///
  /// The returned [MessageBookmark]s will have their `id` fields set.
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
  Future<List<MessageBookmark>> insert(
    _is.DatabaseSession session,
    List<MessageBookmark> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<MessageBookmark>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [MessageBookmark] and returns the inserted row.
  ///
  /// The returned [MessageBookmark] will have its `id` field set.
  Future<MessageBookmark> insertRow(
    _is.DatabaseSession session,
    MessageBookmark row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<MessageBookmark>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [MessageBookmark]s in the list and returns the resulting rows.
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
  /// The returned [MessageBookmark]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<MessageBookmark>> upsert(
    _is.DatabaseSession session,
    List<MessageBookmark> rows, {
    required _is.ColumnSelections<MessageBookmarkTable> conflictColumns,
    _is.ColumnSelections<MessageBookmarkTable>? updateColumns,
    _is.WhereExpressionBuilder<MessageBookmarkTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<MessageBookmark>(
      rows,
      conflictColumns: conflictColumns(MessageBookmark.t),
      updateColumns: updateColumns?.call(MessageBookmark.t),
      updateWhere: updateWhere?.call(MessageBookmark.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [MessageBookmark] and returns the resulting row.
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
  /// The returned [MessageBookmark] will have its `id` field set.
  Future<MessageBookmark?> upsertRow(
    _is.DatabaseSession session,
    MessageBookmark row, {
    required _is.ColumnSelections<MessageBookmarkTable> conflictColumns,
    _is.ColumnSelections<MessageBookmarkTable>? updateColumns,
    _is.WhereExpressionBuilder<MessageBookmarkTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<MessageBookmark>(
      row,
      conflictColumns: conflictColumns(MessageBookmark.t),
      updateColumns: updateColumns?.call(MessageBookmark.t),
      updateWhere: updateWhere?.call(MessageBookmark.t),
      transaction: transaction,
    );
  }

  /// Updates all [MessageBookmark]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<MessageBookmark>> update(
    _is.DatabaseSession session,
    List<MessageBookmark> rows, {
    _is.ColumnSelections<MessageBookmarkTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<MessageBookmark>(
      rows,
      columns: columns?.call(MessageBookmark.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [MessageBookmark]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<MessageBookmark> updateRow(
    _is.DatabaseSession session,
    MessageBookmark row, {
    _is.ColumnSelections<MessageBookmarkTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<MessageBookmark>(
      row,
      columns: columns?.call(MessageBookmark.t),
      transaction: transaction,
    );
  }

  /// Updates a single [MessageBookmark] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<MessageBookmark?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<MessageBookmarkUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<MessageBookmark>(
      id,
      columnValues: columnValues(MessageBookmark.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [MessageBookmark]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<MessageBookmark>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<MessageBookmarkUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<MessageBookmarkTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<MessageBookmarkTable>? orderBy,
    _is.OrderByListBuilder<MessageBookmarkTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<MessageBookmark>(
      columnValues: columnValues(MessageBookmark.t.updateTable),
      where: where(MessageBookmark.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(MessageBookmark.t),
      orderByList: orderByList?.call(MessageBookmark.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [MessageBookmark]s in the list and returns the deleted rows.
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
  Future<List<MessageBookmark>> delete(
    _is.DatabaseSession session,
    List<MessageBookmark> rows, {
    _is.OrderByBuilder<MessageBookmarkTable>? orderBy,
    _is.OrderByListBuilder<MessageBookmarkTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<MessageBookmark>(
      rows,
      orderBy: orderBy?.call(MessageBookmark.t),
      orderByList: orderByList?.call(MessageBookmark.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [MessageBookmark].
  Future<MessageBookmark> deleteRow(
    _is.DatabaseSession session,
    MessageBookmark row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<MessageBookmark>(
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
  Future<List<MessageBookmark>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<MessageBookmarkTable> where,
    _is.OrderByBuilder<MessageBookmarkTable>? orderBy,
    _is.OrderByListBuilder<MessageBookmarkTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<MessageBookmark>(
      where: where(MessageBookmark.t),
      orderBy: orderBy?.call(MessageBookmark.t),
      orderByList: orderByList?.call(MessageBookmark.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<MessageBookmarkTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<MessageBookmark>(
      where: where?.call(MessageBookmark.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [MessageBookmark] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<MessageBookmarkTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<MessageBookmark>(
      where: where(MessageBookmark.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
