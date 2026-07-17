import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';
import '../../accounts/authenticated_account_resolver.dart';
import 'workspace_stream_service.dart';

class WorkspaceStreamEndpoint extends Endpoint {
  Stream<WorkspaceStreamEnvelope> subscribe(
    Session session,
    WorkspaceSubscribeRequest request,
  ) async* {
    final account = await const AuthenticatedAccountResolver()(session);
    yield* const WorkspaceStreamService().subscribe(
      session,
      request: request,
      userId: account.userId,
    );
  }
}
