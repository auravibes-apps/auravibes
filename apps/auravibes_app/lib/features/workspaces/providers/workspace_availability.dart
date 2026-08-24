import 'package:auravibes_server_client/auravibes_server_client.dart';
import '../models/workspace_ref.dart';

sealed class WorkspaceAvailability {
  const WorkspaceAvailability(this.session);

  final WorkspaceSession session;
}

final class WorkspaceAvailable extends WorkspaceAvailability {
  const WorkspaceAvailable(super.session);
}

final class WorkspaceAuthenticationRequired extends WorkspaceAvailability {
  const WorkspaceAuthenticationRequired(super.session);
}
