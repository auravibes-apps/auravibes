import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'domain/workspace_resource_validation.dart';

class WorkspaceSecretResolver {
  const WorkspaceSecretResolver();

  Future<WorkspaceSecret?> find(
    Session session, {
    required int workspaceId,
    required WorkspaceSecretKind kind,
    required WorkspaceSecretScope scope,
    required String ownerUserId,
    required String resourceId,
    Transaction? transaction,
  }) => WorkspaceSecret.db.findFirstRow(
    session,
    where: (table) =>
        table.workspaceId.equals(workspaceId) &
        table.secretKind.equals(kind) &
        table.scope.equals(scope) &
        table.ownerUserId.equals(
          WorkspaceResourceValidation.secretOwnerKey(scope, ownerUserId),
        ) &
        table.resourceId.equals(resourceId) &
        table.deletedAt.equals(null),
    transaction: transaction,
  );

  Future<WorkspaceSecret?> findForInitiator(
    Session session, {
    required int workspaceId,
    required WorkspaceSecretKind kind,
    required String initiatorUserId,
    required String resourceId,
    bool allowWorkspaceFallback = false,
  }) async {
    final userSecret = await find(
      session,
      workspaceId: workspaceId,
      kind: kind,
      scope: WorkspaceSecretScope.user,
      ownerUserId: initiatorUserId,
      resourceId: resourceId,
    );
    if (userSecret != null || !allowWorkspaceFallback) return userSecret;
    return find(
      session,
      workspaceId: workspaceId,
      kind: kind,
      scope: WorkspaceSecretScope.workspace,
      ownerUserId: initiatorUserId,
      resourceId: resourceId,
    );
  }
}
