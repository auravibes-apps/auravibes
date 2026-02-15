import 'dart:async';

import 'package:auravibes_app/domain/enums/message_types.dart';
import 'package:auravibes_app/features/chats/providers/messages_providers.dart';
import 'package:auravibes_app/features/chats/widgets/chat_input_widget.dart';
import 'package:auravibes_app/features/chats/widgets/chat_messages_widget.dart';
import 'package:auravibes_app/features/chats/widgets/mcp_connecting_indicator.dart';
import 'package:auravibes_app/features/models/widgets/select_chat_model.dart';
import 'package:auravibes_app/features/tools/widgets/tools_management_modal.dart';
import 'package:auravibes_app/widgets/app_bar_with_drawer.dart';
import 'package:auravibes_app/widgets/app_error.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

class ChatConversationScreen extends ConsumerWidget {
  const ChatConversationScreen({required this.chatId, super.key});

  final String chatId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ProviderScope(
      overrides: [conversationSelectedProvider.overrideWithValue(chatId)],
      child: const _ChatConversationScreen(),
    );
  }
}

@Dependencies([
  ConversationChatController,
  ChatMessagesController,
  pendingMcpConnections,
])
class _ChatConversationScreen extends HookConsumerWidget {
  const _ChatConversationScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modelId = ref.watch(
      conversationChatControllerProvider.select((c) => c.value?.modelId),
    );

    final modelTitle = ref.watch(
      conversationChatControllerProvider.select((c) => c.value?.title),
    );

    final onToolsPress = useCallback(() async {
      // Try to get conversation info

      final conversation = await ref.read(
        conversationChatControllerProvider.future,
      );
      if (conversation == null) return;
      final conversationId = conversation.id;
      final workspaceId = conversation.workspaceId;

      if (context.mounted) {
        unawaited(
          showDialog<void>(
            context: context,
            builder: (context) => ToolsManagementModal(
              conversationId: conversationId,
              workspaceId: workspaceId,
            ),
          ),
        );
      }
    }, [ref]);

    return AuraScreen(
      appBar: AuraAppBarWithDrawer(
        title: Text(modelTitle ?? ''),
        bottom: SelectCredentialsModelWidget(
          credentialsModelId: modelId,
          selectCredentialsModelId: ref
              .watch(conversationChatControllerProvider.notifier)
              .setModel,
        ),
      ),
      child: Column(
        children: [
          const Expanded(child: _ChatList()),
          const McpConnectingIndicator(),
          ChatInputWidget(
            onToolsPress: onToolsPress,
            onSendMessage: (message) {
              ref
                  .read(chatMessagesControllerProvider.notifier)
                  .addMessage(
                    content: message,
                    messageType: MessageType.text,
                  );
            },
          ),
        ],
      ),
    );
  }
}

class _ChatList extends ConsumerWidget {
  const _ChatList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(
      chatMessagesControllerProvider.select(
        (value) => value.isLoading && value.value == null,
      ),
    );

    if (isLoading) {
      return const Center(child: AuraSpinner());
    }

    final messages = ref.watch(
      messageListProvider.select(
        (value) => value.value ?? <String>[],
      ),
    );
    final asyncError = ref.watch(
      chatMessagesControllerProvider.select(
        (value) => value.asError,
      ),
    );
    if (asyncError != null) {
      return AppErrorWidget(
        error: asyncError.error,
        stackTrace: asyncError.stackTrace,
      );
    }

    return ChatMessagesWidget(messages: messages);
  }
}
