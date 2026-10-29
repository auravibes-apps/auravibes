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
    );
    for (final object in objects) {
      await _queue(object);
    }
  }

  Future<void> _queue(WorkspaceObject object) async {
    final now = DateTime.now().toUtc();
    final upload = await ObjectUpload.db.findFirstRow(
      session,
      where: (row) => row.objectId.equals(object.id!),
      transaction: transaction,
    );
    // The gateway closes the registered key before erasure. URL expiry is
    // therefore not the cleanup gate; its durable write ledger is.
    final availableAt = now;
    final existing = await ObjectDeletion.db.findFirstRow(
      session,
      where: (row) => row.objectId.equals(object.id!),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (existing != null) {
      if (upload == null) return;
      final uploadProofIsCurrent =
          upload.signingReservationCount == 0 &&
          existing.uploadCleanupVerifiedAt != null &&
          existing.uploadCleanupVerifiedGeneration ==
              existing.cleanupGeneration &&
          existing.uploadCleanupVerifiedExpiresAt == upload.expiresAt &&
          upload.gatewayRegistrationId != null &&
          existing.uploadCleanupVerifiedRegistrationId ==
              upload.gatewayRegistrationId;
      final reopenCompletedDeletion =
          existing.completedAt != null && !uploadProofIsCurrent;
      final invalidateUploadProof =
          existing.uploadCleanupVerifiedAt != null && !uploadProofIsCurrent;
      final deferredUntilExpiry = existing.availableAt.isBefore(availableAt);
      if (reopenCompletedDeletion ||
          invalidateUploadProof ||
          deferredUntilExpiry) {
        await ObjectDeletion.db.updateRow(
          session,
          existing.copyWith(
            cleanupGeneration: existing.cleanupGeneration + 1,
            completedAt: reopenCompletedDeletion ? null : existing.completedAt,
            uploadCleanupVerifiedAt: null,
            uploadCleanupVerifiedGeneration: null,
            uploadCleanupVerifiedExpiresAt: null,
            uploadCleanupVerifiedRegistrationId: null,
            attempts: reopenCompletedDeletion ? 0 : existing.attempts,
            availableAt: availableAt,
            lastError: null,
          ),
          transaction: transaction,
        );
      }
      return;
    }
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
        availableAt: availableAt,
      ),
      transaction: transaction,
    );
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
  }
}
