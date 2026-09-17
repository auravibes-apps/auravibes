// ignore_for_file: type=lint, type=warning
// Required: Existing thresholds and limits use numeric values.
// Required: Existing code repeats lookups where extraction adds noise.
// Required: Feature widgets keep closely related private widgets together.
// Required: Existing helpers remain top-level for local feature use.

import 'dart:async';
import 'dart:convert';

import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/features/chats/models/chat_draft.dart';
import 'package:auravibes_app/features/chats/notifiers/chat_a2ui_runtime.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:auravibes_app/features/chats/providers/chat_a2ui_runtime_provider.dart';
import 'package:auravibes_app/features/chats/providers/cloud_conversation_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/features/chats/providers/message_id_list.dart';
import 'package:auravibes_app/features/chats/providers/tool_display_name_provider.dart';
import 'package:auravibes_app/features/chats/services/chatbot/chat_result.dart';
import 'package:auravibes_app/features/chats/usecases/fork_conversation_usecase.dart';
import 'package:auravibes_app/features/chats/usecases/send_message_usecase.dart';
import 'package:auravibes_app/features/chats/widgets/chat_a2ui_surface_host.dart';
import 'package:auravibes_app/features/chats/widgets/chat_attachment_image.dart';
import 'package:auravibes_app/features/chats/widgets/chat_thinking_indicator.dart';
import 'package:auravibes_app/features/chats/widgets/compacted_message_details.dart';
import 'package:auravibes_app/features/chats/widgets/tool_call_response_preview.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/utils/relative_time_formatter.dart';
import 'package:auravibes_app/utils/tool_name_formatter.dart';
import 'package:auravibes_app/utils/tool_metadata_decoder.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

final _a2uiLogger = Logger('chat_a2ui_actions');

class const ChatMessagesWidget({
  required final String workspaceId,
  required final String conversationId,
  required final List<String> messages,
  final Map<String, MessageEntity>? messageEntitiesById,
  final List<PendingToolCall> pendingToolCalls = const [],
  final bool showThinking = false,
  super.key,
}) extends HookConsumerWidget {
  // Null lets callers fall back to per-message provider reads.
  // ignore: unnecessary-nullable
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useMemoized(_DisclosureScrollController.new);
    useEffect(() => controller.dispose, [controller]);
    final parentConversationId = conversationId;
    final conversation = ref
        .watch(
          conversationByIdStreamProvider(
            workspaceId,
            conversationId: conversationId,
          ),
        )
        .value;
    final a2uiRuntime = ref.watch(chatA2uiRuntimeProvider(conversationId));
    final _ = useListenable(a2uiRuntime);
    final isTopLevelConversation = _isTopLevelConversation(
      conversation,
      a2uiRuntime,
    );
    final submittedA2uiReplayPayloads = _submittedA2uiReplayPayloads(
      messageEntitiesById?.values ?? const <MessageEntity>[],
      conversationId,
    );
    final latestA2uiMessageId = _latestA2uiMessageId(
      messages,
      messageEntitiesById,
    );
    useEffect(
      () => _restoreA2uiEffect(
        isTopLevelConversation: isTopLevelConversation,
        runtime: a2uiRuntime,
        messageEntitiesById: messageEntitiesById,
        replayPayloadsByMessageId: submittedA2uiReplayPayloads,
        latestA2uiMessageId: latestA2uiMessageId,
      ),
      [
        a2uiRuntime,
        conversationId,
        isTopLevelConversation,
        latestA2uiMessageId,
        messageEntitiesById,
        messages,
        workspaceId,
      ],
    );
    useEffect(
      () => _listenToA2uiActionsEffect(
        isTopLevelConversation: isTopLevelConversation,
        runtime: a2uiRuntime,
        ref: ref,
        workspaceId: workspaceId,
        conversationId: conversationId,
      ),
      [a2uiRuntime, conversationId, isTopLevelConversation, workspaceId],
    );
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
    final resolvedMessages = <_ResolvedChatMessage?>[];
    for (final messageId in messages) {
      final message =
          ref.watch(
            messageConversationByIdProvider((
              workspaceId: workspaceId,
              conversationId: conversationId,
              messageId: messageId,
            )),
          ) ??
          messageEntitiesById?[messageId];
      final isStreaming = ref.watch(isMessageStreamingProvider(messageId));
      resolvedMessages.add(
        message == null
            ? null
            : _ResolvedChatMessage(message: message, isStreaming: isStreaming),
      );
    }
    final data = _buildChatTimelineItems(
      resolvedMessages,
      submittedA2uiReplayPayloads,
    ).reversed.toList(growable: false);

    void updateDisclosure(VoidCallback update) => update();

    final thinkingCount = showThinking ? 1 : 0;
    final compactionCount = isCompacting ? 1 : 0;
    final itemCount = data.length + thinkingCount + compactionCount;

    return ListView.separated(
      reverse: true,
      controller: controller,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) => _buildChatTimelineItem(
        index: index,
        data: data,
        showThinking: showThinking,
        isCompacting: isCompacting,
        thinkingCount: thinkingCount,
        compactionCount: compactionCount,
        disclosureController: controller,
        onDisclosureChanged: updateDisclosure,
        parentConversationId: parentConversationId,
        childConversations: childConversations,
        workspaceId: workspaceId,
        a2uiRuntime: isTopLevelConversation ? a2uiRuntime : null,
        replayPayloadsByMessageId: submittedA2uiReplayPayloads,
        conversation: conversation,
      ),
      separatorBuilder: (context, index) => const AuraSizedBox(height: .md),
      itemCount: itemCount,
      addAutomaticKeepAlives: false,
      scrollCacheExtent: const ScrollCacheExtent.pixels(500),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    );
  }
}

bool _isTopLevelConversation(
  ConversationEntity? conversation,
  ChatA2uiRuntime runtime,
) => conversation == null
    ? runtime.enabled
    : conversation.parentConversationId == null;

void Function()? _restoreA2uiEffect({
  required bool isTopLevelConversation,
  required ChatA2uiRuntime runtime,
  required Map<String, MessageEntity>? messageEntitiesById,
  required Map<String, List<String>> replayPayloadsByMessageId,
  required String? latestA2uiMessageId,
}) {
  if (!isTopLevelConversation) return null;
  var active = true;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!active) return;
    _restoreA2uiMessages(
      runtime: runtime,
      messageEntitiesById: messageEntitiesById,
      replayPayloadsByMessageId: replayPayloadsByMessageId,
      latestA2uiMessageId: latestA2uiMessageId,
    );
  });
  return () {
    active = false;
  };
}

void _restoreA2uiMessages({
  required ChatA2uiRuntime runtime,
  required Map<String, MessageEntity>? messageEntitiesById,
  required Map<String, List<String>> replayPayloadsByMessageId,
  required String? latestA2uiMessageId,
}) {
  runtime.enable();
  if (messageEntitiesById == null) return;
  for (final message in messageEntitiesById.values) {
    if (message.isForkReference) continue;
    _restoreA2uiMessage(
      runtime: runtime,
      message: message,
      replayPayloads: replayPayloadsByMessageId[message.id] ?? const [],
      isLatestUnfinished:
          message.id == latestA2uiMessageId &&
          message.status == MessageStatus.unfinished,
    );
  }
}

void _restoreA2uiMessage({
  required ChatA2uiRuntime runtime,
  required MessageEntity message,
  required List<String> replayPayloads,
  required bool isLatestUnfinished,
}) {
  final metadata = message.metadata;
  final payloads = [...?metadata?.a2uiMessages, ...replayPayloads];
  final surfaceIssues =
      metadata?.a2uiIssuesBySurface ?? const <String, List<String>>{};
  final messageIssues = metadata?.a2uiMessageIssues ?? const <String>[];
  final diagnosticPayloads = metadata?.modelMetadata['a2uiDiagnosticPayloads'];
  if (!_hasA2uiState(
    payloads,
    surfaceIssues,
    messageIssues,
    diagnosticPayloads,
  )) {
    return;
  }
  runtime.restoreMessage(
    message.id,
    payloads,
    current: isLatestUnfinished,
    a2uiIssuesBySurface: surfaceIssues,
    a2uiMessageIssues: messageIssues,
    diagnosticPayloads: diagnosticPayloads is List
        ? diagnosticPayloads.whereType<String>()
        : const [],
  );
}

bool _hasA2uiState(
  List<String> payloads,
  Map<String, List<String>> surfaceIssues,
  List<String> messageIssues,
  Object? diagnosticPayloads,
) =>
    payloads.isNotEmpty ||
    surfaceIssues.isNotEmpty ||
    messageIssues.isNotEmpty ||
    diagnosticPayloads is List;

void Function()? _listenToA2uiActionsEffect({
  required bool isTopLevelConversation,
  required ChatA2uiRuntime runtime,
  required WidgetRef ref,
  required String workspaceId,
  required String conversationId,
}) {
  if (!isTopLevelConversation) return null;
  final subscription = runtime.actions.listen(
    (action) => unawaited(
      _submitA2uiAction(
        ref,
        runtime: runtime,
        workspaceId: workspaceId,
        conversationId: conversationId,
        action: action,
      ),
    ),
  );
  return () => unawaited(subscription.cancel());
}

Widget _buildChatTimelineItem({
  required int index,
  required List<_ChatTimelineItem> data,
  required bool showThinking,
  required bool isCompacting,
  required int thinkingCount,
  required int compactionCount,
  required _DisclosureScrollController disclosureController,
  required void Function(VoidCallback update) onDisclosureChanged,
  required String parentConversationId,
  required List<ConversationEntity> childConversations,
  required String workspaceId,
  required ChatA2uiRuntime? a2uiRuntime,
  required Map<String, List<String>> replayPayloadsByMessageId,
  required ConversationEntity? conversation,
}) {
  if (showThinking && index == 0) {
    return const ChatThinkingIndicator(
      key: ValueKey('chat_thinking_indicator'),
    );
  }
  if (isCompacting && index == thinkingCount) {
    return const _CompactingIndicator();
  }

  final item = data[index - thinkingCount - compactionCount];
  final messageId = switch (item) {
    _ActivityRunTimelineItem() => null,
    _MessageTimelineItem(:final source) => source.message.id,
  };
  final child = switch (item) {
    _ActivityRunTimelineItem(:final run) => _AssistantActivityRun(
      key: ValueKey('activity_trace_${run.id}'),
      run: run,
      onDisclosureChanged: onDisclosureChanged,
      parentConversationId: parentConversationId,
      childConversations: childConversations,
      workspaceId: workspaceId,
    ),
    _MessageTimelineItem(:final source, :final activityRenderedInSession) =>
      _ChatMessageTimelineItem(
        key: ValueKey(source.message.id),
        source: source,
        activityRenderedInSession: activityRenderedInSession,
        onDisclosureChanged: onDisclosureChanged,
        parentConversationId: parentConversationId,
        childConversations: childConversations,
        workspaceId: workspaceId,
        a2uiRuntime: a2uiRuntime,
        a2uiReplayPayloads:
            replayPayloadsByMessageId[source.message.id] ?? const [],
      ),
  };
  final rendered = _DisclosureSizeReporter(
    controller: disclosureController,
    child: child,
  );
  if (conversation != null &&
      messageId != null &&
      conversation.forkThroughMessageId == messageId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        rendered,
        _ForkBoundaryDivider(
          conversation: conversation!,
          workspaceId: workspaceId,
        ),
      ],
    );
  }
  return rendered;
}

class _ResolvedChatMessage {
  const _ResolvedChatMessage({
    required this.message,
    required this.isStreaming,
  });

  final MessageEntity message;
  final bool isStreaming;
}

sealed class _ChatTimelineItem {
  const _ChatTimelineItem();
}

class _ActivityRunTimelineItem extends _ChatTimelineItem {
  const _ActivityRunTimelineItem(this.run);

  final _ActivityRun run;
}

class _MessageTimelineItem extends _ChatTimelineItem {
  const _MessageTimelineItem(
    this.source, {
    this.activityRenderedInSession = false,
  });

  final _ResolvedChatMessage source;
  final bool activityRenderedInSession;
}

class _ActivityRun {
  const _ActivityRun(this.sources, {this.activityContentMessageIds = const {}});

  final List<_ResolvedChatMessage> sources;
  final Set<String> activityContentMessageIds;

  String get id => sources.first.message.id;
}

typedef _ActivityToolCall = ({
  String messageId,
  MessageToolCallEntity toolCall,
  bool isForkReference,
  bool isStreaming,
});

sealed class _ActivityRunEntry {
  const _ActivityRunEntry();
}

class _ActivityNarrativeEntry extends _ActivityRunEntry {
  const _ActivityNarrativeEntry({
    required this.messageId,
    required this.content,
  });

  final String messageId;
  final String content;
}

class _ActivityThinkingEntry extends _ActivityRunEntry {
  const _ActivityThinkingEntry({
    required this.messageId,
    required this.content,
  });

  final String messageId;
  final String content;
}

class _ActivityToolGroupEntry extends _ActivityRunEntry {
  const _ActivityToolGroupEntry(this.toolCalls);

  final List<_ActivityToolCall> toolCalls;
}

List<_ActivityRunEntry> _buildActivityRunEntries(_ActivityRun run) {
  final entries = <_ActivityRunEntry>[];
  final toolCalls = <_ActivityToolCall>[];

  void addToolGroup() {
    if (toolCalls.isEmpty) return;
    entries.add(_ActivityToolGroupEntry(List.of(toolCalls)));
    toolCalls.clear();
  }

  for (final source in run.sources) {
    if (run.activityContentMessageIds.contains(source.message.id)) {
      final content = source.message.content.trim();
      if (content.isNotEmpty) {
        addToolGroup();
        entries.add(
          _ActivityNarrativeEntry(
            messageId: source.message.id,
            content: content,
          ),
        );
      }
    }

    final thinking = source.message.metadata?.thinking?.trim();
    if (thinking != null && thinking.isNotEmpty) {
      addToolGroup();
      entries.add(
        _ActivityThinkingEntry(messageId: source.message.id, content: thinking),
      );
    }

    for (final toolCall
        in source.message.metadata?.toolCalls ??
            const <MessageToolCallEntity>[]) {
      toolCalls.add((
        messageId: source.message.id,
        toolCall: toolCall,
        isForkReference: source.message.isForkReference,
        isStreaming: source.isStreaming,
      ));
    }
  }
  addToolGroup();

  return entries;
}

String _activityToolGroupId(_ActivityToolGroupEntry entry) =>
    entry.toolCalls.first.messageId;

bool _isLiveActivityToolGroup(_ActivityToolGroupEntry entry) =>
    entry.toolCalls.any(
      (item) =>
          !item.isForkReference &&
          (item.isStreaming || item.toolCall.isPending),
    );

List<_ChatTimelineItem> _buildChatTimelineItems(
  List<_ResolvedChatMessage?> messages,
  Map<String, List<String>> replayPayloadsByMessageId,
) {
  final items = <_ChatTimelineItem>[];
  final activitySources = <_ResolvedChatMessage>[];
  final activityContentMessageIds = <String>{};

  void addActivityRun() {
    if (activitySources.isEmpty) return;
    items.add(
      _ActivityRunTimelineItem(
        _ActivityRun(
          List.of(activitySources),
          activityContentMessageIds: Set.of(activityContentMessageIds),
        ),
      ),
    );
    activitySources.clear();
    activityContentMessageIds.clear();
  }

  for (var index = 0; index < messages.length; index++) {
    final source = messages[index];
    if (source == null) {
      addActivityRun();
      continue;
    }

    final message = source.message;
    final hasVisibleResponse = _hasVisibleAssistantResponse(
      message,
      replayPayloadsByMessageId,
    );
    final hasFollowingAssistantActivity = _hasFollowingAssistantActivity(
      messages,
      index,
    );
    final hasActivity =
        !_isTimelineBoundary(message) &&
        (_hasAssistantActivity(message) ||
            (hasVisibleResponse && hasFollowingAssistantActivity));

    if (hasActivity) {
      final isFinalResponse =
          hasVisibleResponse && !hasFollowingAssistantActivity;
      activitySources.add(source);
      if (hasVisibleResponse && !isFinalResponse) {
        activityContentMessageIds.add(message.id);
      }
      if (isFinalResponse) {
        addActivityRun();
        items.add(
          _MessageTimelineItem(source, activityRenderedInSession: true),
        );
      }
      continue;
    }

    addActivityRun();
    items.add(_MessageTimelineItem(source));
  }
  addActivityRun();

  return items;
}

bool _hasFollowingAssistantActivity(
  List<_ResolvedChatMessage?> messages,
  int index,
) {
  for (var nextIndex = index + 1; nextIndex < messages.length; nextIndex++) {
    final next = messages[nextIndex];
    if (next == null || _isTimelineBoundary(next.message)) return false;

    if (_hasAssistantActivity(next.message)) return true;
  }

  return false;
}

bool _hasAssistantActivity(MessageEntity message) =>
    _hasAssistantThinking(message) ||
    message.metadata?.toolCalls.isNotEmpty == true;

bool _hasAssistantThinking(MessageEntity message) =>
    message.metadata?.thinking?.trim().isNotEmpty == true;

bool _hasVisibleAssistantResponse(
  MessageEntity message,
  Map<String, List<String>> replayPayloadsByMessageId,
) =>
    message.content.trim().isNotEmpty ||
    message.attachments.isNotEmpty ||
    _hasA2uiMessageState(message) ||
    replayPayloadsByMessageId[message.id]?.isNotEmpty == true ||
    message.metadata?.modelMetadata['a2uiDiagnosticPayloads'] is List;

bool _isTimelineBoundary(MessageEntity message) =>
    message.isUser ||
    message.messageType == MessageType.system ||
    message.status == MessageStatus.error ||
    message.metadata?.isCompactionSummary == true;

bool _isErrorSystemMessage(MessageEntity message) =>
    !message.isUser &&
    message.messageType == MessageType.system &&
    message.status == MessageStatus.error;

class const _ChatMessageTimelineItem({
  required final _ResolvedChatMessage source,
  final bool activityRenderedInSession = false,
  required final void Function(VoidCallback update) onDisclosureChanged,
  required final String parentConversationId,
  required final List<ConversationEntity> childConversations,
  required final String workspaceId,
  final ChatA2uiRuntime? a2uiRuntime,
  final List<String> a2uiReplayPayloads = const [],
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final message = source.message;

    if (message.metadata?.isCompactionSummary == true) {
      return _CompactedMessageWidget(
        message: message,
        key: ValueKey(message.id),
      );
    }

    if (_isErrorSystemMessage(message)) {
      return _ErrorMessageWidget(
        content: message.content,
        key: ValueKey(message.id),
      );
    }

    final showActivity =
        !activityRenderedInSession &&
        !_isTimelineBoundary(message) &&
        _hasAssistantActivity(message);
    return AuraColumn(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showActivity)
          _AssistantActivityRun(
            key: ValueKey('activity_trace_${message.id}'),
            run: _ActivityRun([source]),
            onDisclosureChanged: onDisclosureChanged,
            parentConversationId: parentConversationId,
            childConversations: childConversations,
            workspaceId: workspaceId,
          ),
        _ChatMessageContent(
          message: message,
          isStreaming: source.isStreaming,
          workspaceId: workspaceId,
          conversationId: parentConversationId,
          a2uiRuntime: a2uiRuntime,
          a2uiReplayPayloads: a2uiReplayPayloads,
        ),
      ],
    );
  }
}

class const _ChatMessageContent({
  required final MessageEntity message,
  required final bool isStreaming,
  required final String workspaceId,
  required final String conversationId,
  required final ChatA2uiRuntime? a2uiRuntime,
  required final List<String> a2uiReplayPayloads,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final hasContent = message.content.trim().isNotEmpty;
    final showTextBubble = _showTextBubble(
      message: message,
      isStreaming: isStreaming,
      hasContent: hasContent,
      hasActivity: _hasAssistantActivity(message),
    );
    final status = _messageDeliveryStatus(message, isStreaming);
    final hasA2uiResponse =
        !message.isUser &&
        !message.isForkReference &&
        ((message.metadata?.a2uiMessages.isNotEmpty ?? false) ||
            a2uiReplayPayloads.isNotEmpty);

    return AuraColumn(
      children: _messageContentChildren(
        message: message,
        hasContent: hasContent,
        showTextBubble: showTextBubble,
        hasA2uiResponse: hasA2uiResponse,
        status: status,
        workspaceId: workspaceId,
        conversationId: conversationId,
        a2uiRuntime: a2uiRuntime,
        a2uiReplayPayloads: a2uiReplayPayloads,
      ),
      crossAxisAlignment: CrossAxisAlignment.start,
    );
  }
}

bool _showTextBubble({
  required MessageEntity message,
  required bool isStreaming,
  required bool hasContent,
  required bool hasActivity,
}) =>
    hasContent || (message.attachments.isEmpty && !isStreaming && !hasActivity);

AuraMessageDeliveryStatus _messageDeliveryStatus(
  MessageEntity message,
  bool isStreaming,
) {
  final metadata = message.metadata;
  final isAwaitingA2uiAction =
      !isStreaming &&
      message.status == MessageStatus.unfinished &&
      (metadata?.modelMetadata['a2uiRequiresUserAction'] == true ||
          metadata?.a2uiMessages.isNotEmpty == true);
  return isAwaitingA2uiAction
      ? AuraMessageDeliveryStatus.sent
      : _mapMessageStatus(message.status, isStreaming);
}

List<Widget> _messageContentChildren({
  required MessageEntity message,
  required bool hasContent,
  required bool showTextBubble,
  required bool hasA2uiResponse,
  required AuraMessageDeliveryStatus status,
  required String workspaceId,
  required String conversationId,
  required ChatA2uiRuntime? a2uiRuntime,
  required List<String> a2uiReplayPayloads,
}) {
  final selectableChildren = <Widget>[
    if (showTextBubble)
      _MessageTextContent(
        message: message,
        hasContent: hasContent,
        hasA2uiResponse: hasA2uiResponse,
        status: status,
      ),
    if (message.attachments.isNotEmpty) _MessageAttachments(message: message),
    if (!message.isUser && !message.isForkReference && a2uiRuntime != null)
      ChatA2uiSurfaceHost.message(
        key: ValueKey('a2ui_${message.id}'),
        runtime: a2uiRuntime,
        messageId: message.id,
        payloads: [...?message.metadata?.a2uiMessages, ...a2uiReplayPayloads],
        issuesBySurface: message.metadata?.a2uiIssuesBySurface ?? const {},
        messageIssues: message.metadata?.a2uiMessageIssues ?? const [],
        wrapInSelectionArea: false,
      ),
  ];

  return [
    if (selectableChildren.isNotEmpty)
      SelectionArea(
        child: AuraColumn(
          mainAxisSize: .min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: selectableChildren,
        ),
      ),
    if (!hasA2uiResponse && _messageCopyText(message, a2uiRuntime) != null)
      _MessageActions(
        message: message,
        resolveContent: () => _messageCopyText(message, a2uiRuntime),
        workspaceId: workspaceId,
        conversationId: conversationId,
      ),
    if (hasA2uiResponse)
      _MessageFooter(
        key: ValueKey('message_footer_${message.id}'),
        createdAt: message.createdAt,
        status: status,
        resolveContent: () => _messageCopyText(message, a2uiRuntime),
        message: message,
        workspaceId: workspaceId,
        conversationId: conversationId,
      ),
  ];
}

String? _messageCopyText(MessageEntity message, ChatA2uiRuntime? a2uiRuntime) {
  final content = message.content;
  final a2uiText = message.isUser
      ? null
      : a2uiRuntime?.copyableTextFor(message.id);
  if (content.trim().isEmpty) return a2uiText;
  if (a2uiText == null || a2uiText.trim().isEmpty) return content;
  return '$content\n\n$a2uiText';
}

Color _userMessageSelectionColor(AuraColorScheme colors) {
  final overlayColor = colors.onPrimary.computeLuminance() > .5
      ? Colors.black
      : Colors.white;
  return Color.alphaBlend(overlayColor.withValues(alpha: .24), colors.primary);
}

AuraMessageDeliveryStatus _mapMessageStatus(
  MessageStatus status,
  bool isStreaming,
) => switch (status) {
  MessageStatus.sending => AuraMessageDeliveryStatus.sending,
  MessageStatus.unfinished =>
    isStreaming
        ? AuraMessageDeliveryStatus.sending
        : AuraMessageDeliveryStatus.unfinished,
  MessageStatus.sent => AuraMessageDeliveryStatus.sent,
  MessageStatus.error => AuraMessageDeliveryStatus.error,
};

Map<String, List<String>> _submittedA2uiReplayPayloads(
  Iterable<MessageEntity> messages,
  String conversationId,
) {
  final payloadsByAssistantMessage = <String, List<String>>{};
  for (final message in messages) {
    if (!message.isUser || message.isForkReference) continue;
    final action = A2uiChatContract.decodeActionMetadata(
      message.metadata?.modelMetadata,
      conversationId: conversationId,
    );
    final assistantMessageId = action?.assistantMessageId;
    if (action == null || assistantMessageId == null) continue;
    final payload = chatA2uiSubmittedAnswersReplayPayload(action);
    if (payload == null) continue;
    payloadsByAssistantMessage
        .putIfAbsent(assistantMessageId, () => [])
        .add(payload);
  }

  return payloadsByAssistantMessage;
}

String? _latestA2uiMessageId(
  List<String> messageIds,
  Map<String, MessageEntity>? messages,
) {
  if (messages == null) return null;
  final latestUserIndex = _latestUserMessageIndex(messageIds, messages);
  for (var index = messageIds.length - 1; index > latestUserIndex; index--) {
    final id = messageIds[index];
    final message = messages[id];
    if (_hasA2uiMessageState(message)) return id;
  }

  return null;
}

int _latestUserMessageIndex(
  List<String> messageIds,
  Map<String, MessageEntity> messages,
) {
  var latestUserIndex = -1;
  for (var index = 0; index < messageIds.length; index++) {
    if (messages[messageIds[index]]?.isUser == true) latestUserIndex = index;
  }
  return latestUserIndex;
}

bool _hasA2uiMessageState(MessageEntity? message) {
  if (message == null || message.isUser || message.isForkReference)
    return false;
  final metadata = message.metadata;
  if (metadata == null) return false;
  return metadata.a2uiMessages.isNotEmpty ||
      metadata.a2uiIssuesBySurface.isNotEmpty ||
      metadata.a2uiMessageIssues.isNotEmpty;
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

Future<void> _submitA2uiAction(
  WidgetRef ref, {
  required ChatA2uiRuntime runtime,
  required String workspaceId,
  required String conversationId,
  required ChatUiAction action,
}) async {
  try {
    await ref
        .read(sendMessageUsecaseProvider(workspaceId))
        .call(
          conversationId: conversationId,
          draft: ChatDraft(
            text: action.messageText,
            metadataJson: action.metadataJson,
          ),
        );
  } on Object catch (error, stackTrace) {
    runtime.rejectFormSubmission(action.surfaceId);
    _a2uiLogger.warning(
      'A2UI action rejected: conversationId=$conversationId',
      error,
      stackTrace,
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
  required final bool hasContent,
  required final bool hasA2uiResponse,
  required final AuraMessageDeliveryStatus status,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (message.isUser) {
      final colors = context.auraColors;
      return TextSelectionTheme(
        data: Theme.of(context).textSelectionTheme.copyWith(
          selectionColor: _userMessageSelectionColor(colors),
          selectionHandleColor: colors.onPrimary,
        ),
        child: AuraMessageBubble(
          content: message.content,
          isUser: true,
          key: ValueKey(message.id),
          status: status,
          timestamp: message.createdAt,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasContent)
          _AiMessageContent(
            content: message.content,
            timestamp: message.createdAt,
            key: ValueKey(message.id),
            status: status,
            showMetadata: !hasA2uiResponse,
          ),
      ],
    );
  }
}

class const _MessageFooter({
  required final MessageEntity message,
  required final String workspaceId,
  required final String conversationId,
  required final DateTime createdAt,
  required final AuraMessageDeliveryStatus status,
  required final String? Function() resolveContent,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;
    final typography = context.auraTheme.typography;
    final copyableText = resolveContent();

    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (copyableText != null)
                _MessageActions(
                  message: message,
                  resolveContent: resolveContent,
                  workspaceId: workspaceId,
                  conversationId: conversationId,
                ),
              if (copyableText == null && _canForkMessage(message))
                _MessageForkAction(
                  message: message,
                  workspaceId: workspaceId,
                  conversationId: conversationId,
                ),
              Text(
                RelativeTimeFormatter.format(createdAt),
                style: TextStyle(
                  color: auraColors.onSurfaceVariant,
                  fontSize: typography.fontSizeXs,
                  fontFamily: typography.bodyFontFamily,
                ),
              ),
            ],
          ),
          if (status != AuraMessageDeliveryStatus.sent) ...[
            SizedBox(height: context.auraTheme.fromSpacing(.xs) / 2),
            AuraMessageStatus(status: status),
          ],
        ],
      ),
    );
  }
}

bool _canForkMessage(MessageEntity message) =>
    !message.isUser && message.status == MessageStatus.sent;

class const _MessageActions({
  required final MessageEntity message,
  required final String? Function() resolveContent,
  required final String workspaceId,
  required final String conversationId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _MessageCopyAction(
        resolveContent: resolveContent,
        isUser: message.isUser,
      ),
      if (_canForkMessage(message))
        _MessageForkAction(
          message: message,
          workspaceId: workspaceId,
          conversationId: conversationId,
        ),
    ],
  );
}

class const _MessageForkAction({
  required final MessageEntity message,
  required final String workspaceId,
  required final String conversationId,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => Tooltip(
    message: LocaleKeys.chats_screens_chat_conversation_fork.tr(),
    child: IconButton(
      icon: const Icon(Icons.call_split_outlined),
      onPressed: () => unawaited(
        _forkMessage(context, ref, message, workspaceId, conversationId),
      ),
    ),
  );
}

Future<void> _forkMessage(
  BuildContext context,
  WidgetRef ref,
  MessageEntity message,
  String workspaceId,
  String conversationId,
) async {
  try {
    final cloud = await ref.read(
      cloudConversationUsecaseProvider(workspaceId).future,
    );
    final String forkId;
    if (cloud != null) {
      forkId = (await cloud.fork(
        (await ref.read(
          conversationByIdStreamProvider(
            workspaceId,
            conversationId: conversationId,
          ).future,
        ))!,
        throughMessageId: message.id,
      )).id;
    } else {
      final conversation = await ref.read(
        conversationByIdStreamProvider(
          workspaceId,
          conversationId: conversationId,
        ).future,
      );
      if (conversation == null) return;
      forkId =
          (await ref
                  .read(forkConversationUsecaseProvider)
                  .call(conversation, throughMessageId: message.id))
              .id;
    }
    ref.invalidate(conversationsStreamProvider(workspaceId: workspaceId));
    if (context.mounted) {
      ConversationRoute(workspaceId: workspaceId, chatId: forkId).go(context);
    }
  } on Object {
    if (!context.mounted) return;
    AuraSnackBars.show(
      context: context,
      content: const TextLocale(
        LocaleKeys.chats_screens_chat_conversation_fork_error,
      ),
      variant: .error,
    );
  }
}

class const _ForkBoundaryDivider({
  required final ConversationEntity conversation,
  required final String workspaceId,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sourceId = conversation.forkSourceConversationId;
    final source = sourceId == null
        ? null
        : ref
              .watch(
                conversationByIdStreamProvider(
                  workspaceId,
                  conversationId: sourceId,
                ),
              )
              .value;
    final label = TextLocale(
      LocaleKeys.chats_screens_chat_conversation_forked_from,
      args: [conversation.forkSourceTitle ?? ''],
      style: TextStyle(color: context.auraColors.onSurfaceVariant),
    );
    final row = Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: label,
        ),
        const Expanded(child: Divider()),
      ],
    );
    return source == null
        ? row
        : InkWell(
            onTap: () => ConversationRoute(
              workspaceId: source.workspaceId,
              chatId: source.id,
            ).go(context),
            child: row,
          );
  }
}

class _MessageCopyAction extends StatefulWidget {
  const new({required this.resolveContent, required this.isUser, super.key});

  final String? Function() resolveContent;
  final bool isUser;

  @override
  State<_MessageCopyAction> createState() => _MessageCopyActionState();
}

class _MessageCopyActionState extends State<_MessageCopyAction> {
  var _copied = false;

  @override
  Widget build(BuildContext context) => Align(
    alignment: widget.isUser ? Alignment.centerRight : Alignment.centerLeft,
    child: AuraIconButton(
      icon: _copied ? Icons.check : Icons.copy_outlined,
      onPressed: () => unawaited(_copy()),
      tooltip:
          (_copied
                  ? LocaleKeys.chats_screens_chat_conversation_message_copied
                  : LocaleKeys.chats_screens_chat_conversation_copy_message)
              .tr(),
    ),
  );

  Future<void> _copy() async {
    final content = widget.resolveContent();
    if (content == null || content.trim().isEmpty) return;

    try {
      await Clipboard.setData(ClipboardData(text: content));
    } on Object {
      return;
    }

    if (mounted) setState(() => _copied = true);
  }
}

class const _AiMessageContent({
  required final String content,
  required final DateTime timestamp,
  super.key,
  final AuraMessageDeliveryStatus status = AuraMessageDeliveryStatus.sent,
  final bool showMetadata = true,
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
        if (showMetadata) ...[
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
      ],
    );
  }
}

class const _AssistantActivityRun({
  required final _ActivityRun run,
  required final void Function(VoidCallback update) onDisclosureChanged,
  required final String parentConversationId,
  required final List<ConversationEntity> childConversations,
  required final String workspaceId,
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityEntries = _buildActivityRunEntries(run);
    final toolGroupEntries = [
      for (final entry in activityEntries)
        if (entry is _ActivityToolGroupEntry) entry,
    ];
    final toolCalls = <_ActivityToolCall>[
      for (final entry in toolGroupEntries) ...entry.toolCalls,
    ];
    final expandableToolGroupIds = {
      for (final entry in toolGroupEntries)
        if (entry.toolCalls.length > 1) _activityToolGroupId(entry),
    };
    final liveToolGroupIds = [
      for (final entry in toolGroupEntries)
        if (_isLiveActivityToolGroup(entry)) _activityToolGroupId(entry),
    ];
    final liveToolGroupSignature = liveToolGroupIds.join('\u0000');
    final isLive =
        run.sources.any(
          (source) => !source.message.isForkReference && source.isStreaming,
        ) ||
        toolCalls.any(
          (item) => !item.isForkReference && item.toolCall.isPending,
        );
    final toolSignature = toolCalls
        .map((item) => '${item.messageId}\u0000${item.toolCall.id}')
        .join('\u0000');
    final latestPendingToolId = _latestPendingToolId(
      toolCalls
          .where((item) => !item.isForkReference)
          .map((item) => item.toolCall)
          .toList(growable: false),
    );
    final traceExpanded = useState(isLive);
    final expandedToolGroupIds = useState<Set<String>>(
      isLive
          ? liveToolGroupIds.where(expandableToolGroupIds.contains).toSet()
          : <String>{},
    );
    final expandedToolIds = useState(
      latestPendingToolId == null ? <String>{} : <String>{latestPendingToolId},
    );
    final previousIsLive = useRef(isLive);
    final previousToolSignature = useRef(toolSignature);
    final previousPendingToolId = useRef(latestPendingToolId);

    useEffect(
      () {
        final wasLive = previousIsLive.value;
        final hasNewTool = previousToolSignature.value != toolSignature;
        final hasNewPendingTool =
            previousPendingToolId.value != latestPendingToolId;
        if (isLive && (!wasLive || hasNewTool || hasNewPendingTool)) {
          onDisclosureChanged(() {
            traceExpanded.value = true;
            expandedToolGroupIds.value = {
              ...expandedToolGroupIds.value,
              ...liveToolGroupIds.where(expandableToolGroupIds.contains),
            };
            if (latestPendingToolId != null) {
              expandedToolIds.value = {
                ...expandedToolIds.value,
                latestPendingToolId,
              };
            }
          });
        } else if (!isLive && wasLive) {
          onDisclosureChanged(() {
            traceExpanded.value = false;
            expandedToolGroupIds.value = <String>{};
            expandedToolIds.value = <String>{};
          });
        }
        previousIsLive.value = isLive;
        previousToolSignature.value = toolSignature;
        previousPendingToolId.value = latestPendingToolId;
        return null;
      },
      [
        expandableToolGroupIds.length,
        isLive,
        latestPendingToolId,
        liveToolGroupSignature,
        toolSignature,
      ],
    );

    final toolContents = <String, Widget>{};
    for (final entry in toolGroupEntries) {
      final groupId = _activityToolGroupId(entry);
      final activityToolCalls = [
        for (final item in entry.toolCalls)
          (
            messageId: item.messageId,
            toolCall: item.toolCall,
            isForkReference: item.isForkReference,
            displayName: _toolCallDisplayName(
              ref.watch(
                toolDisplayNameProvider(workspaceId, item.toolCall.name),
              ),
              item.toolCall.name,
            ),
            openSubAgent: _openSubAgent(
              context: context,
              ref: ref,
              workspaceId: workspaceId,
              parentConversationId: parentConversationId,
              childConversations: childConversations,
              toolCall: item.toolCall,
            ),
          ),
      ];
      final toolRows = [
        for (final activityToolCall in activityToolCalls)
          _ActivityToolCallRow(
            key: ValueKey('activity_tool_row_${activityToolCall.toolCall.id}'),
            toolCall: activityToolCall.toolCall,
            displayName: activityToolCall.displayName,
            isExpanded: expandedToolIds.value.contains(
              activityToolCall.toolCall.id,
            ),
            onToggle: () => onDisclosureChanged(
              () => expandedToolIds.value = _toggledToolIds(
                expandedToolIds.value,
                activityToolCall.toolCall.id,
              ),
            ),
            openSubAgent: activityToolCall.openSubAgent,
          ),
      ];
      if (toolRows.length == 1) {
        toolContents[groupId] = toolRows.single;
      } else {
        toolContents[groupId] = AuraColumn(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ActivityTraceDisclosure(
              key: ValueKey('activity_tool_list_toggle_$groupId'),
              icon: Icons.build_outlined,
              label: _toolCallsSummary(
                activityToolCalls.map((toolCall) => toolCall.displayName),
              ),
              color: context.auraColors.secondary,
              isExpanded: expandedToolGroupIds.value.contains(groupId),
              onPressed: () => onDisclosureChanged(() {
                final next = {...expandedToolGroupIds.value};
                if (!next.remove(groupId)) next.add(groupId);
                expandedToolGroupIds.value = next;
              }),
            ),
            if (expandedToolGroupIds.value.contains(groupId))
              Padding(
                padding: EdgeInsets.only(
                  left: context.auraTheme.fromSpacing(.sm),
                ),
                child: AuraColumn(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: toolRows,
                ),
              ),
          ],
        );
      }
    }
    final hasOuterDisclosure = activityEntries.length > 1;
    final activityLabel = toolCalls.isEmpty
        ? LocaleKeys.chats_screens_chat_conversation_activity_thinking.tr()
        : LocaleKeys.chats_screens_chat_conversation_activity_tools_count
              .plural(toolCalls.length, context: context);
    final activityContent = AuraColumn(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in activityEntries)
          if (entry case _ActivityNarrativeEntry(
            :final messageId,
            :final content,
          ))
            Padding(
              padding: EdgeInsets.only(
                bottom: context.auraTheme.fromSpacing(.xs),
              ),
              child: _ActivityNarrative(
                key: ValueKey('activity_narrative_$messageId'),
                content: content,
              ),
            )
          else if (entry case _ActivityThinkingEntry(
            :final messageId,
            :final content,
          ))
            Padding(
              padding: EdgeInsets.only(
                bottom: context.auraTheme.fromSpacing(.xs),
              ),
              child: _ActivityThinkingCard(
                key: ValueKey('activity_thinking_$messageId'),
                content: content,
              ),
            )
          else
            toolContents[_activityToolGroupId(
              entry as _ActivityToolGroupEntry,
            )]!,
      ],
    );

    return AuraColumn(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasOuterDisclosure)
          _ActivityTraceDisclosure(
            key: ValueKey('activity_trace_toggle_${run.id}'),
            icon: Icons.psychology_outlined,
            label: activityLabel,
            color: context.auraColors.onSurfaceVariant,
            isActivity: true,
            isExpanded: traceExpanded.value,
            onPressed: () => onDisclosureChanged(
              () => traceExpanded.value = !traceExpanded.value,
            ),
          ),
        if (hasOuterDisclosure && traceExpanded.value)
          Padding(
            padding: EdgeInsets.only(
              left: context.auraTheme.fromSpacing(.sm),
              top: context.auraTheme.fromSpacing(.xs),
            ),
            child: activityContent,
          ),
        if (!hasOuterDisclosure) activityContent,
      ],
    );
  }
}

class const _ActivityNarrative({required final String content, super.key})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.auraColors;
    final typography = context.auraTheme.typography;

    return SelectionArea(
      child: GptMarkdown(
        content,
        style: TextStyle(
          color: colors.onSurfaceVariant,
          fontSize: typography.fontSizeSm,
          height: typography.lineHeightBase,
          fontFamily: typography.bodyFontFamily,
        ),
      ),
    );
  }
}

class const _ActivityThinkingCard({required final String content, super.key})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.auraColors;
    final typography = context.auraTheme.typography;

    return AuraContainer(
      variant: AuraContainerVariant.surfaceVariant,
      padding: .small,
      borderRadius: 8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.psychology_outlined,
                size: 14,
                color: colors.onSurfaceVariant,
              ),
              const AuraSizedBox(width: .xs),
              TextLocale(
                LocaleKeys.chats_screens_chat_conversation_activity_thinking,
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: typography.fontSizeXs,
                  fontWeight: FontWeight.w600,
                  fontFamily: typography.bodyFontFamily,
                ),
              ),
            ],
          ),
          const AuraSizedBox(height: .xs),
          SelectionArea(
            child: GptMarkdown(
              content,
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: typography.fontSizeSm,
                height: typography.lineHeightBase,
                fontFamily: typography.bodyFontFamily,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _toolCallDisplayName(
  AsyncValue<String> displayNameAsync,
  String toolName,
) => displayNameAsync.maybeWhen(
  data: (displayName) => displayName,
  orElse: () => ToolNameFormatter.formatDisplayName(
    ToolNameFormatter.parse(toolName),
    rawName: toolName,
  ),
);

String _toolCallsSummary(Iterable<String> displayNames) {
  const maximumNames = 2;
  final names = displayNames.toList(growable: false);
  final summary = names.take(maximumNames).toList();
  final remaining = names.length - summary.length;
  if (remaining > 0) summary.add('+$remaining');

  return summary.join(', ');
}

String? _latestPendingToolId(List<MessageToolCallEntity> toolCalls) {
  for (var index = toolCalls.length - 1; index >= 0; index--) {
    final toolCall = toolCalls[index];
    if (toolCall.isPending) return toolCall.id;
  }

  return null;
}

Set<String> _toggledToolIds(Set<String> expandedToolIds, String toolCallId) {
  final updated = {...expandedToolIds};
  if (!updated.add(toolCallId)) updated.remove(toolCallId);

  return updated;
}

VoidCallback? _openSubAgent({
  required BuildContext context,
  required WidgetRef ref,
  required String workspaceId,
  required String parentConversationId,
  required List<ConversationEntity> childConversations,
  required MessageToolCallEntity toolCall,
}) {
  final subAgentConversationId =
      _subAgentConversationId(toolCall) ??
      _activeSubAgentConversationId(ref, parentConversationId, toolCall) ??
      _persistedSubAgentConversationId(toolCall, childConversations);
  if (subAgentConversationId == null) return null;

  return () => SubAgentConversationRoute(
    workspaceId: workspaceId,
    chatId: parentConversationId,
    subAgentConversationId: subAgentConversationId,
  ).push(context);
}

class const _ActivityTraceDisclosure({
  required final IconData icon,
  required final String label,
  required final Color color,
  final bool isActivity = false,
  required final bool isExpanded,
  required final VoidCallback onPressed,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.auraColors;
    final typography = context.auraTheme.typography;

    return AuraPressable(
      color: color,
      decoration: isActivity
          ? BoxDecoration(
              color: colors.surfaceVariant.withValues(alpha: .5),
              borderRadius: BorderRadius.circular(
                context.auraTheme.fromBorderRadius(.md),
              ),
            )
          : null,
      onPressed: () => _toggleDisclosure(context: context, update: onPressed),
      interaction: AuraPressableInteraction.localNavigation,
      padding: const AuraEdgeInsetsGeometry.symmetric(
        horizontal: .sm,
        vertical: .xs,
      ),
      semanticLabel: label,
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const AuraSizedBox(width: .xs),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: typography.fontSizeSm,
                fontWeight: isActivity ? typography.fontWeightMedium : null,
                fontFamily: typography.bodyFontFamily,
              ),
            ),
          ),
          Icon(
            isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            size: 18,
            color: color,
          ),
        ],
      ),
    );
  }
}

class _DisclosureScrollController extends ScrollController {
  var anchorActive = false;
  _RenderDisclosureSizeReporter? _anchorReporter;
  double _pendingExtentDelta = 0;

  void beginAnchor(_RenderDisclosureSizeReporter? reporter) {
    anchorActive = true;
    _anchorReporter = reporter;
    _pendingExtentDelta = 0;
  }

  void clearAnchor() {
    anchorActive = false;
    _anchorReporter = null;
    _pendingExtentDelta = 0;
  }

  void recordExtentDelta(_RenderDisclosureSizeReporter reporter, double delta) {
    if (anchorActive && reporter == _anchorReporter) {
      _pendingExtentDelta += delta;
    }
  }

  double takeExtentDelta() {
    final delta = _pendingExtentDelta;
    _pendingExtentDelta = 0;
    return delta;
  }

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) => _DisclosureScrollPosition(
    controller: this,
    physics: physics,
    context: context,
    initialPixels: initialScrollOffset,
    keepScrollOffset: keepScrollOffset,
    oldPosition: oldPosition,
    debugLabel: debugLabel,
  );
}

class _DisclosureScrollPosition extends ScrollPositionWithSingleContext {
  _DisclosureScrollPosition({
    required this.controller,
    required super.physics,
    required super.context,
    super.initialPixels,
    super.keepScrollOffset,
    super.oldPosition,
    super.debugLabel,
  });

  final _DisclosureScrollController controller;

  @override
  bool correctForNewDimensions(
    ScrollMetrics oldPosition,
    ScrollMetrics newPosition,
  ) {
    // Correct during layout; a post-frame jump briefly paints the reverse-list
    // size change in the wrong direction.
    if (controller.anchorActive) {
      final extentDelta = controller.takeExtentDelta();
      if (extentDelta.abs() > .5) {
        final correction = axisDirection == AxisDirection.up
            ? extentDelta
            : -extentDelta;
        final targetPixels = oldPosition.pixels + correction;
        correctPixels(
          targetPixels.clamp(
            newPosition.minScrollExtent,
            newPosition.maxScrollExtent,
          ),
        );
        controller.clearAnchor();
        return false;
      }
      controller.clearAnchor();
    }

    return super.correctForNewDimensions(oldPosition, newPosition);
  }
}

class const _DisclosureSizeReporter({
  required this.controller,
  required super.child,
  super.key,
}) extends SingleChildRenderObjectWidget {
  final _DisclosureScrollController controller;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderDisclosureSizeReporter(controller);
}

class _RenderDisclosureSizeReporter extends RenderProxyBox {
  _RenderDisclosureSizeReporter(this.controller);

  final _DisclosureScrollController controller;
  double? _previousHeight;

  @override
  void performLayout() {
    super.performLayout();
    final previousHeight = _previousHeight;
    final currentHeight = size.height;
    _previousHeight = currentHeight;
    if (previousHeight != null) {
      controller.recordExtentDelta(this, currentHeight - previousHeight);
    }
  }
}

void _toggleDisclosure({
  required BuildContext context,
  required VoidCallback update,
}) {
  final position = Scrollable.maybeOf(context)?.position;
  if (position is _DisclosureScrollPosition) {
    var renderObject = context.findRenderObject();
    _RenderDisclosureSizeReporter? reporter;
    while (renderObject != null) {
      if (renderObject is _RenderDisclosureSizeReporter) {
        reporter = renderObject;
        break;
      }
      renderObject = renderObject.parent;
    }
    position.controller.beginAnchor(reporter);
  }
  update();
}

class const _ActivityToolCallRow({
  required final MessageToolCallEntity toolCall,
  required final String displayName,
  required final bool isExpanded,
  required final VoidCallback onToggle,
  required final VoidCallback? openSubAgent,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final decodedArgs = ToolMetadataDecoder.decode(toolCall.argumentsRaw);
    final decodedResponse = ToolMetadataDecoder.decode(toolCall.responseRaw);
    final hasDetails =
        decodedArgs?.isNotEmpty == true || decodedResponse?.isNotEmpty == true;
    final statusKey = _statusLocaleKey();
    final statusColor = _statusColor(context);
    final onOpenSubAgent = openSubAgent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: AuraPressable(
                key: ValueKey('activity_tool_${toolCall.id}'),
                color: statusColor,
                onPressed: hasDetails
                    ? () =>
                          _toggleDisclosure(context: context, update: onToggle)
                    : null,
                interaction: AuraPressableInteraction.localNavigation,
                padding: const AuraEdgeInsetsGeometry.symmetric(
                  horizontal: .sm,
                  vertical: .xs,
                ),
                semanticLabel: '$displayName ${statusKey.tr()}',
                child: Row(
                  children: [
                    Icon(_statusIcon(), size: 14, color: statusColor),
                    const AuraSizedBox(width: .xs),
                    Expanded(
                      child: Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: context.auraTheme.typography.fontSizeSm,
                          fontFamily:
                              context.auraTheme.typography.bodyFontFamily,
                        ),
                      ),
                    ),
                    const AuraSizedBox(width: .xs),
                    Flexible(
                      child: Text(
                        statusKey.tr(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: context.auraTheme.typography.fontSizeXs,
                          fontFamily:
                              context.auraTheme.typography.bodyFontFamily,
                        ),
                      ),
                    ),
                    if (hasDetails)
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 18,
                        color: statusColor,
                      ),
                  ],
                ),
              ),
            ),
            if (onOpenSubAgent != null)
              AuraButton(
                key: ValueKey('activity_open_sub_agent_${toolCall.id}'),
                onPressed: onOpenSubAgent,
                child: const AuraRow(
                  children: [
                    TextLocale(
                      LocaleKeys
                          .chats_screens_chat_conversation_view_sub_agent_run,
                    ),
                    AuraIcon(Icons.open_in_new, size: .small, tint: .primary),
                  ],
                  spacing: .xs,
                  mainAxisSize: .min,
                ),
                variant: .ghost,
                size: .small,
              ),
          ],
        ),
        if (isExpanded && hasDetails)
          _ActivityToolCallDetails(
            key: ValueKey('activity_tool_details_${toolCall.id}'),
            toolCall: toolCall,
            decodedArgs: decodedArgs,
            decodedResponse: decodedResponse,
          ),
      ],
    );
  }

  String _statusLocaleKey() {
    final status = toolCall.resultStatus;
    if (status != null) return status.localeKey;

    return LocaleKeys.tool_call_status_pending;
  }

  IconData _statusIcon() {
    final status = toolCall.resultStatus;
    if (status == null) {
      return Icons.hourglass_empty;
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

  Color _statusColor(BuildContext context) {
    final status = toolCall.resultStatus;
    final colors = context.auraColors;
    if (status == null) {
      return colors.warning;
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

class const _ActivityToolCallDetails({
  required final MessageToolCallEntity toolCall,
  required final String? decodedArgs,
  required final String? decodedResponse,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = context.auraTheme;
    final colors = context.auraColors;

    return Padding(
      padding: EdgeInsets.only(
        left: theme.fromSpacing(.sm),
        top: theme.fromSpacing(.xs),
        bottom: theme.fromSpacing(.xs),
      ),
      child: SelectionArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (decodedArgs case final value? when value.isNotEmpty)
              _ActivityToolCallDetail(
                label: LocaleKeys
                    .chats_screens_chat_conversation_activity_arguments,
                child: Text(
                  value,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: theme.typography.fontSizeXs,
                    fontFamily: theme.typography.monoFontFamily,
                  ),
                ),
              ),
            if (decodedResponse case final value? when value.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: theme.fromSpacing(.xs)),
                child: _ActivityToolCallDetail(
                  label: LocaleKeys
                      .chats_screens_chat_conversation_activity_result,
                  child: AuraContainer(
                    key: ValueKey('activity_tool_result_${toolCall.id}'),
                    variant: AuraContainerVariant.surfaceVariant,
                    padding: .small,
                    borderRadius: 8,
                    child: ToolCallResponsePreview(
                      toolName: toolCall.name,
                      content: value,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class const _ActivityToolCallDetail({
  required final String label,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextLocale(
        label,
        style: TextStyle(
          color: context.auraColors.onSurfaceVariant,
          fontSize: context.auraTheme.typography.fontSizeXs,
          fontWeight: FontWeight.w600,
          fontFamily: context.auraTheme.typography.bodyFontFamily,
        ),
      ),
      const AuraSizedBox(height: .xs),
      child,
    ],
  );
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
