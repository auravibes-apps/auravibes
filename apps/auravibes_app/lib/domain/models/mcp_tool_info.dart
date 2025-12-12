// ============================================================
// MCP Tool Info
// ============================================================

import 'package:auravibes_app/data/database/drift/tables/mcp_servers_table.dart';
import 'package:auravibes_app/domain/entities/workspace_tool.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'mcp_tool_info.freezed.dart';

/// Information about a tool provided by an MCP server
@freezed
abstract class McpToolInfo with _$McpToolInfo {
  const factory McpToolInfo({
    required String toolName,
    required String description,
    required Map<String, dynamic> inputSchema,
    bool? supportsProgress,
    bool? supportsCancellation,
    Map<String, dynamic>? metadata,
  }) = _McpToolInfo;

  const McpToolInfo._();

  /// Generate a prefixed tool name to avoid conflicts.
  ///
  /// Format: `mcp_<mcp_id>_<slug_name>_<tool_identifier>`
  /// - mcp_id: Database ID of the MCP server (ensures uniqueness)
  /// - slug_name: URL-safe slug of server name (for LLM readability)
  /// - tool_identifier: Original tool name from the MCP server
  ///
  /// Note: Tool names must match pattern ^[a-zA-Z0-9_-]{1,128}$
  /// so we use underscores as separators instead of colons.
  String finalToolName(McpServerEntity server) {
    // Sanitize toolName to only contain valid characters
    final sanitizedToolName = toolName.replaceAll(
      RegExp('[^a-zA-Z0-9_-]'),
      '_',
    );
    return 'mcp_${server.id}_${server.slugServerName}_$sanitizedToolName';
  }
}

/// Information about a tool provided by an MCP server
@freezed
abstract class MCPServerWithTools with _$MCPServerWithTools {
  const factory MCPServerWithTools({
    required McpServerEntity server,

    required List<WorkspaceToolEntity> tools,
  }) = _MCPServerWithTools;

  const MCPServerWithTools._();

  /// Convert a name to a URL-safe slug.
  String get slugServerName {
    return server.slugServerName;
  }
}
