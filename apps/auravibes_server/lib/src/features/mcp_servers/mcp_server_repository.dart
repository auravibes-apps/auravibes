import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../workspace_state/workspace_secret_resolver.dart';

class McpServerRepository {
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
    Session session, {
    required int workspaceId,
    required Transaction transaction,
  }) => CloudWorkspace.db.findFirstRow(
    session,
    where: (t) => t.id.equals(workspaceId) & t.deletedAt.equals(null),
    transaction: transaction,
    lockMode: LockMode.forUpdate,
  );

  Future<WorkspaceResource> insertResource(
    Session session, {
    required WorkspaceResource resource,
    required Transaction transaction,
  }) => WorkspaceResource.db.insertRow(
    session,
    resource,
    transaction: transaction,
  );

  Future<WorkspaceSecret> insertSecret(
    Session session, {
    required WorkspaceSecret secret,
    required Transaction transaction,
  }) => WorkspaceSecret.db.insertRow(session, secret, transaction: transaction);

  Future<void> updateWorkspace(
    Session session, {
    required CloudWorkspace workspace,
    required Transaction transaction,
  }) =>
      CloudWorkspace.db.updateRow(session, workspace, transaction: transaction);

  Future<void> insertEvent(
    Session session, {
    required WorkspaceEvent event,
    required Transaction transaction,
  }) => WorkspaceEvent.db.insertRow(session, event, transaction: transaction);

  Future<WorkspaceMutationReceipt?> findReceipt(
    Session session, {
    required int workspaceId,
    required String userId,
    required String endpoint,
    required String requestId,
    required Transaction transaction,
  }) => WorkspaceMutationReceipt.db.findFirstRow(
    session,
    where: (t) =>
        t.workspaceId.equals(workspaceId) &
        t.actorUserId.equals(userId) &
        t.scopeKey.equals('workspace:$workspaceId') &
        t.endpoint.equals(endpoint) &
        t.requestId.equals(requestId),
    transaction: transaction,
  );

  Future<void> insertReceipt(
    Session session, {
    required WorkspaceMutationReceipt receipt,
    required Transaction transaction,
  }) => WorkspaceMutationReceipt.db.insertRow(
    session,
    receipt,
    transaction: transaction,
  );

  Future<List<WorkspaceResource>> findResources(
    Session session, {
    required int workspaceId,
    required WorkspaceResourceKind kind,
    required Transaction transaction,
  }) => WorkspaceResource.db.find(
    session,
    where: (t) =>
        t.workspaceId.equals(workspaceId) &
        t.resourceKind.equals(kind) &
        t.deletedAt.equals(null),
    transaction: transaction,
  );

  Future<void> updateResource(
    Session session, {
    required WorkspaceResource resource,
    required Transaction transaction,
  }) => WorkspaceResource.db.updateRow(
    session,
    resource,
    transaction: transaction,
  );

  Future<List<WorkspaceSecret>> findSecrets(
    Session session, {
    required int workspaceId,
    required String resourceId,
    required Transaction transaction,
  }) => WorkspaceSecret.db.find(
    session,
    where: (t) =>
        t.workspaceId.equals(workspaceId) &
        t.secretKind.equals(WorkspaceSecretKind.mcp) &
        t.resourceId.equals(resourceId) &
        t.deletedAt.equals(null),
    transaction: transaction,
  );

  Future<void> updateSecret(
    Session session, {
    required WorkspaceSecret secret,
    required Transaction transaction,
  }) => WorkspaceSecret.db.updateRow(session, secret, transaction: transaction);

  Future<WorkspaceResource?> findServer(
    Session session, {
    required int workspaceId,
    required String resourceId,
    Transaction? transaction,
  }) => WorkspaceResource.db.findFirstRow(
    session,
    where: (t) =>
        t.workspaceId.equals(workspaceId) &
        t.resourceKind.equals(WorkspaceResourceKind.mcpServer) &
        t.resourceId.equals(resourceId) &
        t.deletedAt.equals(null),
    transaction: transaction,
  );

  Future<WorkspaceSecret?> findSecret(
    Session session, {
    required int workspaceId,
    required String userId,
    required String resourceId,
  }) => const WorkspaceSecretResolver().findForInitiator(
    session,
    workspaceId: workspaceId,
    kind: WorkspaceSecretKind.mcp,
    initiatorUserId: userId,
    resourceId: resourceId,
    allowWorkspaceFallback: true,
  );
}
