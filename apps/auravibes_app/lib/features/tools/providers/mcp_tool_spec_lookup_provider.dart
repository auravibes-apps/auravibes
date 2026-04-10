import 'package:auravibes_app/notifiers/mcp_connection_notifier.dart';
import 'package:langchain/langchain.dart';
import 'package:riverpod/riverpod.dart';

/// Runtime adapter wrapping a notifier method behind a plain callback.
///
/// Safety note: the method reference is captured once per provider rebuild.
/// Safe for keepAlive notifiers. For auto-dispose notifiers, the adapter's
/// `ref.watch` keeps the notifier alive while the adapter is watched.
class McpToolSpecLookup {
  const McpToolSpecLookup({required this.call});

  final ToolSpec? Function({
    required String mcpServerId,
    required String toolName,
  })
  call;
}

final mcpToolSpecLookupProvider = Provider<McpToolSpecLookup>((ref) {
  final notifier = ref.watch(mcpConnectionProvider.notifier);
  return McpToolSpecLookup(call: notifier.getToolSpec);
});
