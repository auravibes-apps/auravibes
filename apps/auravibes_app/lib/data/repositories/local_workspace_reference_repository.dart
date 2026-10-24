import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/local_workspace_table_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_reference_page.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:drift/drift.dart';

const _pageSize = 50;

class const LocalWorkspaceReferenceRepository(
  final AppDatabase database,
  final String workspaceId,
) implements WorkspaceReferenceRepository {
  LocalWorkspaceTableRepository get tables =>
      LocalWorkspaceTableRepository(database, workspaceId);
  @override
  Future<WorkspaceRecord> record(String tableId, String id) =>
      tables.record(tableId, id);
  @override
  Future<WorkspaceReferencePage> targets(
    WorkspaceReferenceSource source, {
    required String search,
    String? afterId,
    String? parentId,
  }) async {
    final selection = await _LocalReferenceSelection(
      this,
      source,
      parentId,
    ).read();
    final query = (
      search: search,
      afterId: afterId,
      matchColumn: selection.column.targetMatchColumnId,
      parentId: parentId,
    );

    return _page(await _targetRows(selection.target, query));
  }

  @override
  Future<WorkspaceReferencePage> tableTargets(
    String tableId, {
    required String search,
    String? afterId,
  }) async {
    final target = await tables.table(tableId);

    return _page(
      await _targetRows(target, (
        search: search,
        afterId: afterId,
        matchColumn: null,
        parentId: null,
      )),
    );
  }

  @override
  Future<WorkspaceReferencePage> reverse({
    required String tableId,
    required String recordId,
    String? afterId,
  }) async {
    final _ = await tables.record(tableId, recordId);
    final rows = await _reverseRows((
      tableId: tableId,
      recordId: recordId,
      afterId: afterId,
    ));

    return _page(rows);
  }

  Future<List<WorkspaceRecord>> _targetRows(
    WorkspaceTable target,
    _TargetQuery query,
  ) async {
    final rows = await database
        .customSelect(
          _targetSql,
          variables: _targetVariables(target, query),
          readsFrom: {database.workspaceTableRecords},
        )
        .get();

    return rows.map(_record).toList();
  }

  List<Variable<Object>> _targetVariables(
    WorkspaceTable target,
    _TargetQuery query,
  ) => [
    Variable(workspaceId),
    Variable(target.id),
    Variable(query.afterId ?? ''),
    Variable('\$."${target.labelColumnId}"'),
    Variable(query.search),
    Variable(query.matchColumn ?? ''),
    Variable('\$."${query.matchColumn ?? ''}"'),
    Variable(query.parentId ?? ''),
  ];
  Future<List<WorkspaceRecord>> _reverseRows(_ReverseQuery input) async {
    final rows = await database
        .customSelect(
          _reverseSql,
          variables: _reverseVariables(input),
          readsFrom: {database.workspaceTableRecords, database.workspaceTables},
        )
        .get();

    return rows.map(_record).toList();
  }

  List<Variable<Object>> _reverseVariables(_ReverseQuery input) => [
    Variable(workspaceId),
    Variable(input.afterId ?? ''),
    Variable(input.tableId),
    Variable(input.recordId),
    Variable(input.recordId),
  ];
}

typedef _TargetQuery = ({
  String search,
  String? afterId,
  String? matchColumn,
  String? parentId,
});
typedef _ReverseQuery = ({String tableId, String recordId, String? afterId});

WorkspaceRecord _record(QueryRow row) => WorkspaceRecord(
  id: row.read<String>('id'),
  tableId: row.read<String>('table_id'),
  values: _values(row),
  revision: row.read<int>('revision'),
);
Map<String, Object?> _values(QueryRow row) =>
    (jsonDecode(row.read<String>('values_json')) as Map)
        .cast<String, Object?>();
WorkspaceReferencePage _page(List<WorkspaceRecord> rows) =>
    WorkspaceReferencePage(
      records: rows.take(_pageSize).toList(),
      nextId: rows.length > _pageSize ? rows[_pageSize - 1].id : null,
    );
const _targetSql = '''
SELECT * FROM workspace_table_records WHERE workspace_id = ?
      AND table_id = ? AND deleted_at IS NULL AND id > ?
      AND instr(lower(COALESCE(json_extract(values_json, ?), '')), lower(?)) > 0
      AND (? = '' OR json_extract(values_json, ?) = NULLIF(?, ''))
      ORDER BY id LIMIT 51''';

const _reverseSql = r'''
SELECT DISTINCT r.* FROM workspace_table_records r
      JOIN workspace_tables t ON t.id = r.table_id AND t.workspace_id = r.workspace_id,
      json_each(t.columns_json) c
      WHERE r.workspace_id = ? AND r.deleted_at IS NULL AND t.deleted_at IS NULL
      AND r.id > ? AND json_extract(c.value, '$.type') = 'reference'
      AND json_extract(c.value, '$.targetTableId') = ?
      AND EXISTS (SELECT 1 FROM json_each(r.values_json) v
        WHERE v.key = json_extract(c.value, '$.id')
        AND (v.value = ? OR (v.type = 'array' AND EXISTS
          (SELECT 1 FROM json_each(v.value) a WHERE a.value = ?))))
      ORDER BY r.id LIMIT 51''';

class const _LocalReferenceSelection(
  final LocalWorkspaceReferenceRepository repository,
  final WorkspaceReferenceSource source,
  final String? parentId,
) {
  Future<({WorkspaceTable target, WorkspaceColumn column})> read() async {
    final table = await repository.tables.table(source.tableId);
    final column = _sourceColumn(table, source.columnId);
    await _parent(table, column);
    final target = await repository.tables.table(_targetId(column));

    return (target: target, column: column);
  }

  Future<void> _parent(WorkspaceTable table, WorkspaceColumn column) async {
    final id = parentId;
    if (column.dependsOnColumnId == null || id == null) return;
    final parent = _sourceColumn(table, column.dependsOnColumnId ?? '');
    final _ = await repository.tables.record(_targetId(parent), id);
  }
}

String _targetId(WorkspaceColumn column) =>
    column.targetTableId ?? (throw const WorkspaceTableException());
WorkspaceColumn _sourceColumn(WorkspaceTable table, String id) =>
    table.columns
        .where((column) => column.id == id && column.type == .reference)
        .firstOrNull ??
    (throw const WorkspaceTableException());
