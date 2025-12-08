import 'dart:async';

import 'package:auravibes_app/domain/enums/message_types.dart';
import 'package:auravibes_app/features/chats/providers/messages_providers.dart';
import 'package:auravibes_app/features/chats/widgets/chat_input_widget.dart';
import 'package:auravibes_app/features/chats/widgets/chat_messages_widget.dart';
import 'package:auravibes_app/features/chats/widgets/mcp_connecting_indicator.dart';
import 'package:auravibes_app/features/models/widgets/select_chat_model.dart';
import 'package:auravibes_app/features/tools/widgets/tools_management_modal.dart';
import 'package:auravibes_app/widgets/app_error.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

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

class _ChatConversationScreen extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(messageListProvider);

    final modelId = ref.watch(
      conversationChatProvider.select((c) => c.value?.modelId),
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
      appBar: AuraAppBar(
        actions: [
          IconButton(
            icon: const AuraIcon(Icons.more_vert),
            onPressed: () {
              // TODO: Show chat options
            },
          ),
        ],
        footer: SelectCredentialsModelWidget(
          credentialsModelId: modelId,
          selectCredentialsModelId: ref
              .watch(conversationChatProvider.notifier)
              .setModel,
        ),
      ),
      child: switch (messagesAsync) {
        AsyncData(value: final messages) => Column(
          children: [
            Expanded(child: ChatMessagesWidget(messages: messages)),
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
        AsyncLoading() => const Center(child: AuraSpinner()),
        AsyncError(:final error, :final stackTrace) => AppErrorWidget(
          error: error,
          stackTrace: stackTrace,
        ),
      },
    );
  }
}
