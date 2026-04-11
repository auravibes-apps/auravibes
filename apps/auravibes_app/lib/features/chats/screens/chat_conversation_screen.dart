import 'dart:async';

import 'package:auravibes_app/features/chats/notifiers/conversation_chat_notifier.dart';
import 'package:auravibes_app/features/chats/providers/messages_providers.dart';
import 'package:auravibes_app/features/chats/usecases/send_message_usecase.dart';
import 'package:auravibes_app/features/chats/widgets/chat_input_widget.dart';
import 'package:auravibes_app/features/chats/widgets/chat_messages_widget.dart';
import 'package:auravibes_app/features/chats/widgets/chat_queued_messages_indicator.dart';
import 'package:auravibes_app/features/chats/widgets/chat_thinking_indicator.dart';
import 'package:auravibes_app/features/chats/widgets/chat_tool_approval_card.dart';
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
  const ChatConversationScreen({
    required this.workspaceId,
    required this.chatId,
    super.key,
  });

  final String workspaceId;
  final String chatId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ProviderScope(
      overrides: [conversationSelectedProvider.overrideWithValue(chatId)],
      child: _ChatConversationScreen(workspaceId: workspaceId),
    );
  }
}

@Dependencies([
  ConversationChatNotifier,
  chatMessages,
  pendingMcpConnections,
])
class _ChatConversationScreen extends HookConsumerWidget {
  const _ChatConversationScreen({required this.workspaceId});

  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationAsync = ref.watch(conversationChatProvider(workspaceId));

    if (conversationAsync.isLoading) {
      return const AuraScreen(
        child: Center(child: AuraSpinner()),
      );
    }

    if (conversationAsync.hasError) {
      return AppErrorWidget(
        error: conversationAsync.error!,
        stackTrace: conversationAsync.stackTrace ?? StackTrace.empty,
      );
    }

    final conversation = conversationAsync.value;
    if (conversation == null) {
      return const AuraScreen(
        child: AppErrorWidget(
          error: 'Conversation not found in this workspace',
          stackTrace: StackTrace.empty,
        ),
      );
    }

    final onToolsPress = useCallback(() async {
      if (!context.mounted) return;

      unawaited(
        showDialog<void>(
          context: context,
          builder: (context) => ToolsManagementModal(
            conversationId: conversation.id,
            workspaceId: workspaceId,
          ),
        ),
      );
    }, [ref, workspaceId]);

    final busyState = ref.watch(conversationBusyStateProvider).asData?.value;
    final queuedDrafts = ref.watch(conversationQueuedDraftsProvider);

    return AuraScreen(
      appBar: AuraAppBarWithDrawer(
        title: Text(conversation.title),
        bottom: SelectCredentialsModelWidget(
          workspaceId: workspaceId,
          credentialsModelId: conversation.modelId,
          selectCredentialsModelId: ref
              .watch(conversationChatProvider(workspaceId).notifier)
              .setModel,
        ),
      ),
      child: Column(
        children: [
          const Expanded(child: _ChatList()),
          const McpConnectingIndicator(),
          if (busyState?.isStreaming == true) const ChatThinkingIndicator(),
          if (queuedDrafts.isNotEmpty)
            ChatQueuedMessagesIndicator(queuedDrafts: queuedDrafts),
          if (busyState?.hasPendingTools == true) const ChatToolApprovalCard(),
          Offstage(
            offstage: busyState?.hasPendingTools == true,
            child: ChatInputWidget(
              onToolsPress: onToolsPress,
              onSendMessage: (message) async {
                final conversationId = ref.read(conversationSelectedProvider);
                try {
                  await ref
                      .read(sendMessageUsecaseProvider)
                      .call(
                        conversationId: conversationId,
                        content: message,
                      );
                } on Exception catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to send message: $e')),
                    );
                  }
                }
              },
            ),
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
      chatMessagesProvider.select(
        (value) => value.isLoading && value.value == null,
      ),
    );

    if (isLoading) {
      return const Center(child: AuraSpinner());
    }

    final messages = ref.watch(
      chatMessagesProvider.select(
        (value) =>
            value.value?.map((message) => message.id).toList() ?? const [],
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

    return ChatMessagesWidget(messages: messages);
  }
}
