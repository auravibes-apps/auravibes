// ignore_for_file: no-magic-number
// Required: Existing thresholds and limits use numeric values.
// ignore_for_file: format-comment
// Required: Existing comments use generated or domain-specific formatting.
// ignore_for_file: no-equal-arguments
// Required: Existing argument values intentionally repeat.
import 'package:auravibes_app/features/chats/providers/message_id_list.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/notifiers/mcp_connection_status.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

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
    final mcpConnections = ref.watch(mcpConnectionProvider);
    final pendingServerNames = mcpConnections
        .where((c) => pendingMcpIds.contains(c.server.id))
        .map((c) => c.server.name)
        .toList();

    return AuraContainer(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              color: context.auraColors.primary,
              strokeWidth: 2,
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
      padding: .small,
      margin: .small,
      backgroundColor: AuraColorVariant.surfaceVariant,
    );
  }
}
