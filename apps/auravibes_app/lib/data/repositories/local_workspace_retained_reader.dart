import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:drift/drift.dart';

typedef LocalRetainedData = ({
  Map<String, dynamic> data,
  bool view,
  String kind,
  String id,
});
typedef _Source = ({String table, String kind, String column});

class const LocalWorkspaceRetainedReader(
  final AppDatabase database,
  final String workspaceId,
) {
  Future<List<LocalRetainedData>> read(Set<String> scope) async {
    final result = <LocalRetainedData>[];
    for (final source in _sources) {
      await _appendRows(result, scope, source);
    }
    result.addAll(await _snapshots(scope));

    return result;
  }

  Future<void> _appendRows(
    List<LocalRetainedData> result,
    Set<String> scope,
    _Source source,
  ) async {
    for (final row in await _rows(source.table)) {
      if (scope.contains('${source.kind}:${row.data['id']}')) continue;
      result.add(_current(row, source));
      if (source.kind == 'view') result.addAll(_viewHistory(row));
    }
  }

  Future<List<QueryRow>> _rows(String table) => database
      .customSelect(
        'SELECT * FROM $table WHERE workspace_id = ?',
        variables: [Variable(workspaceId)],
      )
      .get();

  Future<List<LocalRetainedData>> _snapshots(Set<String> scope) async {
    final query = database.select(database.workspaceRevisions)
      ..where((row) => row.workspaceId.equals(workspaceId));
    final rows = await query.get();

    return _retainedSnapshots(rows, scope);
  }
}

const _sources = <_Source>[
  (table: 'workspace_tables', kind: 'table', column: 'columns_json'),
  (table: 'workspace_table_records', kind: 'record', column: 'values_json'),
  (table: 'workspace_views', kind: 'view', column: 'data'),
  (table: 'workspace_folders', kind: 'folder', column: 'name'),
  (table: 'workspace_files', kind: 'file', column: 'asset_id'),
];
Map<String, dynamic> _data(QueryRow row, _Source source) {
  final raw = row.data;
  if (source.kind == 'folder') return {'parentId': raw['parent_id']};
  if (source.kind == 'file') {
    return {'parentId': raw['parent_id'], 'assetId': raw['asset_id']};
  }
  final value = jsonDecode(row.read<String>(source.column));

  return switch (source.kind) {
    'table' => {'columns': value, 'parentId': raw['parent_id']},
    'record' => {'tableId': raw['table_id'], 'values': value},
    _ => value as Map<String, dynamic>,
  };
}

Iterable<LocalRetainedData> _viewHistory(QueryRow row) =>
    (jsonDecode(row.read<String>('history')) as List)
        .cast<Map<String, dynamic>>()
        .map((data) => _viewSnapshot(row, data));
LocalRetainedData _viewSnapshot(QueryRow row, Map<String, dynamic> data) =>
    (data: data, view: true, kind: 'view', id: row.read<String>('id'));

LocalRetainedData _snapshot(WorkspaceRevisionRow row) => (
  data: jsonDecode(row.data) as Map<String, dynamic>,
  view: false,
  kind: row.kind,
  id: row.resourceId,
);

List<LocalRetainedData> _retainedSnapshots(
  List<WorkspaceRevisionRow> rows,
  Set<String> scope,
) => rows
    .where((row) => !scope.contains('${row.kind}:${row.resourceId}'))
    .map(_snapshot)
    .toList();

LocalRetainedData _current(QueryRow row, _Source source) => (
  data: _data(row, source),
  view: source.kind == 'view',
  kind: source.kind,
  id: row.read<String>('id'),
);
