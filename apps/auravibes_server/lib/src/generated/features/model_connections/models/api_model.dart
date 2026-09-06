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
import 'package:auravibes_server/src/generated/protocol.dart' as _if5qez1k;
import 'package:serverpod/serverpod.dart' as _is;

abstract class ApiModel
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  ApiModel._({
    this.id,
    required this.providerId,
    required this.modelId,
    required this.name,
    required this.limitContext,
    required this.limitOutput,
    required this.modalitiesInput,
    required this.modalitiesOutput,
    this.family,
    required this.costInput,
    required this.costCacheRead,
    required this.costOutput,
    required this.openWeights,
    required this.supportsReasoning,
    required this.isCanonical,
    required this.supportsPriorityMode,
    required this.supportsToolCalls,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ApiModel({
    int? id,
    required String providerId,
    required String modelId,
    required String name,
    required int limitContext,
    required int limitOutput,
    required List<String> modalitiesInput,
    required List<String> modalitiesOutput,
    String? family,
    required double costInput,
    required double costCacheRead,
    required double costOutput,
    required bool openWeights,
    required bool supportsReasoning,
    required bool isCanonical,
    required bool supportsPriorityMode,
    required bool supportsToolCalls,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ApiModelImpl;

  factory ApiModel.fromJson(Map<String, dynamic> jsonSerialization) {
    return ApiModel(
      id: jsonSerialization['id'] as int?,
      providerId: jsonSerialization['providerId'] as String,
      modelId: jsonSerialization['modelId'] as String,
      name: jsonSerialization['name'] as String,
      limitContext: jsonSerialization['limitContext'] as int,
      limitOutput: jsonSerialization['limitOutput'] as int,
      modalitiesInput: _if5qez1k.Protocol().deserialize<List<String>>(
        jsonSerialization['modalitiesInput'],
      ),
      modalitiesOutput: _if5qez1k.Protocol().deserialize<List<String>>(
        jsonSerialization['modalitiesOutput'],
      ),
      family: jsonSerialization['family'] as String?,
      costInput: (jsonSerialization['costInput'] as num).toDouble(),
      costCacheRead: (jsonSerialization['costCacheRead'] as num).toDouble(),
      costOutput: (jsonSerialization['costOutput'] as num).toDouble(),
      openWeights: _is.BoolJsonExtension.fromJson(
        jsonSerialization['openWeights'],
      ),
      supportsReasoning: _is.BoolJsonExtension.fromJson(
        jsonSerialization['supportsReasoning'],
      ),
      isCanonical: _is.BoolJsonExtension.fromJson(
        jsonSerialization['isCanonical'],
      ),
      supportsPriorityMode: _is.BoolJsonExtension.fromJson(
        jsonSerialization['supportsPriorityMode'],
      ),
      supportsToolCalls: _is.BoolJsonExtension.fromJson(
        jsonSerialization['supportsToolCalls'],
      ),
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  static final t = ApiModelTable();

  static const db = ApiModelRepository._();

  @override
  int? id;

  String providerId;

  String modelId;

  String name;

  int limitContext;

  int limitOutput;

  List<String> modalitiesInput;

  List<String> modalitiesOutput;

  String? family;

  double costInput;

  double costCacheRead;

  double costOutput;

  bool openWeights;

  bool supportsReasoning;

  bool isCanonical;

  bool supportsPriorityMode;

  bool supportsToolCalls;

  DateTime createdAt;

  DateTime updatedAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [ApiModel]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ApiModel copyWith({
    int? id,
    String? providerId,
    String? modelId,
    String? name,
    int? limitContext,
    int? limitOutput,
    List<String>? modalitiesInput,
    List<String>? modalitiesOutput,
    String? family,
    double? costInput,
    double? costCacheRead,
    double? costOutput,
    bool? openWeights,
    bool? supportsReasoning,
    bool? isCanonical,
    bool? supportsPriorityMode,
    bool? supportsToolCalls,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ApiModel',
      if (id != null) 'id': id,
      'providerId': providerId,
      'modelId': modelId,
      'name': name,
      'limitContext': limitContext,
      'limitOutput': limitOutput,
      'modalitiesInput': modalitiesInput.toJson(),
      'modalitiesOutput': modalitiesOutput.toJson(),
      if (family != null) 'family': family,
      'costInput': costInput,
      'costCacheRead': costCacheRead,
      'costOutput': costOutput,
      'openWeights': openWeights,
      'supportsReasoning': supportsReasoning,
      'isCanonical': isCanonical,
      'supportsPriorityMode': supportsPriorityMode,
      'supportsToolCalls': supportsToolCalls,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ApiModel',
      if (id != null) 'id': id,
      'providerId': providerId,
      'modelId': modelId,
      'name': name,
      'limitContext': limitContext,
      'limitOutput': limitOutput,
      'modalitiesInput': modalitiesInput.toJson(),
      'modalitiesOutput': modalitiesOutput.toJson(),
      if (family != null) 'family': family,
      'costInput': costInput,
      'costCacheRead': costCacheRead,
      'costOutput': costOutput,
      'openWeights': openWeights,
      'supportsReasoning': supportsReasoning,
      'isCanonical': isCanonical,
      'supportsPriorityMode': supportsPriorityMode,
      'supportsToolCalls': supportsToolCalls,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  static ApiModelInclude include() {
    return ApiModelInclude._();
  }

  static ApiModelIncludeList includeList({
    _is.WhereExpressionBuilder<ApiModelTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ApiModelTable>? orderBy,
    _is.OrderByListBuilder<ApiModelTable>? orderByList,
    ApiModelInclude? include,
  }) {
    return ApiModelIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ApiModel.t),
      orderByList: orderByList?.call(ApiModel.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ApiModelImpl extends ApiModel {
  _ApiModelImpl({
    int? id,
    required String providerId,
    required String modelId,
    required String name,
    required int limitContext,
    required int limitOutput,
    required List<String> modalitiesInput,
    required List<String> modalitiesOutput,
    String? family,
    required double costInput,
    required double costCacheRead,
    required double costOutput,
    required bool openWeights,
    required bool supportsReasoning,
    required bool isCanonical,
    required bool supportsPriorityMode,
    required bool supportsToolCalls,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         providerId: providerId,
         modelId: modelId,
         name: name,
         limitContext: limitContext,
         limitOutput: limitOutput,
         modalitiesInput: modalitiesInput,
         modalitiesOutput: modalitiesOutput,
         family: family,
         costInput: costInput,
         costCacheRead: costCacheRead,
         costOutput: costOutput,
         openWeights: openWeights,
         supportsReasoning: supportsReasoning,
         isCanonical: isCanonical,
         supportsPriorityMode: supportsPriorityMode,
         supportsToolCalls: supportsToolCalls,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [ApiModel]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ApiModel copyWith({
    Object? id = _Undefined,
    String? providerId,
    String? modelId,
    String? name,
    int? limitContext,
    int? limitOutput,
    List<String>? modalitiesInput,
    List<String>? modalitiesOutput,
    Object? family = _Undefined,
    double? costInput,
    double? costCacheRead,
    double? costOutput,
    bool? openWeights,
    bool? supportsReasoning,
    bool? isCanonical,
    bool? supportsPriorityMode,
    bool? supportsToolCalls,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ApiModel(
      id: id is int? ? id : this.id,
      providerId: providerId ?? this.providerId,
      modelId: modelId ?? this.modelId,
      name: name ?? this.name,
      limitContext: limitContext ?? this.limitContext,
      limitOutput: limitOutput ?? this.limitOutput,
      modalitiesInput:
          modalitiesInput ?? this.modalitiesInput.map((e0) => e0).toList(),
      modalitiesOutput:
          modalitiesOutput ?? this.modalitiesOutput.map((e0) => e0).toList(),
      family: family is String? ? family : this.family,
      costInput: costInput ?? this.costInput,
      costCacheRead: costCacheRead ?? this.costCacheRead,
      costOutput: costOutput ?? this.costOutput,
      openWeights: openWeights ?? this.openWeights,
      supportsReasoning: supportsReasoning ?? this.supportsReasoning,
      isCanonical: isCanonical ?? this.isCanonical,
      supportsPriorityMode: supportsPriorityMode ?? this.supportsPriorityMode,
      supportsToolCalls: supportsToolCalls ?? this.supportsToolCalls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ApiModelUpdateTable extends _is.UpdateTable<ApiModelTable> {
  ApiModelUpdateTable(super.table);

  _is.ColumnValue<String, String> providerId(String value) => _is.ColumnValue(
    table.providerId,
    value,
  );

  _is.ColumnValue<String, String> modelId(String value) => _is.ColumnValue(
    table.modelId,
    value,
  );

  _is.ColumnValue<String, String> name(String value) => _is.ColumnValue(
    table.name,
    value,
  );

  _is.ColumnValue<int, int> limitContext(int value) => _is.ColumnValue(
    table.limitContext,
    value,
  );

  _is.ColumnValue<int, int> limitOutput(int value) => _is.ColumnValue(
    table.limitOutput,
    value,
  );

  _is.ColumnValue<List<String>, List<String>> modalitiesInput(
    List<String> value,
  ) => _is.ColumnValue(
    table.modalitiesInput,
    value,
  );

  _is.ColumnValue<List<String>, List<String>> modalitiesOutput(
    List<String> value,
  ) => _is.ColumnValue(
    table.modalitiesOutput,
    value,
  );

  _is.ColumnValue<String, String> family(String? value) => _is.ColumnValue(
    table.family,
    value,
  );

  _is.ColumnValue<double, double> costInput(double value) => _is.ColumnValue(
    table.costInput,
    value,
  );

  _is.ColumnValue<double, double> costCacheRead(double value) =>
      _is.ColumnValue(
        table.costCacheRead,
        value,
      );

  _is.ColumnValue<double, double> costOutput(double value) => _is.ColumnValue(
    table.costOutput,
    value,
  );

  _is.ColumnValue<bool, bool> openWeights(bool value) => _is.ColumnValue(
    table.openWeights,
    value,
  );

  _is.ColumnValue<bool, bool> supportsReasoning(bool value) => _is.ColumnValue(
    table.supportsReasoning,
    value,
  );

  _is.ColumnValue<bool, bool> isCanonical(bool value) => _is.ColumnValue(
    table.isCanonical,
    value,
  );

  _is.ColumnValue<bool, bool> supportsPriorityMode(bool value) =>
      _is.ColumnValue(
        table.supportsPriorityMode,
        value,
      );

  _is.ColumnValue<bool, bool> supportsToolCalls(bool value) => _is.ColumnValue(
    table.supportsToolCalls,
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

class ApiModelTable extends _is.Table<int?> {
  ApiModelTable({super.tableRelation}) : super(tableName: 'api_model') {
    updateTable = ApiModelUpdateTable(this);
    providerId = _is.ColumnString(
      'providerId',
      this,
    );
    modelId = _is.ColumnString(
      'modelId',
      this,
    );
    name = _is.ColumnString(
      'name',
      this,
    );
    limitContext = _is.ColumnInt(
      'limitContext',
      this,
    );
    limitOutput = _is.ColumnInt(
      'limitOutput',
      this,
    );
    modalitiesInput = _is.ColumnSerializable<List<String>>(
      'modalitiesInput',
      this,
    );
    modalitiesOutput = _is.ColumnSerializable<List<String>>(
      'modalitiesOutput',
      this,
    );
    family = _is.ColumnString(
      'family',
      this,
    );
    costInput = _is.ColumnDouble(
      'costInput',
      this,
    );
    costCacheRead = _is.ColumnDouble(
      'costCacheRead',
      this,
    );
    costOutput = _is.ColumnDouble(
      'costOutput',
      this,
    );
    openWeights = _is.ColumnBool(
      'openWeights',
      this,
    );
    supportsReasoning = _is.ColumnBool(
      'supportsReasoning',
      this,
    );
    isCanonical = _is.ColumnBool(
      'isCanonical',
      this,
    );
    supportsPriorityMode = _is.ColumnBool(
      'supportsPriorityMode',
      this,
    );
    supportsToolCalls = _is.ColumnBool(
      'supportsToolCalls',
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

  late final ApiModelUpdateTable updateTable;

  late final _is.ColumnString providerId;

  late final _is.ColumnString modelId;

  late final _is.ColumnString name;

  late final _is.ColumnInt limitContext;

  late final _is.ColumnInt limitOutput;

  late final _is.ColumnSerializable<List<String>> modalitiesInput;

  late final _is.ColumnSerializable<List<String>> modalitiesOutput;

  late final _is.ColumnString family;

  late final _is.ColumnDouble costInput;

  late final _is.ColumnDouble costCacheRead;

  late final _is.ColumnDouble costOutput;

  late final _is.ColumnBool openWeights;

  late final _is.ColumnBool supportsReasoning;

  late final _is.ColumnBool isCanonical;

  late final _is.ColumnBool supportsPriorityMode;

  late final _is.ColumnBool supportsToolCalls;

  late final _is.ColumnDateTime createdAt;

  late final _is.ColumnDateTime updatedAt;

  @override
  List<_is.Column> get columns => [
    id,
    providerId,
    modelId,
    name,
    limitContext,
    limitOutput,
    modalitiesInput,
    modalitiesOutput,
    family,
    costInput,
    costCacheRead,
    costOutput,
    openWeights,
    supportsReasoning,
    isCanonical,
    supportsPriorityMode,
    supportsToolCalls,
    createdAt,
    updatedAt,
  ];
}

class ApiModelInclude extends _is.IncludeObject {
  ApiModelInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => ApiModel.t;
}

class ApiModelIncludeList extends _is.IncludeList {
  ApiModelIncludeList._({
    _is.WhereExpressionBuilder<ApiModelTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ApiModel.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => ApiModel.t;
}

class ApiModelRepository {
  const ApiModelRepository._();

  /// Returns a list of [ApiModel]s matching the given query parameters.
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
  Future<List<ApiModel>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ApiModelTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ApiModelTable>? orderBy,
    _is.OrderByListBuilder<ApiModelTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ApiModel>(
      where: where?.call(ApiModel.t),
      orderBy: orderBy?.call(ApiModel.t),
      orderByList: orderByList?.call(ApiModel.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [ApiModel] matching the given query parameters.
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
  Future<ApiModel?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ApiModelTable>? where,
    int? offset,
    _is.OrderByBuilder<ApiModelTable>? orderBy,
    _is.OrderByListBuilder<ApiModelTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ApiModel>(
      where: where?.call(ApiModel.t),
      orderBy: orderBy?.call(ApiModel.t),
      orderByList: orderByList?.call(ApiModel.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ApiModel] by its [id] or null if no such row exists.
  Future<ApiModel?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ApiModel>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ApiModel]s in the list and returns the inserted rows.
  ///
  /// The returned [ApiModel]s will have their `id` fields set.
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
  Future<List<ApiModel>> insert(
    _is.DatabaseSession session,
    List<ApiModel> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<ApiModel>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [ApiModel] and returns the inserted row.
  ///
  /// The returned [ApiModel] will have its `id` field set.
  Future<ApiModel> insertRow(
    _is.DatabaseSession session,
    ApiModel row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<ApiModel>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [ApiModel]s in the list and returns the resulting rows.
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
  /// The returned [ApiModel]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ApiModel>> upsert(
    _is.DatabaseSession session,
    List<ApiModel> rows, {
    required _is.ColumnSelections<ApiModelTable> conflictColumns,
    _is.ColumnSelections<ApiModelTable>? updateColumns,
    _is.WhereExpressionBuilder<ApiModelTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<ApiModel>(
      rows,
      conflictColumns: conflictColumns(ApiModel.t),
      updateColumns: updateColumns?.call(ApiModel.t),
      updateWhere: updateWhere?.call(ApiModel.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [ApiModel] and returns the resulting row.
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
  /// The returned [ApiModel] will have its `id` field set.
  Future<ApiModel?> upsertRow(
    _is.DatabaseSession session,
    ApiModel row, {
    required _is.ColumnSelections<ApiModelTable> conflictColumns,
    _is.ColumnSelections<ApiModelTable>? updateColumns,
    _is.WhereExpressionBuilder<ApiModelTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<ApiModel>(
      row,
      conflictColumns: conflictColumns(ApiModel.t),
      updateColumns: updateColumns?.call(ApiModel.t),
      updateWhere: updateWhere?.call(ApiModel.t),
      transaction: transaction,
    );
  }

  /// Updates all [ApiModel]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ApiModel>> update(
    _is.DatabaseSession session,
    List<ApiModel> rows, {
    _is.ColumnSelections<ApiModelTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<ApiModel>(
      rows,
      columns: columns?.call(ApiModel.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [ApiModel]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ApiModel> updateRow(
    _is.DatabaseSession session,
    ApiModel row, {
    _is.ColumnSelections<ApiModelTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<ApiModel>(
      row,
      columns: columns?.call(ApiModel.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ApiModel] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ApiModel?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<ApiModelUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<ApiModel>(
      id,
      columnValues: columnValues(ApiModel.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ApiModel]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ApiModel>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<ApiModelUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<ApiModelTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ApiModelTable>? orderBy,
    _is.OrderByListBuilder<ApiModelTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<ApiModel>(
      columnValues: columnValues(ApiModel.t.updateTable),
      where: where(ApiModel.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ApiModel.t),
      orderByList: orderByList?.call(ApiModel.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [ApiModel]s in the list and returns the deleted rows.
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
  Future<List<ApiModel>> delete(
    _is.DatabaseSession session,
    List<ApiModel> rows, {
    _is.OrderByBuilder<ApiModelTable>? orderBy,
    _is.OrderByListBuilder<ApiModelTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<ApiModel>(
      rows,
      orderBy: orderBy?.call(ApiModel.t),
      orderByList: orderByList?.call(ApiModel.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [ApiModel].
  Future<ApiModel> deleteRow(
    _is.DatabaseSession session,
    ApiModel row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ApiModel>(
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
  Future<List<ApiModel>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ApiModelTable> where,
    _is.OrderByBuilder<ApiModelTable>? orderBy,
    _is.OrderByListBuilder<ApiModelTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<ApiModel>(
      where: where(ApiModel.t),
      orderBy: orderBy?.call(ApiModel.t),
      orderByList: orderByList?.call(ApiModel.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ApiModelTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<ApiModel>(
      where: where?.call(ApiModel.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ApiModel] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ApiModelTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ApiModel>(
      where: where(ApiModel.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
