import 'package:serverpod/serverpod.dart';

import '../accounts/authenticated_account_resolver.dart';
import '../sync/stream/sync_wakeups.dart';
import 'workspace_history_service.dart';
import 'workspace_permanent_delete.dart';

class WorkspaceHistoryEndpoint extends Endpoint {
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
    int workspaceId,
    String targetJson,
    int revision,
    String requestId,
  ) async {
    final account = await const AuthenticatedAccountResolver()(session);
    await WorkspaceHistoryService(
      session,
      workspaceId,
      account.userId,
    ).restore(targetJson, revision, requestId);
    await SyncWakeups.publishWorkspace(session, workspaceId);
  }
}
