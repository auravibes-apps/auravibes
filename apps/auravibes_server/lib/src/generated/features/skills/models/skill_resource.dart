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

abstract class SkillResource
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  SkillResource._({
    this.id,
    required this.workspaceId,
    required this.skillId,
    required this.resourceId,
    required this.title,
    required this.slug,
    required this.description,
    required this.content,
    required this.revision,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory SkillResource({
    int? id,
    required int workspaceId,
    required String skillId,
    required String resourceId,
    required String title,
    required String slug,
    required String description,
    required String content,
    required int revision,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
  }) = _SkillResourceImpl;

  factory SkillResource.fromJson(Map<String, dynamic> jsonSerialization) {
    return SkillResource(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      skillId: jsonSerialization['skillId'] as String,
      resourceId: jsonSerialization['resourceId'] as String,
      title: jsonSerialization['title'] as String,
      slug: jsonSerialization['slug'] as String,
      description: jsonSerialization['description'] as String,
      content: jsonSerialization['content'] as String,
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

  static final t = SkillResourceTable();

  static const db = SkillResourceRepository._();

  @override
  int? id;

  int workspaceId;

  String skillId;

  String resourceId;

  String title;

  String slug;

  String description;

  String content;

  int revision;

  DateTime createdAt;

  DateTime updatedAt;

  DateTime? deletedAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [SkillResource]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  SkillResource copyWith({
    int? id,
    int? workspaceId,
    String? skillId,
    String? resourceId,
    String? title,
    String? slug,
    String? description,
    String? content,
    int? revision,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SkillResource',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'skillId': skillId,
      'resourceId': resourceId,
      'title': title,
      'slug': slug,
      'description': description,
      'content': content,
      'revision': revision,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      if (deletedAt != null) 'deletedAt': deletedAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'SkillResource',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'skillId': skillId,
      'resourceId': resourceId,
      'title': title,
      'slug': slug,
      'description': description,
      'content': content,
      'revision': revision,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      if (deletedAt != null) 'deletedAt': deletedAt?.toJson(),
    };
  }

  static SkillResourceInclude include() {
    return SkillResourceInclude._();
  }

  static SkillResourceIncludeList includeList({
    _is.WhereExpressionBuilder<SkillResourceTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SkillResourceTable>? orderBy,
    _is.OrderByListBuilder<SkillResourceTable>? orderByList,
    SkillResourceInclude? include,
  }) {
    return SkillResourceIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(SkillResource.t),
      orderByList: orderByList?.call(SkillResource.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SkillResourceImpl extends SkillResource {
  _SkillResourceImpl({
    int? id,
    required int workspaceId,
    required String skillId,
    required String resourceId,
    required String title,
    required String slug,
    required String description,
    required String content,
    required int revision,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         skillId: skillId,
         resourceId: resourceId,
         title: title,
         slug: slug,
         description: description,
         content: content,
         revision: revision,
         createdAt: createdAt,
         updatedAt: updatedAt,
         deletedAt: deletedAt,
       );

  /// Returns a shallow copy of this [SkillResource]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  SkillResource copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    String? skillId,
    String? resourceId,
    String? title,
    String? slug,
    String? description,
    String? content,
    int? revision,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? deletedAt = _Undefined,
  }) {
    return SkillResource(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      skillId: skillId ?? this.skillId,
      resourceId: resourceId ?? this.resourceId,
      title: title ?? this.title,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      content: content ?? this.content,
      revision: revision ?? this.revision,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt is DateTime? ? deletedAt : this.deletedAt,
    );
  }
}

class SkillResourceUpdateTable extends _is.UpdateTable<SkillResourceTable> {
  SkillResourceUpdateTable(super.table);

  _is.ColumnValue<int, int> workspaceId(int value) => _is.ColumnValue(
    table.workspaceId,
    value,
  );

  _is.ColumnValue<String, String> skillId(String value) => _is.ColumnValue(
    table.skillId,
    value,
  );

  _is.ColumnValue<String, String> resourceId(String value) => _is.ColumnValue(
    table.resourceId,
    value,
  );

  _is.ColumnValue<String, String> title(String value) => _is.ColumnValue(
    table.title,
    value,
  );

  _is.ColumnValue<String, String> slug(String value) => _is.ColumnValue(
    table.slug,
    value,
  );

  _is.ColumnValue<String, String> description(String value) => _is.ColumnValue(
    table.description,
    value,
  );

  _is.ColumnValue<String, String> content(String value) => _is.ColumnValue(
    table.content,
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

class SkillResourceTable extends _is.Table<int?> {
  SkillResourceTable({super.tableRelation})
    : super(tableName: 'skill_resource') {
    updateTable = SkillResourceUpdateTable(this);
    workspaceId = _is.ColumnInt(
      'workspaceId',
      this,
    );
    skillId = _is.ColumnString(
      'skillId',
      this,
    );
    resourceId = _is.ColumnString(
      'resourceId',
      this,
    );
    title = _is.ColumnString(
      'title',
      this,
    );
    slug = _is.ColumnString(
      'slug',
      this,
    );
    description = _is.ColumnString(
      'description',
      this,
    );
    content = _is.ColumnString(
      'content',
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

  late final SkillResourceUpdateTable updateTable;

  late final _is.ColumnInt workspaceId;

  late final _is.ColumnString skillId;

  late final _is.ColumnString resourceId;

  late final _is.ColumnString title;

  late final _is.ColumnString slug;

  late final _is.ColumnString description;

  late final _is.ColumnString content;

  late final _is.ColumnInt revision;

  late final _is.ColumnDateTime createdAt;

  late final _is.ColumnDateTime updatedAt;

  late final _is.ColumnDateTime deletedAt;

  @override
  List<_is.Column> get columns => [
    id,
    workspaceId,
    skillId,
    resourceId,
    title,
    slug,
    description,
    content,
    revision,
    createdAt,
    updatedAt,
    deletedAt,
  ];
}

class SkillResourceInclude extends _is.IncludeObject {
  SkillResourceInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => SkillResource.t;
}

class SkillResourceIncludeList extends _is.IncludeList {
  SkillResourceIncludeList._({
    _is.WhereExpressionBuilder<SkillResourceTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(SkillResource.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => SkillResource.t;
}

class SkillResourceRepository {
  const SkillResourceRepository._();

  /// Returns a list of [SkillResource]s matching the given query parameters.
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
  Future<List<SkillResource>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SkillResourceTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SkillResourceTable>? orderBy,
    _is.OrderByListBuilder<SkillResourceTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<SkillResource>(
      where: where?.call(SkillResource.t),
      orderBy: orderBy?.call(SkillResource.t),
      orderByList: orderByList?.call(SkillResource.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [SkillResource] matching the given query parameters.
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
  Future<SkillResource?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SkillResourceTable>? where,
    int? offset,
    _is.OrderByBuilder<SkillResourceTable>? orderBy,
    _is.OrderByListBuilder<SkillResourceTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<SkillResource>(
      where: where?.call(SkillResource.t),
      orderBy: orderBy?.call(SkillResource.t),
      orderByList: orderByList?.call(SkillResource.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [SkillResource] by its [id] or null if no such row exists.
  Future<SkillResource?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<SkillResource>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [SkillResource]s in the list and returns the inserted rows.
  ///
  /// The returned [SkillResource]s will have their `id` fields set.
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
  Future<List<SkillResource>> insert(
    _is.DatabaseSession session,
    List<SkillResource> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<SkillResource>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [SkillResource] and returns the inserted row.
  ///
  /// The returned [SkillResource] will have its `id` field set.
  Future<SkillResource> insertRow(
    _is.DatabaseSession session,
    SkillResource row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<SkillResource>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [SkillResource]s in the list and returns the resulting rows.
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
  /// The returned [SkillResource]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<SkillResource>> upsert(
    _is.DatabaseSession session,
    List<SkillResource> rows, {
    required _is.ColumnSelections<SkillResourceTable> conflictColumns,
    _is.ColumnSelections<SkillResourceTable>? updateColumns,
    _is.WhereExpressionBuilder<SkillResourceTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<SkillResource>(
      rows,
      conflictColumns: conflictColumns(SkillResource.t),
      updateColumns: updateColumns?.call(SkillResource.t),
      updateWhere: updateWhere?.call(SkillResource.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [SkillResource] and returns the resulting row.
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
  /// The returned [SkillResource] will have its `id` field set.
  Future<SkillResource?> upsertRow(
    _is.DatabaseSession session,
    SkillResource row, {
    required _is.ColumnSelections<SkillResourceTable> conflictColumns,
    _is.ColumnSelections<SkillResourceTable>? updateColumns,
    _is.WhereExpressionBuilder<SkillResourceTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<SkillResource>(
      row,
      conflictColumns: conflictColumns(SkillResource.t),
      updateColumns: updateColumns?.call(SkillResource.t),
      updateWhere: updateWhere?.call(SkillResource.t),
      transaction: transaction,
    );
  }

  /// Updates all [SkillResource]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<SkillResource>> update(
    _is.DatabaseSession session,
    List<SkillResource> rows, {
    _is.ColumnSelections<SkillResourceTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<SkillResource>(
      rows,
      columns: columns?.call(SkillResource.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [SkillResource]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<SkillResource> updateRow(
    _is.DatabaseSession session,
    SkillResource row, {
    _is.ColumnSelections<SkillResourceTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<SkillResource>(
      row,
      columns: columns?.call(SkillResource.t),
      transaction: transaction,
    );
  }

  /// Updates a single [SkillResource] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<SkillResource?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<SkillResourceUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<SkillResource>(
      id,
      columnValues: columnValues(SkillResource.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [SkillResource]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<SkillResource>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<SkillResourceUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<SkillResourceTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SkillResourceTable>? orderBy,
    _is.OrderByListBuilder<SkillResourceTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<SkillResource>(
      columnValues: columnValues(SkillResource.t.updateTable),
      where: where(SkillResource.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(SkillResource.t),
      orderByList: orderByList?.call(SkillResource.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [SkillResource]s in the list and returns the deleted rows.
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
  Future<List<SkillResource>> delete(
    _is.DatabaseSession session,
    List<SkillResource> rows, {
    _is.OrderByBuilder<SkillResourceTable>? orderBy,
    _is.OrderByListBuilder<SkillResourceTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<SkillResource>(
      rows,
      orderBy: orderBy?.call(SkillResource.t),
      orderByList: orderByList?.call(SkillResource.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [SkillResource].
  Future<SkillResource> deleteRow(
    _is.DatabaseSession session,
    SkillResource row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<SkillResource>(
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
  Future<List<SkillResource>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<SkillResourceTable> where,
    _is.OrderByBuilder<SkillResourceTable>? orderBy,
    _is.OrderByListBuilder<SkillResourceTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<SkillResource>(
      where: where(SkillResource.t),
      orderBy: orderBy?.call(SkillResource.t),
      orderByList: orderByList?.call(SkillResource.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SkillResourceTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<SkillResource>(
      where: where?.call(SkillResource.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [SkillResource] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<SkillResourceTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<SkillResource>(
      where: where(SkillResource.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
