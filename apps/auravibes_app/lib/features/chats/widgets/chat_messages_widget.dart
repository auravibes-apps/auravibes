import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:auravibes_app/domain/enums/message_types.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/features/chats/providers/messages_providers.dart';
import 'package:auravibes_app/features/chats/providers/tool_display_name_provider.dart';
import 'package:auravibes_app/features/chats/widgets/tool_call_response_preview.dart';
import 'package:auravibes_app/utils/relative_time_formatter.dart';
import 'package:auravibes_app/utils/tool_name_formatter.dart';
import 'package:auravibes_app/utils/try_decode_tool_metadata.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ChatMessagesWidget extends HookConsumerWidget {
  const ChatMessagesWidget({required this.messages, super.key});

  final List<String> messages;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = useMemoized(() => messages.reversed.toList(), [messages]);
    final controller = useScrollController();
    // The last message in the original list is at index 0 in reversed list
    final lastMessageId = data.isNotEmpty ? data.first : null;

    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.all(16),
      reverse: true,
      addAutomaticKeepAlives: false,
      itemCount: data.length,
      cacheExtent: 500,
      itemBuilder: (context, index) {
        final messageId = data[index];
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

    final allToolCalls =
        message.metadata?.toolCalls ?? const <MessageToolCallEntity>[];
    final visibleToolCalls = allToolCalls
        .where((toolCall) => toolCall.isResolved)
        .toList();
    final hasToolCalls = allToolCalls.isNotEmpty;
    final hasVisibleToolCalls = visibleToolCalls.isNotEmpty;
    // Hide the text bubble when content is empty/whitespace and there are tool calls
    final hasContent = message.content.trim().isNotEmpty;
    final showTextBubble = hasContent || !hasToolCalls;

    return AnimatedSize(
      duration: const Duration(microseconds: 200),
      alignment: Alignment.topLeft,
      child: AuraColumn(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showTextBubble)
            if (message.isUser)
              AuraMessageBubble(
                key: ValueKey(message.id),
                content: message.content,
                isUser: true,
                timestamp: message.createdAt,
                status: _mapMessageStatus(message.status, isStreaming),
              )
            else
              _AiMessageContent(
                key: ValueKey(message.id),
                content: message.content,
                timestamp: message.createdAt,
                status: _mapMessageStatus(message.status, isStreaming),
              ),
          if (hasVisibleToolCalls) ...[
            for (final toolCall in visibleToolCalls)
              _ToolCallWidget(
                key: ValueKey('tool_${toolCall.id}'),
                toolCall: toolCall,
                messageId: message.id,
                isLastMessage: isLastMessage,
              ),
          ],
        ],
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

class _AiMessageContent extends StatelessWidget {
  const _AiMessageContent({
    required this.content,
    super.key,
    this.timestamp,
    this.status = AuraMessageDeliveryStatus.sent,
  });

  final String content;
  final DateTime? timestamp;
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
        if (timestamp != null) ...[
          SizedBox(height: context.auraTheme.spacing.xs),
          Text(
            const RelativeTimeFormatter().format(timestamp!),
            style: TextStyle(
              color: auraColors.onSurfaceVariant,
              fontSize: DesignTypography.fontSizeXs,
              fontFamily: DesignTypography.bodyFontFamily,
            ),
          ),
        ],
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
    required this.isLastMessage,
    super.key,
  });

  final MessageToolCallEntity toolCall;
  final String messageId;
  final bool isLastMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayNameAsync = ref.watch(toolDisplayNameProvider(toolCall.name));
    final displayName = displayNameAsync.maybeWhen(
      data: (name) => name,
      orElse: () => ToolNameFormatter.formatDisplayName(
        ToolNameFormatter.parse(toolCall.name),
      ),
    );

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
                if (tryDecodeToolMetadata(toolCall.argumentsRaw) != null)
                  const TextSpan(text: ' "'),
                TextSpan(text: tryDecodeToolMetadata(toolCall.argumentsRaw)),
                const TextSpan(text: '"'),
              ],
            ),
          ),
          if (toolCall.isResolved)
            _ToolCallStatusIndicator(
              statusText: TextLocale(toolCall.resultStatus!.localeKey),
              icon: _getStatusIcon(toolCall.resultStatus!),
              color: _getStatusColor(context, toolCall.resultStatus!),
            ),
          if (tryDecodeToolMetadata(toolCall.responseRaw) != null)
            Padding(
              padding: EdgeInsets.only(top: context.auraTheme.spacing.xs),
              child: ToolCallResponsePreview(
                toolName: toolCall.name,
                content: tryDecodeToolMetadata(toolCall.responseRaw)!,
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
