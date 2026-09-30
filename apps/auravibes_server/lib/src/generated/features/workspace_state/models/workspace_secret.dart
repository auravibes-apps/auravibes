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
import 'dart:typed_data' as _idt;

import 'package:serverpod/serverpod.dart' as _is;

import '../../../features/workspace_state/models/workspace_secret_kind.dart'
    as _iffvdh0v;
import '../../../features/workspace_state/models/workspace_secret_scope.dart'
    as _iews8xwg;

abstract class WorkspaceSecret
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
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
    required _iffvdh0v.WorkspaceSecretKind secretKind,
    required _iews8xwg.WorkspaceSecretScope scope,
    required String ownerUserId,
    required String resourceId,
    required _idt.ByteData ciphertext,
    required _idt.ByteData nonce,
    required _idt.ByteData authenticationTag,
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
      secretKind: _iffvdh0v.WorkspaceSecretKind.fromJson(
        (jsonSerialization['secretKind'] as String),
      ),
      scope: _iews8xwg.WorkspaceSecretScope.fromJson(
        (jsonSerialization['scope'] as String),
      ),
      ownerUserId: jsonSerialization['ownerUserId'] as String,
      resourceId: jsonSerialization['resourceId'] as String,
      ciphertext: _is.ByteDataJsonExtension.fromJson(
        jsonSerialization['ciphertext'],
      ),
      nonce: _is.ByteDataJsonExtension.fromJson(jsonSerialization['nonce']),
      authenticationTag: _is.ByteDataJsonExtension.fromJson(
        jsonSerialization['authenticationTag'],
      ),
      algorithm: jsonSerialization['algorithm'] as String,
      keyVersion: jsonSerialization['keyVersion'] as int,
      displaySuffix: jsonSerialization['displaySuffix'] as String?,
      revision: jsonSerialization['revision'] as int,
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
      deletedAt: jsonSerialization['deletedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['deletedAt']),
    );
  }

  static final t = WorkspaceSecretTable();

  static const db = WorkspaceSecretRepository._();

  @override
  int? id;

  int workspaceId;

  _iffvdh0v.WorkspaceSecretKind secretKind;

  _iews8xwg.WorkspaceSecretScope scope;

  String ownerUserId;

  String resourceId;

  _idt.ByteData ciphertext;

  _idt.ByteData nonce;

  _idt.ByteData authenticationTag;

  String algorithm;

  int keyVersion;

  String? displaySuffix;

  int revision;

  DateTime createdAt;

  DateTime updatedAt;

  DateTime? deletedAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [WorkspaceSecret]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  WorkspaceSecret copyWith({
    int? id,
    int? workspaceId,
    _iffvdh0v.WorkspaceSecretKind? secretKind,
    _iews8xwg.WorkspaceSecretScope? scope,
    String? ownerUserId,
    String? resourceId,
    _idt.ByteData? ciphertext,
    _idt.ByteData? nonce,
    _idt.ByteData? authenticationTag,
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
    _is.WhereExpressionBuilder<WorkspaceSecretTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<WorkspaceSecretTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceSecretTable>? orderByList,
    WorkspaceSecretInclude? include,
  }) {
    return WorkspaceSecretIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WorkspaceSecret.t),
      orderByList: orderByList?.call(WorkspaceSecret.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WorkspaceSecretImpl extends WorkspaceSecret {
  _WorkspaceSecretImpl({
    int? id,
    required int workspaceId,
    required _iffvdh0v.WorkspaceSecretKind secretKind,
    required _iews8xwg.WorkspaceSecretScope scope,
    required String ownerUserId,
    required String resourceId,
    required _idt.ByteData ciphertext,
    required _idt.ByteData nonce,
    required _idt.ByteData authenticationTag,
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
  @_is.useResult
  @override
  WorkspaceSecret copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    _iffvdh0v.WorkspaceSecretKind? secretKind,
    _iews8xwg.WorkspaceSecretScope? scope,
    String? ownerUserId,
    String? resourceId,
    _idt.ByteData? ciphertext,
    _idt.ByteData? nonce,
    _idt.ByteData? authenticationTag,
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

class WorkspaceSecretUpdateTable extends _is.UpdateTable<WorkspaceSecretTable> {
  WorkspaceSecretUpdateTable(super.table);

  _is.ColumnValue<int, int> workspaceId(int value) => _is.ColumnValue(
    table.workspaceId,
    value,
  );

  _is.ColumnValue<_iffvdh0v.WorkspaceSecretKind, _iffvdh0v.WorkspaceSecretKind>
  secretKind(_iffvdh0v.WorkspaceSecretKind value) => _is.ColumnValue(
    table.secretKind,
    value,
  );

  _is.ColumnValue<
    _iews8xwg.WorkspaceSecretScope,
    _iews8xwg.WorkspaceSecretScope
  >
  scope(_iews8xwg.WorkspaceSecretScope value) => _is.ColumnValue(
    table.scope,
    value,
  );

  _is.ColumnValue<String, String> ownerUserId(String value) => _is.ColumnValue(
    table.ownerUserId,
    value,
  );

  _is.ColumnValue<String, String> resourceId(String value) => _is.ColumnValue(
    table.resourceId,
    value,
  );

  _is.ColumnValue<_idt.ByteData, _idt.ByteData> ciphertext(
    _idt.ByteData value,
  ) => _is.ColumnValue(
    table.ciphertext,
    value,
  );

  _is.ColumnValue<_idt.ByteData, _idt.ByteData> nonce(_idt.ByteData value) =>
      _is.ColumnValue(
        table.nonce,
        value,
      );

  _is.ColumnValue<_idt.ByteData, _idt.ByteData> authenticationTag(
    _idt.ByteData value,
  ) => _is.ColumnValue(
    table.authenticationTag,
    value,
  );

  _is.ColumnValue<String, String> algorithm(String value) => _is.ColumnValue(
    table.algorithm,
    value,
  );

  _is.ColumnValue<int, int> keyVersion(int value) => _is.ColumnValue(
    table.keyVersion,
    value,
  );

  _is.ColumnValue<String, String> displaySuffix(String? value) =>
      _is.ColumnValue(
        table.displaySuffix,
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

  _is.ColumnValue<DateTime, DateTime> deletedAt(DateTime? value) =>
      _is.ColumnValue(
        table.deletedAt,
        value,
      );
}

class WorkspaceSecretTable extends _is.Table<int?> {
  WorkspaceSecretTable({super.tableRelation})
    : super(tableName: 'workspace_secret') {
    updateTable = WorkspaceSecretUpdateTable(this);
    workspaceId = _is.ColumnInt(
      'workspaceId',
      this,
    );
    secretKind = _is.ColumnEnum(
      'secretKind',
      this,
      _is.EnumSerialization.byName,
    );
    scope = _is.ColumnEnum(
      'scope',
      this,
      _is.EnumSerialization.byName,
    );
    ownerUserId = _is.ColumnString(
      'ownerUserId',
      this,
    );
    resourceId = _is.ColumnString(
      'resourceId',
      this,
    );
    ciphertext = _is.ColumnByteData(
      'ciphertext',
      this,
    );
    nonce = _is.ColumnByteData(
      'nonce',
      this,
    );
    authenticationTag = _is.ColumnByteData(
      'authenticationTag',
      this,
    );
    algorithm = _is.ColumnString(
      'algorithm',
      this,
    );
    keyVersion = _is.ColumnInt(
      'keyVersion',
      this,
    );
    displaySuffix = _is.ColumnString(
      'displaySuffix',
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
    deletedAt = _is.ColumnDateTime(
      'deletedAt',
      this,
    );
  }

  late final WorkspaceSecretUpdateTable updateTable;

  late final _is.ColumnInt workspaceId;

  late final _is.ColumnEnum<_iffvdh0v.WorkspaceSecretKind> secretKind;

  late final _is.ColumnEnum<_iews8xwg.WorkspaceSecretScope> scope;

  late final _is.ColumnString ownerUserId;

  late final _is.ColumnString resourceId;

  late final _is.ColumnByteData ciphertext;

  late final _is.ColumnByteData nonce;

  late final _is.ColumnByteData authenticationTag;

  late final _is.ColumnString algorithm;

  late final _is.ColumnInt keyVersion;

  late final _is.ColumnString displaySuffix;

  late final _is.ColumnInt revision;

  late final _is.ColumnDateTime createdAt;

  late final _is.ColumnDateTime updatedAt;

  late final _is.ColumnDateTime deletedAt;

  @override
  List<_is.Column> get columns => [
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

class WorkspaceSecretInclude extends _is.IncludeObject {
  WorkspaceSecretInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => WorkspaceSecret.t;
}

class WorkspaceSecretIncludeList extends _is.IncludeList {
  WorkspaceSecretIncludeList._({
    _is.WhereExpressionBuilder<WorkspaceSecretTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(WorkspaceSecret.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => WorkspaceSecret.t;
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
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<WorkspaceSecretTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<WorkspaceSecretTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceSecretTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<WorkspaceSecret>(
      where: where?.call(WorkspaceSecret.t),
      orderBy: orderBy?.call(WorkspaceSecret.t),
      orderByList: orderByList?.call(WorkspaceSecret.t),
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
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<WorkspaceSecretTable>? where,
    int? offset,
    _is.OrderByBuilder<WorkspaceSecretTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceSecretTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<WorkspaceSecret>(
      where: where?.call(WorkspaceSecret.t),
      orderBy: orderBy?.call(WorkspaceSecret.t),
      orderByList: orderByList?.call(WorkspaceSecret.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [WorkspaceSecret] by its [id] or null if no such row exists.
  Future<WorkspaceSecret?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
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
    _is.DatabaseSession session,
    List<WorkspaceSecret> rows, {
    _is.Transaction? transaction,
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
    _is.DatabaseSession session,
    WorkspaceSecret row, {
    _is.Transaction? transaction,
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
    _is.DatabaseSession session,
    List<WorkspaceSecret> rows, {
    required _is.ColumnSelections<WorkspaceSecretTable> conflictColumns,
    _is.ColumnSelections<WorkspaceSecretTable>? updateColumns,
    _is.WhereExpressionBuilder<WorkspaceSecretTable>? updateWhere,
    _is.Transaction? transaction,
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
    _is.DatabaseSession session,
    WorkspaceSecret row, {
    required _is.ColumnSelections<WorkspaceSecretTable> conflictColumns,
    _is.ColumnSelections<WorkspaceSecretTable>? updateColumns,
    _is.WhereExpressionBuilder<WorkspaceSecretTable>? updateWhere,
    _is.Transaction? transaction,
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
    _is.DatabaseSession session,
    List<WorkspaceSecret> rows, {
    _is.ColumnSelections<WorkspaceSecretTable>? columns,
    _is.Transaction? transaction,
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
    _is.DatabaseSession session,
    WorkspaceSecret row, {
    _is.ColumnSelections<WorkspaceSecretTable>? columns,
    _is.Transaction? transaction,
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
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<WorkspaceSecretUpdateTable>
    columnValues,
    _is.Transaction? transaction,
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
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<WorkspaceSecretUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<WorkspaceSecretTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<WorkspaceSecretTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceSecretTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<WorkspaceSecret>(
      columnValues: columnValues(WorkspaceSecret.t.updateTable),
      where: where(WorkspaceSecret.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WorkspaceSecret.t),
      orderByList: orderByList?.call(WorkspaceSecret.t),
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
    _is.DatabaseSession session,
    List<WorkspaceSecret> rows, {
    _is.OrderByBuilder<WorkspaceSecretTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceSecretTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<WorkspaceSecret>(
      rows,
      orderBy: orderBy?.call(WorkspaceSecret.t),
      orderByList: orderByList?.call(WorkspaceSecret.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [WorkspaceSecret].
  Future<WorkspaceSecret> deleteRow(
    _is.DatabaseSession session,
    WorkspaceSecret row, {
    _is.Transaction? transaction,
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
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<WorkspaceSecretTable> where,
    _is.OrderByBuilder<WorkspaceSecretTable>? orderBy,
    _is.OrderByListBuilder<WorkspaceSecretTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<WorkspaceSecret>(
      where: where(WorkspaceSecret.t),
      orderBy: orderBy?.call(WorkspaceSecret.t),
      orderByList: orderByList?.call(WorkspaceSecret.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<WorkspaceSecretTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<WorkspaceSecret>(
      where: where?.call(WorkspaceSecret.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [WorkspaceSecret] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<WorkspaceSecretTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<WorkspaceSecret>(
      where: where(WorkspaceSecret.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
