import 'package:auravibes_app/notifiers/mcp_connection_status.dart';
import 'package:riverpod/riverpod.dart';

typedef McpToolCaller =
    Future<String> Function({
      required String mcpServerId,
      required String toolIdentifier,
      required Map<String, dynamic> arguments,
    });

final mcpToolCallerProvider = Provider<McpToolCaller>((ref) {
  return ({
    required String mcpServerId,
    required String toolIdentifier,
    required Map<String, dynamic> arguments,
  }) {
    return ref
        .read(mcpConnectionProvider.notifier)
        .callTool(
          mcpServerId: mcpServerId,
          toolIdentifier: toolIdentifier,
          arguments: arguments,
        );
  };
});
