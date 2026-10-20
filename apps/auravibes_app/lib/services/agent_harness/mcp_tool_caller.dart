import 'package:auravibes_app/domain/entities/mcp_elicitation_request.dart';
import 'package:auravibes_app/notifiers/mcp_connection_status.dart';
import 'package:auravibes_app/services/agent_harness/mcp_tool_caller_result.dart';
import 'package:riverpod/riverpod.dart';

typedef McpToolCaller = Future<Object?> Function({
  required String mcpServerId,
  required String toolIdentifier,
  required Map<String, dynamic> arguments,
  McpElicitationHandler? onElicitation,
});

final mcpToolCallerProvider = Provider<McpToolCaller>((ref) {
  return ({
    required String mcpServerId,
    required String toolIdentifier,
    required Map<String, dynamic> arguments,
    McpElicitationHandler? onElicitation,
  }) async {
    final result = await ref
        .read(mcpConnectionProvider.notifier)
        .callToolWithAppData(
          mcpServerId: mcpServerId,
          toolIdentifier: toolIdentifier,
          arguments: arguments,
          onElicitation: onElicitation,
        );

    return McpToolCallerResult(
      modelText: result.modelText,
      appData: result.appData,
    );
  };
});
