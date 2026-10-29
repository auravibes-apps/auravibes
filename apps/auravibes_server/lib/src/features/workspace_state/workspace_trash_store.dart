import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'workspace_revision_capture.dart';
import 'workspace_trash_access.dart';
import 'workspace_trash_view_store.dart';

class const WorkspaceTrashStore(
  final Session session,
  final int workspaceId,
  final Transaction transaction,
) {
  WorkspaceTrashViewStore get _views => .new(session, workspaceId, transaction);

  // ponytail: Scan retained identities; index hierarchy lookups after #1680 measures capacity.
  Future<List<WorkspaceResource>> resources() async => [
    ...await _ownedResources(),
    ...await _views.resources(),
  ];
  Future<WorkspaceTrashBatch?> batch(String id) =>
      WorkspaceTrashBatch.db.findFirstRow(
        session,
        where: (row) =>
            row.workspaceId.equals(workspaceId) & row.batchId.equals(id),
        transaction: transaction,
      );
  Future<List<WorkspaceTrashBatch>> batches() => WorkspaceTrashBatch.db.find(
    session,
    where: (row) =>
        row.workspaceId.equals(workspaceId) & row.restoredAt.equals(null),
    transaction: transaction,
  );
  Future<void> insertBatch(WorkspaceTrashBatch batch) async {
    final _ = await WorkspaceTrashBatch.db.insertRow(
      session,
      batch,
      transaction: transaction,
    );
  }

  Future<void> commit(
    CloudWorkspace workspace,
    String actor,
    List<WorkspaceResource> resources,
  ) async {
    var sequence = workspace.sequence;
    final now = DateTime.now().toUtc();
    for (final resource in resources) {
      await _write(resource);
      await _event(resource, actor, ++sequence, now);
    }
    await _advance(this, workspace, sequence, now);
  }

  Future<void> markRestored(
    WorkspaceTrashBatch batch,
    DateTime now,
    String result,
  ) async {
    final _ = await WorkspaceTrashBatch.db.updateRow(
      session,
      batch.copyWith(restoredAt: now, restoredResultJson: result),
      transaction: transaction,
    );
  }

  Future<List<WorkspaceResource>> _ownedResources() =>
      WorkspaceResource.db.find(
        session,
        where: (row) =>
            row.workspaceId.equals(workspaceId) &
            row.resourceKind.inSet({.folder, .table, .tableRecord, .file}),
        transaction: transaction,
      );
  Future<void> _write(WorkspaceResource resource) async {
    if (resource.resourceKind == .view) {
      await _views.write(resource);

      return;
    }
    final previous = await WorkspaceResource.db.findById(
      session,
      resource.id!,
      transaction: transaction,
    );
    if (previous != null) {
      await WorkspaceRevisionCapture(session, transaction).save(previous);
    }
    final _ = await WorkspaceResource.db.updateRow(
      session,
      resource,
      transaction: transaction,
    );
    await WorkspaceRevisionCapture(session, transaction).save(resource);
  }

  Future<void> _event(
    WorkspaceResource resource,
    String actor,
    int sequence,
    DateTime now,
  ) async {
    final _ = await WorkspaceEvent.db.insertRow(
      session,
      _eventRow(resource, actor, sequence, now),
      transaction: transaction,
    );
  }
}

Map<String, Object?> trashMember(WorkspaceResource row) => {
  'kind': row.resourceKind.name,
  'id': row.resourceId,
  'revision': row.revision,
  'parentId': trashData(row)['parentId'],
  'tableId': trashData(row)['tableId'],
};
List<Map<String, dynamic>> trashMembers(WorkspaceTrashBatch batch) =>
    (jsonDecode(batch.membersJson) as List).cast<Map<String, dynamic>>();
Map<String, Object?> trashBatchJson(WorkspaceTrashBatch batch) => {
  'id': batch.batchId,
  'target': jsonDecode(batch.targetJson),
  'name': batch.name,
  'affectedCount': trashMembers(batch).length,
};
WorkspaceResource? trashMemberResource(
  List<WorkspaceResource> rows,
  Map<String, dynamic> member,
) => rows
    .where(
      (row) =>
          row.resourceKind.name == member['kind'] &&
          row.resourceId == member['id'],
    )
    .firstOrNull;
List<WorkspaceResource> trashDescendants(
  WorkspaceResource root,
  List<WorkspaceResource> rows,
) {
  final selected = _items(root, rows);
  _appendRecords(selected, rows);

  return selected;
}

List<WorkspaceResource> _items(
  WorkspaceResource root,
  List<WorkspaceResource> rows,
) {
  final selected = <WorkspaceResource>[root];
  final folders = <String>{if (root.resourceKind == .folder) root.resourceId};
  var changed = true;
  while (changed) {
    changed = _appendChildren(selected, folders, rows);
  }

  return selected;
}

void _appendRecords(
  List<WorkspaceResource> selected,
  List<WorkspaceResource> rows,
) {
  final tables = selected
      .where((row) => row.resourceKind == .table)
      .map((row) => row.resourceId)
      .toSet();
  selected.addAll(rows.where((row) => _recordInTables(row, tables)));
}

bool _recordInTables(WorkspaceResource row, Set<String> tables) =>
    row.deletedAt == null &&
    row.resourceKind == .tableRecord &&
    tables.contains(trashData(row)['tableId']);
bool _appendChildren(
  List<WorkspaceResource> selected,
  Set<String> folders,
  List<WorkspaceResource> rows,
) {
  var added = false;
  for (final row in rows) {
    if (!_child(row, folders) || selected.contains(row)) continue;
    selected.add(row);
    if (row.resourceKind == .folder) folders.add(row.resourceId);
    added = true;
  }

  return added;
}

bool _child(WorkspaceResource row, Set<String> folders) =>
    row.deletedAt == null && folders.contains(trashData(row)['parentId']);

WorkspaceEvent _eventRow(
  WorkspaceResource row,
  String actor,
  int sequence,
  DateTime now,
) => .new(
  eventId: const Uuid().v7(),
  workspaceId: row.workspaceId,
  sequence: sequence,
  actorUserId: actor,
  kind: _eventKind(row),
  resourceKind: row.resourceKind.name,
  resourceId: row.resourceId,
  createdAt: now,
);
String _eventKind(WorkspaceResource row) =>
    row.deletedAt == null ? 'updated' : 'deleted';
Future<void> _advance(
  WorkspaceTrashStore store,
  CloudWorkspace workspace,
  int sequence,
  DateTime now,
) async {
  final _ = await CloudWorkspace.db.updateRow(
    store.session,
    workspace.copyWith(sequence: sequence, updatedAt: now),
    transaction: store.transaction,
  );
}
