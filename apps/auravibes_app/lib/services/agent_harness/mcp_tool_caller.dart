import 'package:auravibes_app/notifiers/mcp_connection_status.dart';
import 'package:auravibes_app/services/agent_harness/mcp_tool_caller_result.dart';
import 'package:riverpod/riverpod.dart';

typedef McpToolCaller = Future<Object?> Function({
  required String mcpServerId,
  required String toolIdentifier,
  required Map<String, dynamic> arguments,
});

final mcpToolCallerProvider = Provider<McpToolCaller>((ref) {
  return ({
    required String mcpServerId,
    required String toolIdentifier,
    required Map<String, dynamic> arguments,
  }) async {
    final result = await ref
        .read(mcpConnectionProvider.notifier)
        .callToolWithAppData(
          mcpServerId: mcpServerId,
          toolIdentifier: toolIdentifier,
          arguments: arguments,
        );

    return McpToolCallerResult(
      modelText: result.modelText,
      appData: result.appData,
    );
  };
});
