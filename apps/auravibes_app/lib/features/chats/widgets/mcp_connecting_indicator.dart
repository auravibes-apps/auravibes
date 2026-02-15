import 'package:auravibes_app/features/chats/providers/messages_providers.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/providers/mcp_connection_controller.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

@Dependencies([pendingMcpConnections])
/// Widget that shows a "Waiting for tools to connect..." indicator
/// when MCP servers are still connecting before a message can be sent.
class McpConnectingIndicator extends ConsumerWidget {
  const McpConnectingIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingMcpIds = ref.watch(pendingMcpConnectionsProvider);

    if (pendingMcpIds.isEmpty) {
      return const SizedBox.shrink();
    }

    // Get the server names for the pending MCPs
    final mcpConnections = ref.watch(mcpConnectionControllerProvider);
    final pendingServerNames = mcpConnections
        .where((c) => pendingMcpIds.contains(c.server.id))
        .map((c) => c.server.name)
        .toList();

    return AuraContainer(
      backgroundColor: context.auraColors.surfaceVariant,
      padding: .small,
      margin: .small,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: context.auraColors.primary,
            ),
          ),
          SizedBox(width: context.auraTheme.spacing.sm),
          Flexible(
            child: Text(
              pendingServerNames.isEmpty
                  ? LocaleKeys.chats_screens_chat_conversation_waiting_for_tools
                        .tr()
                  : LocaleKeys
                        .chats_screens_chat_conversation_waiting_for_tools_named
                        .tr(
                          namedArgs: {'tools': pendingServerNames.join(', ')},
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
