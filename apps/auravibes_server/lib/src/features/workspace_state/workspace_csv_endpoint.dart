import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../accounts/authenticated_account_resolver.dart';
import 'usecases/workspace_state_usecases.dart';

class WorkspaceCsvEndpoint extends Endpoint {
  WorkspaceStateUseCases get _useCases => WorkspaceStateUseCases(.new());

  Future<PatchWorkspaceStateResponse> preview(
    Session session,
    PatchWorkspaceStateRequest request,
  ) async {
    final account = await const AuthenticatedAccountResolver()(session);
    _validate(request);

    return await _useCases.patch(
      session,
      userId: account.userId,
      request: request,
      previewOnly: true,
    );
  }

  void _validate(PatchWorkspaceStateRequest request) {
    if (request.viewMoves?.isNotEmpty == true ||
        request.operations.any(
          (operation) =>
              operation.operation != WorkspacePatchOperationKind.create ||
              operation.resourceKind != WorkspaceResourceKind.tableRecord,
        )) {
      throw CloudWorkspaceException(code: .validationFailed);
    }
  }
}
