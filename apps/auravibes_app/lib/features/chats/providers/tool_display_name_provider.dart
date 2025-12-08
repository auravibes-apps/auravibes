import 'package:auravibes_app/features/tools/providers/mcp_repository_provider.dart';
import 'package:auravibes_app/utils/tool_name_formatter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tool_display_name_provider.g.dart';

/// Provides a human-friendly display name for a tool composite ID.
///
/// For MCP tools, fetches the original server name from the database.
/// For built-in tools, formats the tool identifier.
/// Uses Riverpod's family caching to avoid repeated lookups.
@riverpod
Future<String> toolDisplayName(Ref ref, String compositeToolId) async {
  final parsed = ToolNameFormatter.parse(compositeToolId);

  // For MCP tools, try to get the original server name
  String? mcpServerName;
  final mcpServerId = parsed.mcpServerId;
  if (mcpServerId != null) {
    mcpServerName = await ref.watch(mcpServerNameProvider(mcpServerId).future);
  }

  return ToolNameFormatter.formatDisplayName(
    parsed,
    mcpServerName: mcpServerName,
  );
}

/// Provides the name of an MCP server by its ID.
///
/// Returns null if the server is not found.
/// Cached per server ID via Riverpod's family mechanism.
@riverpod
Future<String?> mcpServerName(Ref ref, String mcpServerId) async {
  try {
    final repository = ref.read(mcpServersRepositoryProvider);
    final server = await repository.getMcpServerById(mcpServerId);
    return server?.name;
  } on Exception {
    // Ignore errors, fall back to null (will use slug name)
    return null;
  }
}
