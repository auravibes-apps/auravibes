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

import 'dart:typed_data' as _i2;

abstract class CodexOAuthTransaction
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  CodexOAuthTransaction._({
    this.id,
    required this.transactionId,
    required this.workspaceId,
    required this.connectionId,
    required this.userId,
    required this.stateHash,
    required this.verifierCiphertext,
    required this.verifierNonce,
    required this.verifierAuthenticationTag,
    required this.redirectUri,
    required this.expiresAt,
    this.consumedAt,
    required this.createdAt,
  });

  factory CodexOAuthTransaction({
    int? id,
    required String transactionId,
    required int workspaceId,
    required String connectionId,
    required String userId,
    required String stateHash,
    required _i2.ByteData verifierCiphertext,
    required _i2.ByteData verifierNonce,
    required _i2.ByteData verifierAuthenticationTag,
    required String redirectUri,
    required DateTime expiresAt,
    DateTime? consumedAt,
    required DateTime createdAt,
  }) = _CodexOAuthTransactionImpl;

  factory CodexOAuthTransaction.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return CodexOAuthTransaction(
      id: jsonSerialization['id'] as int?,
      transactionId: jsonSerialization['transactionId'] as String,
      workspaceId: jsonSerialization['workspaceId'] as int,
      connectionId: jsonSerialization['connectionId'] as String,
      userId: jsonSerialization['userId'] as String,
      stateHash: jsonSerialization['stateHash'] as String,
      verifierCiphertext: _i1.ByteDataJsonExtension.fromJson(
        jsonSerialization['verifierCiphertext'],
      ),
      verifierNonce: _i1.ByteDataJsonExtension.fromJson(
        jsonSerialization['verifierNonce'],
      ),
      verifierAuthenticationTag: _i1.ByteDataJsonExtension.fromJson(
        jsonSerialization['verifierAuthenticationTag'],
      ),
      redirectUri: jsonSerialization['redirectUri'] as String,
      expiresAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
      consumedAt: jsonSerialization['consumedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['consumedAt']),
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  static final t = CodexOAuthTransactionTable();

  static const db = CodexOAuthTransactionRepository._();

  @override
  int? id;

  String transactionId;

  int workspaceId;

  String connectionId;

  String userId;

  String stateHash;

  _i2.ByteData verifierCiphertext;

  _i2.ByteData verifierNonce;

  _i2.ByteData verifierAuthenticationTag;

  String redirectUri;

  DateTime expiresAt;

  DateTime? consumedAt;

  DateTime createdAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [CodexOAuthTransaction]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CodexOAuthTransaction copyWith({
    int? id,
    String? transactionId,
    int? workspaceId,
    String? connectionId,
    String? userId,
    String? stateHash,
    _i2.ByteData? verifierCiphertext,
    _i2.ByteData? verifierNonce,
    _i2.ByteData? verifierAuthenticationTag,
    String? redirectUri,
    DateTime? expiresAt,
    DateTime? consumedAt,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CodexOAuthTransaction',
      if (id != null) 'id': id,
      'transactionId': transactionId,
      'workspaceId': workspaceId,
      'connectionId': connectionId,
      'userId': userId,
      'stateHash': stateHash,
      'verifierCiphertext': verifierCiphertext.toJson(),
      'verifierNonce': verifierNonce.toJson(),
      'verifierAuthenticationTag': verifierAuthenticationTag.toJson(),
      'redirectUri': redirectUri,
      'expiresAt': expiresAt.toJson(),
      if (consumedAt != null) 'consumedAt': consumedAt?.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'CodexOAuthTransaction',
      if (id != null) 'id': id,
      'transactionId': transactionId,
      'workspaceId': workspaceId,
      'connectionId': connectionId,
      'userId': userId,
      'stateHash': stateHash,
      'verifierCiphertext': verifierCiphertext.toJson(),
      'verifierNonce': verifierNonce.toJson(),
      'verifierAuthenticationTag': verifierAuthenticationTag.toJson(),
      'redirectUri': redirectUri,
      'expiresAt': expiresAt.toJson(),
      if (consumedAt != null) 'consumedAt': consumedAt?.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  static CodexOAuthTransactionInclude include() {
    return CodexOAuthTransactionInclude._();
  }

  static CodexOAuthTransactionIncludeList includeList({
    _i1.WhereExpressionBuilder<CodexOAuthTransactionTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<CodexOAuthTransactionTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<CodexOAuthTransactionTable>? orderByList,
    CodexOAuthTransactionInclude? include,
  }) {
    return CodexOAuthTransactionIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(CodexOAuthTransaction.t),
      orderDescending: // ignore: deprecated_member_use_from_same_package
          orderDescending,
      orderByList: orderByList?.call(CodexOAuthTransaction.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _CodexOAuthTransactionImpl extends CodexOAuthTransaction {
  _CodexOAuthTransactionImpl({
    int? id,
    required String transactionId,
    required int workspaceId,
    required String connectionId,
    required String userId,
    required String stateHash,
    required _i2.ByteData verifierCiphertext,
    required _i2.ByteData verifierNonce,
    required _i2.ByteData verifierAuthenticationTag,
    required String redirectUri,
    required DateTime expiresAt,
    DateTime? consumedAt,
    required DateTime createdAt,
  }) : super._(
         id: id,
         transactionId: transactionId,
         workspaceId: workspaceId,
         connectionId: connectionId,
         userId: userId,
         stateHash: stateHash,
         verifierCiphertext: verifierCiphertext,
         verifierNonce: verifierNonce,
         verifierAuthenticationTag: verifierAuthenticationTag,
         redirectUri: redirectUri,
         expiresAt: expiresAt,
         consumedAt: consumedAt,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [CodexOAuthTransaction]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CodexOAuthTransaction copyWith({
    Object? id = _Undefined,
    String? transactionId,
    int? workspaceId,
    String? connectionId,
    String? userId,
    String? stateHash,
    _i2.ByteData? verifierCiphertext,
    _i2.ByteData? verifierNonce,
    _i2.ByteData? verifierAuthenticationTag,
    String? redirectUri,
    DateTime? expiresAt,
    Object? consumedAt = _Undefined,
    DateTime? createdAt,
  }) {
    return CodexOAuthTransaction(
      id: id is int? ? id : this.id,
      transactionId: transactionId ?? this.transactionId,
      workspaceId: workspaceId ?? this.workspaceId,
      connectionId: connectionId ?? this.connectionId,
      userId: userId ?? this.userId,
      stateHash: stateHash ?? this.stateHash,
      verifierCiphertext: verifierCiphertext ?? this.verifierCiphertext.clone(),
      verifierNonce: verifierNonce ?? this.verifierNonce.clone(),
      verifierAuthenticationTag:
          verifierAuthenticationTag ?? this.verifierAuthenticationTag.clone(),
      redirectUri: redirectUri ?? this.redirectUri,
      expiresAt: expiresAt ?? this.expiresAt,
      consumedAt: consumedAt is DateTime? ? consumedAt : this.consumedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class CodexOAuthTransactionUpdateTable
    extends _i1.UpdateTable<CodexOAuthTransactionTable> {
  CodexOAuthTransactionUpdateTable(super.table);

  _i1.ColumnValue<String, String> transactionId(String value) =>
      _i1.ColumnValue(
        table.transactionId,
        value,
      );

  _i1.ColumnValue<int, int> workspaceId(int value) => _i1.ColumnValue(
    table.workspaceId,
    value,
  );

  _i1.ColumnValue<String, String> connectionId(String value) => _i1.ColumnValue(
    table.connectionId,
    value,
  );

  _i1.ColumnValue<String, String> userId(String value) => _i1.ColumnValue(
    table.userId,
    value,
  );

  _i1.ColumnValue<String, String> stateHash(String value) => _i1.ColumnValue(
    table.stateHash,
    value,
  );

  _i1.ColumnValue<_i2.ByteData, _i2.ByteData> verifierCiphertext(
    _i2.ByteData value,
  ) => _i1.ColumnValue(
    table.verifierCiphertext,
    value,
  );

  _i1.ColumnValue<_i2.ByteData, _i2.ByteData> verifierNonce(
    _i2.ByteData value,
  ) => _i1.ColumnValue(
    table.verifierNonce,
    value,
  );

  _i1.ColumnValue<_i2.ByteData, _i2.ByteData> verifierAuthenticationTag(
    _i2.ByteData value,
  ) => _i1.ColumnValue(
    table.verifierAuthenticationTag,
    value,
  );

  _i1.ColumnValue<String, String> redirectUri(String value) => _i1.ColumnValue(
    table.redirectUri,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> expiresAt(DateTime value) =>
      _i1.ColumnValue(
        table.expiresAt,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> consumedAt(DateTime? value) =>
      _i1.ColumnValue(
        table.consumedAt,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(
        table.createdAt,
        value,
      );
}

class CodexOAuthTransactionTable extends _i1.Table<int?> {
  CodexOAuthTransactionTable({super.tableRelation})
    : super(tableName: 'codex_oauth_transaction') {
    updateTable = CodexOAuthTransactionUpdateTable(this);
    transactionId = _i1.ColumnString(
      'transactionId',
      this,
    );
    workspaceId = _i1.ColumnInt(
      'workspaceId',
      this,
    );
    connectionId = _i1.ColumnString(
      'connectionId',
      this,
    );
    userId = _i1.ColumnString(
      'userId',
      this,
    );
    stateHash = _i1.ColumnString(
      'stateHash',
      this,
    );
    verifierCiphertext = _i1.ColumnByteData(
      'verifierCiphertext',
      this,
    );
    verifierNonce = _i1.ColumnByteData(
      'verifierNonce',
      this,
    );
    verifierAuthenticationTag = _i1.ColumnByteData(
      'verifierAuthenticationTag',
      this,
    );
    redirectUri = _i1.ColumnString(
      'redirectUri',
      this,
    );
    expiresAt = _i1.ColumnDateTime(
      'expiresAt',
      this,
    );
    consumedAt = _i1.ColumnDateTime(
      'consumedAt',
      this,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final CodexOAuthTransactionUpdateTable updateTable;

  late final _i1.ColumnString transactionId;

  late final _i1.ColumnInt workspaceId;

  late final _i1.ColumnString connectionId;

  late final _i1.ColumnString userId;

  late final _i1.ColumnString stateHash;

  late final _i1.ColumnByteData verifierCiphertext;

  late final _i1.ColumnByteData verifierNonce;

  late final _i1.ColumnByteData verifierAuthenticationTag;

  late final _i1.ColumnString redirectUri;

  late final _i1.ColumnDateTime expiresAt;

  late final _i1.ColumnDateTime consumedAt;

  late final _i1.ColumnDateTime createdAt;

  @override
  List<_i1.Column> get columns => [
    id,
    transactionId,
    workspaceId,
    connectionId,
    userId,
    stateHash,
    verifierCiphertext,
    verifierNonce,
    verifierAuthenticationTag,
    redirectUri,
    expiresAt,
    consumedAt,
    createdAt,
  ];
}

class CodexOAuthTransactionInclude extends _i1.IncludeObject {
  CodexOAuthTransactionInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => CodexOAuthTransaction.t;
}

class CodexOAuthTransactionIncludeList extends _i1.IncludeList {
  CodexOAuthTransactionIncludeList._({
    _i1.WhereExpressionBuilder<CodexOAuthTransactionTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(CodexOAuthTransaction.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => CodexOAuthTransaction.t;
}

class CodexOAuthTransactionRepository {
  const CodexOAuthTransactionRepository._();

  /// Returns a list of [CodexOAuthTransaction]s matching the given query parameters.
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
  Future<List<CodexOAuthTransaction>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<CodexOAuthTransactionTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<CodexOAuthTransactionTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<CodexOAuthTransactionTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<CodexOAuthTransaction>(
      where: where?.call(CodexOAuthTransaction.t),
      orderBy: orderBy?.call(CodexOAuthTransaction.t),
      orderByList: orderByList?.call(CodexOAuthTransaction.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [CodexOAuthTransaction] matching the given query parameters.
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
  Future<CodexOAuthTransaction?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<CodexOAuthTransactionTable>? where,
    int? offset,
    _i1.OrderByBuilder<CodexOAuthTransactionTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<CodexOAuthTransactionTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<CodexOAuthTransaction>(
      where: where?.call(CodexOAuthTransaction.t),
      orderBy: orderBy?.call(CodexOAuthTransaction.t),
      orderByList: orderByList?.call(CodexOAuthTransaction.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [CodexOAuthTransaction] by its [id] or null if no such row exists.
  Future<CodexOAuthTransaction?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<CodexOAuthTransaction>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [CodexOAuthTransaction]s in the list and returns the inserted rows.
  ///
  /// The returned [CodexOAuthTransaction]s will have their `id` fields set.
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
  Future<List<CodexOAuthTransaction>> insert(
    _i1.DatabaseSession session,
    List<CodexOAuthTransaction> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<CodexOAuthTransaction>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [CodexOAuthTransaction] and returns the inserted row.
  ///
  /// The returned [CodexOAuthTransaction] will have its `id` field set.
  Future<CodexOAuthTransaction> insertRow(
    _i1.DatabaseSession session,
    CodexOAuthTransaction row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<CodexOAuthTransaction>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [CodexOAuthTransaction]s in the list and returns the resulting rows.
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
  /// The returned [CodexOAuthTransaction]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<CodexOAuthTransaction>> upsert(
    _i1.DatabaseSession session,
    List<CodexOAuthTransaction> rows, {
    required _i1.ColumnSelections<CodexOAuthTransactionTable> conflictColumns,
    _i1.ColumnSelections<CodexOAuthTransactionTable>? updateColumns,
    _i1.WhereExpressionBuilder<CodexOAuthTransactionTable>? updateWhere,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<CodexOAuthTransaction>(
      rows,
      conflictColumns: conflictColumns(CodexOAuthTransaction.t),
      updateColumns: updateColumns?.call(CodexOAuthTransaction.t),
      updateWhere: updateWhere?.call(CodexOAuthTransaction.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [CodexOAuthTransaction] and returns the resulting row.
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
  /// The returned [CodexOAuthTransaction] will have its `id` field set.
  Future<CodexOAuthTransaction?> upsertRow(
    _i1.DatabaseSession session,
    CodexOAuthTransaction row, {
    required _i1.ColumnSelections<CodexOAuthTransactionTable> conflictColumns,
    _i1.ColumnSelections<CodexOAuthTransactionTable>? updateColumns,
    _i1.WhereExpressionBuilder<CodexOAuthTransactionTable>? updateWhere,
    _i1.Transaction? transaction,
  }) async {
    return session.db.upsertRow<CodexOAuthTransaction>(
      row,
      conflictColumns: conflictColumns(CodexOAuthTransaction.t),
      updateColumns: updateColumns?.call(CodexOAuthTransaction.t),
      updateWhere: updateWhere?.call(CodexOAuthTransaction.t),
      transaction: transaction,
    );
  }

  /// Updates all [CodexOAuthTransaction]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<CodexOAuthTransaction>> update(
    _i1.DatabaseSession session,
    List<CodexOAuthTransaction> rows, {
    _i1.ColumnSelections<CodexOAuthTransactionTable>? columns,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<CodexOAuthTransaction>(
      rows,
      columns: columns?.call(CodexOAuthTransaction.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [CodexOAuthTransaction]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<CodexOAuthTransaction> updateRow(
    _i1.DatabaseSession session,
    CodexOAuthTransaction row, {
    _i1.ColumnSelections<CodexOAuthTransactionTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<CodexOAuthTransaction>(
      row,
      columns: columns?.call(CodexOAuthTransaction.t),
      transaction: transaction,
    );
  }

  /// Updates a single [CodexOAuthTransaction] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<CodexOAuthTransaction?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<CodexOAuthTransactionUpdateTable>
    columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<CodexOAuthTransaction>(
      id,
      columnValues: columnValues(CodexOAuthTransaction.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [CodexOAuthTransaction]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<CodexOAuthTransaction>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<CodexOAuthTransactionUpdateTable>
    columnValues,
    required _i1.WhereExpressionBuilder<CodexOAuthTransactionTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<CodexOAuthTransactionTable>? orderBy,
    _i1.OrderByListBuilder<CodexOAuthTransactionTable>? orderByList,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<CodexOAuthTransaction>(
      columnValues: columnValues(CodexOAuthTransaction.t.updateTable),
      where: where(CodexOAuthTransaction.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(CodexOAuthTransaction.t),
      orderByList: orderByList?.call(CodexOAuthTransaction.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [CodexOAuthTransaction]s in the list and returns the deleted rows.
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
  Future<List<CodexOAuthTransaction>> delete(
    _i1.DatabaseSession session,
    List<CodexOAuthTransaction> rows, {
    _i1.OrderByBuilder<CodexOAuthTransactionTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<CodexOAuthTransactionTable>? orderByList,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<CodexOAuthTransaction>(
      rows,
      orderBy: orderBy?.call(CodexOAuthTransaction.t),
      orderByList: orderByList?.call(CodexOAuthTransaction.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [CodexOAuthTransaction].
  Future<CodexOAuthTransaction> deleteRow(
    _i1.DatabaseSession session,
    CodexOAuthTransaction row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<CodexOAuthTransaction>(
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
  Future<List<CodexOAuthTransaction>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<CodexOAuthTransactionTable> where,
    _i1.OrderByBuilder<CodexOAuthTransactionTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<CodexOAuthTransactionTable>? orderByList,
    _i1.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<CodexOAuthTransaction>(
      where: where(CodexOAuthTransaction.t),
      orderBy: orderBy?.call(CodexOAuthTransaction.t),
      orderByList: orderByList?.call(CodexOAuthTransaction.t),
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
    _i1.WhereExpressionBuilder<CodexOAuthTransactionTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<CodexOAuthTransaction>(
      where: where?.call(CodexOAuthTransaction.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [CodexOAuthTransaction] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<CodexOAuthTransactionTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<CodexOAuthTransaction>(
      where: where(CodexOAuthTransaction.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
