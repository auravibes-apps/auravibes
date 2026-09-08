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

abstract class CodexOAuthTransaction
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
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
    required _idt.ByteData verifierCiphertext,
    required _idt.ByteData verifierNonce,
    required _idt.ByteData verifierAuthenticationTag,
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
      verifierCiphertext: _is.ByteDataJsonExtension.fromJson(
        jsonSerialization['verifierCiphertext'],
      ),
      verifierNonce: _is.ByteDataJsonExtension.fromJson(
        jsonSerialization['verifierNonce'],
      ),
      verifierAuthenticationTag: _is.ByteDataJsonExtension.fromJson(
        jsonSerialization['verifierAuthenticationTag'],
      ),
      redirectUri: jsonSerialization['redirectUri'] as String,
      expiresAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
      consumedAt: jsonSerialization['consumedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['consumedAt']),
      createdAt: _is.DateTimeJsonExtension.fromJson(
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

  _idt.ByteData verifierCiphertext;

  _idt.ByteData verifierNonce;

  _idt.ByteData verifierAuthenticationTag;

  String redirectUri;

  DateTime expiresAt;

  DateTime? consumedAt;

  DateTime createdAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [CodexOAuthTransaction]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  CodexOAuthTransaction copyWith({
    int? id,
    String? transactionId,
    int? workspaceId,
    String? connectionId,
    String? userId,
    String? stateHash,
    _idt.ByteData? verifierCiphertext,
    _idt.ByteData? verifierNonce,
    _idt.ByteData? verifierAuthenticationTag,
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
    _is.WhereExpressionBuilder<CodexOAuthTransactionTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<CodexOAuthTransactionTable>? orderBy,
    _is.OrderByListBuilder<CodexOAuthTransactionTable>? orderByList,
    CodexOAuthTransactionInclude? include,
  }) {
    return CodexOAuthTransactionIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(CodexOAuthTransaction.t),
      orderByList: orderByList?.call(CodexOAuthTransaction.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
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
    required _idt.ByteData verifierCiphertext,
    required _idt.ByteData verifierNonce,
    required _idt.ByteData verifierAuthenticationTag,
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
  @_is.useResult
  @override
  CodexOAuthTransaction copyWith({
    Object? id = _Undefined,
    String? transactionId,
    int? workspaceId,
    String? connectionId,
    String? userId,
    String? stateHash,
    _idt.ByteData? verifierCiphertext,
    _idt.ByteData? verifierNonce,
    _idt.ByteData? verifierAuthenticationTag,
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
    extends _is.UpdateTable<CodexOAuthTransactionTable> {
  CodexOAuthTransactionUpdateTable(super.table);

  _is.ColumnValue<String, String> transactionId(String value) =>
      _is.ColumnValue(
        table.transactionId,
        value,
      );

  _is.ColumnValue<int, int> workspaceId(int value) => _is.ColumnValue(
    table.workspaceId,
    value,
  );

  _is.ColumnValue<String, String> connectionId(String value) => _is.ColumnValue(
    table.connectionId,
    value,
  );

  _is.ColumnValue<String, String> userId(String value) => _is.ColumnValue(
    table.userId,
    value,
  );

  _is.ColumnValue<String, String> stateHash(String value) => _is.ColumnValue(
    table.stateHash,
    value,
  );

  _is.ColumnValue<_idt.ByteData, _idt.ByteData> verifierCiphertext(
    _idt.ByteData value,
  ) => _is.ColumnValue(
    table.verifierCiphertext,
    value,
  );

  _is.ColumnValue<_idt.ByteData, _idt.ByteData> verifierNonce(
    _idt.ByteData value,
  ) => _is.ColumnValue(
    table.verifierNonce,
    value,
  );

  _is.ColumnValue<_idt.ByteData, _idt.ByteData> verifierAuthenticationTag(
    _idt.ByteData value,
  ) => _is.ColumnValue(
    table.verifierAuthenticationTag,
    value,
  );

  _is.ColumnValue<String, String> redirectUri(String value) => _is.ColumnValue(
    table.redirectUri,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> expiresAt(DateTime value) =>
      _is.ColumnValue(
        table.expiresAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> consumedAt(DateTime? value) =>
      _is.ColumnValue(
        table.consumedAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class CodexOAuthTransactionTable extends _is.Table<int?> {
  CodexOAuthTransactionTable({super.tableRelation})
    : super(tableName: 'codex_oauth_transaction') {
    updateTable = CodexOAuthTransactionUpdateTable(this);
    transactionId = _is.ColumnString(
      'transactionId',
      this,
    );
    workspaceId = _is.ColumnInt(
      'workspaceId',
      this,
    );
    connectionId = _is.ColumnString(
      'connectionId',
      this,
    );
    userId = _is.ColumnString(
      'userId',
      this,
    );
    stateHash = _is.ColumnString(
      'stateHash',
      this,
    );
    verifierCiphertext = _is.ColumnByteData(
      'verifierCiphertext',
      this,
    );
    verifierNonce = _is.ColumnByteData(
      'verifierNonce',
      this,
    );
    verifierAuthenticationTag = _is.ColumnByteData(
      'verifierAuthenticationTag',
      this,
    );
    redirectUri = _is.ColumnString(
      'redirectUri',
      this,
    );
    expiresAt = _is.ColumnDateTime(
      'expiresAt',
      this,
    );
    consumedAt = _is.ColumnDateTime(
      'consumedAt',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final CodexOAuthTransactionUpdateTable updateTable;

  late final _is.ColumnString transactionId;

  late final _is.ColumnInt workspaceId;

  late final _is.ColumnString connectionId;

  late final _is.ColumnString userId;

  late final _is.ColumnString stateHash;

  late final _is.ColumnByteData verifierCiphertext;

  late final _is.ColumnByteData verifierNonce;

  late final _is.ColumnByteData verifierAuthenticationTag;

  late final _is.ColumnString redirectUri;

  late final _is.ColumnDateTime expiresAt;

  late final _is.ColumnDateTime consumedAt;

  late final _is.ColumnDateTime createdAt;

  @override
  List<_is.Column> get columns => [
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

class CodexOAuthTransactionInclude extends _is.IncludeObject {
  CodexOAuthTransactionInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => CodexOAuthTransaction.t;
}

class CodexOAuthTransactionIncludeList extends _is.IncludeList {
  CodexOAuthTransactionIncludeList._({
    _is.WhereExpressionBuilder<CodexOAuthTransactionTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(CodexOAuthTransaction.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => CodexOAuthTransaction.t;
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
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<CodexOAuthTransactionTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<CodexOAuthTransactionTable>? orderBy,
    _is.OrderByListBuilder<CodexOAuthTransactionTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<CodexOAuthTransaction>(
      where: where?.call(CodexOAuthTransaction.t),
      orderBy: orderBy?.call(CodexOAuthTransaction.t),
      orderByList: orderByList?.call(CodexOAuthTransaction.t),
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
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<CodexOAuthTransactionTable>? where,
    int? offset,
    _is.OrderByBuilder<CodexOAuthTransactionTable>? orderBy,
    _is.OrderByListBuilder<CodexOAuthTransactionTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<CodexOAuthTransaction>(
      where: where?.call(CodexOAuthTransaction.t),
      orderBy: orderBy?.call(CodexOAuthTransaction.t),
      orderByList: orderByList?.call(CodexOAuthTransaction.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [CodexOAuthTransaction] by its [id] or null if no such row exists.
  Future<CodexOAuthTransaction?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
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
    _is.DatabaseSession session,
    List<CodexOAuthTransaction> rows, {
    _is.Transaction? transaction,
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
    _is.DatabaseSession session,
    CodexOAuthTransaction row, {
    _is.Transaction? transaction,
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
    _is.DatabaseSession session,
    List<CodexOAuthTransaction> rows, {
    required _is.ColumnSelections<CodexOAuthTransactionTable> conflictColumns,
    _is.ColumnSelections<CodexOAuthTransactionTable>? updateColumns,
    _is.WhereExpressionBuilder<CodexOAuthTransactionTable>? updateWhere,
    _is.Transaction? transaction,
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
    _is.DatabaseSession session,
    CodexOAuthTransaction row, {
    required _is.ColumnSelections<CodexOAuthTransactionTable> conflictColumns,
    _is.ColumnSelections<CodexOAuthTransactionTable>? updateColumns,
    _is.WhereExpressionBuilder<CodexOAuthTransactionTable>? updateWhere,
    _is.Transaction? transaction,
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
    _is.DatabaseSession session,
    List<CodexOAuthTransaction> rows, {
    _is.ColumnSelections<CodexOAuthTransactionTable>? columns,
    _is.Transaction? transaction,
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
    _is.DatabaseSession session,
    CodexOAuthTransaction row, {
    _is.ColumnSelections<CodexOAuthTransactionTable>? columns,
    _is.Transaction? transaction,
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
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<CodexOAuthTransactionUpdateTable>
    columnValues,
    _is.Transaction? transaction,
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
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<CodexOAuthTransactionUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<CodexOAuthTransactionTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<CodexOAuthTransactionTable>? orderBy,
    _is.OrderByListBuilder<CodexOAuthTransactionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<CodexOAuthTransaction>(
      columnValues: columnValues(CodexOAuthTransaction.t.updateTable),
      where: where(CodexOAuthTransaction.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(CodexOAuthTransaction.t),
      orderByList: orderByList?.call(CodexOAuthTransaction.t),
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
    _is.DatabaseSession session,
    List<CodexOAuthTransaction> rows, {
    _is.OrderByBuilder<CodexOAuthTransactionTable>? orderBy,
    _is.OrderByListBuilder<CodexOAuthTransactionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<CodexOAuthTransaction>(
      rows,
      orderBy: orderBy?.call(CodexOAuthTransaction.t),
      orderByList: orderByList?.call(CodexOAuthTransaction.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [CodexOAuthTransaction].
  Future<CodexOAuthTransaction> deleteRow(
    _is.DatabaseSession session,
    CodexOAuthTransaction row, {
    _is.Transaction? transaction,
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
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<CodexOAuthTransactionTable> where,
    _is.OrderByBuilder<CodexOAuthTransactionTable>? orderBy,
    _is.OrderByListBuilder<CodexOAuthTransactionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<CodexOAuthTransaction>(
      where: where(CodexOAuthTransaction.t),
      orderBy: orderBy?.call(CodexOAuthTransaction.t),
      orderByList: orderByList?.call(CodexOAuthTransaction.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<CodexOAuthTransactionTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<CodexOAuthTransaction>(
      where: where?.call(CodexOAuthTransaction.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [CodexOAuthTransaction] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<CodexOAuthTransactionTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<CodexOAuthTransaction>(
      where: where(CodexOAuthTransaction.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
