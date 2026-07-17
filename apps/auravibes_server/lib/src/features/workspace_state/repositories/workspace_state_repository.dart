import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';

class WorkspaceStateRepository {
  Future<WorkspaceMember?> findMember(
    Session session, {
    required int workspaceId,
    required String userId,
    Transaction? transaction,
  }) => WorkspaceMember.db.findFirstRow(
    session,
    where: (t) =>
        t.workspaceId.equals(workspaceId) &
        t.userId.equals(userId) &
        t.removedAt.equals(null),
    transaction: transaction,
  );

  Future<CloudWorkspace?> findWorkspace(
    Session session,
    int workspaceId, {
    Transaction? transaction,
    bool lock = false,
  }) => CloudWorkspace.db.findFirstRow(
    session,
    where: (t) => t.id.equals(workspaceId) & t.deletedAt.equals(null),
    transaction: transaction,
    lockMode: lock ? LockMode.forUpdate : null,
  );

  Future<List<WorkspaceResource>> readPage(
    Session session, {
    required int workspaceId,
    required WorkspaceResourceKind kind,
    required int limit,
    String? afterResourceId,
  }) => WorkspaceResource.db.find(
    session,
    where: (t) =>
        t.workspaceId.equals(workspaceId) &
        t.resourceKind.equals(kind) &
        t.deletedAt.equals(null) &
        (afterResourceId == null
            ? Constant.bool(true)
            : t.resourceId > afterResourceId),
    orderBy: (t) => t.resourceId,
    limit: limit,
  );

  Future<List<WorkspaceEvent>> readEvents(
    Session session, {
    required int workspaceId,
    required int afterSequence,
    required int limit,
  }) => WorkspaceEvent.db.find(
    session,
    where: (t) =>
        t.workspaceId.equals(workspaceId) & (t.sequence > afterSequence),
    orderBy: (t) => t.sequence,
    limit: limit,
  );

  Future<WorkspaceEvent?> firstEvent(Session session, int workspaceId) =>
      WorkspaceEvent.db.findFirstRow(
        session,
        where: (t) => t.workspaceId.equals(workspaceId),
        orderBy: (t) => t.sequence,
      );

  Future<WorkspaceResource?> findResource(
    Session session, {
    required int workspaceId,
    required WorkspaceResourceKind kind,
    required String resourceId,
    required Transaction transaction,
  }) => WorkspaceResource.db.findFirstRow(
    session,
    where: (t) =>
        t.workspaceId.equals(workspaceId) &
        t.resourceKind.equals(kind) &
        t.resourceId.equals(resourceId),
    transaction: transaction,
    lockMode: LockMode.forUpdate,
  );

  Future<bool> resourceExists(
    Session session, {
    required int workspaceId,
    required WorkspaceResourceKind kind,
    required String resourceId,
    required Transaction transaction,
  }) async =>
      await WorkspaceResource.db.findFirstRow(
        session,
        where: (t) =>
            t.workspaceId.equals(workspaceId) &
            t.resourceKind.equals(kind) &
            t.resourceId.equals(resourceId) &
            t.deletedAt.equals(null),
        transaction: transaction,
      ) !=
      null;

  Future<WorkspaceSecret?> findSecret(
    Session session, {
    required int workspaceId,
    required WorkspaceSecretKind kind,
    required WorkspaceSecretScope scope,
    required String? ownerUserId,
    required String resourceId,
    required Transaction transaction,
  }) => WorkspaceSecret.db.findFirstRow(
    session,
    where: (t) =>
        t.workspaceId.equals(workspaceId) &
        t.secretKind.equals(kind) &
        t.scope.equals(scope) &
        t.ownerUserId.equals(ownerUserId) &
        t.resourceId.equals(resourceId),
    transaction: transaction,
    lockMode: LockMode.forUpdate,
  );
}
