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

import '../../../features/workspace_state/models/workspace_resource_kind.dart'
    as _iz7spkcy;

abstract class WorkspaceContentReport
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  WorkspaceContentReport._({
    this.id,
    required this.workspaceId,
    required this.reportId,
    required this.resourceKind,
    required this.resourceId,
    this.tableId,
    required this.revision,
    this.conversationId,
    required this.reporterUserId,
    required this.status,
    required this.submittedAt,
    this.reviewerUserId,
    this.reviewedAt,
  });

  factory WorkspaceContentReport({
    int? id,
    required int workspaceId,
    required String reportId,
    required _iz7spkcy.WorkspaceResourceKind resourceKind,
    required String resourceId,
    String? tableId,
    required int revision,
    String? conversationId,
    required String reporterUserId,
    required String status,
    required DateTime submittedAt,
    String? reviewerUserId,
    DateTime? reviewedAt,
  }) = _WorkspaceContentReportImpl;

  factory WorkspaceContentReport.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return WorkspaceContentReport(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      reportId: jsonSerialization['reportId'] as String,
      resourceKind: _iz7spkcy.WorkspaceResourceKind.fromJson(
        (jsonSerialization['resourceKind'] as String),
      ),
      resourceId: jsonSerialization['resourceId'] as String,
      tableId: jsonSerialization['tableId'] as String?,
      revision: jsonSerialization['revision'] as int,
      conversationId: jsonSerialization['conversationId'] as String?,
      reporterUserId: jsonSerialization['reporterUserId'] as String,
      status: jsonSerialization['status'] as String,
      submittedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['submittedAt'],
      ),
      reviewerUserId: jsonSerialization['reviewerUserId'] as String?,
      reviewedAt: jsonSerialization['reviewedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['reviewedAt']),
    );
  }

  static final t = WorkspaceContentReportTable();

  static const db = WorkspaceContentReportRepository._();

  @override
  int? id;

  int workspaceId;

  String reportId;

  _iz7spkcy.WorkspaceResourceKind resourceKind;

  String resourceId;

  String? tableId;

  int revision;

  String? conversationId;

  String reporterUserId;

  String status;

  DateTime submittedAt;

  String? reviewerUserId;

  DateTime? reviewedAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [WorkspaceContentReport]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  WorkspaceContentReport copyWith({
    int? id,
    int? workspaceId,
    String? reportId,
    _iz7spkcy.WorkspaceResourceKind? resourceKind,
    String? resourceId,
    String? tableId,
    int? revision,
    String? conversationId,
    String? reporterUserId,
    String? status,
    DateTime? submittedAt,
    String? reviewerUserId,
    DateTime? reviewedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WorkspaceContentReport',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'reportId': reportId,
      'resourceKind': resourceKind.toJson(),
      'resourceId': resourceId,
      if (tableId != null) 'tableId': tableId,
      'revision': revision,
      if (conversationId != null) 'conversationId': conversationId,
      'reporterUserId': reporterUserId,
      'status': status,
      'submittedAt': submittedAt.toJson(),
      if (reviewerUserId != null) 'reviewerUserId': reviewerUserId,
      if (reviewedAt != null) 'reviewedAt': reviewedAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WorkspaceContentReport',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'reportId': reportId,
      'resourceKind': resourceKind.toJson(),
      'resourceId': resourceId,
      if (tableId != null) 'tableId': tableId,
      'revision': revision,
      if (conversationId != null) 'conversationId': conversationId,
      'reporterUserId': reporterUserId,
      'status': status,
      'submittedAt': submittedAt.toJson(),
      if (reviewerUserId != null) 'reviewerUserId': reviewerUserId,
      if (reviewedAt != null) 'reviewedAt': reviewedAt?.toJson(),
    };
  }

  static WorkspaceContentReportInclude include() {
    return WorkspaceContentReportInclude._();
  }

  static WorkspaceContentReportIncludeList includeList({
    _is.WhereExpressionBuilder<WorkspaceContentReportTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<WorkspaceContentReportTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceContentReportTable>? orderByList,
    WorkspaceContentReportInclude? include,
  }) {
    return WorkspaceContentReportIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WorkspaceContentReport.t),
      orderByList: orderByList?.call(WorkspaceContentReport.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WorkspaceContentReportImpl extends WorkspaceContentReport {
  _WorkspaceContentReportImpl({
    int? id,
    required int workspaceId,
    required String reportId,
    required _iz7spkcy.WorkspaceResourceKind resourceKind,
    required String resourceId,
    String? tableId,
    required int revision,
    String? conversationId,
    required String reporterUserId,
    required String status,
    required DateTime submittedAt,
    String? reviewerUserId,
    DateTime? reviewedAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         reportId: reportId,
         resourceKind: resourceKind,
         resourceId: resourceId,
         tableId: tableId,
         revision: revision,
         conversationId: conversationId,
         reporterUserId: reporterUserId,
         status: status,
         submittedAt: submittedAt,
         reviewerUserId: reviewerUserId,
         reviewedAt: reviewedAt,
       );

  /// Returns a shallow copy of this [WorkspaceContentReport]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  WorkspaceContentReport copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    String? reportId,
    _iz7spkcy.WorkspaceResourceKind? resourceKind,
    String? resourceId,
    Object? tableId = _Undefined,
    int? revision,
    Object? conversationId = _Undefined,
    String? reporterUserId,
    String? status,
    DateTime? submittedAt,
    Object? reviewerUserId = _Undefined,
    Object? reviewedAt = _Undefined,
  }) {
    return WorkspaceContentReport(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      reportId: reportId ?? this.reportId,
      resourceKind: resourceKind ?? this.resourceKind,
      resourceId: resourceId ?? this.resourceId,
      tableId: tableId is String? ? tableId : this.tableId,
      revision: revision ?? this.revision,
      conversationId: conversationId is String?
          ? conversationId
          : this.conversationId,
      reporterUserId: reporterUserId ?? this.reporterUserId,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewerUserId: reviewerUserId is String?
          ? reviewerUserId
          : this.reviewerUserId,
      reviewedAt: reviewedAt is DateTime? ? reviewedAt : this.reviewedAt,
    );
  }
}

class WorkspaceContentReportUpdateTable
    extends _is.UpdateTable<WorkspaceContentReportTable> {
  WorkspaceContentReportUpdateTable(super.table);

  _is.ColumnValue<int, int> workspaceId(int value) => _is.ColumnValue(
    table.workspaceId,
    value,
  );

  _is.ColumnValue<String, String> reportId(String value) => _is.ColumnValue(
    table.reportId,
    value,
  );

  _is.ColumnValue<
    _iz7spkcy.WorkspaceResourceKind,
    _iz7spkcy.WorkspaceResourceKind
  >
  resourceKind(_iz7spkcy.WorkspaceResourceKind value) => _is.ColumnValue(
    table.resourceKind,
    value,
  );

  _is.ColumnValue<String, String> resourceId(String value) => _is.ColumnValue(
    table.resourceId,
    value,
  );

  _is.ColumnValue<String, String> tableId(String? value) => _is.ColumnValue(
    table.tableId,
    value,
  );

  _is.ColumnValue<int, int> revision(int value) => _is.ColumnValue(
    table.revision,
    value,
  );

  _is.ColumnValue<String, String> conversationId(String? value) =>
      _is.ColumnValue(
        table.conversationId,
        value,
      );

  _is.ColumnValue<String, String> reporterUserId(String value) =>
      _is.ColumnValue(
        table.reporterUserId,
        value,
      );

  _is.ColumnValue<String, String> status(String value) => _is.ColumnValue(
    table.status,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> submittedAt(DateTime value) =>
      _is.ColumnValue(
        table.submittedAt,
        value,
      );

  _is.ColumnValue<String, String> reviewerUserId(String? value) =>
      _is.ColumnValue(
        table.reviewerUserId,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> reviewedAt(DateTime? value) =>
      _is.ColumnValue(
        table.reviewedAt,
        value,
      );
}

class WorkspaceContentReportTable extends _is.Table<int?> {
  WorkspaceContentReportTable({super.tableRelation})
    : super(tableName: 'workspace_content_report') {
    updateTable = WorkspaceContentReportUpdateTable(this);
    workspaceId = _is.ColumnInt(
      'workspaceId',
      this,
    );
    reportId = _is.ColumnString(
      'reportId',
      this,
    );
    resourceKind = _is.ColumnEnum(
      'resourceKind',
      this,
      _is.EnumSerialization.byName,
    );
    resourceId = _is.ColumnString(
      'resourceId',
      this,
    );
    tableId = _is.ColumnString(
      'tableId',
      this,
    );
    revision = _is.ColumnInt(
      'revision',
      this,
    );
    conversationId = _is.ColumnString(
      'conversationId',
      this,
    );
    reporterUserId = _is.ColumnString(
      'reporterUserId',
      this,
    );
    status = _is.ColumnString(
      'status',
      this,
    );
    submittedAt = _is.ColumnDateTime(
      'submittedAt',
      this,
    );
    reviewerUserId = _is.ColumnString(
      'reviewerUserId',
      this,
    );
    reviewedAt = _is.ColumnDateTime(
      'reviewedAt',
      this,
    );
  }

  late final WorkspaceContentReportUpdateTable updateTable;

  late final _is.ColumnInt workspaceId;

  late final _is.ColumnString reportId;

  late final _is.ColumnEnum<_iz7spkcy.WorkspaceResourceKind> resourceKind;

  late final _is.ColumnString resourceId;

  late final _is.ColumnString tableId;

  late final _is.ColumnInt revision;

  late final _is.ColumnString conversationId;

  late final _is.ColumnString reporterUserId;

  late final _is.ColumnString status;

  late final _is.ColumnDateTime submittedAt;

  late final _is.ColumnString reviewerUserId;

  late final _is.ColumnDateTime reviewedAt;

  @override
  List<_is.Column> get columns => [
    id,
    workspaceId,
    reportId,
    resourceKind,
    resourceId,
    tableId,
    revision,
    conversationId,
    reporterUserId,
    status,
    submittedAt,
    reviewerUserId,
    reviewedAt,
  ];
}

class WorkspaceContentReportInclude extends _is.IncludeObject {
  WorkspaceContentReportInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => WorkspaceContentReport.t;
}

class WorkspaceContentReportIncludeList extends _is.IncludeList {
  WorkspaceContentReportIncludeList._({
    _is.WhereExpressionBuilder<WorkspaceContentReportTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(WorkspaceContentReport.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => WorkspaceContentReport.t;
}

class WorkspaceContentReportRepository {
  const WorkspaceContentReportRepository._();

  /// Returns a list of [WorkspaceContentReport]s matching the given query parameters.
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
  Future<List<WorkspaceContentReport>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<WorkspaceContentReportTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<WorkspaceContentReportTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceContentReportTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<WorkspaceContentReport>(
      where: where?.call(WorkspaceContentReport.t),
      orderBy: orderBy?.call(WorkspaceContentReport.t),
      orderByList: orderByList?.call(WorkspaceContentReport.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [WorkspaceContentReport] matching the given query parameters.
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
  Future<WorkspaceContentReport?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<WorkspaceContentReportTable>? where,
    int? offset,
    _is.OrderByBuilder<WorkspaceContentReportTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceContentReportTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<WorkspaceContentReport>(
      where: where?.call(WorkspaceContentReport.t),
      orderBy: orderBy?.call(WorkspaceContentReport.t),
      orderByList: orderByList?.call(WorkspaceContentReport.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [WorkspaceContentReport] by its [id] or null if no such row exists.
  Future<WorkspaceContentReport?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<WorkspaceContentReport>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [WorkspaceContentReport]s in the list and returns the inserted rows.
  ///
  /// The returned [WorkspaceContentReport]s will have their `id` fields set.
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
  Future<List<WorkspaceContentReport>> insert(
    _is.DatabaseSession session,
    List<WorkspaceContentReport> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<WorkspaceContentReport>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [WorkspaceContentReport] and returns the inserted row.
  ///
  /// The returned [WorkspaceContentReport] will have its `id` field set.
  Future<WorkspaceContentReport> insertRow(
    _is.DatabaseSession session,
    WorkspaceContentReport row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<WorkspaceContentReport>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [WorkspaceContentReport]s in the list and returns the resulting rows.
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
  /// The returned [WorkspaceContentReport]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WorkspaceContentReport>> upsert(
    _is.DatabaseSession session,
    List<WorkspaceContentReport> rows, {
    required _is.ColumnSelections<WorkspaceContentReportTable> conflictColumns,
    _is.ColumnSelections<WorkspaceContentReportTable>? updateColumns,
    _is.WhereExpressionBuilder<WorkspaceContentReportTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<WorkspaceContentReport>(
      rows,
      conflictColumns: conflictColumns(WorkspaceContentReport.t),
      updateColumns: updateColumns?.call(WorkspaceContentReport.t),
      updateWhere: updateWhere?.call(WorkspaceContentReport.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [WorkspaceContentReport] and returns the resulting row.
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
  /// The returned [WorkspaceContentReport] will have its `id` field set.
  Future<WorkspaceContentReport?> upsertRow(
    _is.DatabaseSession session,
    WorkspaceContentReport row, {
    required _is.ColumnSelections<WorkspaceContentReportTable> conflictColumns,
    _is.ColumnSelections<WorkspaceContentReportTable>? updateColumns,
    _is.WhereExpressionBuilder<WorkspaceContentReportTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<WorkspaceContentReport>(
      row,
      conflictColumns: conflictColumns(WorkspaceContentReport.t),
      updateColumns: updateColumns?.call(WorkspaceContentReport.t),
      updateWhere: updateWhere?.call(WorkspaceContentReport.t),
      transaction: transaction,
    );
  }

  /// Updates all [WorkspaceContentReport]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WorkspaceContentReport>> update(
    _is.DatabaseSession session,
    List<WorkspaceContentReport> rows, {
    _is.ColumnSelections<WorkspaceContentReportTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<WorkspaceContentReport>(
      rows,
      columns: columns?.call(WorkspaceContentReport.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [WorkspaceContentReport]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<WorkspaceContentReport> updateRow(
    _is.DatabaseSession session,
    WorkspaceContentReport row, {
    _is.ColumnSelections<WorkspaceContentReportTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<WorkspaceContentReport>(
      row,
      columns: columns?.call(WorkspaceContentReport.t),
      transaction: transaction,
    );
  }

  /// Updates a single [WorkspaceContentReport] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<WorkspaceContentReport?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<WorkspaceContentReportUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<WorkspaceContentReport>(
      id,
      columnValues: columnValues(WorkspaceContentReport.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [WorkspaceContentReport]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WorkspaceContentReport>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<WorkspaceContentReportUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<WorkspaceContentReportTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<WorkspaceContentReportTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceContentReportTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<WorkspaceContentReport>(
      columnValues: columnValues(WorkspaceContentReport.t.updateTable),
      where: where(WorkspaceContentReport.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WorkspaceContentReport.t),
      orderByList: orderByList?.call(WorkspaceContentReport.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [WorkspaceContentReport]s in the list and returns the deleted rows.
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
  Future<List<WorkspaceContentReport>> delete(
    _is.DatabaseSession session,
    List<WorkspaceContentReport> rows, {
    _is.OrderByBuilder<WorkspaceContentReportTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceContentReportTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<WorkspaceContentReport>(
      rows,
      orderBy: orderBy?.call(WorkspaceContentReport.t),
      orderByList: orderByList?.call(WorkspaceContentReport.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [WorkspaceContentReport].
  Future<WorkspaceContentReport> deleteRow(
    _is.DatabaseSession session,
    WorkspaceContentReport row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<WorkspaceContentReport>(
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
  Future<List<WorkspaceContentReport>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<WorkspaceContentReportTable> where,
    _is.OrderByBuilder<WorkspaceContentReportTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceContentReportTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<WorkspaceContentReport>(
      where: where(WorkspaceContentReport.t),
      orderBy: orderBy?.call(WorkspaceContentReport.t),
      orderByList: orderByList?.call(WorkspaceContentReport.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<WorkspaceContentReportTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<WorkspaceContentReport>(
      where: where?.call(WorkspaceContentReport.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [WorkspaceContentReport] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<WorkspaceContentReportTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<WorkspaceContentReport>(
      where: where(WorkspaceContentReport.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
