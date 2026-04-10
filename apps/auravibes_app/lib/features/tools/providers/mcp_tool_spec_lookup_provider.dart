import 'package:auravibes_app/notifiers/mcp_connection_notifier.dart';
import 'package:langchain/langchain.dart';
import 'package:riverpod/riverpod.dart';

/// Runtime adapter wrapping a notifier method behind a plain callback.
///
/// Safety note: the method reference is captured once per provider rebuild.
/// Safe because code-generated notifiers are singleton-like.
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
