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

abstract class McpCatalogEntry
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  McpCatalogEntry._({
    this.id,
    required this.catalogId,
    required this.name,
    required this.description,
    required this.url,
    required this.transport,
    required this.isEnabled,
    required this.optionsJson,
  });

  factory McpCatalogEntry({
    int? id,
    required String catalogId,
    required String name,
    required String description,
    required String url,
    required String transport,
    required bool isEnabled,
    required String optionsJson,
  }) = _McpCatalogEntryImpl;

  factory McpCatalogEntry.fromJson(Map<String, dynamic> jsonSerialization) {
    return McpCatalogEntry(
      id: jsonSerialization['id'] as int?,
      catalogId: jsonSerialization['catalogId'] as String,
      name: jsonSerialization['name'] as String,
      description: jsonSerialization['description'] as String,
      url: jsonSerialization['url'] as String,
      transport: jsonSerialization['transport'] as String,
      isEnabled: _is.BoolJsonExtension.fromJson(jsonSerialization['isEnabled']),
      optionsJson: jsonSerialization['optionsJson'] as String,
    );
  }

  static final t = McpCatalogEntryTable();

  static const db = McpCatalogEntryRepository._();

  @override
  int? id;

  String catalogId;

  String name;

  String description;

  String url;

  String transport;

  bool isEnabled;

  String optionsJson;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [McpCatalogEntry]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  McpCatalogEntry copyWith({
    int? id,
    String? catalogId,
    String? name,
    String? description,
    String? url,
    String? transport,
    bool? isEnabled,
    String? optionsJson,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'McpCatalogEntry',
      if (id != null) 'id': id,
      'catalogId': catalogId,
      'name': name,
      'description': description,
      'url': url,
      'transport': transport,
      'isEnabled': isEnabled,
      'optionsJson': optionsJson,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'McpCatalogEntry',
      if (id != null) 'id': id,
      'catalogId': catalogId,
      'name': name,
      'description': description,
      'url': url,
      'transport': transport,
      'isEnabled': isEnabled,
      'optionsJson': optionsJson,
    };
  }

  static McpCatalogEntryInclude include() {
    return McpCatalogEntryInclude._();
  }

  static McpCatalogEntryIncludeList includeList({
    _is.WhereExpressionBuilder<McpCatalogEntryTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<McpCatalogEntryTable>? orderBy,
    _is.OrderByListBuilder<McpCatalogEntryTable>? orderByList,
    McpCatalogEntryInclude? include,
  }) {
    return McpCatalogEntryIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(McpCatalogEntry.t),
      orderByList: orderByList?.call(McpCatalogEntry.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _McpCatalogEntryImpl extends McpCatalogEntry {
  _McpCatalogEntryImpl({
    int? id,
    required String catalogId,
    required String name,
    required String description,
    required String url,
    required String transport,
    required bool isEnabled,
    required String optionsJson,
  }) : super._(
         id: id,
         catalogId: catalogId,
         name: name,
         description: description,
         url: url,
         transport: transport,
         isEnabled: isEnabled,
         optionsJson: optionsJson,
       );

  /// Returns a shallow copy of this [McpCatalogEntry]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  McpCatalogEntry copyWith({
    Object? id = _Undefined,
    String? catalogId,
    String? name,
    String? description,
    String? url,
    String? transport,
    bool? isEnabled,
    String? optionsJson,
  }) {
    return McpCatalogEntry(
      id: id is int? ? id : this.id,
      catalogId: catalogId ?? this.catalogId,
      name: name ?? this.name,
      description: description ?? this.description,
      url: url ?? this.url,
      transport: transport ?? this.transport,
      isEnabled: isEnabled ?? this.isEnabled,
      optionsJson: optionsJson ?? this.optionsJson,
    );
  }
}

class McpCatalogEntryUpdateTable extends _is.UpdateTable<McpCatalogEntryTable> {
  McpCatalogEntryUpdateTable(super.table);

  _is.ColumnValue<String, String> catalogId(String value) => _is.ColumnValue(
    table.catalogId,
    value,
  );

  _is.ColumnValue<String, String> name(String value) => _is.ColumnValue(
    table.name,
    value,
  );

  _is.ColumnValue<String, String> description(String value) => _is.ColumnValue(
    table.description,
    value,
  );

  _is.ColumnValue<String, String> url(String value) => _is.ColumnValue(
    table.url,
    value,
  );

  _is.ColumnValue<String, String> transport(String value) => _is.ColumnValue(
    table.transport,
    value,
  );

  _is.ColumnValue<bool, bool> isEnabled(bool value) => _is.ColumnValue(
    table.isEnabled,
    value,
  );

  _is.ColumnValue<String, String> optionsJson(String value) => _is.ColumnValue(
    table.optionsJson,
    value,
  );
}

class McpCatalogEntryTable extends _is.Table<int?> {
  McpCatalogEntryTable({super.tableRelation})
    : super(tableName: 'mcp_catalog_entry') {
    updateTable = McpCatalogEntryUpdateTable(this);
    catalogId = _is.ColumnString(
      'catalogId',
      this,
    );
    name = _is.ColumnString(
      'name',
      this,
    );
    description = _is.ColumnString(
      'description',
      this,
    );
    url = _is.ColumnString(
      'url',
      this,
    );
    transport = _is.ColumnString(
      'transport',
      this,
    );
    isEnabled = _is.ColumnBool(
      'isEnabled',
      this,
    );
    optionsJson = _is.ColumnString(
      'optionsJson',
      this,
    );
  }

  late final McpCatalogEntryUpdateTable updateTable;

  late final _is.ColumnString catalogId;

  late final _is.ColumnString name;

  late final _is.ColumnString description;

  late final _is.ColumnString url;

  late final _is.ColumnString transport;

  late final _is.ColumnBool isEnabled;

  late final _is.ColumnString optionsJson;

  @override
  List<_is.Column> get columns => [
    id,
    catalogId,
    name,
    description,
    url,
    transport,
    isEnabled,
    optionsJson,
  ];
}

class McpCatalogEntryInclude extends _is.IncludeObject {
  McpCatalogEntryInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => McpCatalogEntry.t;
}

class McpCatalogEntryIncludeList extends _is.IncludeList {
  McpCatalogEntryIncludeList._({
    _is.WhereExpressionBuilder<McpCatalogEntryTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(McpCatalogEntry.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => McpCatalogEntry.t;
}

class McpCatalogEntryRepository {
  const McpCatalogEntryRepository._();

  /// Returns a list of [McpCatalogEntry]s matching the given query parameters.
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
  Future<List<McpCatalogEntry>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<McpCatalogEntryTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<McpCatalogEntryTable>? orderBy,
    _is.OrderByListBuilder<McpCatalogEntryTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<McpCatalogEntry>(
      where: where?.call(McpCatalogEntry.t),
      orderBy: orderBy?.call(McpCatalogEntry.t),
      orderByList: orderByList?.call(McpCatalogEntry.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [McpCatalogEntry] matching the given query parameters.
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
  Future<McpCatalogEntry?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<McpCatalogEntryTable>? where,
    int? offset,
    _is.OrderByBuilder<McpCatalogEntryTable>? orderBy,
    _is.OrderByListBuilder<McpCatalogEntryTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<McpCatalogEntry>(
      where: where?.call(McpCatalogEntry.t),
      orderBy: orderBy?.call(McpCatalogEntry.t),
      orderByList: orderByList?.call(McpCatalogEntry.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [McpCatalogEntry] by its [id] or null if no such row exists.
  Future<McpCatalogEntry?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<McpCatalogEntry>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [McpCatalogEntry]s in the list and returns the inserted rows.
  ///
  /// The returned [McpCatalogEntry]s will have their `id` fields set.
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
  Future<List<McpCatalogEntry>> insert(
    _is.DatabaseSession session,
    List<McpCatalogEntry> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<McpCatalogEntry>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [McpCatalogEntry] and returns the inserted row.
  ///
  /// The returned [McpCatalogEntry] will have its `id` field set.
  Future<McpCatalogEntry> insertRow(
    _is.DatabaseSession session,
    McpCatalogEntry row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<McpCatalogEntry>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [McpCatalogEntry]s in the list and returns the resulting rows.
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
  /// The returned [McpCatalogEntry]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<McpCatalogEntry>> upsert(
    _is.DatabaseSession session,
    List<McpCatalogEntry> rows, {
    required _is.ColumnSelections<McpCatalogEntryTable> conflictColumns,
    _is.ColumnSelections<McpCatalogEntryTable>? updateColumns,
    _is.WhereExpressionBuilder<McpCatalogEntryTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<McpCatalogEntry>(
      rows,
      conflictColumns: conflictColumns(McpCatalogEntry.t),
      updateColumns: updateColumns?.call(McpCatalogEntry.t),
      updateWhere: updateWhere?.call(McpCatalogEntry.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [McpCatalogEntry] and returns the resulting row.
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
  /// The returned [McpCatalogEntry] will have its `id` field set.
  Future<McpCatalogEntry?> upsertRow(
    _is.DatabaseSession session,
    McpCatalogEntry row, {
    required _is.ColumnSelections<McpCatalogEntryTable> conflictColumns,
    _is.ColumnSelections<McpCatalogEntryTable>? updateColumns,
    _is.WhereExpressionBuilder<McpCatalogEntryTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<McpCatalogEntry>(
      row,
      conflictColumns: conflictColumns(McpCatalogEntry.t),
      updateColumns: updateColumns?.call(McpCatalogEntry.t),
      updateWhere: updateWhere?.call(McpCatalogEntry.t),
      transaction: transaction,
    );
  }

  /// Updates all [McpCatalogEntry]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<McpCatalogEntry>> update(
    _is.DatabaseSession session,
    List<McpCatalogEntry> rows, {
    _is.ColumnSelections<McpCatalogEntryTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<McpCatalogEntry>(
      rows,
      columns: columns?.call(McpCatalogEntry.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [McpCatalogEntry]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<McpCatalogEntry> updateRow(
    _is.DatabaseSession session,
    McpCatalogEntry row, {
    _is.ColumnSelections<McpCatalogEntryTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<McpCatalogEntry>(
      row,
      columns: columns?.call(McpCatalogEntry.t),
      transaction: transaction,
    );
  }

  /// Updates a single [McpCatalogEntry] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<McpCatalogEntry?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<McpCatalogEntryUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<McpCatalogEntry>(
      id,
      columnValues: columnValues(McpCatalogEntry.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [McpCatalogEntry]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<McpCatalogEntry>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<McpCatalogEntryUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<McpCatalogEntryTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<McpCatalogEntryTable>? orderBy,
    _is.OrderByListBuilder<McpCatalogEntryTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<McpCatalogEntry>(
      columnValues: columnValues(McpCatalogEntry.t.updateTable),
      where: where(McpCatalogEntry.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(McpCatalogEntry.t),
      orderByList: orderByList?.call(McpCatalogEntry.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [McpCatalogEntry]s in the list and returns the deleted rows.
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
  Future<List<McpCatalogEntry>> delete(
    _is.DatabaseSession session,
    List<McpCatalogEntry> rows, {
    _is.OrderByBuilder<McpCatalogEntryTable>? orderBy,
    _is.OrderByListBuilder<McpCatalogEntryTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<McpCatalogEntry>(
      rows,
      orderBy: orderBy?.call(McpCatalogEntry.t),
      orderByList: orderByList?.call(McpCatalogEntry.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [McpCatalogEntry].
  Future<McpCatalogEntry> deleteRow(
    _is.DatabaseSession session,
    McpCatalogEntry row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<McpCatalogEntry>(
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
  Future<List<McpCatalogEntry>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<McpCatalogEntryTable> where,
    _is.OrderByBuilder<McpCatalogEntryTable>? orderBy,
    _is.OrderByListBuilder<McpCatalogEntryTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<McpCatalogEntry>(
      where: where(McpCatalogEntry.t),
      orderBy: orderBy?.call(McpCatalogEntry.t),
      orderByList: orderByList?.call(McpCatalogEntry.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<McpCatalogEntryTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<McpCatalogEntry>(
      where: where?.call(McpCatalogEntry.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [McpCatalogEntry] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<McpCatalogEntryTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<McpCatalogEntry>(
      where: where(McpCatalogEntry.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
