import 'package:auravibes_app/notifiers/mcp_connection_status.dart';
import 'package:riverpod/riverpod.dart';

typedef McpToolCallerResult = ({
  String modelText,
  Map<String, Object?> appData,
});

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

    return (modelText: result.modelText, appData: result.appData);
  };
});
