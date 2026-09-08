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

final class const WorkspaceSession(final WorkspaceRef workspace) {
  WorkspaceCapabilities get capabilities => switch (workspace) {
    CloudWorkspaceRef() => WorkspaceCapabilities.cloud,
    LocalWorkspaceRef() => WorkspaceCapabilities.local,
  };

  CloudWorkspaceRef? get cloud => switch (workspace) {
    final CloudWorkspaceRef cloud => cloud,
    LocalWorkspaceRef() => null,
  };
}
