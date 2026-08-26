import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';

sealed class WorkspaceAvailability {
  const WorkspaceAvailability(this.session);

  final WorkspaceSession session;
}

// ignore: unused-code, returned by workspaceAvailability provider.
final class WorkspaceAvailable extends WorkspaceAvailability {
  const WorkspaceAvailable(super.session);
}

final class WorkspaceAuthenticationRequired extends WorkspaceAvailability {
  const WorkspaceAuthenticationRequired(super.session);
}
