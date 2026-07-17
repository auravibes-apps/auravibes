import 'package:auravibes_app/features/workspaces/models/workspace_capabilities.dart';

sealed class WorkspaceRef {
  const WorkspaceRef({required this.localWorkspaceId});

  final String localWorkspaceId;
}

final class LocalWorkspaceRef extends WorkspaceRef {
  const LocalWorkspaceRef({required super.localWorkspaceId});
}

final class CloudWorkspaceRef extends WorkspaceRef {
  const CloudWorkspaceRef({
    required super.localWorkspaceId,
    required this.serverUrl,
    required this.accountId,
    required this.cloudWorkspaceId,
  });

  final String serverUrl;
  final String accountId;
  final int cloudWorkspaceId;
}

final class WorkspaceSession {
  const WorkspaceSession(this.workspace);

  final WorkspaceRef workspace;

  WorkspaceCapabilities get capabilities => switch (workspace) {
    CloudWorkspaceRef() => WorkspaceCapabilities.cloud,
    LocalWorkspaceRef() => WorkspaceCapabilities.local,
  };

  CloudWorkspaceRef? get cloud => switch (workspace) {
    final CloudWorkspaceRef cloud => cloud,
    LocalWorkspaceRef() => null,
  };
}
