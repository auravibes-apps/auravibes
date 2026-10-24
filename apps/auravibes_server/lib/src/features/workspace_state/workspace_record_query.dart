import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'repositories/workspace_state_repository.dart';
import 'workspace_table_access.dart';

typedef WorkspaceRecordQueryInput = ({
  int workspaceId,
  String tableId,
  String encoded,
});

/// Bounded host-owned record queries. SQL values use bound parameters.
class const WorkspaceRecordQuery() {
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
  Future<List<WorkspaceResource>> read() async {
    final source = await _AuthorizedTable(
      session,
      userId,
      input,
      transaction,
    ).read();
    final query = _QueryParameters(input.encoded, source.table).read();

    return await _QueryReader(
      session,
      input,
      transaction,
      source.member,
    ).read(query);
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
  _QueryParameters(String encoded, WorkspaceResource table)
    : input = _decodeInput(encoded),
      data = _decode(table.data);
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
    }
  }

  Map<String, Object?> _selection() {
    final sort =
        input['sortColumnId'] as String? ?? data['labelColumnId'] as String;
    final filter = input['filterColumnId'] as String? ?? '';
    final sortColumn = _column(sort);
    if (filter.isNotEmpty) {
      final _ = _column(filter);
    }

    return {
      'sort': sort,
      'filter': filter,
      'label': data['labelColumnId'],
      'numeric': sortColumn['type'] == 'number',
    };
  }

  Map<String, Object?> _pagination() {
    final limit = input['limit'] as int? ?? 50;
    final offset = input['offset'] as int? ?? 0;
    if (limit < 1 ||
        limit > _maxPageSize ||
        offset < 0 ||
        offset > _maxOffset) {
      _invalid();
    }

    return {'limit': limit + 1, 'offset': offset};
  }

  Map<String, Object?> _text() {
    final search = input['search'] as String? ?? '';
    final value = input['filterValue'] as String? ?? '';
    if (search.length > _maxTextLength || value.length > _maxTextLength) {
      _invalid();
    }

    return {'search': _fold(search), 'value': value};
  }

  Map<String, dynamic> _column(String id) {
    final column = columns.where((column) => column['id'] == id).firstOrNull;
    if (column == null || _unsupported.contains(column['type'])) _invalid();

    return column;
  }
}

const _unsupported = {
  'timestamp',
  'money',
  'multiSelect',
  'attachment',
  'reference',
};

String _sql(bool descending, bool numeric) =>
    '''
SELECT "resourceId" FROM workspace_resource
WHERE "workspaceId" = @workspaceId AND "resourceKind" = 'tableRecord' AND "deletedAt" IS NULL
AND data::jsonb->>'tableId' = @tableId
AND (@search = '' OR strpos(translate(data::jsonb->'values'->>@label, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), @search) > 0)
AND (@filter = '' OR data::jsonb->'values'->>@filter = @value)
ORDER BY ${_order(numeric)} ${descending ? 'DESC' : 'ASC'} ${descending ? 'NULLS LAST' : 'NULLS FIRST'}, "resourceId" ASC
LIMIT @limit OFFSET @offset
''';

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

String _order(bool numeric) => numeric
    ? "(data::jsonb->'values'->>@sort)::numeric"
    : "(data::jsonb->'values'->>@sort) COLLATE \"C\"";

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

const _maxEncodedLength = 2000;

String _querySql(Map<String, Object?> query) {
  final descending = query.remove('descending') == true;
  final numeric = query.remove('numeric') == true;

  return _sql(descending, numeric);
}
