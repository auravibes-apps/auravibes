import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/features/chats/providers/message_id_list.dart';
import 'package:auravibes_app/features/chats/providers/tool_display_name_provider.dart';
import 'package:auravibes_app/features/chats/usecases/conversation_busy_state.dart';
import 'package:auravibes_app/features/chats/widgets/compacted_message_details.dart';
import 'package:auravibes_app/features/chats/widgets/tool_call_response_preview.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
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

class ChatMessagesWidget extends HookConsumerWidget {
  const ChatMessagesWidget({
    required this.messages,
    super.key,
  });

  final List<String> messages;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = useMemoized(() => messages.reversed.toList(), [messages]);
    final controller = useScrollController();
    final lastMessageId = data.isNotEmpty ? data.first : null;

    final compactionState = ref.watch(
      conversationCompactionExecutionStateProvider,
    );
    final isCompacting =
        compactionState?.status == CompactionExecutionStatus.running;

    final itemCount = isCompacting ? data.length + 1 : data.length;

    return ListView.builder(
      scrollCacheExtent: const ScrollCacheExtent.pixels(500),
      controller: controller,
      padding: const EdgeInsets.all(16),
      reverse: true,
      addAutomaticKeepAlives: false,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (isCompacting && index == 0) {
          return const _CompactingIndicator();
        }

        final messageIndex = isCompacting ? index - 1 : index;
        final messageId = data[messageIndex];
        final isLastMessage = messageId == lastMessageId;

        return _ChatMessageRow(
          messageId: messageId,
          isLastMessage: isLastMessage,
        );
      },
    );
  }
}

class _ChatMessageRow extends HookConsumerWidget {
  const _ChatMessageRow({
    required this.messageId,
    required this.isLastMessage,
  });

  final String messageId;
  final bool isLastMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = ref.watch(messageConversationByIdProvider(messageId));
    if (message == null) {
      return const SizedBox.shrink();
    }

    final isStreaming = ref.watch(isMessageStreamingProvider(messageId));
    final busyState = ref.watch(
      conversationBusyStateProvider.select(
        (value) => value.maybeWhen(data: (state) => state, orElse: () => null),
      ),
    );

    final isCompactionSummary = message.metadata?.isCompactionSummary == true;
    final isErrorSystemMessage =
        !message.isUser &&
        message.messageType == MessageType.system &&
        message.status == MessageStatus.error;

    if (isCompactionSummary) {
      return _CompactedMessageWidget(
        key: ValueKey(message.id),
        message: message,
      );
    }

    if (isErrorSystemMessage) {
      return _ErrorMessageWidget(
        key: ValueKey(message.id),
        content: message.content,
      );
    }

    final visibleToolCalls = _visibleToolCalls(message, busyState);
    final hasVisibleToolCalls = visibleToolCalls.isNotEmpty;
    final hasContent = message.content.trim().isNotEmpty;
    final thinking = message.metadata?.thinking?.trim();
    final hasThinking = thinking != null && thinking.isNotEmpty;
    final showTextBubble = hasContent || hasThinking || !hasVisibleToolCalls;
    final status = _mapMessageStatus(message.status, isStreaming);

    return AnimatedSize(
      duration: const Duration(microseconds: 200),
      alignment: Alignment.topLeft,
      child: AuraColumn(
        crossAxisAlignment: CrossAxisAlignment.start,
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
              key: ValueKey('tool_${toolCall.id}'),
              toolCall: toolCall,
              messageId: message.id,
            ),
        ],
      ),
    );
  }

  List<MessageToolCallEntity> _visibleToolCalls(
    MessageEntity message,
    ConversationBusyState? busyState,
  ) {
    final allToolCalls =
        message.metadata?.toolCalls ?? const <MessageToolCallEntity>[];
    final hidePendingToolCalls =
        !message.isUser &&
        isLastMessage &&
        (busyState?.hasPendingTools ?? false) &&
        !(busyState?.isStreaming ?? false);

    if (!hidePendingToolCalls) return allToolCalls;

    return allToolCalls.where((toolCall) => toolCall.isResolved).toList();
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
        key: ValueKey(message.id),
        content: message.content,
        isUser: true,
        timestamp: message.createdAt,
        status: status,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasThinking) _ReasoningSummary(content: thinking!),
        if (hasContent)
          _AiMessageContent(
            key: ValueKey(message.id),
            content: message.content,
            timestamp: message.createdAt,
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
      backgroundColor: AuraColorVariant.surfaceVariant,
      borderRadius: 10,
      margin: .small,
      padding: .medium,
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
              SizedBox(width: context.auraTheme.spacing.xs),
              TextLocale(
                LocaleKeys.chats_screens_chat_conversation_reasoning_summary,
                style: TextStyle(
                  color: auraColors.onSurfaceVariant,
                  fontSize: DesignTypography.fontSizeSm,
                  fontFamily: DesignTypography.bodyFontFamily,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: context.auraTheme.spacing.xs),
          GptMarkdown(
            content,
            style: TextStyle(
              color: auraColors.onSurfaceVariant,
              fontSize: DesignTypography.fontSizeSm,
              fontFamily: DesignTypography.bodyFontFamily,
              height: DesignTypography.lineHeightBase,
            ),
          ),
        ],
      ),
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
            fontFamily: DesignTypography.bodyFontFamily,
            height: DesignTypography.lineHeightBase,
          ),
        ),
        SizedBox(height: context.auraTheme.spacing.xs),
        Text(
          const RelativeTimeFormatter().format(timestamp),
          style: TextStyle(
            color: auraColors.onSurfaceVariant,
            fontSize: DesignTypography.fontSizeXs,
            fontFamily: DesignTypography.bodyFontFamily,
          ),
        ),
        if (status != AuraMessageDeliveryStatus.sent) ...[
          SizedBox(height: context.auraTheme.spacing.xs / 2),
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
    super.key,
  });

  final MessageToolCallEntity toolCall;
  final String messageId;

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
      backgroundColor: AuraColorVariant.surfaceVariant,
      borderRadius: 10,
      margin: .small,
      padding: .medium,
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
          if (toolCall.isResolved)
            _ToolCallStatusIndicator(
              statusText: TextLocale(toolCall.resultStatus!.localeKey),
              icon: _getStatusIcon(toolCall.resultStatus!),
              color: _getStatusColor(context, toolCall.resultStatus!),
            ),
          if (decodedResponse != null)
            Padding(
              padding: EdgeInsets.only(top: context.auraTheme.spacing.xs),
              child: ToolCallResponsePreview(
                toolName: toolCall.name,
                content: decodedResponse,
              ),
            ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(ToolCallResultStatus status) {
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

  Color _getStatusColor(BuildContext context, ToolCallResultStatus status) {
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
        width: MediaQuery.of(dialogContext).size.width * 0.8,
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
      onTap: () => _showCompactionDetails(context, message),
      child: AuraContainer(
        backgroundColor: AuraColorVariant.surfaceVariant,
        borderRadius: 10,
        margin: .small,
        padding: .medium,
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
                SizedBox(width: context.auraTheme.spacing.xs),
                Text(
                  originLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: auraColors.onSurfaceVariant,
                    fontSize: DesignTypography.fontSizeSm,
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
            SizedBox(height: context.auraTheme.spacing.xs),
            Text(
              message.content,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: auraColors.onSurfaceVariant,
                fontSize: DesignTypography.fontSizeSm,
              ),
            ),
          ],
        ),
      ),
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
      backgroundColor: AuraColorVariant.error,
      borderRadius: 10,
      margin: .small,
      padding: .medium,
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            size: 16,
            color: auraColors.onError,
          ),
          SizedBox(width: context.auraTheme.spacing.xs),
          Flexible(
            child: TextLocale(content),
          ),
        ],
      ),
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
      padding: EdgeInsets.only(top: context.auraTheme.spacing.xs),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          SizedBox(width: context.auraTheme.spacing.xs),
          DefaultTextStyle(
            style: TextStyle(
              fontSize: 12,
              color: color,
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
      backgroundColor: AuraColorVariant.surfaceVariant,
      borderRadius: 10,
      margin: .small,
      padding: .medium,
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
          SizedBox(width: context.auraTheme.spacing.sm),
          Text(
            LocaleKeys.compaction_compacting_row_label.tr(),
            style: TextStyle(
              color: auraColors.onSurfaceVariant,
              fontSize: DesignTypography.fontSizeSm,
            ),
          ),
        ],
      ),
    );
  }
}
