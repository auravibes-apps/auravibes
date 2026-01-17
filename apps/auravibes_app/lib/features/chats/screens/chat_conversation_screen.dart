import 'dart:async';

import 'package:auravibes_app/domain/entities/messages.dart';
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
      child: _ChatConversationScreen(),
    );
  }
}

@Dependencies([
  ConversationChatNotifier,
  ChatMessages,
  pendingMcpConnections,
])
class _ChatConversationScreen extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modelId = ref.watch(
      conversationChatProvider.select((c) => c.value?.modelId),
    );

    final modelTitle = ref.watch(
      conversationChatProvider.select((c) => c.value?.title),
    );

    final onToolsPress = useCallback(() async {
      // Try to get conversation info

      final conversation = await ref.read(conversationChatProvider.future);
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
              .watch(conversationChatProvider.notifier)
              .setModel,
        ),
      ),
      child: Column(
        children: [
          Expanded(child: _ChatList()),
          const McpConnectingIndicator(),
          ChatInputWidget(
            onToolsPress: onToolsPress,
            onSendMessage: (message) {
              ref
                  .read(chatMessagesProvider.notifier)
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

@Dependencies([ChatMessages])
class _ChatList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(
      chatMessagesProvider.select(
        (value) => value.isLoading && value.value == null,
      ),
    );

    if (isLoading) {
      return const Center(child: AuraSpinner());
    }

    final messages = ref.watch(
      chatMessagesProvider.select(
        (value) => [
          for (final message in value.value ?? <MessageEntity>[]) message.id,
        ],
      ),
    );
    final asyncError = ref.watch(
      chatMessagesProvider.select(
        (value) => value.asError,
      ),
    );
    if (asyncError != null) {
      return AppErrorWidget(
        error: asyncError.error,
        stackTrace: asyncError.stackTrace,
      );
    }

    return ChatMessagesWidget(
      messages: messages,
    );
  }
}
