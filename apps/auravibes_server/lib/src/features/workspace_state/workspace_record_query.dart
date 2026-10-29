import 'dart:convert';

import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../accounts/auth_user_lock.dart';
import 'domain/workspace_query_filter_validation.dart';
import 'repositories/workspace_state_repository.dart';
import 'workspace_record_query_reference_access.dart';
import 'workspace_record_query_sql.dart';
import 'workspace_table_access.dart';

typedef WorkspaceRecordQueryInput = ({
  int workspaceId,
  String tableId,
  String encoded,
});

/// Bounded host-owned record queries. SQL values use bound parameters.
class const WorkspaceRecordQuery() {
  Future<Map<String, Object?>> summarize(
    Session session,
    String userId,
    WorkspaceRecordQueryInput input,
    List<String> columnIds,
  ) => session.db.transaction(
    (transaction) => _CloudRecordSummary(
      _QueryScope(session, userId, input, transaction),
      columnIds,
    ).read(),
  );
  Future<List<WorkspaceResource>> call(
    Session session,
    String userId,
    WorkspaceRecordQueryInput input,
  ) => session.db.transaction(
    (transaction) => _QueryScope(session, userId, input, transaction).read(),
  );
}

class const _QueryScope(
  final Session session,
  final String userId,
  final WorkspaceRecordQueryInput input,
  final Transaction transaction,
) {
  Future<List<WorkspaceResource>> read({bool summary = false}) async {
    final source = await _AuthorizedTable(
      session,
      userId,
      input,
      transaction,
    ).read();
    final query = _QueryParameters(
      input.encoded,
      source.table,
      summary: summary,
    ).read();
    await _target(source.member, query);

    return await _QueryReader(
      session,
      input,
      transaction,
      source.member,
    ).read(query);
  }

  Future<void> _target(
    WorkspaceMember member,
    Map<String, Object?> query,
  ) async {
    final target = query.remove('referenceTarget');
    if (query['filterType'] != 'reference') return;
    if (target is! String || target.isEmpty) _denied();
    await WorkspaceRecordQueryReferenceAccess(
      session,
      member,
      input.workspaceId,
      transaction,
    ).require(target, query['value'] as String);
  }
}

typedef _AuthorizedSource = ({WorkspaceResource table, WorkspaceMember member});

class const _AuthorizedTable(
  final Session session,
  final String userId,
  final WorkspaceRecordQueryInput input,
  final Transaction transaction,
) {
  Future<_AuthorizedSource> read() async {
    final authUser = await const AuthUserLock().lock(
      session,
      userId: userId,
      transaction: transaction,
    );
    if (authUser == null) {
      throw CloudWorkspaceException(
        code: CloudWorkspaceErrorCode.authenticationRequired,
      );
    }
    final repository = WorkspaceStateRepository();
    await _workspace(repository);
    final member = await repository.findMember(
      session,
      workspaceId: input.workspaceId,
      userId: userId,
      transaction: transaction,
    );
    if (member == null) _denied();

    return (table: await _visible(member), member: member);
  }

  Future<void> _workspace(WorkspaceStateRepository repository) async {
    final workspace = await repository.findWorkspace(
      session,
      input.workspaceId,
      transaction: transaction,
      lock: true,
    );
    if (workspace == null) _denied();
  }

  Future<WorkspaceResource> _visible(WorkspaceMember member) async {
    final table = await WorkspaceResource.db.findFirstRow(
      session,
      where: _matches,
      transaction: transaction,
    );
    if (table == null) _denied();
    WorkspaceRecordQueryReferenceAccess.requireSchema(table);
    final visible = await WorkspaceTableAccess(transaction: transaction)
        .visible(
          session,
          member,
          table,
        );
    if (visible == null) _denied();

    return visible;
  }

  Expression _matches(WorkspaceResourceTable row) =>
      _active(row, input.workspaceId, .table) &
      row.resourceId.equals(input.tableId);
}

class const _QueryReader(
  final Session session,
  final WorkspaceRecordQueryInput input,
  final Transaction transaction,
  final WorkspaceMember member,
) {
  Future<List<WorkspaceResource>> read(Map<String, Object?> query) async {
    final ids = await _ids(query);

    return await _resources(ids);
  }

  Future<List<String>> _ids(Map<String, Object?> query) async {
    final rows = await session.db.unsafeQuery(
      _querySql(query),
      parameters: .named(_parameters(query)),
      transaction: transaction,
    );

    return rows
        .map((row) => row.toColumnMap()['resourceId'] as String)
        .toList();
  }

  Map<String, Object?> _parameters(Map<String, Object?> query) => {
    ...query,
    'workspaceId': input.workspaceId,
    'tableId': input.tableId,
  };

  Future<List<WorkspaceResource>> _resources(List<String> ids) async {
    if (ids.isEmpty) return [];
    final rows = await _find(ids);

    return await _visible(_ordered(rows, ids));
  }

  Future<List<WorkspaceResource>> _visible(List<WorkspaceResource> rows) async {
    final access = WorkspaceTableAccess(transaction: transaction);

    return [
      for (final row in rows) ?await access.visible(session, member, row),
    ];
  }

  Future<List<WorkspaceResource>> _find(List<String> ids) async {
    return await WorkspaceResource.db.find(
      session,
      where: (row) =>
          _active(row, input.workspaceId, .tableRecord) &
          row.resourceId.inSet(ids.toSet()),
      transaction: transaction,
    );
  }

  List<WorkspaceResource> _ordered(
    List<WorkspaceResource> rows,
    List<String> ids,
  ) {
    final byId = {
      for (final row in rows.where(_matchesTable)) row.resourceId: row,
    };

    return [for (final id in ids) ?byId[id]];
  }

  bool _matchesTable(WorkspaceResource row) =>
      (jsonDecode(row.data) as Map<String, dynamic>)['tableId'] ==
      input.tableId;
}

Expression _active(
  WorkspaceResourceTable row,
  int workspaceId,
  WorkspaceResourceKind kind,
) =>
    row.workspaceId.equals(workspaceId) &
    row.resourceKind.equals(kind) &
    row.deletedAt.equals(null);

class _QueryParameters {
  static const _maxTextLength = 200;
  static const _maxPageSize = 100;
  static const _maxOffset = 100000;
  _QueryParameters(
    String encoded,
    WorkspaceResource table, {
    this.summary = false,
  }) : input = _decodeInput(encoded),
       data = _decode(table.data);
  final bool summary;
  final Map<String, dynamic> input;
  final Map<String, dynamic> data;
  List<Map<String, dynamic>> get columns =>
      (data['columns'] as List<dynamic>).cast<Map<String, dynamic>>();

  Map<String, Object?> read() {
    try {
      return {
        ..._selection(),
        ..._pagination(),
        ..._text(),
        'descending': input['descending'] == true,
      };
    } on TypeError {
      _invalid();
    } on FormatException {
      _invalid();
    }
  }

  Map<String, Object?> _selection() {
    final sort =
        input['sortColumnId'] as String? ?? data['labelColumnId'] as String;

    final column = _column(sort);
    if (_unsupported.contains(column['type'])) _invalid();

    return {
      'sort': sort,
      'label': data['labelColumnId'],
      'sortType': column['type'],
      ..._filter(),
    };
  }

  Map<String, Object?> _filter() {
    final filter = input['filterColumnId'] as String? ?? '';
    final column = filter.isEmpty ? null : _column(filter);
    if (column != null) _validateFilter(column);

    return {
      'filter': filter,
      'filterType': column?['type'] ?? 'text',
      'contains': input['filterOperator'] == 'contains',
      'referenceMultiple': column?['referenceMultiple'] == true,
      if (column?['type'] == 'reference')
        'referenceTarget': column?['targetTableId'],
    };
  }

  void _validateFilter(Map<String, dynamic> column) =>
      WorkspaceQueryFilterValidation.validate(
        column,
        input['filterValue'] as String? ?? '',
        operator: input['filterOperator'] as String? ?? 'equals',
      );

  Map<String, Object?> _pagination() {
    final limit = input['limit'] as int? ?? 50;
    final offset = input['offset'] as int? ?? 0;
    if (limit < 1 ||
        limit > _maxPageSize ||
        offset < 0 ||
        !summary && offset > _maxOffset) {
      _invalid();
    }

    return {'limit': limit + 1, 'offset': offset};
  }

  Map<String, Object?> _text() {
    final search = input['search'] as String? ?? '';
    final value = input['filterValue'] as String? ?? '';
    if (search.length > _maxTextLength || value.length > _maxFilterLength) {
      _invalid();
    }

    return {'search': _fold(search), 'value': _normalized(value)};
  }

  String _normalized(String value) {
    final filter = input['filterColumnId'] as String?;
    if (filter == null || filter.isEmpty) return value;
    if (_column(filter)['type'] != 'number') return value;

    return num.parse(value).toString();
  }

  Map<String, dynamic> _column(String id) {
    final column = columns.where((column) => column['id'] == id).firstOrNull;
    if (column == null || column['type'] == 'attachment') _invalid();

    return column;
  }
}

const _unsupported = {
  'multiSelect',
  'attachment',
  'reference',
};

Never _denied() => throw CloudWorkspaceException(
  code: .permissionDenied,
);
Never _invalid() => throw CloudWorkspaceException(
  code: .validationFailed,
);

String _fold(String value) => value.replaceAllMapped(
  RegExp('[A-Z]'),
  (match) => match.group(0)?.toLowerCase() ?? '',
);

Map<String, dynamic> _decodeInput(String encoded) {
  if (encoded.length > _maxEncodedLength) _invalid();

  return _decode(encoded);
}

Map<String, dynamic> _decode(String encoded) {
  try {
    return jsonDecode(encoded) as Map<String, dynamic>;
  } on FormatException {
    _invalid();
  } on TypeError {
    _invalid();
  }
}

// Bound includes worst-case JSON escaping of the existing field value limit.
const _maxEncodedLength = 120000;
const _maxFilterLength = 16448;

String _querySql(Map<String, Object?> query) {
  final descending = query.remove('descending') == true;
  final sortType = query.remove('sortType') as String;
  final filterType = query.remove('filterType') as String;
  final contains = query.remove('contains') == true;
  final referenceMultiple = query.remove('referenceMultiple') == true;

  return WorkspaceRecordQuerySql(
    sortType,
    filterType,
    descending: descending,
    contains: contains,
    referenceMultiple: referenceMultiple,
  ).build();
}

const _summaryBatchSize = 100;
const _maximumSummaryColumns = 50;

class const _CloudRecordSummary(
  final _QueryScope scope,
  final List<String> columnIds,
) {
  Future<Map<String, Object?>> read() async {
    final summary = await _summary();
    var offset = 0;
    while (await _appendPage(summary, offset)) {
      offset += _summaryBatchSize;
    }

    return summary.toJson();
  }

  Future<A2uiDataSummary> _summary() async {
    final source = await _AuthorizedTable(
      scope.session,
      scope.userId,
      scope.input,
      scope.transaction,
    ).read();
    final columns = _summaryColumns(source.table);
    _validateSummaryColumns(columns, columnIds);

    return A2uiDataSummary(_summaryTypes(columns, columnIds));
  }

  Future<bool> _appendPage(A2uiDataSummary summary, int offset) async {
    final rows = await _scope(offset).read(summary: true);
    for (final row in rows.take(_summaryBatchSize)) {
      summary.add(_summaryValues(row));
    }

    return rows.length > _summaryBatchSize;
  }

  _QueryScope _scope(int offset) => _QueryScope(
    scope.session,
    scope.userId,
    _input(offset),
    scope.transaction,
  );
  WorkspaceRecordQueryInput _input(int offset) => (
    workspaceId: scope.input.workspaceId,
    tableId: scope.input.tableId,
    encoded: jsonEncode({
      ..._decodeInput(scope.input.encoded),
      'offset': offset,
      'limit': _summaryBatchSize,
    }),
  );
}

Map<String, Object?> _summaryValues(WorkspaceResource row) {
  final data = _decode(row.data);
  final values = Map<String, Object?>.from(data['values'] as Map);
  for (final id
      in (data['restrictedReferenceColumns'] as List<dynamic>? ?? const [])) {
    values.remove(id);
  }

  return values;
}

void _validateSummaryColumns(
  List<Map<String, dynamic>> columns,
  List<String> ids,
) {
  if (!_validSummaryIds(ids) ||
      ids.any(
        (id) => !columns.any(
          (column) => column['id'] == id && column['type'] != 'attachment',
        ),
      )) {
    _invalid();
  }
}

bool _validSummaryIds(List<String> ids) =>
    ids.length <= _maximumSummaryColumns && ids.length == ids.toSet().length;
Map<String, String> _summaryTypes(
  List<Map<String, dynamic>> columns,
  List<String> ids,
) => {
  for (final column in columns.where((column) => ids.contains(column['id'])))
    column['id'] as String: column['type'] as String,
};

List<Map<String, dynamic>> _summaryColumns(WorkspaceResource source) =>
    (_decode(source.data)['columns'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
