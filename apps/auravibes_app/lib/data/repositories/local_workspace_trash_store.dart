import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/local_trash_node.dart';
import 'package:auravibes_app/data/repositories/local_workspace_trash_view_store.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_trash_target.dart';
import 'package:drift/drift.dart';

class const LocalWorkspaceTrashStore(
  final AppDatabase database,
  final String workspaceId,
) {
  Future<void> requireLocal() async {
    final row = await (database.select(
      database.workspaces,
    )..where((row) => row.id.equals(workspaceId))).getSingleOrNull();
    if (row == null || row.type != .local) {
      throw const WorkspaceTableException();
    }
  }

  Future<List<WorkspaceTrashBatchRow>> batches() => (database.select(
    database.workspaceTrashBatches,
  )..where((row) => row.workspaceId.equals(workspaceId))).get();
  Future<WorkspaceTrashBatchRow> batch(String id) async {
    final row =
        await (database.select(database.workspaceTrashBatches)..where(
              (row) => row.workspaceId.equals(workspaceId) & row.id.equals(id),
            ))
            .getSingleOrNull();

    return row ?? (throw const WorkspaceTableException());
  }

  Future<void> deleteBatch(String id) async {
    final _ =
        await (database.delete(database.workspaceTrashBatches)..where(
              (row) => row.workspaceId.equals(workspaceId) & row.id.equals(id),
            ))
            .go();
  }

  Future<void> insertBatch(
    WorkspaceTrashBatch batch,
    List<LocalTrashNode> members,
  ) async {
    final _ = await database
        .into(database.workspaceTrashBatches)
        .insert(_batchCompanion(batch, members, workspaceId));
  }

  Future<List<LocalTrashNode>> nodes() async => [
    for (final kind in [
      WorkspaceTrashKind.folder,
      WorkspaceTrashKind.table,
      WorkspaceTrashKind.record,
      WorkspaceTrashKind.view,
    ])
      ...await _nodes(kind),
  ];

  Future<void> tombstone(
    LocalTrashNode node,
    DateTime? time, {
    String? parentId,
  }) async {
    if (node.kind == .view) {
      await LocalWorkspaceTrashViewStore(
        database,
        workspaceId,
      ).tombstone(node.id, time, parentId);

      return;
    }
    final changed = await _updateRows(node, time, parentId);
    if (changed != 1) throw const WorkspaceTableException(conflict: true);
  }

  Future<List<LocalTrashNode>> _nodes(WorkspaceTrashKind kind) async {
    final rows = await database
        .customSelect(
          'SELECT ${_nodeColumns(kind)} FROM ${_table(kind)} '
          'WHERE workspace_id = ?',
          variables: [Variable(workspaceId)],
        )
        .get();

    return rows.map((row) => _node(kind, row)).toList();
  }

  Future<int> _updateRows(
    LocalTrashNode node,
    DateTime? time,
    String? parentId,
  ) => database.customUpdate(
    _tombstoneSql(node.kind),
    variables: _variables(node, time, parentId, workspaceId),
    updates: {
      database.workspaceFolders,
      database.workspaceTables,
      database.workspaceTableRecords,
    },
    updateKind: .update,
  );
}

String _table(WorkspaceTrashKind kind) => switch (kind) {
  .folder => 'workspace_folders',
  .table => 'workspace_tables',
  .record => 'workspace_table_records',
  .view => 'workspace_views',
};
LocalTrashNode _node(WorkspaceTrashKind kind, QueryRow row) =>
    .fromJson({..._identity(kind, row), ..._content(row)});
Map<String, Object?> _identity(WorkspaceTrashKind kind, QueryRow row) => {
  'kind': kind.name,
  'id': row.read<String>('id'),
  'revision': row.read<int>('revision'),
  'deleted': row.readNullable<int>('deleted_at') != null,
};
Map<String, Object?> _content(QueryRow row) => {
  'name': row.read<String>('name'),
  'parentId': row.readNullable<String>('parent_id'),
  'tableId': row.readNullable<String>('table_id'),
};
String _nodeColumns(WorkspaceTrashKind kind) => switch (kind) {
  .record =>
    '''id, revision, deleted_at, '' AS name, NULL AS parent_id, table_id''',
  .view =>
    'id, revision, deleted_at, '
        r'''json_extract(data, '$.name') AS name, '''
        r'''json_extract(data, '$.parentId') AS parent_id, '''
        r'''json_extract(data, '$.tableId') AS table_id''',
  .folder ||
  .table => 'id, revision, deleted_at, name, parent_id, NULL AS table_id',
};
String _tombstoneSql(WorkspaceTrashKind kind) {
  final parent = kind == .record ? '' : ', parent_id = ?';

  return 'UPDATE ${_table(kind)} SET deleted_at = ?, updated_at = ?, '
      'revision = revision + 1$parent '
      'WHERE workspace_id = ? AND id = ? AND revision = ?';
}

List<Object?> _tombstoneValues(
  LocalTrashNode node,
  DateTime? time,
  String? parentId,
  String workspaceId,
) => [
  _epochSeconds(time),
  _epochSeconds(.now()),
  if (node.kind != .record) parentId,
  workspaceId,
  node.id,
  node.revision,
];
int? _epochSeconds(DateTime? value) => value == null
    ? null
    : value.millisecondsSinceEpoch ~/ Duration.millisecondsPerSecond;

WorkspaceTrashBatchesCompanion _batchCompanion(
  WorkspaceTrashBatch batch,
  List<LocalTrashNode> members,
  String workspaceId,
) => .insert(
  id: .new(batch.id),
  workspaceId: workspaceId,
  targetJson: jsonEncode(batch.target.toJson()),
  name: batch.name,
  membersJson: jsonEncode(members.map((node) => node.toJson()).toList()),
);

List<Variable<Object>> _variables(
  LocalTrashNode node,
  DateTime? time,
  String? parentId,
  String workspaceId,
) => _tombstoneValues(
  node,
  time,
  parentId,
  workspaceId,
).map(Variable<Object>.new).toList();
