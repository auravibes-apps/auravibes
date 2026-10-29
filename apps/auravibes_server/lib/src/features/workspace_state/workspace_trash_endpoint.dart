import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../accounts/authenticated_account_resolver.dart';
import '../sync/stream/sync_wakeups.dart';
import 'workspace_trash_service.dart';

class WorkspaceTrashEndpoint extends Endpoint {
  Future<String> deletedReference(
    Session session,
    int workspaceId,
    String tableId,
    String recordId,
  ) async {
    final account = await const AuthenticatedAccountResolver()(session);
    return await WorkspaceTrashService(
      session,
      workspaceId,
      account.userId,
    ).deletedReference(tableId, recordId);
  }

  Future<String> preview(
    Session session,
    int workspaceId,
    String targetJson,
  ) async {
    final account = await const AuthenticatedAccountResolver()(session);
    return await WorkspaceTrashService(
      session,
      workspaceId,
      account.userId,
    ).preview(targetJson);
  }

  Future<String> trash(Session session, WorkspaceTrashRequest request) async {
    final account = await const AuthenticatedAccountResolver()(session);
    final result = await WorkspaceTrashService(
      session,
      request.workspaceId,
      account.userId,
    ).trash(request.requestId, request.targetJson, request.planToken);
    await SyncWakeups.publishWorkspace(session, request.workspaceId);
    return result;
  }

  Future<List<String>> list(Session session, int workspaceId) async {
    final account = await const AuthenticatedAccountResolver()(session);
    return await WorkspaceTrashService(
      session,
      workspaceId,
      account.userId,
    ).list();
  }

  Future<String> restore(
    Session session,
    int workspaceId,
    String batchId,
  ) async {
    final account = await const AuthenticatedAccountResolver()(session);
    final result = await WorkspaceTrashService(
      session,
      workspaceId,
      account.userId,
    ).restore(batchId);
    await SyncWakeups.publishWorkspace(session, workspaceId);
    return result;
  }
}
