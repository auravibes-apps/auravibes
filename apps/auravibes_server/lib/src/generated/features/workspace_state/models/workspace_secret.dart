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
import '../../../features/workspace_state/models/workspace_secret_kind.dart'
    as _i2;
import '../../../features/workspace_state/models/workspace_secret_scope.dart'
    as _i3;
import 'dart:typed_data' as _i4;

abstract class WorkspaceSecret
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  WorkspaceSecret._({
    this.id,
    required this.workspaceId,
    required this.secretKind,
    required this.scope,
    required this.ownerUserId,
    required this.resourceId,
    required this.ciphertext,
    required this.nonce,
    required this.authenticationTag,
    required this.algorithm,
    required this.keyVersion,
    this.displaySuffix,
    required this.revision,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory WorkspaceSecret({
    int? id,
    required int workspaceId,
    required _i2.WorkspaceSecretKind secretKind,
    required _i3.WorkspaceSecretScope scope,
    required String ownerUserId,
    required String resourceId,
    required _i4.ByteData ciphertext,
    required _i4.ByteData nonce,
    required _i4.ByteData authenticationTag,
    required String algorithm,
    required int keyVersion,
    String? displaySuffix,
    required int revision,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
  }) = _WorkspaceSecretImpl;

  factory WorkspaceSecret.fromJson(Map<String, dynamic> jsonSerialization) {
    return WorkspaceSecret(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      secretKind: _i2.WorkspaceSecretKind.fromJson(
        (jsonSerialization['secretKind'] as String),
      ),
      scope: _i3.WorkspaceSecretScope.fromJson(
        (jsonSerialization['scope'] as String),
      ),
      ownerUserId: jsonSerialization['ownerUserId'] as String,
      resourceId: jsonSerialization['resourceId'] as String,
      ciphertext: _i1.ByteDataJsonExtension.fromJson(
        jsonSerialization['ciphertext'],
      ),
      nonce: _i1.ByteDataJsonExtension.fromJson(jsonSerialization['nonce']),
      authenticationTag: _i1.ByteDataJsonExtension.fromJson(
        jsonSerialization['authenticationTag'],
      ),
      algorithm: jsonSerialization['algorithm'] as String,
      keyVersion: jsonSerialization['keyVersion'] as int,
      displaySuffix: jsonSerialization['displaySuffix'] as String?,
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

  static final t = WorkspaceSecretTable();

  static const db = WorkspaceSecretRepository._();

  @override
  int? id;

  int workspaceId;

  _i2.WorkspaceSecretKind secretKind;

  _i3.WorkspaceSecretScope scope;

  String ownerUserId;

  String resourceId;

  _i4.ByteData ciphertext;

  _i4.ByteData nonce;

  _i4.ByteData authenticationTag;

  String algorithm;

  int keyVersion;

  String? displaySuffix;

  int revision;

  DateTime createdAt;

  DateTime updatedAt;

  DateTime? deletedAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [WorkspaceSecret]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  WorkspaceSecret copyWith({
    int? id,
    int? workspaceId,
    _i2.WorkspaceSecretKind? secretKind,
    _i3.WorkspaceSecretScope? scope,
    String? ownerUserId,
    String? resourceId,
    _i4.ByteData? ciphertext,
    _i4.ByteData? nonce,
    _i4.ByteData? authenticationTag,
    String? algorithm,
    int? keyVersion,
    String? displaySuffix,
    int? revision,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WorkspaceSecret',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'secretKind': secretKind.toJson(),
      'scope': scope.toJson(),
      'ownerUserId': ownerUserId,
      'resourceId': resourceId,
      'ciphertext': ciphertext.toJson(),
      'nonce': nonce.toJson(),
      'authenticationTag': authenticationTag.toJson(),
      'algorithm': algorithm,
      'keyVersion': keyVersion,
      if (displaySuffix != null) 'displaySuffix': displaySuffix,
      'revision': revision,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      if (deletedAt != null) 'deletedAt': deletedAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WorkspaceSecret',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'secretKind': secretKind.toJson(),
      'scope': scope.toJson(),
      'ownerUserId': ownerUserId,
      'resourceId': resourceId,
      'ciphertext': ciphertext.toJson(),
      'nonce': nonce.toJson(),
      'authenticationTag': authenticationTag.toJson(),
      'algorithm': algorithm,
      'keyVersion': keyVersion,
      if (displaySuffix != null) 'displaySuffix': displaySuffix,
      'revision': revision,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      if (deletedAt != null) 'deletedAt': deletedAt?.toJson(),
    };
  }

  static WorkspaceSecretInclude include() {
    return WorkspaceSecretInclude._();
  }

  static WorkspaceSecretIncludeList includeList({
    _i1.WhereExpressionBuilder<WorkspaceSecretTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<WorkspaceSecretTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<WorkspaceSecretTable>? orderByList,
    WorkspaceSecretInclude? include,
  }) {
    return WorkspaceSecretIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WorkspaceSecret.t),
      orderDescending: // ignore: deprecated_member_use_from_same_package
          orderDescending,
      orderByList: orderByList?.call(WorkspaceSecret.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WorkspaceSecretImpl extends WorkspaceSecret {
  _WorkspaceSecretImpl({
    int? id,
    required int workspaceId,
    required _i2.WorkspaceSecretKind secretKind,
    required _i3.WorkspaceSecretScope scope,
    required String ownerUserId,
    required String resourceId,
    required _i4.ByteData ciphertext,
    required _i4.ByteData nonce,
    required _i4.ByteData authenticationTag,
    required String algorithm,
    required int keyVersion,
    String? displaySuffix,
    required int revision,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         secretKind: secretKind,
         scope: scope,
         ownerUserId: ownerUserId,
         resourceId: resourceId,
         ciphertext: ciphertext,
         nonce: nonce,
         authenticationTag: authenticationTag,
         algorithm: algorithm,
         keyVersion: keyVersion,
         displaySuffix: displaySuffix,
         revision: revision,
         createdAt: createdAt,
         updatedAt: updatedAt,
         deletedAt: deletedAt,
       );

  /// Returns a shallow copy of this [WorkspaceSecret]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  WorkspaceSecret copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    _i2.WorkspaceSecretKind? secretKind,
    _i3.WorkspaceSecretScope? scope,
    String? ownerUserId,
    String? resourceId,
    _i4.ByteData? ciphertext,
    _i4.ByteData? nonce,
    _i4.ByteData? authenticationTag,
    String? algorithm,
    int? keyVersion,
    Object? displaySuffix = _Undefined,
    int? revision,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? deletedAt = _Undefined,
  }) {
    return WorkspaceSecret(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      secretKind: secretKind ?? this.secretKind,
      scope: scope ?? this.scope,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      resourceId: resourceId ?? this.resourceId,
      ciphertext: ciphertext ?? this.ciphertext.clone(),
      nonce: nonce ?? this.nonce.clone(),
      authenticationTag: authenticationTag ?? this.authenticationTag.clone(),
      algorithm: algorithm ?? this.algorithm,
      keyVersion: keyVersion ?? this.keyVersion,
      displaySuffix: displaySuffix is String?
          ? displaySuffix
          : this.displaySuffix,
      revision: revision ?? this.revision,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt is DateTime? ? deletedAt : this.deletedAt,
    );
  }
}

class WorkspaceSecretUpdateTable extends _i1.UpdateTable<WorkspaceSecretTable> {
  WorkspaceSecretUpdateTable(super.table);

  _i1.ColumnValue<int, int> workspaceId(int value) => _i1.ColumnValue(
    table.workspaceId,
    value,
  );

  _i1.ColumnValue<_i2.WorkspaceSecretKind, _i2.WorkspaceSecretKind> secretKind(
    _i2.WorkspaceSecretKind value,
  ) => _i1.ColumnValue(
    table.secretKind,
    value,
  );

  _i1.ColumnValue<_i3.WorkspaceSecretScope, _i3.WorkspaceSecretScope> scope(
    _i3.WorkspaceSecretScope value,
  ) => _i1.ColumnValue(
    table.scope,
    value,
  );

  _i1.ColumnValue<String, String> ownerUserId(String value) => _i1.ColumnValue(
    table.ownerUserId,
    value,
  );

  _i1.ColumnValue<String, String> resourceId(String value) => _i1.ColumnValue(
    table.resourceId,
    value,
  );

  _i1.ColumnValue<_i4.ByteData, _i4.ByteData> ciphertext(_i4.ByteData value) =>
      _i1.ColumnValue(
        table.ciphertext,
        value,
      );

  _i1.ColumnValue<_i4.ByteData, _i4.ByteData> nonce(_i4.ByteData value) =>
      _i1.ColumnValue(
        table.nonce,
        value,
      );

  _i1.ColumnValue<_i4.ByteData, _i4.ByteData> authenticationTag(
    _i4.ByteData value,
  ) => _i1.ColumnValue(
    table.authenticationTag,
    value,
  );

  _i1.ColumnValue<String, String> algorithm(String value) => _i1.ColumnValue(
    table.algorithm,
    value,
  );

  _i1.ColumnValue<int, int> keyVersion(int value) => _i1.ColumnValue(
    table.keyVersion,
    value,
  );

  _i1.ColumnValue<String, String> displaySuffix(String? value) =>
      _i1.ColumnValue(
        table.displaySuffix,
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

class WorkspaceSecretTable extends _i1.Table<int?> {
  WorkspaceSecretTable({super.tableRelation})
    : super(tableName: 'workspace_secret') {
    updateTable = WorkspaceSecretUpdateTable(this);
    workspaceId = _i1.ColumnInt(
      'workspaceId',
      this,
    );
    secretKind = _i1.ColumnEnum(
      'secretKind',
      this,
      _i1.EnumSerialization.byName,
    );
    scope = _i1.ColumnEnum(
      'scope',
      this,
      _i1.EnumSerialization.byName,
    );
    ownerUserId = _i1.ColumnString(
      'ownerUserId',
      this,
    );
    resourceId = _i1.ColumnString(
      'resourceId',
      this,
    );
    ciphertext = _i1.ColumnByteData(
      'ciphertext',
      this,
    );
    nonce = _i1.ColumnByteData(
      'nonce',
      this,
    );
    authenticationTag = _i1.ColumnByteData(
      'authenticationTag',
      this,
    );
    algorithm = _i1.ColumnString(
      'algorithm',
      this,
    );
    keyVersion = _i1.ColumnInt(
      'keyVersion',
      this,
    );
    displaySuffix = _i1.ColumnString(
      'displaySuffix',
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

  late final WorkspaceSecretUpdateTable updateTable;

  late final _i1.ColumnInt workspaceId;

  late final _i1.ColumnEnum<_i2.WorkspaceSecretKind> secretKind;

  late final _i1.ColumnEnum<_i3.WorkspaceSecretScope> scope;

  late final _i1.ColumnString ownerUserId;

  late final _i1.ColumnString resourceId;

  late final _i1.ColumnByteData ciphertext;

  late final _i1.ColumnByteData nonce;

  late final _i1.ColumnByteData authenticationTag;

  late final _i1.ColumnString algorithm;

  late final _i1.ColumnInt keyVersion;

  late final _i1.ColumnString displaySuffix;

  late final _i1.ColumnInt revision;

  late final _i1.ColumnDateTime createdAt;

  late final _i1.ColumnDateTime updatedAt;

  late final _i1.ColumnDateTime deletedAt;

  @override
  List<_i1.Column> get columns => [
    id,
    workspaceId,
    secretKind,
    scope,
    ownerUserId,
    resourceId,
    ciphertext,
    nonce,
    authenticationTag,
    algorithm,
    keyVersion,
    displaySuffix,
    revision,
    createdAt,
    updatedAt,
    deletedAt,
  ];
}

class WorkspaceSecretInclude extends _i1.IncludeObject {
  WorkspaceSecretInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => WorkspaceSecret.t;
}

class WorkspaceSecretIncludeList extends _i1.IncludeList {
  WorkspaceSecretIncludeList._({
    _i1.WhereExpressionBuilder<WorkspaceSecretTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(WorkspaceSecret.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => WorkspaceSecret.t;
}

class WorkspaceSecretRepository {
  const WorkspaceSecretRepository._();

  /// Returns a list of [WorkspaceSecret]s matching the given query parameters.
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
  Future<List<WorkspaceSecret>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<WorkspaceSecretTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<WorkspaceSecretTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<WorkspaceSecretTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<WorkspaceSecret>(
      where: where?.call(WorkspaceSecret.t),
      orderBy: orderBy?.call(WorkspaceSecret.t),
      orderByList: orderByList?.call(WorkspaceSecret.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [WorkspaceSecret] matching the given query parameters.
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
  Future<WorkspaceSecret?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<WorkspaceSecretTable>? where,
    int? offset,
    _i1.OrderByBuilder<WorkspaceSecretTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<WorkspaceSecretTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<WorkspaceSecret>(
      where: where?.call(WorkspaceSecret.t),
      orderBy: orderBy?.call(WorkspaceSecret.t),
      orderByList: orderByList?.call(WorkspaceSecret.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [WorkspaceSecret] by its [id] or null if no such row exists.
  Future<WorkspaceSecret?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<WorkspaceSecret>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [WorkspaceSecret]s in the list and returns the inserted rows.
  ///
  /// The returned [WorkspaceSecret]s will have their `id` fields set.
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
  Future<List<WorkspaceSecret>> insert(
    _i1.DatabaseSession session,
    List<WorkspaceSecret> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<WorkspaceSecret>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [WorkspaceSecret] and returns the inserted row.
  ///
  /// The returned [WorkspaceSecret] will have its `id` field set.
  Future<WorkspaceSecret> insertRow(
    _i1.DatabaseSession session,
    WorkspaceSecret row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<WorkspaceSecret>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [WorkspaceSecret]s in the list and returns the resulting rows.
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
  /// The returned [WorkspaceSecret]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WorkspaceSecret>> upsert(
    _i1.DatabaseSession session,
    List<WorkspaceSecret> rows, {
    required _i1.ColumnSelections<WorkspaceSecretTable> conflictColumns,
    _i1.ColumnSelections<WorkspaceSecretTable>? updateColumns,
    _i1.WhereExpressionBuilder<WorkspaceSecretTable>? updateWhere,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<WorkspaceSecret>(
      rows,
      conflictColumns: conflictColumns(WorkspaceSecret.t),
      updateColumns: updateColumns?.call(WorkspaceSecret.t),
      updateWhere: updateWhere?.call(WorkspaceSecret.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [WorkspaceSecret] and returns the resulting row.
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
  /// The returned [WorkspaceSecret] will have its `id` field set.
  Future<WorkspaceSecret?> upsertRow(
    _i1.DatabaseSession session,
    WorkspaceSecret row, {
    required _i1.ColumnSelections<WorkspaceSecretTable> conflictColumns,
    _i1.ColumnSelections<WorkspaceSecretTable>? updateColumns,
    _i1.WhereExpressionBuilder<WorkspaceSecretTable>? updateWhere,
    _i1.Transaction? transaction,
  }) async {
    return session.db.upsertRow<WorkspaceSecret>(
      row,
      conflictColumns: conflictColumns(WorkspaceSecret.t),
      updateColumns: updateColumns?.call(WorkspaceSecret.t),
      updateWhere: updateWhere?.call(WorkspaceSecret.t),
      transaction: transaction,
    );
  }

  /// Updates all [WorkspaceSecret]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WorkspaceSecret>> update(
    _i1.DatabaseSession session,
    List<WorkspaceSecret> rows, {
    _i1.ColumnSelections<WorkspaceSecretTable>? columns,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<WorkspaceSecret>(
      rows,
      columns: columns?.call(WorkspaceSecret.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [WorkspaceSecret]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<WorkspaceSecret> updateRow(
    _i1.DatabaseSession session,
    WorkspaceSecret row, {
    _i1.ColumnSelections<WorkspaceSecretTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<WorkspaceSecret>(
      row,
      columns: columns?.call(WorkspaceSecret.t),
      transaction: transaction,
    );
  }

  /// Updates a single [WorkspaceSecret] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<WorkspaceSecret?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<WorkspaceSecretUpdateTable>
    columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<WorkspaceSecret>(
      id,
      columnValues: columnValues(WorkspaceSecret.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [WorkspaceSecret]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WorkspaceSecret>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<WorkspaceSecretUpdateTable>
    columnValues,
    required _i1.WhereExpressionBuilder<WorkspaceSecretTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<WorkspaceSecretTable>? orderBy,
    _i1.OrderByListBuilder<WorkspaceSecretTable>? orderByList,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<WorkspaceSecret>(
      columnValues: columnValues(WorkspaceSecret.t.updateTable),
      where: where(WorkspaceSecret.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WorkspaceSecret.t),
      orderByList: orderByList?.call(WorkspaceSecret.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [WorkspaceSecret]s in the list and returns the deleted rows.
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
  Future<List<WorkspaceSecret>> delete(
    _i1.DatabaseSession session,
    List<WorkspaceSecret> rows, {
    _i1.OrderByBuilder<WorkspaceSecretTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<WorkspaceSecretTable>? orderByList,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<WorkspaceSecret>(
      rows,
      orderBy: orderBy?.call(WorkspaceSecret.t),
      orderByList: orderByList?.call(WorkspaceSecret.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [WorkspaceSecret].
  Future<WorkspaceSecret> deleteRow(
    _i1.DatabaseSession session,
    WorkspaceSecret row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<WorkspaceSecret>(
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
  Future<List<WorkspaceSecret>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<WorkspaceSecretTable> where,
    _i1.OrderByBuilder<WorkspaceSecretTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<WorkspaceSecretTable>? orderByList,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<WorkspaceSecret>(
      where: where(WorkspaceSecret.t),
      orderBy: orderBy?.call(WorkspaceSecret.t),
      orderByList: orderByList?.call(WorkspaceSecret.t),
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
    _i1.WhereExpressionBuilder<WorkspaceSecretTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<WorkspaceSecret>(
      where: where?.call(WorkspaceSecret.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [WorkspaceSecret] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<WorkspaceSecretTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<WorkspaceSecret>(
      where: where(WorkspaceSecret.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
