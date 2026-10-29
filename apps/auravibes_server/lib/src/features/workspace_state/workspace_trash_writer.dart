import 'dart:convert';

import '../../generated/protocol.dart';
import 'workspace_trash_access.dart';
import 'workspace_trash_context.dart';
import 'workspace_trash_restorer.dart';
import 'workspace_trash_selection.dart';
import 'workspace_trash_store.dart';

const _maximumRequestLength = 200;

class const WorkspaceTrashWriter(final WorkspaceTrashContext context) {
  Future<String> trash(
    String requestId,
    String targetJson,
    String token,
  ) async {
    _requestId(requestId);
    final existing = await context.store.batch(requestId);
    if (existing != null) return await _replay(existing, targetJson);
    final selection = await WorkspaceTrashSelection.load(context, targetJson);
    if (await selection.token() != token) trashConflict();
    return await _commit(requestId, selection);
  }

  Future<String> restore(String id) async {
    final batch = await context.store.batch(id);
    if (batch == null) trashDenied();
    final rows = await context.store.resources();
    await context.requireBatch(batch, rows);
    if (batch.restoredAt != null) {
      return batch.restoredResultJson ?? trashConflict();
    }
    return await _restorer().restore(batch, rows);
  }

  Future<String> _replay(WorkspaceTrashBatch batch, String targetJson) async {
    await context.requireBatch(batch, await context.store.resources());
    if (batch.targetJson != targetJson) trashConflict();
    return jsonEncode(trashBatchJson(batch));
  }

  Future<String> _commit(String id, WorkspaceTrashSelection selection) async {
    final now = DateTime.now().toUtc();
    final batch = _batch(id, selection, now);
    await context.store.insertBatch(batch);
    await context.store.commit(
      context.workspace,
      context.access.userId,
      selection.tombstones(now),
    );
    return jsonEncode(trashBatchJson(batch));
  }

  WorkspaceTrashBatch _batch(
    String id,
    WorkspaceTrashSelection plan,
    DateTime now,
  ) => .new(
    workspaceId: context.store.workspaceId,
    batchId: id,
    targetJson: plan.encodedTarget,
    name: plan.name,
    membersJson: jsonEncode(plan.members.map(trashMember).toList()),
    createdAt: now,
  );
  WorkspaceTrashRestorer _restorer() =>
      .new(context.store, context.workspace, context.access.userId);
}

void _requestId(String value) {
  if (value.isEmpty || value.length > _maximumRequestLength) trashInvalid();
}
