import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../accounts/authenticated_account_resolver.dart';
import '../sync/stream/sync_wakeups.dart';
import 'workspace_history_policy_service.dart';
import 'workspace_history_service.dart';
import 'workspace_permanent_delete.dart';

class WorkspaceHistoryEndpoint extends Endpoint {
  Future<String> policy(Session session, int workspaceId) async {
    final account = await const AuthenticatedAccountResolver()(session);

    return await WorkspaceHistoryPolicyService(
      session,
      workspaceId,
      account.userId,
    ).read();
  }

  Future<void> configurePolicy(
    Session session,
    WorkspaceHistoryPolicyRequest request,
  ) async {
    final account = await const AuthenticatedAccountResolver()(session);
    await WorkspaceHistoryPolicyService(
      session,
      request.workspaceId,
      account.userId,
    ).configure(request);
  }

  Future<void> permanentlyDelete(
    Session session,
    int workspaceId,
    String targetJson,
  ) async {
    final account = await const AuthenticatedAccountResolver()(session);
    await WorkspacePermanentDelete(session, workspaceId, account.userId)(
      targetJson,
    );
    await SyncWakeups.publishWorkspace(session, workspaceId);
  }

  Future<List<String>> history(
    Session session,
    int workspaceId,
    String targetJson,
  ) async {
    final account = await const AuthenticatedAccountResolver()(session);

    return await WorkspaceHistoryService(
      session,
      workspaceId,
      account.userId,
    ).history(targetJson);
  }

  Future<void> restore(
    Session session,
    WorkspaceHistoryRestoreRequest request,
  ) async {
    final account = await const AuthenticatedAccountResolver()(session);
    await WorkspaceHistoryService(
      session,
      request.workspaceId,
      account.userId,
    ).restore(request.targetJson, request.revision, request.requestId);
    await SyncWakeups.publishWorkspace(session, request.workspaceId);
  }
}
