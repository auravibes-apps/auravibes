import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/domain/models/mcp_tool_info.dart';

/// Contract for MCP server persistence.
abstract interface class McpServersRepositoryContract {
  Future<McpServerEntity> addMcpServerWithTools({
    required String workspaceId,
    required McpServerToCreate serverToCreate,
    required List<McpToolInfo> tools,
  });
  Future<bool> deleteMcpServer(String serverId);
  Future<void> syncMcpTools({
    required String mcpServerId,
    required List<McpToolInfo> currentTools,
  });
  Future<List<McpServerEntity>> getMcpServersForWorkspace(String workspaceId);
  Future<List<McpServerEntity>> getEnabledMcpServersForWorkspace(
    String workspaceId,
  );
  Future<McpServerEntity?> getMcpServerById(String serverId);
}
