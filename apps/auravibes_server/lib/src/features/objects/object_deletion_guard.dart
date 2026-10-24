import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'object_retained_assets.dart';

class const ObjectDeletionGuard() {
  Future<bool> allows(
    Session session,
    ObjectDeletion deletion,
    WorkerCoordinatorLease coordinator,
  ) => session.db.transaction((transaction) async {
    if (!await ownsCoordinator(session, transaction, coordinator)) return false;
    if (!await _pending(session, deletion, transaction)) return false;
    final object = await _object(session, deletion, transaction);
    if (!_matches(object, deletion)) return false;

    return !await ObjectRetainedAssets(
      session,
      deletion.workspaceId,
      transaction,
    ).retained(deletion.objectId);
  });

  Future<bool> _pending(
    Session session,
    ObjectDeletion deletion,
    Transaction transaction,
  ) async {
    final current = await ObjectDeletion.db.findById(
      session,
      deletion.id!,
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );

    return current != null &&
        current.completedAt == null &&
        current.objectId == deletion.objectId &&
        current.objectKey == deletion.objectKey;
  }

  Future<WorkspaceObject?> _object(
    Session session,
    ObjectDeletion deletion,
    Transaction transaction,
  ) => WorkspaceObject.db.findFirstRow(
    session,
    where: (row) =>
        row.id.equals(deletion.objectId) &
        row.workspaceId.equals(deletion.workspaceId),
    transaction: transaction,
    lockMode: LockMode.forUpdate,
  );

  static bool _matches(WorkspaceObject? object, ObjectDeletion deletion) =>
      object != null &&
      object.status == 'deleted' &&
      object.deletedAt != null &&
      object.objectKey == deletion.objectKey &&
      object.revision == deletion.expectedRevision + 1;

  static Future<bool> ownsCoordinator(
    Session session,
    Transaction transaction,
    WorkerCoordinatorLease coordinator,
  ) async {
    final lease = await WorkerCoordinatorLease.db.findFirstRow(
      session,
      where: (row) => row.key.equals('global'),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    final now = await _databaseNow(session, transaction);

    return _owns(lease, coordinator, now);
  }

  static bool _owns(
    WorkerCoordinatorLease? lease,
    WorkerCoordinatorLease coordinator,
    DateTime now,
  ) =>
      lease != null &&
      lease.ownerId == coordinator.ownerId &&
      lease.fencingToken == coordinator.fencingToken &&
      lease.expiresAt.isAfter(now);

  static Future<DateTime> _databaseNow(
    Session session,
    Transaction transaction,
  ) async {
    final rows = await session.db.unsafeQuery(
      'SELECT clock_timestamp() AS "now"',
      transaction: transaction,
    );

    return rows.first.toColumnMap()['now']! as DateTime;
  }
}
