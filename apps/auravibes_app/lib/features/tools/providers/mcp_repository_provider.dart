import 'package:auravibes_app/data/repositories/mcp_servers_repository_impl.dart';
import 'package:auravibes_app/domain/repositories/mcp_servers_repository.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'mcp_repository_provider.g.dart';

/// Provides the MCP servers repository instance.
@riverpod
McpServersRepository mcpServersRepository(Ref ref) {
  final appDatabase = ref.watch(appDatabaseProvider);
  return McpServersRepositoryImpl(appDatabase);
}
