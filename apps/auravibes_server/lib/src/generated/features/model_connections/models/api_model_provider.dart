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

abstract class ApiModelProvider
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  ApiModelProvider._({
    this.id,
    required this.providerId,
    required this.name,
    this.type,
    this.url,
    this.documentationUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ApiModelProvider({
    int? id,
    required String providerId,
    required String name,
    String? type,
    String? url,
    String? documentationUrl,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ApiModelProviderImpl;

  factory ApiModelProvider.fromJson(Map<String, dynamic> jsonSerialization) {
    return ApiModelProvider(
      id: jsonSerialization['id'] as int?,
      providerId: jsonSerialization['providerId'] as String,
      name: jsonSerialization['name'] as String,
      type: jsonSerialization['type'] as String?,
      url: jsonSerialization['url'] as String?,
      documentationUrl: jsonSerialization['documentationUrl'] as String?,
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  static final t = ApiModelProviderTable();

  static const db = ApiModelProviderRepository._();

  @override
  int? id;

  String providerId;

  String name;

  String? type;

  String? url;

  String? documentationUrl;

  DateTime createdAt;

  DateTime updatedAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [ApiModelProvider]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ApiModelProvider copyWith({
    int? id,
    String? providerId,
    String? name,
    String? type,
    String? url,
    String? documentationUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ApiModelProvider',
      if (id != null) 'id': id,
      'providerId': providerId,
      'name': name,
      if (type != null) 'type': type,
      if (url != null) 'url': url,
      if (documentationUrl != null) 'documentationUrl': documentationUrl,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ApiModelProvider',
      if (id != null) 'id': id,
      'providerId': providerId,
      'name': name,
      if (type != null) 'type': type,
      if (url != null) 'url': url,
      if (documentationUrl != null) 'documentationUrl': documentationUrl,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  static ApiModelProviderInclude include() {
    return ApiModelProviderInclude._();
  }

  static ApiModelProviderIncludeList includeList({
    _is.WhereExpressionBuilder<ApiModelProviderTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ApiModelProviderTable>? orderBy,
    _is.OrderByListBuilder<ApiModelProviderTable>? orderByList,
    ApiModelProviderInclude? include,
  }) {
    return ApiModelProviderIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ApiModelProvider.t),
      orderByList: orderByList?.call(ApiModelProvider.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ApiModelProviderImpl extends ApiModelProvider {
  _ApiModelProviderImpl({
    int? id,
    required String providerId,
    required String name,
    String? type,
    String? url,
    String? documentationUrl,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         providerId: providerId,
         name: name,
         type: type,
         url: url,
         documentationUrl: documentationUrl,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [ApiModelProvider]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ApiModelProvider copyWith({
    Object? id = _Undefined,
    String? providerId,
    String? name,
    Object? type = _Undefined,
    Object? url = _Undefined,
    Object? documentationUrl = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ApiModelProvider(
      id: id is int? ? id : this.id,
      providerId: providerId ?? this.providerId,
      name: name ?? this.name,
      type: type is String? ? type : this.type,
      url: url is String? ? url : this.url,
      documentationUrl: documentationUrl is String?
          ? documentationUrl
          : this.documentationUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ApiModelProviderUpdateTable
    extends _is.UpdateTable<ApiModelProviderTable> {
  ApiModelProviderUpdateTable(super.table);

  _is.ColumnValue<String, String> providerId(String value) => _is.ColumnValue(
    table.providerId,
    value,
  );

  _is.ColumnValue<String, String> name(String value) => _is.ColumnValue(
    table.name,
    value,
  );

  _is.ColumnValue<String, String> type(String? value) => _is.ColumnValue(
    table.type,
    value,
  );

  _is.ColumnValue<String, String> url(String? value) => _is.ColumnValue(
    table.url,
    value,
  );

  _is.ColumnValue<String, String> documentationUrl(String? value) =>
      _is.ColumnValue(
        table.documentationUrl,
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

class ApiModelProviderTable extends _is.Table<int?> {
  ApiModelProviderTable({super.tableRelation})
    : super(tableName: 'api_model_provider') {
    updateTable = ApiModelProviderUpdateTable(this);
    providerId = _is.ColumnString(
      'providerId',
      this,
    );
    name = _is.ColumnString(
      'name',
      this,
    );
    type = _is.ColumnString(
      'type',
      this,
    );
    url = _is.ColumnString(
      'url',
      this,
    );
    documentationUrl = _is.ColumnString(
      'documentationUrl',
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

  late final ApiModelProviderUpdateTable updateTable;

  late final _is.ColumnString providerId;

  late final _is.ColumnString name;

  late final _is.ColumnString type;

  late final _is.ColumnString url;

  late final _is.ColumnString documentationUrl;

  late final _is.ColumnDateTime createdAt;

  late final _is.ColumnDateTime updatedAt;

  @override
  List<_is.Column> get columns => [
    id,
    providerId,
    name,
    type,
    url,
    documentationUrl,
    createdAt,
    updatedAt,
  ];
}

class ApiModelProviderInclude extends _is.IncludeObject {
  ApiModelProviderInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => ApiModelProvider.t;
}

class ApiModelProviderIncludeList extends _is.IncludeList {
  ApiModelProviderIncludeList._({
    _is.WhereExpressionBuilder<ApiModelProviderTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ApiModelProvider.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => ApiModelProvider.t;
}

class ApiModelProviderRepository {
  const ApiModelProviderRepository._();

  /// Returns a list of [ApiModelProvider]s matching the given query parameters.
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
  Future<List<ApiModelProvider>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ApiModelProviderTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ApiModelProviderTable>? orderBy,
    _is.OrderByListBuilder<ApiModelProviderTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ApiModelProvider>(
      where: where?.call(ApiModelProvider.t),
      orderBy: orderBy?.call(ApiModelProvider.t),
      orderByList: orderByList?.call(ApiModelProvider.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [ApiModelProvider] matching the given query parameters.
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
  Future<ApiModelProvider?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ApiModelProviderTable>? where,
    int? offset,
    _is.OrderByBuilder<ApiModelProviderTable>? orderBy,
    _is.OrderByListBuilder<ApiModelProviderTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ApiModelProvider>(
      where: where?.call(ApiModelProvider.t),
      orderBy: orderBy?.call(ApiModelProvider.t),
      orderByList: orderByList?.call(ApiModelProvider.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ApiModelProvider] by its [id] or null if no such row exists.
  Future<ApiModelProvider?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ApiModelProvider>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ApiModelProvider]s in the list and returns the inserted rows.
  ///
  /// The returned [ApiModelProvider]s will have their `id` fields set.
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
  Future<List<ApiModelProvider>> insert(
    _is.DatabaseSession session,
    List<ApiModelProvider> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<ApiModelProvider>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [ApiModelProvider] and returns the inserted row.
  ///
  /// The returned [ApiModelProvider] will have its `id` field set.
  Future<ApiModelProvider> insertRow(
    _is.DatabaseSession session,
    ApiModelProvider row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<ApiModelProvider>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [ApiModelProvider]s in the list and returns the resulting rows.
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
  /// The returned [ApiModelProvider]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ApiModelProvider>> upsert(
    _is.DatabaseSession session,
    List<ApiModelProvider> rows, {
    required _is.ColumnSelections<ApiModelProviderTable> conflictColumns,
    _is.ColumnSelections<ApiModelProviderTable>? updateColumns,
    _is.WhereExpressionBuilder<ApiModelProviderTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<ApiModelProvider>(
      rows,
      conflictColumns: conflictColumns(ApiModelProvider.t),
      updateColumns: updateColumns?.call(ApiModelProvider.t),
      updateWhere: updateWhere?.call(ApiModelProvider.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [ApiModelProvider] and returns the resulting row.
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
  /// The returned [ApiModelProvider] will have its `id` field set.
  Future<ApiModelProvider?> upsertRow(
    _is.DatabaseSession session,
    ApiModelProvider row, {
    required _is.ColumnSelections<ApiModelProviderTable> conflictColumns,
    _is.ColumnSelections<ApiModelProviderTable>? updateColumns,
    _is.WhereExpressionBuilder<ApiModelProviderTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<ApiModelProvider>(
      row,
      conflictColumns: conflictColumns(ApiModelProvider.t),
      updateColumns: updateColumns?.call(ApiModelProvider.t),
      updateWhere: updateWhere?.call(ApiModelProvider.t),
      transaction: transaction,
    );
  }

  /// Updates all [ApiModelProvider]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ApiModelProvider>> update(
    _is.DatabaseSession session,
    List<ApiModelProvider> rows, {
    _is.ColumnSelections<ApiModelProviderTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<ApiModelProvider>(
      rows,
      columns: columns?.call(ApiModelProvider.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [ApiModelProvider]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ApiModelProvider> updateRow(
    _is.DatabaseSession session,
    ApiModelProvider row, {
    _is.ColumnSelections<ApiModelProviderTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<ApiModelProvider>(
      row,
      columns: columns?.call(ApiModelProvider.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ApiModelProvider] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ApiModelProvider?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<ApiModelProviderUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<ApiModelProvider>(
      id,
      columnValues: columnValues(ApiModelProvider.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ApiModelProvider]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ApiModelProvider>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<ApiModelProviderUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<ApiModelProviderTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ApiModelProviderTable>? orderBy,
    _is.OrderByListBuilder<ApiModelProviderTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<ApiModelProvider>(
      columnValues: columnValues(ApiModelProvider.t.updateTable),
      where: where(ApiModelProvider.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ApiModelProvider.t),
      orderByList: orderByList?.call(ApiModelProvider.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [ApiModelProvider]s in the list and returns the deleted rows.
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
  Future<List<ApiModelProvider>> delete(
    _is.DatabaseSession session,
    List<ApiModelProvider> rows, {
    _is.OrderByBuilder<ApiModelProviderTable>? orderBy,
    _is.OrderByListBuilder<ApiModelProviderTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<ApiModelProvider>(
      rows,
      orderBy: orderBy?.call(ApiModelProvider.t),
      orderByList: orderByList?.call(ApiModelProvider.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [ApiModelProvider].
  Future<ApiModelProvider> deleteRow(
    _is.DatabaseSession session,
    ApiModelProvider row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ApiModelProvider>(
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
  Future<List<ApiModelProvider>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ApiModelProviderTable> where,
    _is.OrderByBuilder<ApiModelProviderTable>? orderBy,
    _is.OrderByListBuilder<ApiModelProviderTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<ApiModelProvider>(
      where: where(ApiModelProvider.t),
      orderBy: orderBy?.call(ApiModelProvider.t),
      orderByList: orderByList?.call(ApiModelProvider.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ApiModelProviderTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<ApiModelProvider>(
      where: where?.call(ApiModelProvider.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ApiModelProvider] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ApiModelProviderTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ApiModelProvider>(
      where: where(ApiModelProvider.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
