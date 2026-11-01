import 'package:auravibes_app/features/settings/usecases/workspace_agent_hook_settings_usecase.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/providers/agent_lifecycle_hook_runtime_provider.dart';
import 'package:auravibes_app/providers/workspace_agent_hook_settings_repository_provider.dart';
import 'package:riverpod/riverpod.dart';

final workspaceAgentHookSettingsUsecaseProvider =
    Provider<WorkspaceAgentHookSettingsUsecase>((ref) {
      return WorkspaceAgentHookSettingsUsecase(
        settingsRepository: ref.watch(
          workspaceAgentHookSettingsRepositoryProvider,
        ),
        workspaceRepository: ref.watch(workspaceRepositoryProvider),
        runtime: ref.watch(agentLifecycleHookRuntimeProvider),
      );
    });
