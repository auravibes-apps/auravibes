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

abstract class WorkspaceInvite
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  WorkspaceInvite._({
    this.id,
    required this.workspaceId,
    required this.email,
    required this.role,
    required this.invitedByUserId,
    this.acceptedByUserId,
    required this.createdAt,
    this.expiresAt,
    this.acceptedAt,
    this.declinedAt,
    this.revokedAt,
    this.pendingKey,
  });

  factory WorkspaceInvite({
    int? id,
    required int workspaceId,
    required String email,
    required String role,
    required String invitedByUserId,
    String? acceptedByUserId,
    required DateTime createdAt,
    DateTime? expiresAt,
    DateTime? acceptedAt,
    DateTime? declinedAt,
    DateTime? revokedAt,
    String? pendingKey,
  }) = _WorkspaceInviteImpl;

  factory WorkspaceInvite.fromJson(Map<String, dynamic> jsonSerialization) {
    return WorkspaceInvite(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      email: jsonSerialization['email'] as String,
      role: jsonSerialization['role'] as String,
      invitedByUserId: jsonSerialization['invitedByUserId'] as String,
      acceptedByUserId: jsonSerialization['acceptedByUserId'] as String?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      expiresAt: jsonSerialization['expiresAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['expiresAt']),
      acceptedAt: jsonSerialization['acceptedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['acceptedAt']),
      declinedAt: jsonSerialization['declinedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['declinedAt']),
      revokedAt: jsonSerialization['revokedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['revokedAt']),
      pendingKey: jsonSerialization['pendingKey'] as String?,
    );
  }

  static final t = WorkspaceInviteTable();

  static const db = WorkspaceInviteRepository._();

  @override
  int? id;

  int workspaceId;

  String email;

  String role;

  String invitedByUserId;

  String? acceptedByUserId;

  DateTime createdAt;

  DateTime? expiresAt;

  DateTime? acceptedAt;

  DateTime? declinedAt;

  DateTime? revokedAt;

  String? pendingKey;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [WorkspaceInvite]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  WorkspaceInvite copyWith({
    int? id,
    int? workspaceId,
    String? email,
    String? role,
    String? invitedByUserId,
    String? acceptedByUserId,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? acceptedAt,
    DateTime? declinedAt,
    DateTime? revokedAt,
    String? pendingKey,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WorkspaceInvite',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'email': email,
      'role': role,
      'invitedByUserId': invitedByUserId,
      if (acceptedByUserId != null) 'acceptedByUserId': acceptedByUserId,
      'createdAt': createdAt.toJson(),
      if (expiresAt != null) 'expiresAt': expiresAt?.toJson(),
      if (acceptedAt != null) 'acceptedAt': acceptedAt?.toJson(),
      if (declinedAt != null) 'declinedAt': declinedAt?.toJson(),
      if (revokedAt != null) 'revokedAt': revokedAt?.toJson(),
      if (pendingKey != null) 'pendingKey': pendingKey,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WorkspaceInvite',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'email': email,
      'role': role,
      'invitedByUserId': invitedByUserId,
      if (acceptedByUserId != null) 'acceptedByUserId': acceptedByUserId,
      'createdAt': createdAt.toJson(),
      if (expiresAt != null) 'expiresAt': expiresAt?.toJson(),
      if (acceptedAt != null) 'acceptedAt': acceptedAt?.toJson(),
      if (declinedAt != null) 'declinedAt': declinedAt?.toJson(),
      if (revokedAt != null) 'revokedAt': revokedAt?.toJson(),
      if (pendingKey != null) 'pendingKey': pendingKey,
    };
  }

  static WorkspaceInviteInclude include() {
    return WorkspaceInviteInclude._();
  }

  static WorkspaceInviteIncludeList includeList({
    _i1.WhereExpressionBuilder<WorkspaceInviteTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<WorkspaceInviteTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<WorkspaceInviteTable>? orderByList,
    WorkspaceInviteInclude? include,
  }) {
    return WorkspaceInviteIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WorkspaceInvite.t),
      orderDescending: // ignore: deprecated_member_use_from_same_package
          orderDescending,
      orderByList: orderByList?.call(WorkspaceInvite.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WorkspaceInviteImpl extends WorkspaceInvite {
  _WorkspaceInviteImpl({
    int? id,
    required int workspaceId,
    required String email,
    required String role,
    required String invitedByUserId,
    String? acceptedByUserId,
    required DateTime createdAt,
    DateTime? expiresAt,
    DateTime? acceptedAt,
    DateTime? declinedAt,
    DateTime? revokedAt,
    String? pendingKey,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         email: email,
         role: role,
         invitedByUserId: invitedByUserId,
         acceptedByUserId: acceptedByUserId,
         createdAt: createdAt,
         expiresAt: expiresAt,
         acceptedAt: acceptedAt,
         declinedAt: declinedAt,
         revokedAt: revokedAt,
         pendingKey: pendingKey,
       );

  /// Returns a shallow copy of this [WorkspaceInvite]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  WorkspaceInvite copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    String? email,
    String? role,
    String? invitedByUserId,
    Object? acceptedByUserId = _Undefined,
    DateTime? createdAt,
    Object? expiresAt = _Undefined,
    Object? acceptedAt = _Undefined,
    Object? declinedAt = _Undefined,
    Object? revokedAt = _Undefined,
    Object? pendingKey = _Undefined,
  }) {
    return WorkspaceInvite(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      email: email ?? this.email,
      role: role ?? this.role,
      invitedByUserId: invitedByUserId ?? this.invitedByUserId,
      acceptedByUserId: acceptedByUserId is String?
          ? acceptedByUserId
          : this.acceptedByUserId,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt is DateTime? ? expiresAt : this.expiresAt,
      acceptedAt: acceptedAt is DateTime? ? acceptedAt : this.acceptedAt,
      declinedAt: declinedAt is DateTime? ? declinedAt : this.declinedAt,
      revokedAt: revokedAt is DateTime? ? revokedAt : this.revokedAt,
      pendingKey: pendingKey is String? ? pendingKey : this.pendingKey,
    );
  }
}

class WorkspaceInviteUpdateTable extends _i1.UpdateTable<WorkspaceInviteTable> {
  WorkspaceInviteUpdateTable(super.table);

  _i1.ColumnValue<int, int> workspaceId(int value) => _i1.ColumnValue(
    table.workspaceId,
    value,
  );

  _i1.ColumnValue<String, String> email(String value) => _i1.ColumnValue(
    table.email,
    value,
  );

  _i1.ColumnValue<String, String> role(String value) => _i1.ColumnValue(
    table.role,
    value,
  );

  _i1.ColumnValue<String, String> invitedByUserId(String value) =>
      _i1.ColumnValue(
        table.invitedByUserId,
        value,
      );

  _i1.ColumnValue<String, String> acceptedByUserId(String? value) =>
      _i1.ColumnValue(
        table.acceptedByUserId,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(
        table.createdAt,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> expiresAt(DateTime? value) =>
      _i1.ColumnValue(
        table.expiresAt,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> acceptedAt(DateTime? value) =>
      _i1.ColumnValue(
        table.acceptedAt,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> declinedAt(DateTime? value) =>
      _i1.ColumnValue(
        table.declinedAt,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> revokedAt(DateTime? value) =>
      _i1.ColumnValue(
        table.revokedAt,
        value,
      );

  _i1.ColumnValue<String, String> pendingKey(String? value) => _i1.ColumnValue(
    table.pendingKey,
    value,
  );
}

class WorkspaceInviteTable extends _i1.Table<int?> {
  WorkspaceInviteTable({super.tableRelation})
    : super(tableName: 'workspace_invite') {
    updateTable = WorkspaceInviteUpdateTable(this);
    workspaceId = _i1.ColumnInt(
      'workspaceId',
      this,
    );
    email = _i1.ColumnString(
      'email',
      this,
    );
    role = _i1.ColumnString(
      'role',
      this,
    );
    invitedByUserId = _i1.ColumnString(
      'invitedByUserId',
      this,
    );
    acceptedByUserId = _i1.ColumnString(
      'acceptedByUserId',
      this,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
    expiresAt = _i1.ColumnDateTime(
      'expiresAt',
      this,
    );
    acceptedAt = _i1.ColumnDateTime(
      'acceptedAt',
      this,
    );
    declinedAt = _i1.ColumnDateTime(
      'declinedAt',
      this,
    );
    revokedAt = _i1.ColumnDateTime(
      'revokedAt',
      this,
    );
    pendingKey = _i1.ColumnString(
      'pendingKey',
      this,
    );
  }

  late final WorkspaceInviteUpdateTable updateTable;

  late final _i1.ColumnInt workspaceId;

  late final _i1.ColumnString email;

  late final _i1.ColumnString role;

  late final _i1.ColumnString invitedByUserId;

  late final _i1.ColumnString acceptedByUserId;

  late final _i1.ColumnDateTime createdAt;

  late final _i1.ColumnDateTime expiresAt;

  late final _i1.ColumnDateTime acceptedAt;

  late final _i1.ColumnDateTime declinedAt;

  late final _i1.ColumnDateTime revokedAt;

  late final _i1.ColumnString pendingKey;

  @override
  List<_i1.Column> get columns => [
    id,
    workspaceId,
    email,
    role,
    invitedByUserId,
    acceptedByUserId,
    createdAt,
    expiresAt,
    acceptedAt,
    declinedAt,
    revokedAt,
    pendingKey,
  ];
}

class WorkspaceInviteInclude extends _i1.IncludeObject {
  WorkspaceInviteInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => WorkspaceInvite.t;
}

class WorkspaceInviteIncludeList extends _i1.IncludeList {
  WorkspaceInviteIncludeList._({
    _i1.WhereExpressionBuilder<WorkspaceInviteTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(WorkspaceInvite.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => WorkspaceInvite.t;
}

class WorkspaceInviteRepository {
  const WorkspaceInviteRepository._();

  /// Returns a list of [WorkspaceInvite]s matching the given query parameters.
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
  Future<List<WorkspaceInvite>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<WorkspaceInviteTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<WorkspaceInviteTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<WorkspaceInviteTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<WorkspaceInvite>(
      where: where?.call(WorkspaceInvite.t),
      orderBy: orderBy?.call(WorkspaceInvite.t),
      orderByList: orderByList?.call(WorkspaceInvite.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [WorkspaceInvite] matching the given query parameters.
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
  Future<WorkspaceInvite?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<WorkspaceInviteTable>? where,
    int? offset,
    _i1.OrderByBuilder<WorkspaceInviteTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<WorkspaceInviteTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<WorkspaceInvite>(
      where: where?.call(WorkspaceInvite.t),
      orderBy: orderBy?.call(WorkspaceInvite.t),
      orderByList: orderByList?.call(WorkspaceInvite.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [WorkspaceInvite] by its [id] or null if no such row exists.
  Future<WorkspaceInvite?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<WorkspaceInvite>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [WorkspaceInvite]s in the list and returns the inserted rows.
  ///
  /// The returned [WorkspaceInvite]s will have their `id` fields set.
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
  Future<List<WorkspaceInvite>> insert(
    _i1.DatabaseSession session,
    List<WorkspaceInvite> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<WorkspaceInvite>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [WorkspaceInvite] and returns the inserted row.
  ///
  /// The returned [WorkspaceInvite] will have its `id` field set.
  Future<WorkspaceInvite> insertRow(
    _i1.DatabaseSession session,
    WorkspaceInvite row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<WorkspaceInvite>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [WorkspaceInvite]s in the list and returns the resulting rows.
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
  /// The returned [WorkspaceInvite]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WorkspaceInvite>> upsert(
    _i1.DatabaseSession session,
    List<WorkspaceInvite> rows, {
    required _i1.ColumnSelections<WorkspaceInviteTable> conflictColumns,
    _i1.ColumnSelections<WorkspaceInviteTable>? updateColumns,
    _i1.WhereExpressionBuilder<WorkspaceInviteTable>? updateWhere,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<WorkspaceInvite>(
      rows,
      conflictColumns: conflictColumns(WorkspaceInvite.t),
      updateColumns: updateColumns?.call(WorkspaceInvite.t),
      updateWhere: updateWhere?.call(WorkspaceInvite.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [WorkspaceInvite] and returns the resulting row.
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
  /// The returned [WorkspaceInvite] will have its `id` field set.
  Future<WorkspaceInvite?> upsertRow(
    _i1.DatabaseSession session,
    WorkspaceInvite row, {
    required _i1.ColumnSelections<WorkspaceInviteTable> conflictColumns,
    _i1.ColumnSelections<WorkspaceInviteTable>? updateColumns,
    _i1.WhereExpressionBuilder<WorkspaceInviteTable>? updateWhere,
    _i1.Transaction? transaction,
  }) async {
    return session.db.upsertRow<WorkspaceInvite>(
      row,
      conflictColumns: conflictColumns(WorkspaceInvite.t),
      updateColumns: updateColumns?.call(WorkspaceInvite.t),
      updateWhere: updateWhere?.call(WorkspaceInvite.t),
      transaction: transaction,
    );
  }

  /// Updates all [WorkspaceInvite]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WorkspaceInvite>> update(
    _i1.DatabaseSession session,
    List<WorkspaceInvite> rows, {
    _i1.ColumnSelections<WorkspaceInviteTable>? columns,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<WorkspaceInvite>(
      rows,
      columns: columns?.call(WorkspaceInvite.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [WorkspaceInvite]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<WorkspaceInvite> updateRow(
    _i1.DatabaseSession session,
    WorkspaceInvite row, {
    _i1.ColumnSelections<WorkspaceInviteTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<WorkspaceInvite>(
      row,
      columns: columns?.call(WorkspaceInvite.t),
      transaction: transaction,
    );
  }

  /// Updates a single [WorkspaceInvite] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<WorkspaceInvite?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<WorkspaceInviteUpdateTable>
    columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<WorkspaceInvite>(
      id,
      columnValues: columnValues(WorkspaceInvite.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [WorkspaceInvite]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WorkspaceInvite>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<WorkspaceInviteUpdateTable>
    columnValues,
    required _i1.WhereExpressionBuilder<WorkspaceInviteTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<WorkspaceInviteTable>? orderBy,
    _i1.OrderByListBuilder<WorkspaceInviteTable>? orderByList,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<WorkspaceInvite>(
      columnValues: columnValues(WorkspaceInvite.t.updateTable),
      where: where(WorkspaceInvite.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WorkspaceInvite.t),
      orderByList: orderByList?.call(WorkspaceInvite.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [WorkspaceInvite]s in the list and returns the deleted rows.
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
  Future<List<WorkspaceInvite>> delete(
    _i1.DatabaseSession session,
    List<WorkspaceInvite> rows, {
    _i1.OrderByBuilder<WorkspaceInviteTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<WorkspaceInviteTable>? orderByList,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<WorkspaceInvite>(
      rows,
      orderBy: orderBy?.call(WorkspaceInvite.t),
      orderByList: orderByList?.call(WorkspaceInvite.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [WorkspaceInvite].
  Future<WorkspaceInvite> deleteRow(
    _i1.DatabaseSession session,
    WorkspaceInvite row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<WorkspaceInvite>(
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
  Future<List<WorkspaceInvite>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<WorkspaceInviteTable> where,
    _i1.OrderByBuilder<WorkspaceInviteTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<WorkspaceInviteTable>? orderByList,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<WorkspaceInvite>(
      where: where(WorkspaceInvite.t),
      orderBy: orderBy?.call(WorkspaceInvite.t),
      orderByList: orderByList?.call(WorkspaceInvite.t),
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
    _i1.WhereExpressionBuilder<WorkspaceInviteTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<WorkspaceInvite>(
      where: where?.call(WorkspaceInvite.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [WorkspaceInvite] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<WorkspaceInviteTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<WorkspaceInvite>(
      where: where(WorkspaceInvite.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
