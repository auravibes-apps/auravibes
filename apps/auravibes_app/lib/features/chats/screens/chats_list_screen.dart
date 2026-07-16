// Required: UI callbacks stay local to their widgets.
import 'package:auravibes_app/features/chats/notifiers/conversation_result.dart';
import 'package:auravibes_app/features/chats/providers/cloud_conversation_provider.dart';
import 'package:auravibes_app/features/chats/providers/context_usage_level.dart';
import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/features/chats/providers/message_id_list.dart';
import 'package:auravibes_app/features/chats/widgets/chat_list_widget.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selection_providers.dart';
import 'package:auravibes_app/features/service_connections/providers/service_connection_operations_provider.dart';
import 'package:auravibes_app/features/service_connections/providers/service_connections_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/app_content.dart';
import 'package:auravibes_app/widgets/aura_app_bar_with_drawer.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

@Dependencies([
  workspaceModelSelectionById,
  workspaceSession,
  cloudWorkspaceStateGateway,
  serviceConnectionOperations,
  serviceConnections,
  ConversationChatNotifier,
  conversationBusyState,
  pendingToolCalls,
  contextUsage,
  chatMessages,
  childConversationsStream,
  conversationByIdStream,
  messageConversationById,
  cloudConversationUsecase,
])
class ChatsListScreen extends ConsumerWidget {
  const ChatsListScreen({required this.workspaceId, super.key});

  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AuraScreen(
      child: AuraColumn(
        children: [
          AuraPadding(
            child: AppContent(
              child: Row(
                children: [
                  Expanded(
                    child: AuraButton(
                      onPressed: () {
                        NewChatRoute(workspaceId: workspaceId).go(context);
                      },
                      child: const TextLocale(
                        LocaleKeys.chats_screens_chats_list_add_chat,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            padding: const .horizontal(.md),
          ),

          Expanded(child: ChatListWidget(workspaceId: workspaceId)),
        ],
      ),
      appBar: const AuraAppBarWithDrawer(
        title: TextLocale(LocaleKeys.chats_screens_chats_list_title),
      ),
    );
  }
}
