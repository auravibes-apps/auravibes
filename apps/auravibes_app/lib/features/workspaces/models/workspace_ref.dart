import 'package:auravibes_app/features/workspaces/models/workspace_capabilities.dart';

sealed class const WorkspaceRef({required final String localWorkspaceId});

final class const LocalWorkspaceRef({required super.localWorkspaceId})
    extends WorkspaceRef;

final class const CloudWorkspaceRef({
  required super.localWorkspaceId,
  required final String serverUrl,
  required final String accountId,
  required final int cloudWorkspaceId,
}) extends WorkspaceRef;

final class WorkspaceSession {
  const new(this.workspace)
    : capabilities = workspace is LocalWorkspaceRef
          ? WorkspaceCapabilities.local
          : WorkspaceCapabilities.cloud,
      cloud = workspace is CloudWorkspaceRef ? workspace : null;

  final WorkspaceRef workspace;
  final WorkspaceCapabilities capabilities;
  final CloudWorkspaceRef? cloud;

  /// Returns whether this session supports [capability].
  bool hasCapability(WorkspaceCapabilities capability) =>
      capabilities == capability;
}
