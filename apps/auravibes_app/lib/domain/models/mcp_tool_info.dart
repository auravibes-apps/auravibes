// ============================================================
// MCP Tool Info
// ============================================================

import 'package:freezed_annotation/freezed_annotation.dart';

part 'mcp_tool_info.freezed.dart';

/// Information about a tool provided by an MCP server
@freezed
abstract class McpToolInfo with _$McpToolInfo {
  const factory McpToolInfo({
    /// Original tool name from the MCP server
    required String toolName,

    /// Original MCP server name to avoid conflicts
    required String serverName,

    /// Tool description from the MCP server
    required String description,

    /// JSON Schema for the tool's input parameters
    required Map<String, dynamic> inputSchema,

    /// ID of the MCP server that provides this tool
    required String mcpServerId,

    /// Whether the tool supports progress updates
    bool? supportsProgress,

    /// Whether the tool supports cancellation
    bool? supportsCancellation,

    /// Additional metadata for the tool
    Map<String, dynamic>? metadata,
  }) = _McpToolInfo;

  const McpToolInfo._();

  /// Convert a name to a URL-safe slug.
  String get slugServerName {
    return serverName.toLowerCase().replaceAll(RegExp('[^a-z0-9]+'), '_');
  }

  /// Generate a prefixed tool name to avoid conflicts.
  ///
  /// Format: `mcp::<mcp_id>::<slug_name>::<tool_identifier>`
  /// - mcp_id: Database ID of the MCP server (ensures uniqueness)
  /// - slug_name: URL-safe slug of server name (for LLM readability)
  /// - tool_identifier: Original tool name from the MCP server
  String get finalToolName {
    return 'mcp::$mcpServerId::$slugServerName::$toolName';
  }
}
