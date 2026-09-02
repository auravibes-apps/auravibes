// Required: Existing thresholds and limits use numeric values.
// Required: Existing code repeats lookups where extraction adds noise.
// Required: Feature widgets keep closely related private widgets together.
// Required: Existing helpers remain top-level for local feature use.

import 'dart:convert';

import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/features/chats/notifiers/messages_streaming_state.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/features/chats/providers/message_id_list.dart';
import 'package:auravibes_app/features/chats/providers/tool_display_name_provider.dart';
import 'package:auravibes_app/features/chats/widgets/chat_attachment_image.dart';
import 'package:auravibes_app/features/chats/widgets/chat_thinking_indicator.dart';
import 'package:auravibes_app/features/chats/widgets/compacted_message_details.dart';
import 'package:auravibes_app/features/chats/widgets/tool_call_response_preview.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/services/chatbot_service/chat_result.dart';
import 'package:auravibes_app/utils/relative_time_formatter.dart';
import 'package:auravibes_app/utils/tool_name_formatter.dart';
import 'package:auravibes_app/utils/try_decode_tool_metadata.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class const ChatMessagesWidget({
  required final String workspaceId,
  required final String conversationId,
  required final List<String> messages,
  final Map<String, MessageEntity>? messageEntitiesById,
  final List<PendingToolCall> pendingToolCalls = const [],
  super.key,
}) extends HookConsumerWidget {
  // Null lets callers fall back to per-message provider reads.
  // ignore: unnecessary-nullable
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = useMemoized(() => messages.reversed.toList(), [messages]);
    final controller = useScrollController();
    final parentConversationId = conversationId;
    final childConversations =
        ref
            .watch(
              childConversationsStreamProvider(
                workspaceId,
                parentConversationId: parentConversationId,
              ),
            )
            .value ??
        const <ConversationEntity>[];
    final compactionState = ref.watch(
      conversationCompactionExecutionStateProvider(workspaceId, conversationId),
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
          parentConversationId: parentConversationId,
          childConversations: childConversations,
          workspaceId: workspaceId,
        );
      },
      itemCount: itemCount,
      addAutomaticKeepAlives: false,
      scrollCacheExtent: const ScrollCacheExtent.pixels(500),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    );
  }
}

class const _ChatMessageRow({
  required final String messageId,
  required final MessageEntity? baseMessage,
  required final List<PendingToolCall> pendingToolCalls,
  required final String parentConversationId,
  required final List<ConversationEntity> childConversations,
  required final String workspaceId,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streamingResult = ref.watch(
      messagesStreamingProvider.select((state) => state[messageId]?.lastResult),
    );
    final message = switch (baseMessage) {
      final baseMessage? => _mergeStreamingResult(baseMessage, streamingResult),
      null => ref.watch(
        messageConversationByIdProvider(
          workspaceId,
          parentConversationId,
          messageId,
        ),
      ),
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
    final hasAttachments = message.attachments.isNotEmpty;
    final thinking = message.metadata?.thinking?.trim();
    final hasThinking = thinking != null && thinking.isNotEmpty;
    final showTextBubble =
        hasContent || hasThinking || (!hasVisibleToolCalls && !hasAttachments);
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
          if (hasAttachments) _MessageAttachments(message: message),
          for (final toolCall in visibleToolCalls)
            _ToolCallWidget(
              toolCall: toolCall,
              messageId: message.id,
              parentConversationId: parentConversationId,
              childConversations: childConversations,
              workspaceId: workspaceId,
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
      metadata: StreamingMessageMetadata.merge(
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

class const _MessageAttachments({required final MessageEntity message})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Wrap(
        spacing: context.auraTheme.fromSpacing(.xs),
        runSpacing: context.auraTheme.fromSpacing(.xs),
        children: [
          for (final attachment in message.attachments)
            _AttachmentPreview(attachment: attachment),
        ],
      ),
    );
  }
}

class const _AttachmentPreview({
  required final MessageAttachmentEntity attachment,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (attachment.modality == MessageAttachmentModality.image) {
      return ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        child: ChatAttachmentImage(localPath: attachment.localPath),
      );
    }

    return Chip(
      avatar: Icon(
        attachment.modality == MessageAttachmentModality.audio
            ? Icons.mic_none_outlined
            : Icons.insert_drive_file_outlined,
      ),
      label: Text(attachment.displayName),
    );
  }
}

class const _MessageTextContent({
  required final MessageEntity message,
  required final String? thinking,
  required final bool hasContent,
  required final bool hasThinking,
  required final AuraMessageDeliveryStatus status,
}) extends StatelessWidget {
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
        if (!hasContent &&
            !hasThinking &&
            message.status == MessageStatus.unfinished)
          const ChatThinkingIndicator(),
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

class const _ReasoningSummary({required final String content})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;
    final typography = context.auraTheme.typography;
    const containerBorderRadius = 10.0;

    return AuraContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.psychology_outlined,
                size: context.auraTheme.fromSpacing(.lg),
                color: auraColors.onSurfaceVariant,
              ),
              const AuraSizedBox(width: .xs),
              TextLocale(
                LocaleKeys.chats_screens_chat_conversation_reasoning_summary,
                style: TextStyle(
                  color: auraColors.onSurfaceVariant,
                  fontSize: typography.fontSizeSm,
                  fontWeight: FontWeight.w600,
                  fontFamily: typography.bodyFontFamily,
                ),
              ),
            ],
          ),
          const AuraSizedBox(height: .xs),
          GptMarkdown(
            content,
            style: TextStyle(
              color: auraColors.onSurfaceVariant,
              fontSize: typography.fontSizeSm,
              height: typography.lineHeightBase,
              fontFamily: typography.bodyFontFamily,
            ),
          ),
        ],
      ),
      padding: .medium,
      margin: .small,
      variant: AuraContainerVariant.surfaceVariant,
      borderRadius: containerBorderRadius,
    );
  }
}

class const _AiMessageContent({
  required final String content,
  required final DateTime timestamp,
  super.key,
  final AuraMessageDeliveryStatus status = AuraMessageDeliveryStatus.sent,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;
    final typography = context.auraTheme.typography;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GptMarkdown(
          content,
          style: TextStyle(
            color: auraColors.onSurface,
            fontSize: typography.fontSizeBase,
            height: typography.lineHeightBase,
            fontFamily: typography.bodyFontFamily,
          ),
        ),
        const AuraSizedBox(height: .xs),
        Text(
          RelativeTimeFormatter.format(timestamp),
          style: TextStyle(
            color: auraColors.onSurfaceVariant,
            fontSize: typography.fontSizeXs,
            fontFamily: typography.bodyFontFamily,
          ),
        ),
        if (status != AuraMessageDeliveryStatus.sent) ...[
          SizedBox(height: context.auraTheme.fromSpacing(.xs) / 2),
          AuraMessageStatus(status: status),
        ],
      ],
    );
  }
}

/// Widget that displays a single tool call with optional confirmation UI.
class const _ToolCallWidget({
  required final MessageToolCallEntity toolCall,
  required final String messageId,
  required final String parentConversationId,
  required final List<ConversationEntity> childConversations,
  required final String? workspaceId,
  required final bool isAwaitingApproval,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const containerBorderRadius = 10.0;
    final currentWorkspaceId = workspaceId;
    final displayNameAsync = currentWorkspaceId == null
        ? null
        : ref.watch(toolDisplayNameProvider(currentWorkspaceId, toolCall.name));
    final displayName =
        displayNameAsync?.maybeWhen(
          data: (name) => name,
          orElse: () => ToolNameFormatter.formatDisplayName(
            ToolNameFormatter.parse(toolCall.name),
            rawName: toolCall.name,
          ),
        ) ??
        ToolNameFormatter.formatDisplayName(
          ToolNameFormatter.parse(toolCall.name),
          rawName: toolCall.name,
        );

    final decodedArgs = ToolMetadataDecoder.decode(toolCall.argumentsRaw);
    final decodedResponse = ToolMetadataDecoder.decode(toolCall.responseRaw);
    final subAgentConversationId =
        _subAgentConversationId(toolCall) ??
        _activeSubAgentConversationId(ref, parentConversationId, toolCall) ??
        _persistedSubAgentConversationId(toolCall, childConversations);

    final parentWorkspaceId = workspaceId;
    final openSubAgent =
        parentWorkspaceId == null || subAgentConversationId == null
        ? null
        : () => SubAgentConversationRoute(
            workspaceId: parentWorkspaceId,
            chatId: parentConversationId,
            subAgentConversationId: subAgentConversationId,
          ).go(context);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: displayName,
                style: const TextStyle(fontWeight: FontWeight.bold),
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
            padding: EdgeInsets.only(top: context.auraTheme.fromSpacing(.xs)),
            child: ToolCallResponsePreview(
              toolName: toolCall.name,
              content: decodedResponse,
              showExpandButton: openSubAgent == null,
            ),
          ),
      ],
    );

    if (openSubAgent != null) {
      return AuraContainer(
        child: AuraTile(
          child: content,
          onTap: openSubAgent,
          variant: AuraTileVariant.surface,
          size: AuraTileSize.small,
          trailing: const AuraIcon(Icons.chevron_right),
        ),
        padding: .none,
        margin: .small,
        variant: AuraContainerVariant.transparent,
      );
    }

    return AuraContainer(
      child: content,
      padding: .medium,
      margin: .small,
      variant: AuraContainerVariant.surfaceVariant,
      borderRadius: containerBorderRadius,
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
      ToolCallResultStatus.running => Icons.sync,
      ToolCallResultStatus.success => Icons.check_circle_outline,
      ToolCallResultStatus.skippedByUser => Icons.skip_next,
      ToolCallResultStatus.stoppedByUser => Icons.stop_circle_outlined,
      ToolCallResultStatus.toolNotFound => Icons.error_outline,
      ToolCallResultStatus.disabledInWorkspace => Icons.block,
      ToolCallResultStatus.disabledInConversation => Icons.block,
      ToolCallResultStatus.disabledByAgent => Icons.block,
      ToolCallResultStatus.notConfigured => Icons.settings,
      ToolCallResultStatus.executionError => Icons.warning_amber,
    };
  }

  Color _getStatusColor(BuildContext context) {
    final status = toolCall.resultStatus;
    final colors = context.auraColors;
    if (status == null) {
      return isAwaitingApproval ? colors.warning : colors.primary;
    }

    return switch (status) {
      ToolCallResultStatus.running => colors.primary,
      ToolCallResultStatus.success => colors.success,
      ToolCallResultStatus.skippedByUser => colors.onSurfaceVariant,
      ToolCallResultStatus.stoppedByUser => colors.onSurfaceVariant,
      ToolCallResultStatus.toolNotFound => colors.error,
      ToolCallResultStatus.disabledInWorkspace => colors.warning,
      ToolCallResultStatus.disabledInConversation => colors.warning,
      ToolCallResultStatus.disabledByAgent => colors.warning,
      ToolCallResultStatus.notConfigured => colors.warning,
      ToolCallResultStatus.executionError => colors.error,
    };
  }
}

String? _persistedSubAgentConversationId(
  MessageToolCallEntity toolCall,
  List<ConversationEntity> children,
) {
  if (!_isRunSubAgentTool(toolCall.name)) return null;
  final title = _subAgentTitle(toolCall);
  if (title == null) return null;

  final matches = children.where((child) => child.title == title).toList();

  return matches.length == 1 ? matches.single.id : null;
}

String? _activeSubAgentConversationId(
  WidgetRef ref,
  String parentConversationId,
  MessageToolCallEntity toolCall,
) {
  if (!_isRunSubAgentTool(toolCall.name) || toolCall.responseRaw != null) {
    return null;
  }

  return ref.watch(
    activeSubAgentRuntimeProvider.select((state) {
      final childIds = state[parentConversationId] ?? const <String>{};

      return childIds.length == 1 ? childIds.single : null;
    }),
  );
}

String? _subAgentConversationId(MessageToolCallEntity toolCall) {
  if (!_isRunSubAgentTool(toolCall.name)) return null;

  final responseRaw = toolCall.responseRaw;
  if (responseRaw == null) return null;

  try {
    final decoded = jsonDecode(responseRaw);
    if (decoded case {'conversationId': final String conversationId}) {
      return conversationId;
    }
  } on Object {
    return null;
  }

  return null;
}

bool _isRunSubAgentTool(String toolName) {
  return toolName == runSubAgentToolName ||
      toolName.endsWith('__$runSubAgentToolName');
}

String? _subAgentTitle(MessageToolCallEntity toolCall) {
  try {
    final decoded = jsonDecode(toolCall.argumentsRaw);
    if (decoded case {'title': final String title}) {
      final normalized = title.trim();
      if (normalized.isNotEmpty) return normalized;
    }
  } on Object {
    return null;
  }

  return null;
}

class const _CompactedMessageWidget({
  required final MessageEntity message,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;
    const iconSize = 16.0;
    const infoIconSize = 14.0;
    const containerBorderRadius = 10.0;
    final kind = message.metadata?.compactionKind;
    final originLabel = switch (kind) {
      CompactionKind.manual =>
        LocaleKeys.compaction_compacted_manual_origin.tr(),
      CompactionKind.auto => LocaleKeys.compaction_compacted_auto_origin.tr(),
      _ => LocaleKeys.compaction_compacted_widget_label.tr(),
    };

    return AuraModal(
      entryPointChild: AuraContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.compress_outlined,
                  size: iconSize,
                  color: auraColors.onSurfaceVariant,
                ),
                const AuraSizedBox(width: .xs),
                Text(
                  originLabel,
                  style: TextStyle(
                    color: auraColors.onSurfaceVariant,
                    fontSize: context.auraTheme.typography.fontSizeSm,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.info_outline,
                  size: infoIconSize,
                  color: auraColors.onSurfaceVariant,
                ),
              ],
            ),
            const AuraSizedBox(height: .xs),
            Text(
              message.content,
              style: TextStyle(
                color: auraColors.onSurfaceVariant,
                fontSize: context.auraTheme.typography.fontSizeSm,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 3,
            ),
          ],
        ),
        padding: .medium,
        margin: .small,
        variant: AuraContainerVariant.surfaceVariant,
        borderRadius: containerBorderRadius,
      ),
      contentChild: Builder(
        builder: (modalContext) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: CompactedMessageDetails(message: message)),
            AuraButton(
              onPressed: () =>
                  Navigator.of(modalContext, rootNavigator: true).pop(),
              child: const TextLocale(LocaleKeys.common_close),
              variant: AuraButtonVariant.text,
            ),
          ],
        ),
      ),
      barrierLabel: LocaleKeys.common_close.tr(),
      semanticLabel: LocaleKeys.compaction_compacted_details_title.tr(),
    );
  }
}

class const _ErrorMessageWidget({required final String content, super.key})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;
    const iconSize = 16.0;
    const containerBorderRadius = 10.0;

    return AuraContainer(
      child: Row(
        children: [
          Icon(Icons.error_outline, size: iconSize, color: auraColors.onError),
          const AuraSizedBox(width: .xs),
          Flexible(child: TextLocale(content)),
        ],
      ),
      padding: .medium,
      margin: .small,
      variant: AuraContainerVariant.surfaceVariant,
      borderRadius: containerBorderRadius,
      border: Border.fromBorderSide(BorderSide(color: auraColors.error)),
    );
  }
}

/// A small status indicator widget with icon and text.
class const _ToolCallStatusIndicator({
  required final Widget statusText,
  required final IconData icon,
  required final Color color,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const iconSize = 14.0;
    const textSize = 12.0;

    return Padding(
      padding: EdgeInsets.only(top: context.auraTheme.fromSpacing(.xs)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: color),
          const AuraSizedBox(width: .xs),
          DefaultTextStyle(
            style: TextStyle(color: color, fontSize: textSize),
            child: statusText,
          ),
        ],
      ),
    );
  }
}

class const _CompactingIndicator() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;
    const containerBorderRadius = 10.0;

    return AuraContainer(
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.all(4),
            child: SizedBox(width: 16, height: 16, child: AuraSpinner()),
          ),
          const AuraSizedBox(width: .sm),
          Text(
            LocaleKeys.compaction_compacting_row_label.tr(),
            style: TextStyle(
              color: auraColors.onSurfaceVariant,
              fontSize: context.auraTheme.typography.fontSizeSm,
            ),
          ),
        ],
      ),
      padding: .medium,
      margin: .small,
      variant: AuraContainerVariant.surfaceVariant,
      borderRadius: containerBorderRadius,
    );
  }
}
