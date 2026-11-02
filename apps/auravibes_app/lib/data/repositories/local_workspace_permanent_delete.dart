import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/local_workspace_history_retention.dart';
import 'package:auravibes_app/data/repositories/local_workspace_retained_reader.dart';
import 'package:auravibes_app/data/repositories/workspace_retained_references.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_history_blocked_exception.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_trash_target.dart';
import 'package:drift/drift.dart';

class const LocalWorkspacePermanentDelete(
  final AppDatabase database,
  final String workspaceId,
) {
  Future<void> call(WorkspaceTrashTarget target) =>
      database.transaction(() => _run(target));

  Future<void> _run(WorkspaceTrashTarget target) async {
    await LocalWorkspaceHistoryRetention(database, workspaceId).prune();
    final batch = await _batch(target);
    final members = _members(batch);
    final scope = _scope(members);
    await _validate(members, scope);
    await _erase(members);
    await _deleteBatch(batch);
  }

  Future<void> _deleteBatch(WorkspaceTrashBatchRow batch) async {
    final query = database.delete(database.workspaceTrashBatches)
      ..where(
        (row) => row.id.equals(batch.id) & row.workspaceId.equals(workspaceId),
      );
    final _ = await query.go();
  }

  Future<WorkspaceTrashBatchRow> _batch(WorkspaceTrashTarget target) async {
    final query = database.select(database.workspaceTrashBatches)
      ..where((row) => row.workspaceId.equals(workspaceId));
    final rows = await query.get();

    return _findBatch(rows, target);
  }

  Future<void> _validate(
    List<Map<String, dynamic>> members,
    Set<String> scope,
  ) async {
    final retained = await LocalWorkspaceRetainedReader(
      database,
      workspaceId,
    ).read(scope);
    final columns = WorkspaceRetainedReferences.columns(
      retained.map((item) => item.data),
    );
    final ids = _ids(members);
    _requireUnreferenced(_blocked(retained, ids, columns));
  }

  Future<void> _erase(List<Map<String, dynamic>> members) async {
    final writer = _PurgeWriter(database, workspaceId);
    for (final member in members.reversed) {
      await writer.delete(member);
    }
  }
}

class const _PurgeWriter(final AppDatabase database, final String workspaceId) {
  Future<void> delete(Map<String, dynamic> member) async {
    final kind = member['kind'] as String;
    final id = member['id'] as String;
    final table = _table(kind);
    await _requireDeleted(table, id);
    await database.customStatement(
      'DELETE FROM $table WHERE workspace_id = ? AND id = ?',
      [workspaceId, id],
    );
    await _history(kind, id);
  }

  Future<void> _requireDeleted(String table, String id) async {
    final rows = await database
        .customSelect(
          'SELECT deleted_at FROM $table WHERE workspace_id = ? AND id = ?',
          variables: [Variable(workspaceId), Variable(id)],
        )
        .get();
    if (rows.length != 1 || rows.single.data['deleted_at'] == null) {
      throw const WorkspaceTableException();
    }
  }

  Future<void> _history(String kind, String id) async {
    final query = database.delete(database.workspaceRevisions)
      ..where((row) => _revisionMatches(row, workspaceId, kind, id));
    final _ = await query.go();
    await _saveMarker(kind, id);
  }

  Future<void> _saveMarker(String kind, String id) async {
    final _ = await database
        .into(database.workspaceRevisions)
        .insert(_marker(workspaceId, kind, id));
  }
}

WorkspaceRevisionsCompanion _marker(
  String workspaceId,
  String kind,
  String id,
) => WorkspaceRevisionsCompanion.insert(
  workspaceId: workspaceId,
  kind: kind,
  resourceId: id,
  revision: 0,
  data: '{}',
);
Map<String, dynamic> _decode(String data) =>
    jsonDecode(data) as Map<String, dynamic>;
List<Map<String, dynamic>> _members(WorkspaceTrashBatchRow batch) =>
    (jsonDecode(batch.membersJson) as List).cast<Map<String, dynamic>>();
Set<String> _scope(List<Map<String, dynamic>> members) => {
  for (final member in members) '${member['kind']}:${member['id']}',
};
bool _same(Map<String, dynamic> data, WorkspaceTrashTarget target) =>
    data['kind'] == target.kind.name &&
    data['id'] == target.id &&
    data['revision'] == target.revision &&
    data['tableId'] == target.tableId;
Iterable<LocalRetainedData> _blocked(
  List<LocalRetainedData> rows,
  Set<String> ids,
  Set<String> columns,
) => rows.where(
  (row) => WorkspaceRetainedReferences.references(row.data, ids, (
    columns: columns,
    view: row.view,
  )),
);
String _table(String kind) => switch (kind) {
  'folder' => 'workspace_folders',
  'table' => 'workspace_tables',
  'record' => 'workspace_table_records',
  'view' => 'workspace_views',
  'file' => 'workspace_files',
  'workflow' => 'workspace_workflows',
  _ => throw const WorkspaceTableException(),
};
Expression<bool> _revisionMatches(
  $WorkspaceRevisionsTable row,
  String workspaceId,
  String kind,
  String id,
) =>
    row.workspaceId.equals(workspaceId) &
    row.kind.equals(kind) &
    row.resourceId.equals(id);

Set<String> _ids(List<Map<String, dynamic>> members) =>
    members.map((member) => member['id'] as String).toSet();
WorkspaceTrashBatchRow _findBatch(
  List<WorkspaceTrashBatchRow> rows,
  WorkspaceTrashTarget target,
) =>
    rows.where((row) => _same(_decode(row.targetJson), target)).firstOrNull ??
    (throw const WorkspaceTableException());

void _requireUnreferenced(Iterable<LocalRetainedData> blocked) {
  if (blocked.firstOrNull case final source?) {
    throw WorkspaceHistoryBlockedException([source.id]);
  }
}
