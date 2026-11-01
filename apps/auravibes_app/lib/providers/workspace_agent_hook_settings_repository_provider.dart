import 'package:auravibes_app/data/repositories/workspace_agent_hook_settings_repository.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workspace_agent_hook_settings_repository_provider.g.dart';

@Riverpod(keepAlive: true)
WorkspaceAgentHookSettingsRepository workspaceAgentHookSettingsRepository(
  Ref ref,
) {
  final database = ref.watch(appDatabaseProvider);

  return WorkspaceAgentHookSettingsRepository(
    database.workspaceAgentHookSettingsDao,
  );
}
