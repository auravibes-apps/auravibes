import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../accounts/authenticated_account_resolver.dart';
import '../sync/stream/sync_wakeups.dart';
import 'repositories/workspace_state_repository.dart';
import 'usecases/workspace_state_usecases.dart';

class WorkspaceSecretEndpoint extends Endpoint {
  Future<PutWorkspaceSecretResponse> put(
    Session session,
    PutWorkspaceSecretRequest request,
  ) async {
    final account = await const AuthenticatedAccountResolver()(session);
    final response = await WorkspaceStateUseCases(WorkspaceStateRepository())
        .putSecret(
          session,
          userId: account.userId,
          request: request,
        );
    await SyncWakeups.publishWorkspace(session, request.workspaceId);
    return response;
  }
}
