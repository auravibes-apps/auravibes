import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';
import '../../workspace_state/workspace_secret_resolver.dart';

class ModelConnectionRepository {
  Future<WorkspaceMember?> findMember(
    Session session, {
    required int workspaceId,
    required String userId,
  }) => WorkspaceMember.db.findFirstRow(
    session,
    where: (table) =>
        table.workspaceId.equals(workspaceId) &
        table.userId.equals(userId) &
        table.removedAt.equals(null),
  );

  Future<WorkspaceModelConnection?> findConnection(
    Session session, {
    required int workspaceId,
    required String connectionId,
  }) => WorkspaceModelConnection.db.findFirstRow(
    session,
    where: (table) =>
        table.workspaceId.equals(workspaceId) &
        table.connectionId.equals(connectionId) &
        table.deletedAt.equals(null),
  );

  Future<List<WorkspaceModelConnection>> listConnections(
    Session session, {
    required int workspaceId,
  }) => WorkspaceModelConnection.db.find(
    session,
    where: (table) =>
        table.workspaceId.equals(workspaceId) & table.deletedAt.equals(null),
  );

  Future<WorkspaceModelConnection> insertConnection(
    Session session,
    WorkspaceModelConnection connection, {
    required Transaction transaction,
  }) => WorkspaceModelConnection.db.insertRow(
    session,
    connection,
    transaction: transaction,
  );

  Future<WorkspaceModelConnection> updateConnection(
    Session session,
    WorkspaceModelConnection connection, {
    required Transaction transaction,
  }) => WorkspaceModelConnection.db.updateRow(
    session,
    connection,
    transaction: transaction,
  );

  Future<List<ApiModel>> listCatalogModels(
    Session session, {
    required String providerId,
  }) => ApiModel.db.find(
    session,
    where: (table) => table.providerId.equals(providerId),
    orderByList: (table) => [table.name, table.modelId],
  );

  Future<WorkspaceSecret?> findSecret(
    Session session, {
    required int workspaceId,
    required String userId,
    required String connectionId,
  }) => const WorkspaceSecretResolver().findForInitiator(
    session,
    workspaceId: workspaceId,
    kind: WorkspaceSecretKind.provider,
    initiatorUserId: userId,
    resourceId: connectionId,
    allowWorkspaceFallback: true,
  );
}
