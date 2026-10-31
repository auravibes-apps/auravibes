import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/entities/provider_recovery_metadata.dart';

/// A message together with the transient streaming state used by the timeline.
class const ResolvedChatMessage({
  required final MessageEntity message,
  required final bool isStreaming,
});

sealed class const ChatTimelineItem();

class const ActivityRunTimelineItem(final ActivityRun run)
    extends ChatTimelineItem;

class const MessageTimelineItem(
  final ResolvedChatMessage source, {
  final bool activityRenderedInSession = false,
  final bool showResponseActions = true,
}) extends ChatTimelineItem;

class const ActivityRun(
  final List<ResolvedChatMessage> sources, {
  final Set<String> activityContentMessageIds = const {},
  final Set<String> richResponseMessageIds = const {},
  final Set<String> pendingToolCallKeys = const {},
  final String? responseMessageId,
}) {
  String get id =>
      sources.firstOrNull?.message.id ??
      (throw StateError('An activity run must contain a message source.'));
}

typedef ActivityToolCall = ({
  String messageId,
  MessageToolCallEntity toolCall,
  bool isForkReference,
  bool isStreaming,
  bool hideArguments,
});

String activityToolCallKey(String messageId, String toolCallId) =>
    '$messageId:$toolCallId';

sealed class const ActivityRunEntry();

class const ActivityNarrativeEntry({
  required final String messageId,
  required final String content,
}) extends ActivityRunEntry;

class const ActivityThinkingEntry({
  required final String messageId,
  required final String content,
}) extends ActivityRunEntry;

class const ActivityResponseEntry(
  final ResolvedChatMessage source, {
  required final bool isFinal,
}) extends ActivityRunEntry;

class const ActivityToolGroupEntry(final List<ActivityToolCall> toolCalls)
    extends ActivityRunEntry;

List<ActivityRunEntry> buildActivityRunEntries(ActivityRun run) {
  final entries = <ActivityRunEntry>[];
  final toolCalls = <ActivityToolCall>[];

  void addToolGroup() {
    if (toolCalls.isEmpty) return;
    entries.add(ActivityToolGroupEntry(.of(toolCalls)));
    toolCalls.clear();
  }

  for (final source in run.sources) {
    final messageId = source.message.id;

    final thinking = source.message.metadata?.thinking?.trim();
    if (thinking != null && thinking.isNotEmpty) {
      addToolGroup();
      entries.add(
        ActivityThinkingEntry(messageId: messageId, content: thinking),
      );
    }

    if (run.responseMessageId == messageId) {
      entries.add(ActivityResponseEntry(source, isFinal: true));
    } else if (run.richResponseMessageIds.contains(messageId)) {
      addToolGroup();
      entries.add(ActivityResponseEntry(source, isFinal: false));
    } else if (run.activityContentMessageIds.contains(messageId)) {
      final content = source.message.content.trim();
      if (content.isNotEmpty) {
        addToolGroup();
        entries.add(
          ActivityNarrativeEntry(messageId: messageId, content: content),
        );
      }
    }

    for (final toolCall
        in source.message.metadata?.toolCalls ??
            const <MessageToolCallEntity>[]) {
      toolCalls.add((
        messageId: messageId,
        toolCall: toolCall,
        isForkReference: source.message.isForkReference,
        isStreaming: source.isStreaming,
        hideArguments: run.pendingToolCallKeys.contains(
          activityToolCallKey(messageId, toolCall.id),
        ),
      ));
    }
  }
  addToolGroup();

  return entries;
}

List<ChatTimelineItem> buildChatTimelineItems(
  List<ResolvedChatMessage?> messages,
  Map<String, List<String>> replayPayloadsByMessageId, {
  Set<String> pendingToolCallKeys = const {},
  String? searchTargetMessageId,
}) {
  final items = <ChatTimelineItem>[];
  final activitySources = <ResolvedChatMessage>[];
  final activityContentMessageIds = <String>{};
  final richResponseMessageIds = <String>{};

  void addActivityRun({String? responseMessageId}) {
    if (activitySources.isEmpty) return;
    final run = ActivityRun(
      .of(activitySources),
      activityContentMessageIds: .of(activityContentMessageIds),
      richResponseMessageIds: .of(richResponseMessageIds),
      pendingToolCallKeys: pendingToolCallKeys,
      responseMessageId: responseMessageId,
    );
    if (buildActivityRunEntries(run).isNotEmpty) {
      items.add(ActivityRunTimelineItem(run));
    }
    activitySources.clear();
    activityContentMessageIds.clear();
    richResponseMessageIds.clear();
  }

  for (var index = 0; index < messages.length; index++) {
    final source = messages[index];
    if (source == null) {
      addActivityRun();
      continue;
    }

    final message = source.message;
    if (message.id == searchTargetMessageId) {
      addActivityRun();
      items.add(MessageTimelineItem(source));
      continue;
    }
    final hasVisibleResponse = _hasVisibleAssistantResponse(
      message,
      replayPayloadsByMessageId,
    );
    final hasFollowingAssistantActivity = _hasFollowingAssistantActivity(
      messages,
      index,
    );
    final hasToolCalls = message.metadata?.toolCalls.isNotEmpty == true;
    final requiresMessageItem = _requiresMessageTimelineItem(
      message,
      replayPayloadsByMessageId,
    );
    final hasActivity =
        !isTimelineBoundary(message) &&
        (hasAssistantActivity(message) ||
            (hasVisibleResponse && hasFollowingAssistantActivity));

    if (hasActivity) {
      final awaitsA2uiAction =
          message.status == .unfinished && hasA2uiMessageState(message);
      final isFinalResponse =
          message.status == .sent &&
          hasVisibleResponse &&
          !hasFollowingAssistantActivity &&
          !hasToolCalls;
      if (requiresMessageItem && (awaitsA2uiAction || isFinalResponse)) {
        activitySources.add(source);
        addActivityRun();
        items.add(
          MessageTimelineItem(
            source,
            activityRenderedInSession: true,
            showResponseActions: isFinalResponse && !source.isStreaming,
          ),
        );
        continue;
      }
      activitySources.add(source);
      if (hasVisibleResponse && !isFinalResponse) {
        if (requiresMessageItem) {
          final _ = richResponseMessageIds.add(message.id);
        } else {
          final _ = activityContentMessageIds.add(message.id);
        }
      }
      if (isFinalResponse) {
        addActivityRun(responseMessageId: message.id);
      }
      continue;
    }

    addActivityRun();
    items.add(
      MessageTimelineItem(
        source,
        showResponseActions:
            message.isUser || (!source.isStreaming && message.status == .sent),
      ),
    );
  }
  addActivityRun();

  return items;
}

bool hasAssistantResponseCandidate(
  ResolvedChatMessage source,
  Map<String, List<String>> replayPayloadsByMessageId,
) {
  if (_hasVisibleAssistantResponse(source.message, replayPayloadsByMessageId)) {
    return true;
  }

  return source.isStreaming &&
      source.message.metadata?.toolCalls.isNotEmpty != true;
}

String? retryableUserMessageId(List<ResolvedChatMessage?> messages) {
  for (final source in messages.reversed) {
    final message = source?.message;
    if (message == null || !message.isUser) continue;

    return canRetryUserMessage(message) ? message.id : null;
  }

  return null;
}

bool canRetryUserMessage(MessageEntity message) =>
    message.isUser &&
    !message.isForkReference &&
    message.hasValidContent &&
    (message.status == .unfinished ||
        (message.status == .error &&
            ProviderRecoveryMetadata.isRetryEligible(message)));

bool hasA2uiMessageState(MessageEntity? message) {
  if (message == null || message.isUser || message.isForkReference) {
    return false;
  }
  final metadata = message.metadata;
  if (metadata == null) return false;

  return metadata.a2uiMessages.isNotEmpty ||
      metadata.a2uiIssuesBySurface.isNotEmpty ||
      metadata.a2uiMessageIssues.isNotEmpty;
}

bool _hasFollowingAssistantActivity(
  List<ResolvedChatMessage?> messages,
  int index,
) {
  if (index + 1 >= messages.length) return false;
  final next = messages[index + 1];

  return next == null || !isTimelineBoundary(next.message);
}

bool hasAssistantActivity(MessageEntity message) =>
    message.metadata?.thinking?.trim().isNotEmpty == true ||
    message.metadata?.toolCalls.isNotEmpty == true;

bool _hasVisibleAssistantResponse(
  MessageEntity message,
  Map<String, List<String>> replayPayloadsByMessageId,
) =>
    message.content.trim().isNotEmpty ||
    _requiresMessageTimelineItem(message, replayPayloadsByMessageId);

bool _requiresMessageTimelineItem(
  MessageEntity message,
  Map<String, List<String>> replayPayloadsByMessageId,
) =>
    message.attachments.isNotEmpty ||
    hasA2uiMessageState(message) ||
    replayPayloadsByMessageId[message.id]?.isNotEmpty == true ||
    message.metadata?.modelMetadata['a2uiDiagnosticPayloads'] is List;

bool isTimelineBoundary(MessageEntity message) =>
    message.isUser ||
    message.messageType == .system ||
    message.status == .error ||
    message.metadata?.isCompactionSummary == true;
