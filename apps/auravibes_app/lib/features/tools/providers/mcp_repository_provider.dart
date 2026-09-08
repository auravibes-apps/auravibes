// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_app/data/repositories/mcp_servers_repository.dart';
import 'package:auravibes_app/features/tools/data/cloud_tools_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'mcp_repository_provider.g.dart';

extension McpRepositoryProvider on McpServersRepositoryFamily {
  Override overrideWithValue(McpServersRepositoryContract value) =>
      overrideWith((_, _) => value);
}

/// Provides the MCP servers repository instance.
@riverpod
McpServersRepositoryContract mcpServersRepository(
  Ref ref,
  WorkspaceSession session,
) {
  if (session.cloud != null) {
    return CloudToolsRepository(
      ref.read(cloudWorkspaceStateGatewayProvider(session).future),
    );
  }
  final appDatabase = ref.watch(appDatabaseProvider);

  return McpServersRepository(appDatabase);
}
