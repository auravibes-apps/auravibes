import 'dart:convert';

import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:auravibes_app/domain/enums/message_types.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/features/chats/providers/messages_providers.dart';
import 'package:auravibes_app/features/chats/providers/tool_display_name_provider.dart';
import 'package:auravibes_app/features/chats/widgets/tool_call_confirmation_widget.dart';
import 'package:auravibes_app/features/chats/widgets/tool_call_response_preview.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/utils/relative_time_formatter.dart';
import 'package:auravibes_app/utils/tool_name_formatter.dart';
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

JsonEncoder encoder = const JsonEncoder.withIndent('  ');

String? _tryDecode(Object? metadata) {
  if (metadata == null) return null;
  dynamic decoded;
  try {
    if (metadata is String) {
      decoded = jsonDecode(metadata);
    }
  } on Exception catch (_) {
    return metadata.toString();
  }

  if (decoded is Map<String, dynamic>) {
    if (decoded.length == 1) {
      return _tryDecode(decoded.values.first);
    }
  }

  return encoder.convert(decoded);
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

    final hasToolCalls = message.metadata?.toolCalls.isNotEmpty ?? false;
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
          if (hasToolCalls) ...[
            for (final toolCall in message.metadata!.toolCalls)
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
    // Only show confirmation for pending tool calls in the last message.
    // If a tool call is pending in a previous message, the user skipped it.
    // A tool is pending if resultStatus is null (not yet resolved).
    final isPendingConfirmation = toolCall.isPending && isLastMessage;

    // Get human-readable display name for the tool
    final displayNameAsync = ref.watch(toolDisplayNameProvider(toolCall.name));
    final displayName = displayNameAsync.maybeWhen(
      data: (name) => name,
      // Fallback to formatted name while loading or on error
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
                  style: const .new(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_tryDecode(toolCall.argumentsRaw) != null)
                  const TextSpan(text: ' "'),
                TextSpan(text: _tryDecode(toolCall.argumentsRaw)),
                const TextSpan(text: '"'),
              ],
            ),
          ),
          // Show pending confirmation indicator
          if (isPendingConfirmation) ...[
            _ToolCallStatusIndicator(
              statusText: const TextLocale(LocaleKeys.tool_call_status_pending),
              icon: Icons.help_outline,
              color: context.auraColors.warning,
            ),
            Padding(
              padding: EdgeInsets.only(top: context.auraTheme.spacing.sm),
              child: ToolCallConfirmationWidget(
                toolCall: toolCall,
                messageId: messageId,
              ),
            ),
          ],
          // Show resolved status once persisted on the tool call metadata.
          if (toolCall.isResolved)
            _ToolCallStatusIndicator(
              statusText: TextLocale(toolCall.resultStatus!.localeKey),
              icon: _getStatusIcon(toolCall.resultStatus!),
              color: _getStatusColor(context, toolCall.resultStatus!),
            ),
          // Show response content if available
          if (_tryDecode(toolCall.responseRaw) != null)
            Padding(
              padding: EdgeInsets.only(top: context.auraTheme.spacing.xs),
              child: ToolCallResponsePreview(
                toolName: toolCall.name,
                content: _tryDecode(toolCall.responseRaw)!,
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
