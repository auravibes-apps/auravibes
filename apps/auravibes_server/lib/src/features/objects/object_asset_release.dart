import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'object_repository.dart';
import 'object_retained_assets.dart';

/// Called inside the authorized content transaction. Byte removal stays in the
/// existing object cleanup worker, after the content transaction commits.
class const ObjectAssetRelease(
  final Session session,
  final int workspaceId,
  final Transaction transaction,
) {
  Future<T> mutate<T>(Future<T> Function() action) async {
    final retained = ObjectRetainedAssets(session, workspaceId, transaction);
    final before = await retained.ids();
    final result = await action();
    final after = await retained.ids();
    for (final id in before.difference(after)) {
      await _release(id);
    }

    return result;
  }

  Future<void> _release(int id) async {
    final object = await ObjectRepository().findObject(
      session,
      workspaceId: workspaceId,
      objectId: id,
      transaction: transaction,
      lock: true,
    );
    if (object == null ||
        object.status != 'active' ||
        object.deletedAt != null) {
      return;
    }
    if (await ObjectRetainedAssets(
      session,
      workspaceId,
      transaction,
    ).retained(id)) {
      return;
    }
    await _queue(object);
  }

  Future<void> _queue(WorkspaceObject object) async {
    final existing = await ObjectDeletion.db.findFirstRow(
      session,
      where: (row) => row.objectId.equals(object.id),
      transaction: transaction,
    );
    if (existing != null) return;
    final now = DateTime.now().toUtc();
    await _markDeleted(object, now);
    await ObjectDeletion.db.insertRow(
      session,
      _deletion(object, now),
      transaction: transaction,
    );
  }

  Future<void> _markDeleted(WorkspaceObject object, DateTime now) =>
      WorkspaceObject.db.updateRow(
        session,
        object.copyWith(
          status: 'deleted',
          revision: object.revision + 1,
          updatedAt: now,
          deletedAt: now,
        ),
        transaction: transaction,
      );

  ObjectDeletion _deletion(WorkspaceObject object, DateTime now) => .new(
    workspaceId: workspaceId,
    objectId: object.id!,
    objectKey: object.objectKey,
    requestId: const Uuid().v4().toString(),
    expectedRevision: object.revision,
    requestedAt: now,
    attempts: 0,
    availableAt: now,
  );
}
