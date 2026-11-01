import 'package:auravibes_app/domain/entities/workspace_agent_hook_settings.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/providers/agent_lifecycle_hook_runtime_provider.dart';
import 'package:auravibes_app/providers/workspace_agent_hook_settings_repository_provider.dart';
import 'package:riverpod/riverpod.dart';

enum WorkspaceAgentHookTrustStatus {
  notConfigured,
  trustRequired,
  trusted,
  changed,
  invalid,
  unsupportedPlatform,
  unsupportedWorkspace,
}

final workspaceAgentHookSettingsProvider =
    StreamProvider.family<WorkspaceAgentHookSettings, String>(
      (ref, workspaceId) => ref
          .watch(workspaceAgentHookSettingsRepositoryProvider)
          .watch(workspaceId),
    );

final workspaceAgentHookTrustStatusProvider =
    FutureProvider.family<WorkspaceAgentHookTrustStatus, String>((
      ref,
      workspaceId,
    ) async {
      final workspaces = ref.watch(allWorkspacesProvider).asData?.value;
      final workspace = workspaces
          ?.where((workspace) => workspace.id == workspaceId)
          .firstOrNull;
      if (workspace == null || workspace.type != WorkspaceType.local) {
        return WorkspaceAgentHookTrustStatus.unsupportedWorkspace;
      }

      final runtime = ref.watch(agentLifecycleHookRuntimeProvider);
      if (!runtime.isSupported) {
        return WorkspaceAgentHookTrustStatus.unsupportedPlatform;
      }

      final settings = await ref.watch(
        workspaceAgentHookSettingsProvider(workspaceId).future,
      );
      final path = settings.configPath;
      if (path == null) return WorkspaceAgentHookTrustStatus.notConfigured;

      if (!settings.isTrusted) {
        return WorkspaceAgentHookTrustStatus.trustRequired;
      }

      try {
        final snapshot = await runtime.inspect(path);
        return snapshot.canonicalPath == settings.trustedSourcePath &&
                snapshot.canonicalPath == path &&
                snapshot.digest == settings.trustedDigest
            ? WorkspaceAgentHookTrustStatus.trusted
            : WorkspaceAgentHookTrustStatus.changed;
      } on Object {
        return WorkspaceAgentHookTrustStatus.invalid;
      }
    });
