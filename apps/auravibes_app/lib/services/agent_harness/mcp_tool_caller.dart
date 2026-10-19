import 'package:auravibes_app/domain/entities/mcp_elicitation_request.dart';
import 'package:auravibes_app/notifiers/mcp_connection_status.dart';
import 'package:riverpod/riverpod.dart';

typedef McpToolCaller = Future<String> Function({
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
  }) {
    return ref
        .read(mcpConnectionProvider.notifier)
        .callTool(
          mcpServerId: mcpServerId,
          toolIdentifier: toolIdentifier,
          arguments: arguments,
          onElicitation: onElicitation,
        );
  };
});
