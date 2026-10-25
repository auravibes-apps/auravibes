import 'package:serverpod/serverpod.dart';

import '../accounts/authenticated_account_resolver.dart';
import 'workspace_context_store.dart';

/// Explicit host UI consent. This endpoint is never exposed as an agent tool.
class WorkspaceContextEndpoint extends Endpoint {
  Future<String> read(
    Session session,
    int workspaceId,
    String conversationId,
  ) async {
    final account = await const AuthenticatedAccountResolver()(session);
    return WorkspaceContextStore(
      session,
      workspaceId,
      conversationId,
      account.userId,
    ).read();
  }

  Future<String> save(
    Session session,
    int workspaceId,
    String conversationId,
    String requestId,
    String? selectionJson,
  ) async {
    final account = await const AuthenticatedAccountResolver()(session);
    return WorkspaceContextStore(
      session,
      workspaceId,
      conversationId,
      account.userId,
    ).save(requestId, selectionJson);
  }
}
