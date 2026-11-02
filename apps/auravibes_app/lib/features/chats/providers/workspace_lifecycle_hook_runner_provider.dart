import 'package:auravibes_app/features/chats/agent_adapters/workspace_lifecycle_hook_runner.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/providers/agent_lifecycle_hook_runtime_provider.dart';
import 'package:auravibes_app/providers/workspace_agent_hook_settings_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workspace_lifecycle_hook_runner_provider.g.dart';

@Riverpod(keepAlive: true)
WorkspaceLifecycleHookRunner workspaceLifecycleHookRunner(Ref ref) =>
    WorkspaceLifecycleHookRunner(
      settingsRepository: ref.watch(
        workspaceAgentHookSettingsRepositoryProvider,
      ),
      workspaceRepository: ref.watch(workspaceRepositoryProvider),
      runtime: ref.watch(agentLifecycleHookRuntimeProvider),
    );
