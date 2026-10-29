import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/local_trash_node.dart';
import 'package:auravibes_app/data/repositories/local_workspace_trash_store.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_trash_target.dart';

class const LocalWorkspaceTrashReader(final LocalWorkspaceTrashStore store) {
  Future<List<WorkspaceTrashBatch>> list() async {
    await store.requireLocal();

    return (await store.batches()).map(_batch).toList();
  }

  Future<WorkspaceDeletedReference?> deletedReference(
    String tableId,
    String recordId,
  ) async {
    await store.requireLocal();
    final nodes = await store.nodes();
    if (!_deleted(nodes, tableId, recordId)) return null;
    for (final batch in await store.batches()) {
      final members = localTrashMembers(batch);
      if (!_contains(members, .record, recordId)) continue;

      return _recovery(batch, nodes, members, tableId);
    }

    return null;
  }
}

bool _deleted(List<LocalTrashNode> nodes, String tableId, String recordId) =>
    nodes.any(
      (node) =>
          node.kind == .record &&
          node.id == recordId &&
          node.tableId == tableId &&
          node.deleted,
    );
bool _contains(
  List<LocalTrashNode> nodes,
  WorkspaceTrashKind kind,
  String id,
) => nodes.any((node) => node.kind == kind && node.id == id);
bool _tableAvailable(
  List<LocalTrashNode> nodes,
  List<LocalTrashNode> members,
  String id,
) {
  final table = nodes
      .where((node) => node.kind == .table && node.id == id)
      .firstOrNull;

  return table != null && (!table.deleted || _contains(members, .table, id));
}

List<LocalTrashNode> localTrashMembers(WorkspaceTrashBatchRow row) =>
    (jsonDecode(row.membersJson) as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(LocalTrashNode.fromJson)
        .toList();
WorkspaceTrashBatch _batch(WorkspaceTrashBatchRow row) => .new(
  id: row.id,
  target: _target(row.targetJson),
  name: row.name,
  affectedCount: localTrashMembers(row).length,
);
WorkspaceTrashTarget _target(String encoded) =>
    .fromJson(jsonDecode(encoded) as Map<String, dynamic>);

WorkspaceDeletedReference _recovery(
  WorkspaceTrashBatchRow batch,
  List<LocalTrashNode> nodes,
  List<LocalTrashNode> members,
  String id,
) => .new(batchId: batch.id, canRestore: _tableAvailable(nodes, members, id));
