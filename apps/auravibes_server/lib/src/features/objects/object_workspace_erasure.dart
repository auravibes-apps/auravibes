import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';

/// Queues every workspace object for the existing durable object-cleanup worker.
class const ObjectWorkspaceErasure(
  final Session session,
  final int workspaceId,
  final Transaction transaction,
) {
  Future<void> queue() async {
    final objects = await WorkspaceObject.db.find(
      session,
      where: (row) => row.workspaceId.equals(workspaceId),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    for (final object in objects) {
      await _queue(object);
    }
  }

  Future<void> _queue(WorkspaceObject object) async {
    final existing = await ObjectDeletion.db.findFirstRow(
      session,
      where: (row) => row.objectId.equals(object.id!),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (existing != null) return;

    final now = DateTime.now().toUtc();
    await WorkspaceObject.db.updateRow(
      session,
      object.copyWith(
        status: 'deleted',
        revision: object.revision + 1,
        updatedAt: now,
        deletedAt: now,
      ),
      transaction: transaction,
    );
    await ObjectDeletion.db.insertRow(
      session,
      ObjectDeletion(
        workspaceId: workspaceId,
        objectId: object.id!,
        objectKey: object.objectKey,
        requestId: const Uuid().v4().toString(),
        expectedRevision: object.revision,
        requestedAt: now,
        attempts: 0,
        availableAt: now,
      ),
      transaction: transaction,
    );
  }
}
