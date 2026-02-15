import 'package:auravibes_app/domain/models/mcp_tool_info.dart';

class CallMcpToolUseCase {
  const CallMcpToolUseCase({
    required Future<String> Function({
      required String toolIdentifier,
      required Map<String, dynamic> arguments,
    })
    callTool,
  }) : _callTool = callTool;

  final Future<String> Function({
    required String toolIdentifier,
    required Map<String, dynamic> arguments,
  })
  _callTool;

  Future<String> call({
    required bool isConnected,
    required List<McpToolInfo> availableTools,
    required String mcpServerId,
    required String toolIdentifier,
    required Map<String, dynamic> arguments,
  }) async {
    if (!isConnected) {
      throw Exception('MCP server not connected: $mcpServerId');
    }

    final toolExists = availableTools.any((t) => t.toolName == toolIdentifier);
    if (!toolExists) {
      throw Exception(
        'Tool "$toolIdentifier" not found on MCP server: $mcpServerId',
      );
    }

    return _callTool(toolIdentifier: toolIdentifier, arguments: arguments);
  }
}
