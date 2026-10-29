import 'package:auravibes_server_client/auravibes_server_client.dart';

class CloudWorkspaceViewState {
  const new({
    required this.workspaces,
    required this.pendingInvites,
    this.erasures = const [],
    this.deletedOwnedWorkspaces = const [],
    this.authenticationRequired = false,
  });

  const new authenticationRequired()
    : workspaces = const [],
      pendingInvites = const [],
      erasures = const [],
      deletedOwnedWorkspaces = const [],
      authenticationRequired = true;

  final List<CloudWorkspaceSummary> workspaces;
  final List<PendingWorkspaceInviteSummary> pendingInvites;
  final List<CloudWorkspaceErasureStatus> erasures;
  final List<CloudWorkspaceSummary> deletedOwnedWorkspaces;
  final bool authenticationRequired;

  bool containsWorkspace(int workspaceId) =>
      workspaces.any((workspace) => workspace.id == workspaceId);

  bool containsInvite(int inviteId) =>
      pendingInvites.any((invite) => invite.id == inviteId);
}
