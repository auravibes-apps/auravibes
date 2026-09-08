import 'package:auravibes_server_client/auravibes_server_client.dart';

class const CloudWorkspaceDetailState({
  required final CloudWorkspaceDetail detail,
  required final List<CloudWorkspaceMemberSummary> members,
  required final List<CloudWorkspaceInviteSummary> invites,
});

class CloudWorkspaceViewState {
  const new({
    required this.workspaces,
    required this.pendingInvites,
    this.authenticationRequired = false,
  });

  const new authenticationRequired()
    : workspaces = const [],
      pendingInvites = const [],
      authenticationRequired = true;

  final List<CloudWorkspaceSummary> workspaces;
  final List<PendingWorkspaceInviteSummary> pendingInvites;
  final bool authenticationRequired;
}
