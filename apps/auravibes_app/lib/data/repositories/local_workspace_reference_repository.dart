import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/local_workspace_table_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_reference.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:drift/drift.dart';

class const LocalWorkspaceReferenceRepository(
  final AppDatabase database,
  final String workspaceId,
) implements WorkspaceReferenceRepository {
  @override
  Future<WorkspaceReferencePage> targets({
    required String sourceTableId,
    required String columnId,
    required String search,
    String? afterId,
  }) async {
    final tables = LocalWorkspaceTableRepository(database, workspaceId);
    final source = await tables.table(sourceTableId);
    final column = source.columns
        .where((column) => column.id == columnId && column.type == .reference)
        .firstOrNull;
    if (column == null || column.targetTableId == null)
      throw const WorkspaceTableException();
    final target = await tables.table(column.targetTableId!);
    final rows = await database
        .customSelect(
          '''SELECT * FROM workspace_table_records WHERE workspace_id = ?
      AND table_id = ? AND deleted_at IS NULL AND id > ?
      AND instr(lower(COALESCE(json_extract(values_json, ?), '')), lower(?)) > 0
      ORDER BY id LIMIT 51''',
          variables: [
            Variable(workspaceId),
            Variable(target.id),
            Variable(afterId ?? ''),
            Variable('\$."${target.labelColumnId}"'),
            Variable(search),
          ],
          readsFrom: {database.workspaceTableRecords},
        )
        .get();
    return _page(rows.map(_record).toList());
  }

  @override
  Future<WorkspaceReferencePage> reverse({
    required String tableId,
    required String recordId,
    String? afterId,
  }) async {
    final tables = LocalWorkspaceTableRepository(database, workspaceId);
    final _ = await tables.record(tableId, recordId);
    final rows = await database
        .customSelect(
          '''SELECT DISTINCT r.* FROM workspace_table_records r
      JOIN workspace_tables t ON t.id = r.table_id AND t.workspace_id = r.workspace_id,
      json_each(t.columns_json) c
      WHERE r.workspace_id = ? AND r.deleted_at IS NULL AND t.deleted_at IS NULL
      AND r.id > ? AND json_extract(c.value, '\$.type') = 'reference'
      AND json_extract(c.value, '\$.targetTableId') = ?
      AND EXISTS (SELECT 1 FROM json_each(r.values_json) v
        WHERE v.key = json_extract(c.value, '\$.id')
        AND (v.value = ? OR (v.type = 'array' AND EXISTS
          (SELECT 1 FROM json_each(v.value) a WHERE a.value = ?))))
      ORDER BY r.id LIMIT 51''',
          variables: [
            Variable(workspaceId),
            Variable(afterId ?? ''),
            Variable(tableId),
            Variable(recordId),
            Variable(recordId),
          ],
          readsFrom: {database.workspaceTableRecords, database.workspaceTables},
        )
        .get();
    return _page(rows.map(_record).toList());
  }
}

WorkspaceRecord _record(QueryRow row) => WorkspaceRecord(
  id: row.read<String>('id'),
  tableId: row.read<String>('table_id'),
  values: (jsonDecode(row.read<String>('values_json')) as Map)
      .cast<String, Object?>(),
  revision: row.read<int>('revision'),
);

WorkspaceReferencePage _page(List<WorkspaceRecord> rows) =>
    WorkspaceReferencePage(
      records: rows.take(50).toList(),
      nextId: rows.length > 50 ? rows[49].id : null,
    );
