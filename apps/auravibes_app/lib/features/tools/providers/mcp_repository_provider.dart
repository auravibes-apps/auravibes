// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_app/data/repositories/mcp_servers_repository.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'mcp_repository_provider.g.dart';

/// Provides the MCP servers repository instance.
@Riverpod(keepAlive: true)
McpServersRepository mcpServersRepository(Ref ref) {
  final appDatabase = ref.watch(appDatabaseProvider);

  return McpServersRepository(appDatabase);
}
