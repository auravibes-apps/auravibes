// Required: Existing thresholds and limits use numeric values.
// Required: Existing code repeats lookups where extraction adds noise.
// Required: Feature widgets keep closely related private widgets together.
// Required: Existing helpers remain top-level for local feature use.

import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/features/chats/notifiers/messages_streaming_state.dart';
import 'package:auravibes_app/features/chats/providers/message_id_list.dart';
import 'package:auravibes_app/features/chats/providers/tool_display_name_provider.dart';
import 'package:auravibes_app/features/chats/widgets/compacted_message_details.dart';
import 'package:auravibes_app/features/chats/widgets/tool_call_response_preview.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/services/chatbot_service/chat_result.dart';
import 'package:auravibes_app/utils/relative_time_formatter.dart';
import 'package:auravibes_app/utils/tool_name_formatter.dart';
import 'package:auravibes_app/utils/try_decode_tool_metadata.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

@Dependencies([
  conversationCompactionExecutionState,
  messageConversationById,
])
class ChatMessagesWidget extends HookConsumerWidget {
  // Null lets callers fall back to per-message provider reads.
  // ignore: unnecessary-nullable
  const ChatMessagesWidget({
    required this.messages,
    this.messageEntitiesById,
    this.pendingToolCalls = const [],
    super.key,
  });

  final List<String> messages;
  final Map<String, MessageEntity>? messageEntitiesById;
  final List<PendingToolCall> pendingToolCalls;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = useMemoized(() => messages.reversed.toList(), [messages]);
    final controller = useScrollController();
    final compactionState = ref.watch(
      conversationCompactionExecutionStateProvider,
    );
    final isCompacting =
        compactionState?.status == CompactionExecutionStatus.running;

    final itemCount = isCompacting ? data.length + 1 : data.length;

    return ListView.builder(
      reverse: true,
      controller: controller,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        if (isCompacting && index == 0) {
          return const _CompactingIndicator();
        }

        final messageIndex = isCompacting ? index - 1 : index;
        final messageId = data[messageIndex];

        return _ChatMessageRow(
          messageId: messageId,
          baseMessage: messageEntitiesById?[messageId],
          pendingToolCalls: pendingToolCalls,
        );
      },
      itemCount: itemCount,
      addAutomaticKeepAlives: false,
      scrollCacheExtent: const ScrollCacheExtent.pixels(500),
    );
  }
}

@Dependencies([
  messageConversationById,
])
class _ChatMessageRow extends HookConsumerWidget {
  const _ChatMessageRow({
    required this.messageId,
    required this.baseMessage,
    required this.pendingToolCalls,
  });

  final String messageId;
  final MessageEntity? baseMessage;
  final List<PendingToolCall> pendingToolCalls;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streamingResult = ref.watch(
      messagesStreamingProvider.select((state) => state[messageId]?.lastResult),
    );
    final message = switch (baseMessage) {
      final baseMessage? => _mergeStreamingResult(
        baseMessage,
        streamingResult,
      ),
      null => ref.watch(messageConversationByIdProvider(messageId)),
    };
    if (message == null) {
      return const SizedBox.shrink();
    }

    final isStreaming = ref.watch(isMessageStreamingProvider(messageId));

    final isCompactionSummary = message.metadata?.isCompactionSummary == true;
    final isErrorSystemMessage =
        !message.isUser &&
        message.messageType == MessageType.system &&
        message.status == MessageStatus.error;

    if (isCompactionSummary) {
      return _CompactedMessageWidget(
        message: message,
        key: ValueKey(message.id),
      );
    }

    if (isErrorSystemMessage) {
      return _ErrorMessageWidget(
        content: message.content,
        key: ValueKey(message.id),
      );
    }

    final visibleToolCalls =
        message.metadata?.toolCalls ?? const <MessageToolCallEntity>[];
    final hasVisibleToolCalls = visibleToolCalls.isNotEmpty;
    final hasContent = message.content.trim().isNotEmpty;
    final thinking = message.metadata?.thinking?.trim();
    final hasThinking = thinking != null && thinking.isNotEmpty;
    final showTextBubble = hasContent || hasThinking || !hasVisibleToolCalls;
    final status = _mapMessageStatus(message.status, isStreaming);

    return AnimatedSize(
      child: AuraColumn(
        children: [
          if (showTextBubble)
            _MessageTextContent(
              message: message,
              thinking: thinking,
              hasContent: hasContent,
              hasThinking: hasThinking,
              status: status,
            ),
          for (final toolCall in visibleToolCalls)
            _ToolCallWidget(
              toolCall: toolCall,
              messageId: message.id,
              isAwaitingApproval: pendingToolCalls.any(
                (pending) =>
                    pending.messageId == message.id &&
                    pending.toolCall.id == toolCall.id,
              ),
              key: ValueKey('tool_${toolCall.id}'),
            ),
        ],
        crossAxisAlignment: CrossAxisAlignment.start,
      ),
      alignment: Alignment.topLeft,
      duration: const Duration(microseconds: 200),
    );
  }

  MessageEntity _mergeStreamingResult(
    MessageEntity message,
    ChatResult<ChatMessage>? streamingResult,
  ) {
    if (streamingResult == null) return message;

    return message.copyWith(
      content: streamingResult.output.text,
      metadata: mergeStreamingMessageMetadata(
        message.metadata,
        streamingResult.entityMetadata,
      ),
    );
  }

  AuraMessageDeliveryStatus _mapMessageStatus(
    MessageStatus status,
    bool isStreaming,
  ) {
    return switch (status) {
      MessageStatus.sending => AuraMessageDeliveryStatus.sending,
      MessageStatus.unfinished =>
        isStreaming
            ? AuraMessageDeliveryStatus.sending
            : AuraMessageDeliveryStatus.unfinished,
      MessageStatus.sent => AuraMessageDeliveryStatus.sent,
      MessageStatus.error => AuraMessageDeliveryStatus.error,
    };
  }
}

class _MessageTextContent extends StatelessWidget {
  const _MessageTextContent({
    required this.message,
    required this.thinking,
    required this.hasContent,
    required this.hasThinking,
    required this.status,
  });

  final MessageEntity message;
  final String? thinking;
  final bool hasContent;
  final bool hasThinking;
  final AuraMessageDeliveryStatus status;

  @override
  Widget build(BuildContext context) {
    if (message.isUser) {
      return AuraMessageBubble(
        content: message.content,
        isUser: true,
        key: ValueKey(message.id),
        status: status,
        timestamp: message.createdAt,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (thinking case final thinking? when hasThinking)
          _ReasoningSummary(content: thinking),
        if (hasContent)
          _AiMessageContent(
            content: message.content,
            timestamp: message.createdAt,
            key: ValueKey(message.id),
            status: status,
          ),
      ],
    );
  }
}

class _ReasoningSummary extends StatelessWidget {
  const _ReasoningSummary({required this.content});

  final String content;

  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;

    return AuraContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.psychology_outlined,
                size: DesignSpacing.lg,
                color: auraColors.onSurfaceVariant,
              ),
              const SizedBox(width: DesignSpacing.xs),
              TextLocale(
                LocaleKeys.chats_screens_chat_conversation_reasoning_summary,
                style: TextStyle(
                  color: auraColors.onSurfaceVariant,
                  fontSize: DesignTypography.fontSizeSm,
                  fontWeight: FontWeight.w600,
                  fontFamily: DesignTypography.bodyFontFamily,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignSpacing.xs),
          GptMarkdown(
            content,
            style: TextStyle(
              color: auraColors.onSurfaceVariant,
              fontSize: DesignTypography.fontSizeSm,
              height: DesignTypography.lineHeightBase,
              fontFamily: DesignTypography.bodyFontFamily,
            ),
          ),
        ],
      ),
      padding: .medium,
      margin: .small,
      backgroundColor: AuraColorVariant.surfaceVariant,
      borderRadius: 10,
    );
  }
}

class _AiMessageContent extends StatelessWidget {
  const _AiMessageContent({
    required this.content,
    required this.timestamp,
    super.key,
    this.status = AuraMessageDeliveryStatus.sent,
  });

  final String content;
  final DateTime timestamp;
  final AuraMessageDeliveryStatus status;

  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GptMarkdown(
          content,
          style: TextStyle(
            color: auraColors.onSurface,
            fontSize: DesignTypography.fontSizeBase,
            height: DesignTypography.lineHeightBase,
            fontFamily: DesignTypography.bodyFontFamily,
          ),
        ),
        const SizedBox(height: DesignSpacing.xs),
        Text(
          const RelativeTimeFormatter().format(timestamp),
          style: TextStyle(
            color: auraColors.onSurfaceVariant,
            fontSize: DesignTypography.fontSizeXs,
            fontFamily: DesignTypography.bodyFontFamily,
          ),
        ),
        if (status != AuraMessageDeliveryStatus.sent) ...[
          const SizedBox(height: DesignSpacing.xs / 2),
          AuraMessageStatus(status: status),
        ],
      ],
    );
  }
}

/// Widget that displays a single tool call with optional confirmation UI.
class _ToolCallWidget extends ConsumerWidget {
  const _ToolCallWidget({
    required this.toolCall,
    required this.messageId,
    required this.isAwaitingApproval,
    super.key,
  });

  final MessageToolCallEntity toolCall;
  final String messageId;
  final bool isAwaitingApproval;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayNameAsync = ref.watch(toolDisplayNameProvider(toolCall.name));
    final displayName = displayNameAsync.maybeWhen(
      data: (name) => name,
      orElse: () => ToolNameFormatter.formatDisplayName(
        ToolNameFormatter.parse(toolCall.name),
      ),
    );

    final decodedArgs = tryDecodeToolMetadata(toolCall.argumentsRaw);
    final decodedResponse = tryDecodeToolMetadata(toolCall.responseRaw);

    return AuraContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (decodedArgs != null) ...[
                  const TextSpan(text: ' "'),
                  TextSpan(text: decodedArgs),
                  const TextSpan(text: '"'),
                ],
              ],
            ),
          ),
          _ToolCallStatusIndicator(
            statusText: TextLocale(_getStatusLocaleKey()),
            icon: _getStatusIcon(),
            color: _getStatusColor(context),
          ),
          if (decodedResponse != null)
            Padding(
              padding: const EdgeInsets.only(top: DesignSpacing.xs),
              child: ToolCallResponsePreview(
                toolName: toolCall.name,
                content: decodedResponse,
              ),
            ),
        ],
      ),
      padding: .medium,
      margin: .small,
      backgroundColor: AuraColorVariant.surfaceVariant,
      borderRadius: 10,
    );
  }

  String _getStatusLocaleKey() {
    final status = toolCall.resultStatus;
    if (status != null) return status.localeKey;

    return isAwaitingApproval
        ? LocaleKeys.tool_call_status_pending
        : LocaleKeys.tool_call_status_running;
  }

  IconData _getStatusIcon() {
    final status = toolCall.resultStatus;
    if (status == null) {
      return isAwaitingApproval ? Icons.hourglass_empty : Icons.sync;
    }

    return switch (status) {
      ToolCallResultStatus.success => Icons.check_circle_outline,
      ToolCallResultStatus.skippedByUser => Icons.skip_next,
      ToolCallResultStatus.stoppedByUser => Icons.stop_circle_outlined,
      ToolCallResultStatus.toolNotFound => Icons.error_outline,
      ToolCallResultStatus.disabledInWorkspace => Icons.block,
      ToolCallResultStatus.disabledInConversation => Icons.block,
      ToolCallResultStatus.notConfigured => Icons.settings,
      ToolCallResultStatus.executionError => Icons.warning_amber,
    };
  }

  Color _getStatusColor(BuildContext context) {
    final status = toolCall.resultStatus;
    if (status == null) {
      return isAwaitingApproval
          ? context.auraColors.warning
          : context.auraColors.primary;
    }

    return switch (status) {
      ToolCallResultStatus.success => context.auraColors.success,
      ToolCallResultStatus.skippedByUser => context.auraColors.onSurfaceVariant,
      ToolCallResultStatus.stoppedByUser => context.auraColors.onSurfaceVariant,
      ToolCallResultStatus.toolNotFound => context.auraColors.error,
      ToolCallResultStatus.disabledInWorkspace => context.auraColors.warning,
      ToolCallResultStatus.disabledInConversation => context.auraColors.warning,
      ToolCallResultStatus.notConfigured => context.auraColors.warning,
      ToolCallResultStatus.executionError => context.auraColors.error,
    };
  }
}

void _showCompactionDetails(BuildContext context, MessageEntity message) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      content: SizedBox(
        width: MediaQuery.sizeOf(dialogContext).width * 0.8,
        child: CompactedMessageDetails(message: message),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const TextLocale(LocaleKeys.common_close),
        ),
      ],
    ),
  );
}

class _CompactedMessageWidget extends StatelessWidget {
  const _CompactedMessageWidget({required this.message, super.key});

  final MessageEntity message;

  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;
    final kind = message.metadata?.compactionKind;
    final originLabel = switch (kind) {
      CompactionKind.manual =>
        LocaleKeys.compaction_compacted_manual_origin.tr(),
      CompactionKind.auto => LocaleKeys.compaction_compacted_auto_origin.tr(),
      _ => LocaleKeys.compaction_compacted_widget_label.tr(),
    };

    return GestureDetector(
      child: AuraContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.compress_outlined,
                  size: 16,
                  color: auraColors.onSurfaceVariant,
                ),
                const SizedBox(width: DesignSpacing.xs),
                Text(
                  originLabel,
                  style: TextStyle(
                    color: auraColors.onSurfaceVariant,
                    fontSize: DesignTypography.fontSizeSm,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: auraColors.onSurfaceVariant,
                ),
              ],
            ),
            const SizedBox(height: DesignSpacing.xs),
            Text(
              message.content,
              style: TextStyle(
                color: auraColors.onSurfaceVariant,
                fontSize: DesignTypography.fontSizeSm,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 3,
            ),
          ],
        ),
        padding: .medium,
        margin: .small,
        backgroundColor: AuraColorVariant.surfaceVariant,
        borderRadius: 10,
      ),
      onTap: () => _showCompactionDetails(context, message),
    );
  }
}

class _ErrorMessageWidget extends StatelessWidget {
  const _ErrorMessageWidget({required this.content, super.key});

  final String content;

  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;

    return AuraContainer(
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            size: 16,
            color: auraColors.onError,
          ),
          const SizedBox(width: DesignSpacing.xs),
          Flexible(
            child: TextLocale(content),
          ),
        ],
      ),
      padding: .medium,
      margin: .small,
      backgroundColor: AuraColorVariant.error,
      borderRadius: 10,
    );
  }
}

/// A small status indicator widget with icon and text.
class _ToolCallStatusIndicator extends StatelessWidget {
  const _ToolCallStatusIndicator({
    required this.statusText,
    required this.icon,
    required this.color,
  });

  final Widget statusText;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: DesignSpacing.xs),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: DesignSpacing.xs),
          DefaultTextStyle(
            style: TextStyle(
              color: color,
              fontSize: 12,
            ),
            child: statusText,
          ),
        ],
      ),
    );
  }
}

class _CompactingIndicator extends StatelessWidget {
  const _CompactingIndicator();

  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;

    return AuraContainer(
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.all(4),
            child: SizedBox(
              width: 16,
              height: 16,
              child: AuraSpinner(),
            ),
          ),
          const SizedBox(width: DesignSpacing.sm),
          Text(
            LocaleKeys.compaction_compacting_row_label.tr(),
            style: TextStyle(
              color: auraColors.onSurfaceVariant,
              fontSize: DesignTypography.fontSizeSm,
            ),
          ),
        ],
      ),
      padding: .medium,
      margin: .small,
      backgroundColor: AuraColorVariant.surfaceVariant,
      borderRadius: 10,
    );
  }
}
