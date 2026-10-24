import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/workspace_retained_references.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_trash_target.dart';
import 'package:drift/drift.dart';

class const LocalWorkspacePermanentDelete(
  final AppDatabase database,
  final String workspaceId,
) {
  Future<void> call(
    WorkspaceTrashTarget target,
  ) => database.transaction(() async {
    final batches = await (database.select(
      database.workspaceTrashBatches,
    )..where((row) => row.workspaceId.equals(workspaceId))).get();
    final batch = batches
        .where(
          (row) =>
              _same(jsonDecode(row.targetJson) as Map<String, dynamic>, target),
        )
        .firstOrNull;
    if (batch == null) throw const WorkspaceTableException();
    final members = (jsonDecode(batch.membersJson) as List)
        .cast<Map<String, dynamic>>();
    final scope = {
      for (final member in members) '${member['kind']}:${member['id']}',
    };
    final ids = {for (final member in members) member['id'] as String};
    final retained = await _retained(scope);
    final columns = workspaceReferenceColumns(
      retained.map((item) => item.data),
    );
    if (retained.any(
      (item) =>
          workspaceRetainedReference(item.data, ids, columns, view: item.view),
    )) {
      throw const WorkspaceTableException();
    }
    for (final member in members.reversed) {
      await _delete(member);
    }
    final _ =
        await (database.delete(database.workspaceTrashBatches)..where(
              (row) =>
                  row.id.equals(batch.id) & row.workspaceId.equals(workspaceId),
            ))
            .go();
  });

  Future<List<({Map<String, dynamic> data, bool view})>> _retained(
    Set<String> scope,
  ) async {
    final result = <({Map<String, dynamic> data, bool view})>[];
    for (final (table, kind, column) in [
      ('workspace_tables', 'table', 'columns_json'),
      ('workspace_table_records', 'record', 'values_json'),
      ('workspace_views', 'view', 'data'),
      ('workspace_folders', 'folder', 'name'),
    ]) {
      final rows = await database
          .customSelect(
            'SELECT * FROM $table WHERE workspace_id = ?',
            variables: [Variable(workspaceId)],
          )
          .get();
      for (final row in rows) {
        if (scope.contains('$kind:${row.data['id']}')) continue;
        final data = switch (kind) {
          'table' => <String, dynamic>{
            'columns': jsonDecode(row.read<String>(column)),
            'parentId': row.data['parent_id'],
          },
          'record' => <String, dynamic>{
            'tableId': row.data['table_id'],
            'values': jsonDecode(row.read<String>(column)),
          },
          'folder' => <String, dynamic>{'parentId': row.data['parent_id']},
          _ => jsonDecode(row.read<String>(column)) as Map<String, dynamic>,
        };
        result.add((data: data, view: kind == 'view'));
        if (kind == 'view') {
          for (final old in (jsonDecode(
            row.read<String>('history'),
          ) as List).cast<Map<String, dynamic>>()) {
            result.add((data: old, view: true));
          }
        }
      }
    }
    final snapshots = await (database.select(
      database.workspaceRevisions,
    )..where((row) => row.workspaceId.equals(workspaceId))).get();
    for (final row in snapshots) {
      if (!scope.contains('${row.kind}:${row.resourceId}')) {
        result.add((
          data: jsonDecode(row.data) as Map<String, dynamic>,
          view: false,
        ));
      }
    }
    return result;
  }

  Future<void> _delete(Map<String, dynamic> member) async {
    final table = switch (member['kind']) {
      'folder' => 'workspace_folders',
      'table' => 'workspace_tables',
      'record' => 'workspace_table_records',
      'view' => 'workspace_views',
      _ => throw const WorkspaceTableException(),
    };
    final rows = await database
        .customSelect(
          'SELECT revision, deleted_at FROM $table WHERE workspace_id = ? AND id = ?',
          variables: [Variable(workspaceId), Variable(member['id'] as String)],
        )
        .get();
    if (rows.length != 1 || rows.single.data['deleted_at'] == null) {
      throw const WorkspaceTableException();
    }
    await database.customStatement(
      'DELETE FROM $table WHERE workspace_id = ? AND id = ?',
      [workspaceId, member['id']],
    );
    final _ =
        await (database.delete(database.workspaceRevisions)..where(
              (row) =>
                  row.workspaceId.equals(workspaceId) &
                  row.kind.equals(member['kind'] as String) &
                  row.resourceId.equals(member['id'] as String),
            ))
            .go();
  }
}

bool _same(Map<String, dynamic> data, WorkspaceTrashTarget target) =>
    data['kind'] == target.kind.name &&
    data['id'] == target.id &&
    data['revision'] == target.revision &&
    data['tableId'] == target.tableId;
