import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/local_workspace_table_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_record_query.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:drift/drift.dart';

class const LocalWorkspaceRecordQueryRepository(
  final AppDatabase database,
  final String workspaceId,
) implements WorkspaceRecordQueryRepository {
  @override
  Future<WorkspaceRecordPage> query(
    String tableId,
    WorkspaceRecordQuery query,
  ) async {
    final table = await LocalWorkspaceTableRepository(
      database,
      workspaceId,
    ).table(tableId);
    final statement = _QueryStatement(workspaceId, table, query);
    statement._validate();
    final rows = await _read(statement);

    return _page(rows, query.limit);
  }

  Future<List<QueryRow>> _read(_QueryStatement statement) => database
      .customSelect(
        _sql(statement.query.descending),
        variables: statement._variables(),
        readsFrom: {database.workspaceTableRecords},
      )
      .get();
}

String _path(String id) => '\$.${jsonEncode(id)}';

String _sql(bool descending) =>
    '''
SELECT id, table_id, values_json, revision FROM workspace_table_records
WHERE workspace_id = ? AND table_id = ? AND deleted_at IS NULL
AND (? = '' OR instr(lower(CAST(json_extract(values_json, ?) AS TEXT)), ?) > 0)
AND (? = '' OR CASE json_type(values_json, ?) WHEN 'true' THEN 'true' WHEN 'false' THEN 'false' ELSE CAST(json_extract(values_json, ?) AS TEXT) END = ?)
ORDER BY json_extract(values_json, ?) ${descending ? 'DESC' : 'ASC'}, id ASC
LIMIT ? OFFSET ?
''';

WorkspaceRecord _record(QueryRow row) => WorkspaceRecord(
  id: row.read<String>('id'),
  tableId: row.read<String>('table_id'),
  values: _values(row.read<String>('values_json')),
  revision: row.read<int>('revision'),
);

void _requireSupported(WorkspaceTable table, String columnId) {
  final column = table.columns.firstWhere((column) => column.id == columnId);
  if ({
    'timestamp',
    'money',
    'multiSelect',
    'attachment',
    'reference',
  }.contains(column.type.name))
    throw const WorkspaceTableException();
}

Map<String, Object?> _values(String encoded) =>
    (jsonDecode(encoded) as Map<String, dynamic>).cast<String, Object?>();
WorkspaceRecordPage _page(List<QueryRow> rows, int limit) =>
    WorkspaceRecordPage(
      records: rows.take(limit).map(_record).toList(),
      hasMore: rows.length > limit,
    );

class const _QueryStatement(
  final String workspaceId,
  final WorkspaceTable table,
  final WorkspaceRecordQuery query,
) {
  String get _sort => query.sortColumnId ?? table.labelColumnId;
  String get _filter => query.filterColumnId ?? table.labelColumnId;
  void _validate() {
    _column(_sort);
    if (query.filterColumnId != null) _column(_filter);
  }

  void _column(String id) {
    if (!table.columns.any((column) => column.id == id))
      throw const WorkspaceTableException();
    _requireSupported(table, id);
  }

  List<Variable<Object>> _variables() => [
    Variable(workspaceId),
    Variable(table.id),
    ..._search(),
    ..._filters(),
    Variable(_path(_sort)),
    Variable(query.limit + 1),
    Variable(query.offset),
  ];
  List<Variable<String>> _search() => [
    Variable(_fold(query.search)),
    Variable(_path(table.labelColumnId)),
    Variable(_fold(query.search)),
  ];
  List<Variable<String>> _filters() => [
    Variable(query.filterColumnId ?? ''),
    Variable(_path(_filter)),
    Variable(_path(_filter)),
    Variable(query.filterValue ?? ''),
  ];
}

String _fold(String value) => value.replaceAllMapped(
  RegExp('[A-Z]'),
  (match) => match.group(0)?.toLowerCase() ?? '',
);
