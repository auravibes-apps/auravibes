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

abstract class ProviderAdmissionLock
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  ProviderAdmissionLock._({
    this.id,
    required this.key,
  });

  factory ProviderAdmissionLock({
    int? id,
    required String key,
  }) = _ProviderAdmissionLockImpl;

  factory ProviderAdmissionLock.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ProviderAdmissionLock(
      id: jsonSerialization['id'] as int?,
      key: jsonSerialization['key'] as String,
    );
  }

  static final t = ProviderAdmissionLockTable();

  static const db = ProviderAdmissionLockRepository._();

  @override
  int? id;

  String key;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [ProviderAdmissionLock]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ProviderAdmissionLock copyWith({
    int? id,
    String? key,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ProviderAdmissionLock',
      if (id != null) 'id': id,
      'key': key,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ProviderAdmissionLock',
      if (id != null) 'id': id,
      'key': key,
    };
  }

  static ProviderAdmissionLockInclude include() {
    return ProviderAdmissionLockInclude._();
  }

  static ProviderAdmissionLockIncludeList includeList({
    _is.WhereExpressionBuilder<ProviderAdmissionLockTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ProviderAdmissionLockTable>? orderBy,
    _is.OrderByListBuilder<ProviderAdmissionLockTable>? orderByList,
    ProviderAdmissionLockInclude? include,
  }) {
    return ProviderAdmissionLockIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ProviderAdmissionLock.t),
      orderByList: orderByList?.call(ProviderAdmissionLock.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ProviderAdmissionLockImpl extends ProviderAdmissionLock {
  _ProviderAdmissionLockImpl({
    int? id,
    required String key,
  }) : super._(
         id: id,
         key: key,
       );

  /// Returns a shallow copy of this [ProviderAdmissionLock]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ProviderAdmissionLock copyWith({
    Object? id = _Undefined,
    String? key,
  }) {
    return ProviderAdmissionLock(
      id: id is int? ? id : this.id,
      key: key ?? this.key,
    );
  }
}

class ProviderAdmissionLockUpdateTable
    extends _is.UpdateTable<ProviderAdmissionLockTable> {
  ProviderAdmissionLockUpdateTable(super.table);

  _is.ColumnValue<String, String> key(String value) => _is.ColumnValue(
    table.key,
    value,
  );
}

class ProviderAdmissionLockTable extends _is.Table<int?> {
  ProviderAdmissionLockTable({super.tableRelation})
    : super(tableName: 'provider_admission_lock') {
    updateTable = ProviderAdmissionLockUpdateTable(this);
    key = _is.ColumnString(
      'key',
      this,
    );
  }

  late final ProviderAdmissionLockUpdateTable updateTable;

  late final _is.ColumnString key;

  @override
  List<_is.Column> get columns => [
    id,
    key,
  ];
}

class ProviderAdmissionLockInclude extends _is.IncludeObject {
  ProviderAdmissionLockInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => ProviderAdmissionLock.t;
}

class ProviderAdmissionLockIncludeList extends _is.IncludeList {
  ProviderAdmissionLockIncludeList._({
    _is.WhereExpressionBuilder<ProviderAdmissionLockTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ProviderAdmissionLock.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => ProviderAdmissionLock.t;
}

class ProviderAdmissionLockRepository {
  const ProviderAdmissionLockRepository._();

  /// Returns a list of [ProviderAdmissionLock]s matching the given query parameters.
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
  Future<List<ProviderAdmissionLock>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ProviderAdmissionLockTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ProviderAdmissionLockTable>? orderBy,
    _is.OrderByListBuilder<ProviderAdmissionLockTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ProviderAdmissionLock>(
      where: where?.call(ProviderAdmissionLock.t),
      orderBy: orderBy?.call(ProviderAdmissionLock.t),
      orderByList: orderByList?.call(ProviderAdmissionLock.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [ProviderAdmissionLock] matching the given query parameters.
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
  Future<ProviderAdmissionLock?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ProviderAdmissionLockTable>? where,
    int? offset,
    _is.OrderByBuilder<ProviderAdmissionLockTable>? orderBy,
    _is.OrderByListBuilder<ProviderAdmissionLockTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ProviderAdmissionLock>(
      where: where?.call(ProviderAdmissionLock.t),
      orderBy: orderBy?.call(ProviderAdmissionLock.t),
      orderByList: orderByList?.call(ProviderAdmissionLock.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ProviderAdmissionLock] by its [id] or null if no such row exists.
  Future<ProviderAdmissionLock?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ProviderAdmissionLock>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ProviderAdmissionLock]s in the list and returns the inserted rows.
  ///
  /// The returned [ProviderAdmissionLock]s will have their `id` fields set.
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
  Future<List<ProviderAdmissionLock>> insert(
    _is.DatabaseSession session,
    List<ProviderAdmissionLock> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<ProviderAdmissionLock>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [ProviderAdmissionLock] and returns the inserted row.
  ///
  /// The returned [ProviderAdmissionLock] will have its `id` field set.
  Future<ProviderAdmissionLock> insertRow(
    _is.DatabaseSession session,
    ProviderAdmissionLock row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<ProviderAdmissionLock>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [ProviderAdmissionLock]s in the list and returns the resulting rows.
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
  /// The returned [ProviderAdmissionLock]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ProviderAdmissionLock>> upsert(
    _is.DatabaseSession session,
    List<ProviderAdmissionLock> rows, {
    required _is.ColumnSelections<ProviderAdmissionLockTable> conflictColumns,
    _is.ColumnSelections<ProviderAdmissionLockTable>? updateColumns,
    _is.WhereExpressionBuilder<ProviderAdmissionLockTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<ProviderAdmissionLock>(
      rows,
      conflictColumns: conflictColumns(ProviderAdmissionLock.t),
      updateColumns: updateColumns?.call(ProviderAdmissionLock.t),
      updateWhere: updateWhere?.call(ProviderAdmissionLock.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [ProviderAdmissionLock] and returns the resulting row.
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
  /// The returned [ProviderAdmissionLock] will have its `id` field set.
  Future<ProviderAdmissionLock?> upsertRow(
    _is.DatabaseSession session,
    ProviderAdmissionLock row, {
    required _is.ColumnSelections<ProviderAdmissionLockTable> conflictColumns,
    _is.ColumnSelections<ProviderAdmissionLockTable>? updateColumns,
    _is.WhereExpressionBuilder<ProviderAdmissionLockTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<ProviderAdmissionLock>(
      row,
      conflictColumns: conflictColumns(ProviderAdmissionLock.t),
      updateColumns: updateColumns?.call(ProviderAdmissionLock.t),
      updateWhere: updateWhere?.call(ProviderAdmissionLock.t),
      transaction: transaction,
    );
  }

  /// Updates all [ProviderAdmissionLock]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ProviderAdmissionLock>> update(
    _is.DatabaseSession session,
    List<ProviderAdmissionLock> rows, {
    _is.ColumnSelections<ProviderAdmissionLockTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<ProviderAdmissionLock>(
      rows,
      columns: columns?.call(ProviderAdmissionLock.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [ProviderAdmissionLock]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ProviderAdmissionLock> updateRow(
    _is.DatabaseSession session,
    ProviderAdmissionLock row, {
    _is.ColumnSelections<ProviderAdmissionLockTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<ProviderAdmissionLock>(
      row,
      columns: columns?.call(ProviderAdmissionLock.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ProviderAdmissionLock] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ProviderAdmissionLock?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<ProviderAdmissionLockUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<ProviderAdmissionLock>(
      id,
      columnValues: columnValues(ProviderAdmissionLock.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ProviderAdmissionLock]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ProviderAdmissionLock>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<ProviderAdmissionLockUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<ProviderAdmissionLockTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ProviderAdmissionLockTable>? orderBy,
    _is.OrderByListBuilder<ProviderAdmissionLockTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<ProviderAdmissionLock>(
      columnValues: columnValues(ProviderAdmissionLock.t.updateTable),
      where: where(ProviderAdmissionLock.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ProviderAdmissionLock.t),
      orderByList: orderByList?.call(ProviderAdmissionLock.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [ProviderAdmissionLock]s in the list and returns the deleted rows.
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
  Future<List<ProviderAdmissionLock>> delete(
    _is.DatabaseSession session,
    List<ProviderAdmissionLock> rows, {
    _is.OrderByBuilder<ProviderAdmissionLockTable>? orderBy,
    _is.OrderByListBuilder<ProviderAdmissionLockTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<ProviderAdmissionLock>(
      rows,
      orderBy: orderBy?.call(ProviderAdmissionLock.t),
      orderByList: orderByList?.call(ProviderAdmissionLock.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [ProviderAdmissionLock].
  Future<ProviderAdmissionLock> deleteRow(
    _is.DatabaseSession session,
    ProviderAdmissionLock row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ProviderAdmissionLock>(
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
  Future<List<ProviderAdmissionLock>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ProviderAdmissionLockTable> where,
    _is.OrderByBuilder<ProviderAdmissionLockTable>? orderBy,
    _is.OrderByListBuilder<ProviderAdmissionLockTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<ProviderAdmissionLock>(
      where: where(ProviderAdmissionLock.t),
      orderBy: orderBy?.call(ProviderAdmissionLock.t),
      orderByList: orderByList?.call(ProviderAdmissionLock.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ProviderAdmissionLockTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<ProviderAdmissionLock>(
      where: where?.call(ProviderAdmissionLock.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ProviderAdmissionLock] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ProviderAdmissionLockTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ProviderAdmissionLock>(
      where: where(ProviderAdmissionLock.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
