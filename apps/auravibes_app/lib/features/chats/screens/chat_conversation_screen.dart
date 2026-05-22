import 'dart:async';

import 'package:auravibes_app/domain/entities/compaction.dart';
import 'package:auravibes_app/features/chats/notifiers/conversation_chat_notifier.dart';
import 'package:auravibes_app/features/chats/providers/compaction_providers.dart';
import 'package:auravibes_app/features/chats/providers/messages_providers.dart';
import 'package:auravibes_app/features/chats/usecases/manual_compact_conversation_usecase.dart';
import 'package:auravibes_app/features/chats/usecases/send_message_usecase.dart';
import 'package:auravibes_app/features/chats/usecases/stop_conversation_usecase.dart';
import 'package:auravibes_app/features/chats/widgets/chat_input_widget.dart';
import 'package:auravibes_app/features/chats/widgets/chat_messages_widget.dart';
import 'package:auravibes_app/features/chats/widgets/chat_queued_messages_indicator.dart';
import 'package:auravibes_app/features/chats/widgets/chat_thinking_indicator.dart';
import 'package:auravibes_app/features/chats/widgets/chat_tool_approval_card.dart';
import 'package:auravibes_app/features/chats/widgets/conversation_context_usage_pill.dart';
import 'package:auravibes_app/features/chats/widgets/mcp_connecting_indicator.dart';
import 'package:auravibes_app/features/models/widgets/select_chat_model.dart';
import 'package:auravibes_app/features/tools/widgets/tools_management_modal.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/app_bar_with_drawer.dart';
import 'package:auravibes_app/widgets/app_error.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
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

    if (conversationAsync.isLoading && !conversationAsync.hasValue) {
      return const AuraScreen(
        child: Center(child: AuraSpinner()),
      );
    }

    if (conversationAsync.hasError && !conversationAsync.hasValue) {
      return AuraScreen(
        child: AppErrorWidget(
          error: conversationAsync.error!,
          stackTrace: conversationAsync.stackTrace ?? StackTrace.empty,
        ),
      );
    }

    final conversationResult = conversationAsync.value;
    if (conversationResult == null ||
        conversationResult is! ConversationFound) {
      final errorMessage = switch (conversationResult) {
        ConversationWorkspaceMismatch() =>
          LocaleKeys.chats_screens_chat_conversation_error_workspace_mismatch
              .tr(),
        ConversationNotFound() =>
          LocaleKeys.chats_screens_chat_conversation_error_not_found.tr(),
        _ => LocaleKeys.chats_screens_chat_conversation_error_not_found.tr(),
      };
      return AuraScreen(
        child: AppErrorWidget(
          error: errorMessage,
          stackTrace: StackTrace.empty,
        ),
      );
    }

    final conversation = conversationResult.conversation;

    final onToolsPress = useCallback(() async {
      _showToolsModal(
        context: context,
        workspaceId: workspaceId,
        conversationId: conversation.id,
      );
    }, [ref, workspaceId, conversation.id]);

    final onStop = useCallback(() async {
      await _stopConversation(context, ref);
    }, [ref]);

    final onSendMessage = useCallback<Future<void> Function(String)>(
      (message) async {
        await _sendMessage(context, ref, message);
      },
      [ref],
    );

    final onCompact = useCallback(() async {
      await _manualCompact(context, ref, conversation.id);
    }, [ref, conversation.id]);

    final busyState = ref.watch(conversationBusyStateProvider).asData?.value;
    final queuedDrafts = ref.watch(conversationQueuedDraftsProvider);
    final pendingCalls = ref.watch(pendingToolCallsProvider).value ?? const [];
    final hasPendingApprovals = pendingCalls.isNotEmpty;
    final compactionState = ref.watch(
      compactionExecutionStateProvider(conversation.id),
    );
    final isCompacting =
        compactionState?.status == CompactionExecutionStatus.running;

    return AuraScreen(
      appBar: AuraAppBarWithDrawer(
        title: Text(conversation.title),
      ),
      child: AuraColumn(
        children: [
          const ConversationContextUsagePill(),
          SelectWorkspaceModelSelectionWidget(
            workspaceId: workspaceId,
            workspaceModelSelectionId: conversation.modelId,
            selectWorkspaceModelSelectionId: ref
                .watch(conversationChatProvider(workspaceId).notifier)
                .setModel,
            onProviderChanged: (_) {},
          ),
          const Expanded(child: _ChatList()),
          const McpConnectingIndicator(),
          if (busyState?.isStreaming == true) const ChatThinkingIndicator(),
          if (queuedDrafts.isNotEmpty)
            ChatQueuedMessagesIndicator(queuedDrafts: queuedDrafts),
          if (hasPendingApprovals) const ChatToolApprovalCard(),
          Offstage(
            offstage: hasPendingApprovals,
            child: ChatInputWidget(
              onToolsPress: onToolsPress,
              isBusy: busyState?.isBusy ?? false,
              onStop: onStop,
              onSendMessage: onSendMessage,
              onCompact: onCompact,
              isCompacting: isCompacting,
            ),
          ),
        ],
      ),
    );
  }
}

void _showToolsModal({
  required BuildContext context,
  required String workspaceId,
  required String conversationId,
}) {
  if (!context.mounted) return;

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

Future<void> _stopConversation(BuildContext context, WidgetRef ref) async {
  final conversationId = ref.read(conversationSelectedProvider);
  try {
    await ref
        .read(stopConversationUsecaseProvider)
        .call(conversationId: conversationId);
  } catch (error, stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'chat_conversation_screen',
        context: ErrorDescription('while stopping a conversation'),
      ),
    );
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          LocaleKeys.chats_screens_chat_conversation_stop_error.tr(),
        ),
      ),
    );
  }
}

Future<void> _sendMessage(
  BuildContext context,
  WidgetRef ref,
  String message,
) async {
  final conversationId = ref.read(conversationSelectedProvider);
  try {
    await ref
        .read(sendMessageUsecaseProvider)
        .call(conversationId: conversationId, content: message);
  } on Exception catch (error, stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'chat_conversation_screen',
        context: ErrorDescription('while sending a message'),
      ),
    );
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          LocaleKeys.chats_screens_chat_conversation_send_error.tr(),
        ),
      ),
    );
  }
}

Future<void> _manualCompact(
  BuildContext context,
  WidgetRef ref,
  String conversationId,
) async {
  final result = await ref.read(manualCompactConversationUsecaseProvider)(
    conversationId,
  );
  if (!context.mounted) return;

  if (result.success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(LocaleKeys.compaction_manual_success.tr()),
      ),
    );
  } else if (result.error != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(LocaleKeys.compaction_manual_failure.tr()),
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

    final messages = ref.watch(chatMessageIdsProvider);
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
