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

abstract class ProviderAdmissionReservation
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  ProviderAdmissionReservation._({
    this.id,
    required this.jobId,
    required this.workspaceId,
    required this.providerId,
    required this.leaseToken,
    required this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProviderAdmissionReservation({
    int? id,
    required int jobId,
    required int workspaceId,
    required String providerId,
    required String leaseToken,
    required DateTime expiresAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ProviderAdmissionReservationImpl;

  factory ProviderAdmissionReservation.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ProviderAdmissionReservation(
      id: jsonSerialization['id'] as int?,
      jobId: jsonSerialization['jobId'] as int,
      workspaceId: jsonSerialization['workspaceId'] as int,
      providerId: jsonSerialization['providerId'] as String,
      leaseToken: jsonSerialization['leaseToken'] as String,
      expiresAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  static final t = ProviderAdmissionReservationTable();

  static const db = ProviderAdmissionReservationRepository._();

  @override
  int? id;

  int jobId;

  int workspaceId;

  String providerId;

  String leaseToken;

  DateTime expiresAt;

  DateTime createdAt;

  DateTime updatedAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [ProviderAdmissionReservation]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ProviderAdmissionReservation copyWith({
    int? id,
    int? jobId,
    int? workspaceId,
    String? providerId,
    String? leaseToken,
    DateTime? expiresAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ProviderAdmissionReservation',
      if (id != null) 'id': id,
      'jobId': jobId,
      'workspaceId': workspaceId,
      'providerId': providerId,
      'leaseToken': leaseToken,
      'expiresAt': expiresAt.toJson(),
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ProviderAdmissionReservation',
      if (id != null) 'id': id,
      'jobId': jobId,
      'workspaceId': workspaceId,
      'providerId': providerId,
      'leaseToken': leaseToken,
      'expiresAt': expiresAt.toJson(),
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  static ProviderAdmissionReservationInclude include() {
    return ProviderAdmissionReservationInclude._();
  }

  static ProviderAdmissionReservationIncludeList includeList({
    _is.WhereExpressionBuilder<ProviderAdmissionReservationTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ProviderAdmissionReservationTable>? orderBy,
    _is.OrderByListBuilder<ProviderAdmissionReservationTable>? orderByList,
    ProviderAdmissionReservationInclude? include,
  }) {
    return ProviderAdmissionReservationIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ProviderAdmissionReservation.t),
      orderByList: orderByList?.call(ProviderAdmissionReservation.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ProviderAdmissionReservationImpl extends ProviderAdmissionReservation {
  _ProviderAdmissionReservationImpl({
    int? id,
    required int jobId,
    required int workspaceId,
    required String providerId,
    required String leaseToken,
    required DateTime expiresAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         jobId: jobId,
         workspaceId: workspaceId,
         providerId: providerId,
         leaseToken: leaseToken,
         expiresAt: expiresAt,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [ProviderAdmissionReservation]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ProviderAdmissionReservation copyWith({
    Object? id = _Undefined,
    int? jobId,
    int? workspaceId,
    String? providerId,
    String? leaseToken,
    DateTime? expiresAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProviderAdmissionReservation(
      id: id is int? ? id : this.id,
      jobId: jobId ?? this.jobId,
      workspaceId: workspaceId ?? this.workspaceId,
      providerId: providerId ?? this.providerId,
      leaseToken: leaseToken ?? this.leaseToken,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ProviderAdmissionReservationUpdateTable
    extends _is.UpdateTable<ProviderAdmissionReservationTable> {
  ProviderAdmissionReservationUpdateTable(super.table);

  _is.ColumnValue<int, int> jobId(int value) => _is.ColumnValue(
    table.jobId,
    value,
  );

  _is.ColumnValue<int, int> workspaceId(int value) => _is.ColumnValue(
    table.workspaceId,
    value,
  );

  _is.ColumnValue<String, String> providerId(String value) => _is.ColumnValue(
    table.providerId,
    value,
  );

  _is.ColumnValue<String, String> leaseToken(String value) => _is.ColumnValue(
    table.leaseToken,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> expiresAt(DateTime value) =>
      _is.ColumnValue(
        table.expiresAt,
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

class ProviderAdmissionReservationTable extends _is.Table<int?> {
  ProviderAdmissionReservationTable({super.tableRelation})
    : super(tableName: 'provider_admission_reservation') {
    updateTable = ProviderAdmissionReservationUpdateTable(this);
    jobId = _is.ColumnInt(
      'jobId',
      this,
    );
    workspaceId = _is.ColumnInt(
      'workspaceId',
      this,
    );
    providerId = _is.ColumnString(
      'providerId',
      this,
    );
    leaseToken = _is.ColumnString(
      'leaseToken',
      this,
    );
    expiresAt = _is.ColumnDateTime(
      'expiresAt',
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

  late final ProviderAdmissionReservationUpdateTable updateTable;

  late final _is.ColumnInt jobId;

  late final _is.ColumnInt workspaceId;

  late final _is.ColumnString providerId;

  late final _is.ColumnString leaseToken;

  late final _is.ColumnDateTime expiresAt;

  late final _is.ColumnDateTime createdAt;

  late final _is.ColumnDateTime updatedAt;

  @override
  List<_is.Column> get columns => [
    id,
    jobId,
    workspaceId,
    providerId,
    leaseToken,
    expiresAt,
    createdAt,
    updatedAt,
  ];
}

class ProviderAdmissionReservationInclude extends _is.IncludeObject {
  ProviderAdmissionReservationInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => ProviderAdmissionReservation.t;
}

class ProviderAdmissionReservationIncludeList extends _is.IncludeList {
  ProviderAdmissionReservationIncludeList._({
    _is.WhereExpressionBuilder<ProviderAdmissionReservationTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ProviderAdmissionReservation.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => ProviderAdmissionReservation.t;
}

class ProviderAdmissionReservationRepository {
  const ProviderAdmissionReservationRepository._();

  /// Returns a list of [ProviderAdmissionReservation]s matching the given query parameters.
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
  Future<List<ProviderAdmissionReservation>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ProviderAdmissionReservationTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ProviderAdmissionReservationTable>? orderBy,
    _is.OrderByListBuilder<ProviderAdmissionReservationTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ProviderAdmissionReservation>(
      where: where?.call(ProviderAdmissionReservation.t),
      orderBy: orderBy?.call(ProviderAdmissionReservation.t),
      orderByList: orderByList?.call(ProviderAdmissionReservation.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [ProviderAdmissionReservation] matching the given query parameters.
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
  Future<ProviderAdmissionReservation?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ProviderAdmissionReservationTable>? where,
    int? offset,
    _is.OrderByBuilder<ProviderAdmissionReservationTable>? orderBy,
    _is.OrderByListBuilder<ProviderAdmissionReservationTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ProviderAdmissionReservation>(
      where: where?.call(ProviderAdmissionReservation.t),
      orderBy: orderBy?.call(ProviderAdmissionReservation.t),
      orderByList: orderByList?.call(ProviderAdmissionReservation.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ProviderAdmissionReservation] by its [id] or null if no such row exists.
  Future<ProviderAdmissionReservation?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ProviderAdmissionReservation>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ProviderAdmissionReservation]s in the list and returns the inserted rows.
  ///
  /// The returned [ProviderAdmissionReservation]s will have their `id` fields set.
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
  Future<List<ProviderAdmissionReservation>> insert(
    _is.DatabaseSession session,
    List<ProviderAdmissionReservation> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<ProviderAdmissionReservation>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [ProviderAdmissionReservation] and returns the inserted row.
  ///
  /// The returned [ProviderAdmissionReservation] will have its `id` field set.
  Future<ProviderAdmissionReservation> insertRow(
    _is.DatabaseSession session,
    ProviderAdmissionReservation row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<ProviderAdmissionReservation>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [ProviderAdmissionReservation]s in the list and returns the resulting rows.
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
  /// The returned [ProviderAdmissionReservation]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ProviderAdmissionReservation>> upsert(
    _is.DatabaseSession session,
    List<ProviderAdmissionReservation> rows, {
    required _is.ColumnSelections<ProviderAdmissionReservationTable>
    conflictColumns,
    _is.ColumnSelections<ProviderAdmissionReservationTable>? updateColumns,
    _is.WhereExpressionBuilder<ProviderAdmissionReservationTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<ProviderAdmissionReservation>(
      rows,
      conflictColumns: conflictColumns(ProviderAdmissionReservation.t),
      updateColumns: updateColumns?.call(ProviderAdmissionReservation.t),
      updateWhere: updateWhere?.call(ProviderAdmissionReservation.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [ProviderAdmissionReservation] and returns the resulting row.
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
  /// The returned [ProviderAdmissionReservation] will have its `id` field set.
  Future<ProviderAdmissionReservation?> upsertRow(
    _is.DatabaseSession session,
    ProviderAdmissionReservation row, {
    required _is.ColumnSelections<ProviderAdmissionReservationTable>
    conflictColumns,
    _is.ColumnSelections<ProviderAdmissionReservationTable>? updateColumns,
    _is.WhereExpressionBuilder<ProviderAdmissionReservationTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<ProviderAdmissionReservation>(
      row,
      conflictColumns: conflictColumns(ProviderAdmissionReservation.t),
      updateColumns: updateColumns?.call(ProviderAdmissionReservation.t),
      updateWhere: updateWhere?.call(ProviderAdmissionReservation.t),
      transaction: transaction,
    );
  }

  /// Updates all [ProviderAdmissionReservation]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ProviderAdmissionReservation>> update(
    _is.DatabaseSession session,
    List<ProviderAdmissionReservation> rows, {
    _is.ColumnSelections<ProviderAdmissionReservationTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<ProviderAdmissionReservation>(
      rows,
      columns: columns?.call(ProviderAdmissionReservation.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [ProviderAdmissionReservation]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ProviderAdmissionReservation> updateRow(
    _is.DatabaseSession session,
    ProviderAdmissionReservation row, {
    _is.ColumnSelections<ProviderAdmissionReservationTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<ProviderAdmissionReservation>(
      row,
      columns: columns?.call(ProviderAdmissionReservation.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ProviderAdmissionReservation] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ProviderAdmissionReservation?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<ProviderAdmissionReservationUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<ProviderAdmissionReservation>(
      id,
      columnValues: columnValues(ProviderAdmissionReservation.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ProviderAdmissionReservation]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ProviderAdmissionReservation>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<ProviderAdmissionReservationUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<ProviderAdmissionReservationTable>
    where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ProviderAdmissionReservationTable>? orderBy,
    _is.OrderByListBuilder<ProviderAdmissionReservationTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<ProviderAdmissionReservation>(
      columnValues: columnValues(ProviderAdmissionReservation.t.updateTable),
      where: where(ProviderAdmissionReservation.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ProviderAdmissionReservation.t),
      orderByList: orderByList?.call(ProviderAdmissionReservation.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [ProviderAdmissionReservation]s in the list and returns the deleted rows.
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
  Future<List<ProviderAdmissionReservation>> delete(
    _is.DatabaseSession session,
    List<ProviderAdmissionReservation> rows, {
    _is.OrderByBuilder<ProviderAdmissionReservationTable>? orderBy,
    _is.OrderByListBuilder<ProviderAdmissionReservationTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<ProviderAdmissionReservation>(
      rows,
      orderBy: orderBy?.call(ProviderAdmissionReservation.t),
      orderByList: orderByList?.call(ProviderAdmissionReservation.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [ProviderAdmissionReservation].
  Future<ProviderAdmissionReservation> deleteRow(
    _is.DatabaseSession session,
    ProviderAdmissionReservation row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ProviderAdmissionReservation>(
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
  Future<List<ProviderAdmissionReservation>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ProviderAdmissionReservationTable>
    where,
    _is.OrderByBuilder<ProviderAdmissionReservationTable>? orderBy,
    _is.OrderByListBuilder<ProviderAdmissionReservationTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<ProviderAdmissionReservation>(
      where: where(ProviderAdmissionReservation.t),
      orderBy: orderBy?.call(ProviderAdmissionReservation.t),
      orderByList: orderByList?.call(ProviderAdmissionReservation.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ProviderAdmissionReservationTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<ProviderAdmissionReservation>(
      where: where?.call(ProviderAdmissionReservation.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ProviderAdmissionReservation] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ProviderAdmissionReservationTable>
    where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ProviderAdmissionReservation>(
      where: where(ProviderAdmissionReservation.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
