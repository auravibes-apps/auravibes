import 'package:auravibes_app/domain/entities/workspace_agent_hook_settings.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:auravibes_app/features/settings/models/workspace_agent_hook_trust_status.dart';
import 'package:auravibes_app/features/settings/usecases/workspace_agent_hook_trust_status_usecase.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/providers/agent_lifecycle_hook_runtime_provider.dart';
import 'package:auravibes_app/providers/workspace_agent_hook_settings_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

export 'package:auravibes_app/features/settings/models/workspace_agent_hook_trust_status.dart';

part 'workspace_agent_hook_settings_provider.g.dart';

@Riverpod(keepAlive: true)
Stream<WorkspaceAgentHookSettings> workspaceAgentHookSettings(
  Ref ref,
  String workspaceId,
) => ref.watch(workspaceAgentHookSettingsRepositoryProvider).watch(workspaceId);

@Riverpod(keepAlive: true)
Future<WorkspaceAgentHookTrustStatus> workspaceAgentHookTrustStatus(
  Ref ref,
  String workspaceId,
) async {
  final workspaceStatus = _workspaceSupportStatus(ref, workspaceId);
  if (workspaceStatus != null) return workspaceStatus;
  final runtime = ref.watch(agentLifecycleHookRuntimeProvider);
  if (!runtime.isSupported) {
    return WorkspaceAgentHookTrustStatus.unsupportedPlatform;
  }

  final settings = await ref.watch(
    workspaceAgentHookSettingsProvider(workspaceId).future,
  );

  return await WorkspaceAgentHookTrustStatusUsecase(runtime).call(settings);
}

WorkspaceAgentHookTrustStatus? _workspaceSupportStatus(
  Ref ref,
  String workspaceId,
) {
  final workspace = ref
      .watch(allWorkspacesProvider)
      .asData
      ?.value
      .where((workspace) => workspace.id == workspaceId)
      .firstOrNull;
  if (workspace != null && workspace.type == WorkspaceType.local) return null;

  return WorkspaceAgentHookTrustStatus.unsupportedWorkspace;
}
