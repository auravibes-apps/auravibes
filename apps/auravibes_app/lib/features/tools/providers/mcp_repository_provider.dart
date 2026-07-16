// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_app/data/repositories/mcp_servers_repository.dart';
import 'package:auravibes_app/features/tools/data/cloud_tools_repository.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'mcp_repository_provider.g.dart';

/// Provides the MCP servers repository instance.
@Dependencies([workspaceSession, cloudWorkspaceStateGateway])
@Riverpod(dependencies: [workspaceSession])
McpServersRepositoryContract mcpServersRepository(Ref ref) {
  if (ref.watch(workspaceSessionProvider).cloud != null) {
    return CloudToolsRepository(
      ref.read(cloudWorkspaceStateGatewayProvider.future),
    );
  }
  final appDatabase = ref.watch(appDatabaseProvider);

  return McpServersRepository(appDatabase);
}
