import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../accounts/authenticated_account_resolver.dart';
import '../sync/stream/sync_wakeups.dart';
import 'repositories/workspace_state_repository.dart';
import 'usecases/workspace_state_usecases.dart';

class WorkspaceStateEndpoint extends Endpoint {
  WorkspaceStateUseCases get _useCases =>
      WorkspaceStateUseCases(WorkspaceStateRepository());

  Future<ReadWorkspaceStateResponse> read(
    Session session,
    ReadWorkspaceStateRequest request,
  ) async {
    final account = await const AuthenticatedAccountResolver()(session);
    return _useCases.read(session, userId: account.userId, request: request);
  }

  Future<PatchWorkspaceStateResponse> patch(
    Session session,
    PatchWorkspaceStateRequest request,
  ) async {
    final account = await const AuthenticatedAccountResolver()(session);
    final response = await _useCases.patch(
      session,
      userId: account.userId,
      request: request,
    );
    await SyncWakeups.publishWorkspace(session, request.workspaceId);
    return response;
  }

  Future<MutateWorkspaceCredentialResponse> mutateCredential(
    Session session,
    MutateWorkspaceCredentialRequest request,
  ) async {
    final account = await const AuthenticatedAccountResolver()(session);
    final response = await _useCases.mutateCredential(
      session,
      userId: account.userId,
      request: request,
    );
    await SyncWakeups.publishWorkspace(session, request.workspaceId);
    return response;
  }
}
