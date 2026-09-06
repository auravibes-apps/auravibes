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

abstract class WorkspaceInvite
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  WorkspaceInvite._({
    this.id,
    required this.workspaceId,
    required this.email,
    required this.normalizedEmail,
    required this.role,
    required this.invitedByUserId,
    this.acceptedByUserId,
    required this.revision,
    required this.createdAt,
    required this.updatedAt,
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
    required String normalizedEmail,
    required String role,
    required String invitedByUserId,
    String? acceptedByUserId,
    required int revision,
    required DateTime createdAt,
    required DateTime updatedAt,
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
      normalizedEmail: jsonSerialization['normalizedEmail'] as String,
      role: jsonSerialization['role'] as String,
      invitedByUserId: jsonSerialization['invitedByUserId'] as String,
      acceptedByUserId: jsonSerialization['acceptedByUserId'] as String?,
      revision: jsonSerialization['revision'] as int,
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
      expiresAt: jsonSerialization['expiresAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['expiresAt']),
      acceptedAt: jsonSerialization['acceptedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['acceptedAt']),
      declinedAt: jsonSerialization['declinedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['declinedAt']),
      revokedAt: jsonSerialization['revokedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['revokedAt']),
      pendingKey: jsonSerialization['pendingKey'] as String?,
    );
  }

  static final t = WorkspaceInviteTable();

  static const db = WorkspaceInviteRepository._();

  @override
  int? id;

  int workspaceId;

  String email;

  String normalizedEmail;

  String role;

  String invitedByUserId;

  String? acceptedByUserId;

  int revision;

  DateTime createdAt;

  DateTime updatedAt;

  DateTime? expiresAt;

  DateTime? acceptedAt;

  DateTime? declinedAt;

  DateTime? revokedAt;

  String? pendingKey;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [WorkspaceInvite]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  WorkspaceInvite copyWith({
    int? id,
    int? workspaceId,
    String? email,
    String? normalizedEmail,
    String? role,
    String? invitedByUserId,
    String? acceptedByUserId,
    int? revision,
    DateTime? createdAt,
    DateTime? updatedAt,
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
      'normalizedEmail': normalizedEmail,
      'role': role,
      'invitedByUserId': invitedByUserId,
      if (acceptedByUserId != null) 'acceptedByUserId': acceptedByUserId,
      'revision': revision,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
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
      'normalizedEmail': normalizedEmail,
      'role': role,
      'invitedByUserId': invitedByUserId,
      if (acceptedByUserId != null) 'acceptedByUserId': acceptedByUserId,
      'revision': revision,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
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
    _is.WhereExpressionBuilder<WorkspaceInviteTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<WorkspaceInviteTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceInviteTable>? orderByList,
    WorkspaceInviteInclude? include,
  }) {
    return WorkspaceInviteIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WorkspaceInvite.t),
      orderByList: orderByList?.call(WorkspaceInvite.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WorkspaceInviteImpl extends WorkspaceInvite {
  _WorkspaceInviteImpl({
    int? id,
    required int workspaceId,
    required String email,
    required String normalizedEmail,
    required String role,
    required String invitedByUserId,
    String? acceptedByUserId,
    required int revision,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? expiresAt,
    DateTime? acceptedAt,
    DateTime? declinedAt,
    DateTime? revokedAt,
    String? pendingKey,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         email: email,
         normalizedEmail: normalizedEmail,
         role: role,
         invitedByUserId: invitedByUserId,
         acceptedByUserId: acceptedByUserId,
         revision: revision,
         createdAt: createdAt,
         updatedAt: updatedAt,
         expiresAt: expiresAt,
         acceptedAt: acceptedAt,
         declinedAt: declinedAt,
         revokedAt: revokedAt,
         pendingKey: pendingKey,
       );

  /// Returns a shallow copy of this [WorkspaceInvite]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  WorkspaceInvite copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    String? email,
    String? normalizedEmail,
    String? role,
    String? invitedByUserId,
    Object? acceptedByUserId = _Undefined,
    int? revision,
    DateTime? createdAt,
    DateTime? updatedAt,
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
      normalizedEmail: normalizedEmail ?? this.normalizedEmail,
      role: role ?? this.role,
      invitedByUserId: invitedByUserId ?? this.invitedByUserId,
      acceptedByUserId: acceptedByUserId is String?
          ? acceptedByUserId
          : this.acceptedByUserId,
      revision: revision ?? this.revision,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expiresAt: expiresAt is DateTime? ? expiresAt : this.expiresAt,
      acceptedAt: acceptedAt is DateTime? ? acceptedAt : this.acceptedAt,
      declinedAt: declinedAt is DateTime? ? declinedAt : this.declinedAt,
      revokedAt: revokedAt is DateTime? ? revokedAt : this.revokedAt,
      pendingKey: pendingKey is String? ? pendingKey : this.pendingKey,
    );
  }
}

class WorkspaceInviteUpdateTable extends _is.UpdateTable<WorkspaceInviteTable> {
  WorkspaceInviteUpdateTable(super.table);

  _is.ColumnValue<int, int> workspaceId(int value) => _is.ColumnValue(
    table.workspaceId,
    value,
  );

  _is.ColumnValue<String, String> email(String value) => _is.ColumnValue(
    table.email,
    value,
  );

  _is.ColumnValue<String, String> normalizedEmail(String value) =>
      _is.ColumnValue(
        table.normalizedEmail,
        value,
      );

  _is.ColumnValue<String, String> role(String value) => _is.ColumnValue(
    table.role,
    value,
  );

  _is.ColumnValue<String, String> invitedByUserId(String value) =>
      _is.ColumnValue(
        table.invitedByUserId,
        value,
      );

  _is.ColumnValue<String, String> acceptedByUserId(String? value) =>
      _is.ColumnValue(
        table.acceptedByUserId,
        value,
      );

  _is.ColumnValue<int, int> revision(int value) => _is.ColumnValue(
    table.revision,
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

  _is.ColumnValue<DateTime, DateTime> expiresAt(DateTime? value) =>
      _is.ColumnValue(
        table.expiresAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> acceptedAt(DateTime? value) =>
      _is.ColumnValue(
        table.acceptedAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> declinedAt(DateTime? value) =>
      _is.ColumnValue(
        table.declinedAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> revokedAt(DateTime? value) =>
      _is.ColumnValue(
        table.revokedAt,
        value,
      );

  _is.ColumnValue<String, String> pendingKey(String? value) => _is.ColumnValue(
    table.pendingKey,
    value,
  );
}

class WorkspaceInviteTable extends _is.Table<int?> {
  WorkspaceInviteTable({super.tableRelation})
    : super(tableName: 'workspace_invite') {
    updateTable = WorkspaceInviteUpdateTable(this);
    workspaceId = _is.ColumnInt(
      'workspaceId',
      this,
    );
    email = _is.ColumnString(
      'email',
      this,
    );
    normalizedEmail = _is.ColumnString(
      'normalizedEmail',
      this,
    );
    role = _is.ColumnString(
      'role',
      this,
    );
    invitedByUserId = _is.ColumnString(
      'invitedByUserId',
      this,
    );
    acceptedByUserId = _is.ColumnString(
      'acceptedByUserId',
      this,
    );
    revision = _is.ColumnInt(
      'revision',
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
    expiresAt = _is.ColumnDateTime(
      'expiresAt',
      this,
    );
    acceptedAt = _is.ColumnDateTime(
      'acceptedAt',
      this,
    );
    declinedAt = _is.ColumnDateTime(
      'declinedAt',
      this,
    );
    revokedAt = _is.ColumnDateTime(
      'revokedAt',
      this,
    );
    pendingKey = _is.ColumnString(
      'pendingKey',
      this,
    );
  }

  late final WorkspaceInviteUpdateTable updateTable;

  late final _is.ColumnInt workspaceId;

  late final _is.ColumnString email;

  late final _is.ColumnString normalizedEmail;

  late final _is.ColumnString role;

  late final _is.ColumnString invitedByUserId;

  late final _is.ColumnString acceptedByUserId;

  late final _is.ColumnInt revision;

  late final _is.ColumnDateTime createdAt;

  late final _is.ColumnDateTime updatedAt;

  late final _is.ColumnDateTime expiresAt;

  late final _is.ColumnDateTime acceptedAt;

  late final _is.ColumnDateTime declinedAt;

  late final _is.ColumnDateTime revokedAt;

  late final _is.ColumnString pendingKey;

  @override
  List<_is.Column> get columns => [
    id,
    workspaceId,
    email,
    normalizedEmail,
    role,
    invitedByUserId,
    acceptedByUserId,
    revision,
    createdAt,
    updatedAt,
    expiresAt,
    acceptedAt,
    declinedAt,
    revokedAt,
    pendingKey,
  ];
}

class WorkspaceInviteInclude extends _is.IncludeObject {
  WorkspaceInviteInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => WorkspaceInvite.t;
}

class WorkspaceInviteIncludeList extends _is.IncludeList {
  WorkspaceInviteIncludeList._({
    _is.WhereExpressionBuilder<WorkspaceInviteTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(WorkspaceInvite.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => WorkspaceInvite.t;
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
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<WorkspaceInviteTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<WorkspaceInviteTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceInviteTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<WorkspaceInvite>(
      where: where?.call(WorkspaceInvite.t),
      orderBy: orderBy?.call(WorkspaceInvite.t),
      orderByList: orderByList?.call(WorkspaceInvite.t),
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
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<WorkspaceInviteTable>? where,
    int? offset,
    _is.OrderByBuilder<WorkspaceInviteTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceInviteTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<WorkspaceInvite>(
      where: where?.call(WorkspaceInvite.t),
      orderBy: orderBy?.call(WorkspaceInvite.t),
      orderByList: orderByList?.call(WorkspaceInvite.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [WorkspaceInvite] by its [id] or null if no such row exists.
  Future<WorkspaceInvite?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
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
    _is.DatabaseSession session,
    List<WorkspaceInvite> rows, {
    _is.Transaction? transaction,
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
    _is.DatabaseSession session,
    WorkspaceInvite row, {
    _is.Transaction? transaction,
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
    _is.DatabaseSession session,
    List<WorkspaceInvite> rows, {
    required _is.ColumnSelections<WorkspaceInviteTable> conflictColumns,
    _is.ColumnSelections<WorkspaceInviteTable>? updateColumns,
    _is.WhereExpressionBuilder<WorkspaceInviteTable>? updateWhere,
    _is.Transaction? transaction,
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
    _is.DatabaseSession session,
    WorkspaceInvite row, {
    required _is.ColumnSelections<WorkspaceInviteTable> conflictColumns,
    _is.ColumnSelections<WorkspaceInviteTable>? updateColumns,
    _is.WhereExpressionBuilder<WorkspaceInviteTable>? updateWhere,
    _is.Transaction? transaction,
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
    _is.DatabaseSession session,
    List<WorkspaceInvite> rows, {
    _is.ColumnSelections<WorkspaceInviteTable>? columns,
    _is.Transaction? transaction,
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
    _is.DatabaseSession session,
    WorkspaceInvite row, {
    _is.ColumnSelections<WorkspaceInviteTable>? columns,
    _is.Transaction? transaction,
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
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<WorkspaceInviteUpdateTable>
    columnValues,
    _is.Transaction? transaction,
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
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<WorkspaceInviteUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<WorkspaceInviteTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<WorkspaceInviteTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceInviteTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<WorkspaceInvite>(
      columnValues: columnValues(WorkspaceInvite.t.updateTable),
      where: where(WorkspaceInvite.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WorkspaceInvite.t),
      orderByList: orderByList?.call(WorkspaceInvite.t),
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
    _is.DatabaseSession session,
    List<WorkspaceInvite> rows, {
    _is.OrderByBuilder<WorkspaceInviteTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceInviteTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<WorkspaceInvite>(
      rows,
      orderBy: orderBy?.call(WorkspaceInvite.t),
      orderByList: orderByList?.call(WorkspaceInvite.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [WorkspaceInvite].
  Future<WorkspaceInvite> deleteRow(
    _is.DatabaseSession session,
    WorkspaceInvite row, {
    _is.Transaction? transaction,
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
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<WorkspaceInviteTable> where,
    _is.OrderByBuilder<WorkspaceInviteTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceInviteTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<WorkspaceInvite>(
      where: where(WorkspaceInvite.t),
      orderBy: orderBy?.call(WorkspaceInvite.t),
      orderByList: orderByList?.call(WorkspaceInvite.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<WorkspaceInviteTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<WorkspaceInvite>(
      where: where?.call(WorkspaceInvite.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [WorkspaceInvite] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<WorkspaceInviteTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<WorkspaceInvite>(
      where: where(WorkspaceInvite.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
