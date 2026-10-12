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

abstract class BackgroundWorkRecord
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  BackgroundWorkRecord._({
    this.id,
    required this.workspaceId,
    required this.conversationId,
    required this.conversationToolCallId,
    this.originatingMessageId,
    required this.stableId,
    required this.toolCallId,
    required this.toolKind,
    required this.status,
    this.statusPreview,
    this.resultContent,
    int? resultByteLength,
    this.errorCode,
    required this.createdAt,
    required this.updatedAt,
  }) : resultByteLength = resultByteLength ?? 0;

  factory BackgroundWorkRecord({
    int? id,
    required int workspaceId,
    required int conversationId,
    required int conversationToolCallId,
    int? originatingMessageId,
    required String stableId,
    required String toolCallId,
    required String toolKind,
    required String status,
    String? statusPreview,
    String? resultContent,
    int? resultByteLength,
    String? errorCode,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _BackgroundWorkRecordImpl;

  factory BackgroundWorkRecord.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return BackgroundWorkRecord(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      conversationId: jsonSerialization['conversationId'] as int,
      conversationToolCallId:
          jsonSerialization['conversationToolCallId'] as int,
      originatingMessageId: jsonSerialization['originatingMessageId'] as int?,
      stableId: jsonSerialization['stableId'] as String,
      toolCallId: jsonSerialization['toolCallId'] as String,
      toolKind: jsonSerialization['toolKind'] as String,
      status: jsonSerialization['status'] as String,
      statusPreview: jsonSerialization['statusPreview'] as String?,
      resultContent: jsonSerialization['resultContent'] as String?,
      resultByteLength: jsonSerialization['resultByteLength'] as int?,
      errorCode: jsonSerialization['errorCode'] as String?,
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  static final t = BackgroundWorkRecordTable();

  static const db = BackgroundWorkRecordRepository._();

  @override
  int? id;

  int workspaceId;

  int conversationId;

  int conversationToolCallId;

  int? originatingMessageId;

  String stableId;

  String toolCallId;

  String toolKind;

  String status;

  String? statusPreview;

  String? resultContent;

  int resultByteLength;

  String? errorCode;

  DateTime createdAt;

  DateTime updatedAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [BackgroundWorkRecord]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  BackgroundWorkRecord copyWith({
    int? id,
    int? workspaceId,
    int? conversationId,
    int? conversationToolCallId,
    int? originatingMessageId,
    String? stableId,
    String? toolCallId,
    String? toolKind,
    String? status,
    String? statusPreview,
    String? resultContent,
    int? resultByteLength,
    String? errorCode,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'BackgroundWorkRecord',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'conversationId': conversationId,
      'conversationToolCallId': conversationToolCallId,
      if (originatingMessageId != null)
        'originatingMessageId': originatingMessageId,
      'stableId': stableId,
      'toolCallId': toolCallId,
      'toolKind': toolKind,
      'status': status,
      if (statusPreview != null) 'statusPreview': statusPreview,
      if (resultContent != null) 'resultContent': resultContent,
      'resultByteLength': resultByteLength,
      if (errorCode != null) 'errorCode': errorCode,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'BackgroundWorkRecord',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'conversationId': conversationId,
      'conversationToolCallId': conversationToolCallId,
      if (originatingMessageId != null)
        'originatingMessageId': originatingMessageId,
      'stableId': stableId,
      'toolCallId': toolCallId,
      'toolKind': toolKind,
      'status': status,
      if (statusPreview != null) 'statusPreview': statusPreview,
      if (resultContent != null) 'resultContent': resultContent,
      'resultByteLength': resultByteLength,
      if (errorCode != null) 'errorCode': errorCode,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  static BackgroundWorkRecordInclude include() {
    return BackgroundWorkRecordInclude._();
  }

  static BackgroundWorkRecordIncludeList includeList({
    _is.WhereExpressionBuilder<BackgroundWorkRecordTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<BackgroundWorkRecordTable>? orderBy,
    _is.OrderByListBuilder<BackgroundWorkRecordTable>? orderByList,
    BackgroundWorkRecordInclude? include,
  }) {
    return BackgroundWorkRecordIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(BackgroundWorkRecord.t),
      orderByList: orderByList?.call(BackgroundWorkRecord.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _BackgroundWorkRecordImpl extends BackgroundWorkRecord {
  _BackgroundWorkRecordImpl({
    int? id,
    required int workspaceId,
    required int conversationId,
    required int conversationToolCallId,
    int? originatingMessageId,
    required String stableId,
    required String toolCallId,
    required String toolKind,
    required String status,
    String? statusPreview,
    String? resultContent,
    int? resultByteLength,
    String? errorCode,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         conversationId: conversationId,
         conversationToolCallId: conversationToolCallId,
         originatingMessageId: originatingMessageId,
         stableId: stableId,
         toolCallId: toolCallId,
         toolKind: toolKind,
         status: status,
         statusPreview: statusPreview,
         resultContent: resultContent,
         resultByteLength: resultByteLength,
         errorCode: errorCode,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [BackgroundWorkRecord]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  BackgroundWorkRecord copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    int? conversationId,
    int? conversationToolCallId,
    Object? originatingMessageId = _Undefined,
    String? stableId,
    String? toolCallId,
    String? toolKind,
    String? status,
    Object? statusPreview = _Undefined,
    Object? resultContent = _Undefined,
    int? resultByteLength,
    Object? errorCode = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BackgroundWorkRecord(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      conversationId: conversationId ?? this.conversationId,
      conversationToolCallId:
          conversationToolCallId ?? this.conversationToolCallId,
      originatingMessageId: originatingMessageId is int?
          ? originatingMessageId
          : this.originatingMessageId,
      stableId: stableId ?? this.stableId,
      toolCallId: toolCallId ?? this.toolCallId,
      toolKind: toolKind ?? this.toolKind,
      status: status ?? this.status,
      statusPreview: statusPreview is String?
          ? statusPreview
          : this.statusPreview,
      resultContent: resultContent is String?
          ? resultContent
          : this.resultContent,
      resultByteLength: resultByteLength ?? this.resultByteLength,
      errorCode: errorCode is String? ? errorCode : this.errorCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class BackgroundWorkRecordUpdateTable
    extends _is.UpdateTable<BackgroundWorkRecordTable> {
  BackgroundWorkRecordUpdateTable(super.table);

  _is.ColumnValue<int, int> workspaceId(int value) => _is.ColumnValue(
    table.workspaceId,
    value,
  );

  _is.ColumnValue<int, int> conversationId(int value) => _is.ColumnValue(
    table.conversationId,
    value,
  );

  _is.ColumnValue<int, int> conversationToolCallId(int value) =>
      _is.ColumnValue(
        table.conversationToolCallId,
        value,
      );

  _is.ColumnValue<int, int> originatingMessageId(int? value) => _is.ColumnValue(
    table.originatingMessageId,
    value,
  );

  _is.ColumnValue<String, String> stableId(String value) => _is.ColumnValue(
    table.stableId,
    value,
  );

  _is.ColumnValue<String, String> toolCallId(String value) => _is.ColumnValue(
    table.toolCallId,
    value,
  );

  _is.ColumnValue<String, String> toolKind(String value) => _is.ColumnValue(
    table.toolKind,
    value,
  );

  _is.ColumnValue<String, String> status(String value) => _is.ColumnValue(
    table.status,
    value,
  );

  _is.ColumnValue<String, String> statusPreview(String? value) =>
      _is.ColumnValue(
        table.statusPreview,
        value,
      );

  _is.ColumnValue<String, String> resultContent(String? value) =>
      _is.ColumnValue(
        table.resultContent,
        value,
      );

  _is.ColumnValue<int, int> resultByteLength(int value) => _is.ColumnValue(
    table.resultByteLength,
    value,
  );

  _is.ColumnValue<String, String> errorCode(String? value) => _is.ColumnValue(
    table.errorCode,
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

class BackgroundWorkRecordTable extends _is.Table<int?> {
  BackgroundWorkRecordTable({super.tableRelation})
    : super(tableName: 'background_work_record') {
    updateTable = BackgroundWorkRecordUpdateTable(this);
    workspaceId = _is.ColumnInt(
      'workspaceId',
      this,
    );
    conversationId = _is.ColumnInt(
      'conversationId',
      this,
    );
    conversationToolCallId = _is.ColumnInt(
      'conversationToolCallId',
      this,
    );
    originatingMessageId = _is.ColumnInt(
      'originatingMessageId',
      this,
    );
    stableId = _is.ColumnString(
      'stableId',
      this,
    );
    toolCallId = _is.ColumnString(
      'toolCallId',
      this,
    );
    toolKind = _is.ColumnString(
      'toolKind',
      this,
    );
    status = _is.ColumnString(
      'status',
      this,
    );
    statusPreview = _is.ColumnString(
      'statusPreview',
      this,
    );
    resultContent = _is.ColumnString(
      'resultContent',
      this,
    );
    resultByteLength = _is.ColumnInt(
      'resultByteLength',
      this,
      hasDefault: true,
    );
    errorCode = _is.ColumnString(
      'errorCode',
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

  late final BackgroundWorkRecordUpdateTable updateTable;

  late final _is.ColumnInt workspaceId;

  late final _is.ColumnInt conversationId;

  late final _is.ColumnInt conversationToolCallId;

  late final _is.ColumnInt originatingMessageId;

  late final _is.ColumnString stableId;

  late final _is.ColumnString toolCallId;

  late final _is.ColumnString toolKind;

  late final _is.ColumnString status;

  late final _is.ColumnString statusPreview;

  late final _is.ColumnString resultContent;

  late final _is.ColumnInt resultByteLength;

  late final _is.ColumnString errorCode;

  late final _is.ColumnDateTime createdAt;

  late final _is.ColumnDateTime updatedAt;

  @override
  List<_is.Column> get columns => [
    id,
    workspaceId,
    conversationId,
    conversationToolCallId,
    originatingMessageId,
    stableId,
    toolCallId,
    toolKind,
    status,
    statusPreview,
    resultContent,
    resultByteLength,
    errorCode,
    createdAt,
    updatedAt,
  ];
}

class BackgroundWorkRecordInclude extends _is.IncludeObject {
  BackgroundWorkRecordInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => BackgroundWorkRecord.t;
}

class BackgroundWorkRecordIncludeList extends _is.IncludeList {
  BackgroundWorkRecordIncludeList._({
    _is.WhereExpressionBuilder<BackgroundWorkRecordTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(BackgroundWorkRecord.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => BackgroundWorkRecord.t;
}

class BackgroundWorkRecordRepository {
  const BackgroundWorkRecordRepository._();

  /// Returns a list of [BackgroundWorkRecord]s matching the given query parameters.
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
  Future<List<BackgroundWorkRecord>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<BackgroundWorkRecordTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<BackgroundWorkRecordTable>? orderBy,
    _is.OrderByListBuilder<BackgroundWorkRecordTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<BackgroundWorkRecord>(
      where: where?.call(BackgroundWorkRecord.t),
      orderBy: orderBy?.call(BackgroundWorkRecord.t),
      orderByList: orderByList?.call(BackgroundWorkRecord.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [BackgroundWorkRecord] matching the given query parameters.
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
  Future<BackgroundWorkRecord?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<BackgroundWorkRecordTable>? where,
    int? offset,
    _is.OrderByBuilder<BackgroundWorkRecordTable>? orderBy,
    _is.OrderByListBuilder<BackgroundWorkRecordTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<BackgroundWorkRecord>(
      where: where?.call(BackgroundWorkRecord.t),
      orderBy: orderBy?.call(BackgroundWorkRecord.t),
      orderByList: orderByList?.call(BackgroundWorkRecord.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [BackgroundWorkRecord] by its [id] or null if no such row exists.
  Future<BackgroundWorkRecord?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<BackgroundWorkRecord>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [BackgroundWorkRecord]s in the list and returns the inserted rows.
  ///
  /// The returned [BackgroundWorkRecord]s will have their `id` fields set.
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
  Future<List<BackgroundWorkRecord>> insert(
    _is.DatabaseSession session,
    List<BackgroundWorkRecord> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<BackgroundWorkRecord>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [BackgroundWorkRecord] and returns the inserted row.
  ///
  /// The returned [BackgroundWorkRecord] will have its `id` field set.
  Future<BackgroundWorkRecord> insertRow(
    _is.DatabaseSession session,
    BackgroundWorkRecord row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<BackgroundWorkRecord>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [BackgroundWorkRecord]s in the list and returns the resulting rows.
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
  /// The returned [BackgroundWorkRecord]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<BackgroundWorkRecord>> upsert(
    _is.DatabaseSession session,
    List<BackgroundWorkRecord> rows, {
    required _is.ColumnSelections<BackgroundWorkRecordTable> conflictColumns,
    _is.ColumnSelections<BackgroundWorkRecordTable>? updateColumns,
    _is.WhereExpressionBuilder<BackgroundWorkRecordTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<BackgroundWorkRecord>(
      rows,
      conflictColumns: conflictColumns(BackgroundWorkRecord.t),
      updateColumns: updateColumns?.call(BackgroundWorkRecord.t),
      updateWhere: updateWhere?.call(BackgroundWorkRecord.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [BackgroundWorkRecord] and returns the resulting row.
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
  /// The returned [BackgroundWorkRecord] will have its `id` field set.
  Future<BackgroundWorkRecord?> upsertRow(
    _is.DatabaseSession session,
    BackgroundWorkRecord row, {
    required _is.ColumnSelections<BackgroundWorkRecordTable> conflictColumns,
    _is.ColumnSelections<BackgroundWorkRecordTable>? updateColumns,
    _is.WhereExpressionBuilder<BackgroundWorkRecordTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<BackgroundWorkRecord>(
      row,
      conflictColumns: conflictColumns(BackgroundWorkRecord.t),
      updateColumns: updateColumns?.call(BackgroundWorkRecord.t),
      updateWhere: updateWhere?.call(BackgroundWorkRecord.t),
      transaction: transaction,
    );
  }

  /// Updates all [BackgroundWorkRecord]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<BackgroundWorkRecord>> update(
    _is.DatabaseSession session,
    List<BackgroundWorkRecord> rows, {
    _is.ColumnSelections<BackgroundWorkRecordTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<BackgroundWorkRecord>(
      rows,
      columns: columns?.call(BackgroundWorkRecord.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [BackgroundWorkRecord]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<BackgroundWorkRecord> updateRow(
    _is.DatabaseSession session,
    BackgroundWorkRecord row, {
    _is.ColumnSelections<BackgroundWorkRecordTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<BackgroundWorkRecord>(
      row,
      columns: columns?.call(BackgroundWorkRecord.t),
      transaction: transaction,
    );
  }

  /// Updates a single [BackgroundWorkRecord] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<BackgroundWorkRecord?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<BackgroundWorkRecordUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<BackgroundWorkRecord>(
      id,
      columnValues: columnValues(BackgroundWorkRecord.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [BackgroundWorkRecord]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<BackgroundWorkRecord>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<BackgroundWorkRecordUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<BackgroundWorkRecordTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<BackgroundWorkRecordTable>? orderBy,
    _is.OrderByListBuilder<BackgroundWorkRecordTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<BackgroundWorkRecord>(
      columnValues: columnValues(BackgroundWorkRecord.t.updateTable),
      where: where(BackgroundWorkRecord.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(BackgroundWorkRecord.t),
      orderByList: orderByList?.call(BackgroundWorkRecord.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [BackgroundWorkRecord]s in the list and returns the deleted rows.
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
  Future<List<BackgroundWorkRecord>> delete(
    _is.DatabaseSession session,
    List<BackgroundWorkRecord> rows, {
    _is.OrderByBuilder<BackgroundWorkRecordTable>? orderBy,
    _is.OrderByListBuilder<BackgroundWorkRecordTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<BackgroundWorkRecord>(
      rows,
      orderBy: orderBy?.call(BackgroundWorkRecord.t),
      orderByList: orderByList?.call(BackgroundWorkRecord.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [BackgroundWorkRecord].
  Future<BackgroundWorkRecord> deleteRow(
    _is.DatabaseSession session,
    BackgroundWorkRecord row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<BackgroundWorkRecord>(
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
  Future<List<BackgroundWorkRecord>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<BackgroundWorkRecordTable> where,
    _is.OrderByBuilder<BackgroundWorkRecordTable>? orderBy,
    _is.OrderByListBuilder<BackgroundWorkRecordTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<BackgroundWorkRecord>(
      where: where(BackgroundWorkRecord.t),
      orderBy: orderBy?.call(BackgroundWorkRecord.t),
      orderByList: orderByList?.call(BackgroundWorkRecord.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<BackgroundWorkRecordTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<BackgroundWorkRecord>(
      where: where?.call(BackgroundWorkRecord.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [BackgroundWorkRecord] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<BackgroundWorkRecordTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<BackgroundWorkRecord>(
      where: where(BackgroundWorkRecord.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
