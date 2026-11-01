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

  List<ActivityRunEntry> buildEntries() =>
      _ActivityRunEntryBuilder(this).build();
}

typedef ActivityToolCall = ({
  String messageId,
  MessageToolCallEntity toolCall,
  bool isForkReference,
  bool isStreaming,
  bool hideArguments,
});

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

class _ActivityRunEntryBuilder(final ActivityRun run) {
  final _entries = <ActivityRunEntry>[];
  final _toolCalls = <ActivityToolCall>[];

  List<ActivityRunEntry> build() {
    for (final source in run.sources) {
      _appendThinkingEntry(source);
      _appendResponseEntries(source);
      _appendToolCalls(source);
    }
    _appendToolGroup();

    return _entries;
  }

  void _appendThinkingEntry(ResolvedChatMessage source) {
    final thinking = source.message.metadata?.thinking?.trim();
    if (thinking == null || thinking.isEmpty) return;
    _appendToolGroup();
    _entries.add(
      ActivityThinkingEntry(messageId: source.message.id, content: thinking),
    );
  }

  void _appendResponseEntries(ResolvedChatMessage source) {
    if (_appendFinalResponse(source)) return;
    if (_appendRichResponse(source)) return;
    _appendNarrative(source);
  }

  bool _appendFinalResponse(ResolvedChatMessage source) {
    if (run.responseMessageId != source.message.id) return false;
    _entries.add(ActivityResponseEntry(source, isFinal: true));

    return true;
  }

  bool _appendRichResponse(ResolvedChatMessage source) {
    if (!run.richResponseMessageIds.contains(source.message.id)) return false;
    _appendToolGroup();
    _entries.add(ActivityResponseEntry(source, isFinal: false));

    return true;
  }

  void _appendNarrative(ResolvedChatMessage source) {
    final entry = ChatTimelineProjection._activityNarrativeEntry(run, source);
    if (entry == null) return;
    _appendToolGroup();
    _entries.add(entry);
  }

  void _appendToolCalls(ResolvedChatMessage source) {
    final messageId = source.message.id;
    for (final toolCall
        in source.message.metadata?.toolCalls ??
            const <MessageToolCallEntity>[]) {
      _toolCalls.add(_activityToolCall(source, toolCall, messageId));
    }
  }

  ActivityToolCall _activityToolCall(
    ResolvedChatMessage source,
    MessageToolCallEntity toolCall,
    String messageId,
  ) => (
    messageId: messageId,
    toolCall: toolCall,
    isForkReference: source.message.isForkReference,
    isStreaming: source.isStreaming,
    hideArguments: run.pendingToolCallKeys.contains(
      ChatTimelineProjection.activityToolCallKey(messageId, toolCall.id),
    ),
  );

  void _appendToolGroup() {
    if (_toolCalls.isEmpty) return;
    _entries.add(ActivityToolGroupEntry(.of(_toolCalls)));
    _toolCalls.clear();
  }
}

abstract final class ChatTimelineProjection {
  static String activityToolCallKey(String messageId, String toolCallId) =>
      '$messageId:$toolCallId';

  static bool hasAssistantResponseCandidate(
    ResolvedChatMessage source,
    Map<String, List<String>> replayPayloadsByMessageId,
  ) {
    if (ChatTimelineMessagePolicy._hasVisibleAssistantResponse(
      source.message,
      replayPayloadsByMessageId,
    )) {
      return true;
    }

    return source.isStreaming &&
        source.message.metadata?.toolCalls.isNotEmpty != true;
  }

  static List<ChatTimelineItem> buildChatTimelineItems(
    List<ResolvedChatMessage?> messages,
    Map<String, List<String>> replayPayloadsByMessageId, {
    Set<String> pendingToolCallKeys = const {},
    String? searchTargetMessageId,
  }) => _ChatTimelineBuilder(
    messages: messages,
    replayPayloadsByMessageId: replayPayloadsByMessageId,
    pendingToolCallKeys: pendingToolCallKeys,
    searchTargetMessageId: searchTargetMessageId,
  ).build();

  static bool _shouldRenderMessageForActivity(
    bool requiresMessageItem,
    bool awaitsA2uiAction,
    bool isFinalResponse,
  ) => requiresMessageItem && (awaitsA2uiAction || isFinalResponse);

  static MessageTimelineItem _activityMessageItem(
    ResolvedChatMessage source,
    bool isFinalResponse,
  ) => MessageTimelineItem(
    source,
    activityRenderedInSession: true,
    showResponseActions: isFinalResponse && !source.isStreaming,
  );

  static ActivityNarrativeEntry? _activityNarrativeEntry(
    ActivityRun run,
    ResolvedChatMessage source,
  ) {
    final messageId = source.message.id;
    final content = source.message.content.trim();
    if (!run.activityContentMessageIds.contains(messageId) || content.isEmpty) {
      return null;
    }

    return ActivityNarrativeEntry(messageId: messageId, content: content);
  }

  static _ResponseFacts _responseFacts(
    MessageEntity message,
    Map<String, List<String>> replayPayloadsByMessageId,
  ) => (
    hasVisibleResponse: ChatTimelineMessagePolicy._hasVisibleAssistantResponse(
      message,
      replayPayloadsByMessageId,
    ),
    requiresMessageItem: ChatTimelineMessagePolicy._requiresMessageTimelineItem(
      message,
      replayPayloadsByMessageId,
    ),
  );

  static _MessageSequenceFacts _messageSequenceFacts(
    MessageEntity message,
    List<ResolvedChatMessage?> messages,
    int index,
  ) => (
    hasFollowingAssistantActivity:
        ChatTimelineMessagePolicy._hasFollowingAssistantActivity(
          messages,
          index,
        ),
    hasToolCalls: message.metadata?.toolCalls.isNotEmpty == true,
  );
}

abstract final class ChatTimelineMessagePolicy {
  static bool hasA2uiMessageState(MessageEntity? message) {
    if (message == null || message.isUser || message.isForkReference) {
      return false;
    }
    final metadata = message.metadata;
    if (metadata == null) return false;

    return metadata.a2uiMessages.isNotEmpty ||
        metadata.a2uiIssuesBySurface.isNotEmpty ||
        metadata.a2uiMessageIssues.isNotEmpty;
  }

  static bool isAwaitingA2uiAction(MessageEntity message) =>
      message.status == .unfinished && hasA2uiMessageState(message);

  static bool hasAssistantActivity(MessageEntity message) =>
      message.metadata?.thinking?.trim().isNotEmpty == true ||
      message.metadata?.toolCalls.isNotEmpty == true;

  static bool isTimelineBoundary(MessageEntity message) =>
      message.isUser ||
      message.messageType == .system ||
      message.status == .error ||
      message.metadata?.isCompactionSummary == true;

  static bool _hasFollowingAssistantActivity(
    List<ResolvedChatMessage?> messages,
    int index,
  ) {
    if (index + 1 >= messages.length) return false;
    final next = messages[index + 1];

    return next == null || !isTimelineBoundary(next.message);
  }

  static bool _hasVisibleAssistantResponse(
    MessageEntity message,
    Map<String, List<String>> replayPayloadsByMessageId,
  ) =>
      message.content.trim().isNotEmpty ||
      _requiresMessageTimelineItem(message, replayPayloadsByMessageId);

  static bool _requiresMessageTimelineItem(
    MessageEntity message,
    Map<String, List<String>> replayPayloadsByMessageId,
  ) =>
      message.attachments.isNotEmpty ||
      hasA2uiMessageState(message) ||
      replayPayloadsByMessageId[message.id]?.isNotEmpty == true ||
      message.metadata?.modelMetadata['a2uiDiagnosticPayloads'] is List;

  static bool _hasActivity(MessageEntity message, _MessageFacts facts) =>
      !isTimelineBoundary(message) &&
      (hasAssistantActivity(message) ||
          (facts.hasVisibleResponse && facts.hasFollowingAssistantActivity));

  static bool _isFinalResponse(MessageEntity message, _MessageFacts facts) =>
      message.status == .sent &&
      facts.hasVisibleResponse &&
      !facts.hasFollowingAssistantActivity &&
      !facts.hasToolCalls;
}

abstract final class ChatTimelineRetryPolicy {
  static String? retryableUserMessageId(List<ResolvedChatMessage?> messages) {
    for (final source in messages.reversed) {
      final message = source?.message;
      if (message == null || !message.isUser) continue;

      return canRetryUserMessage(message) ? message.id : null;
    }

    return null;
  }

  static bool canRetryUserMessage(MessageEntity message) =>
      message.isUser &&
      !message.isForkReference &&
      message.hasValidContent &&
      (message.status == .unfinished ||
          (message.status == .error &&
              ProviderRecoveryMetadata.isRetryEligible(message)));
}

typedef _MessageFacts = ({
  bool hasVisibleResponse,
  bool hasFollowingAssistantActivity,
  bool hasToolCalls,
  bool requiresMessageItem,
});

typedef _ResponseFacts = ({bool hasVisibleResponse, bool requiresMessageItem});

typedef _MessageSequenceFacts = ({
  bool hasFollowingAssistantActivity,
  bool hasToolCalls,
});

typedef _MessageProjection = ({
  _MessageFacts facts,
  bool hasActivity,
  bool awaitsA2uiAction,
  bool isFinalResponse,
});

class _ActivityRunBuffer(final Set<String> pendingToolCallKeys) {
  final sources = <ResolvedChatMessage>[];
  final activityContentMessageIds = <String>{};
  final richResponseMessageIds = <String>{};

  bool get isEmpty => sources.isEmpty;

  ActivityRun build({String? responseMessageId}) => ActivityRun(
    .of(sources),
    activityContentMessageIds: .of(activityContentMessageIds),
    richResponseMessageIds: .of(richResponseMessageIds),
    pendingToolCallKeys: pendingToolCallKeys,
    responseMessageId: responseMessageId,
  );

  void clear() {
    sources.clear();
    activityContentMessageIds.clear();
    richResponseMessageIds.clear();
  }
}

class _ChatTimelineBuilder({
  required final List<ResolvedChatMessage?> messages,
  required final Map<String, List<String>> replayPayloadsByMessageId,
  required final Set<String> pendingToolCallKeys,
  required final String? searchTargetMessageId,
}) {
  late final _ActivityRunBuffer _activityRun = _ActivityRunBuffer(
    pendingToolCallKeys,
  );
  final _items = <ChatTimelineItem>[];

  List<ChatTimelineItem> build() {
    for (var index = 0; index < messages.length; index++) {
      _projectMessage(messages[index], index);
    }
    _flushActivityRun();

    return _items;
  }

  void _projectMessage(ResolvedChatMessage? source, int index) {
    if (source == null) {
      _flushActivityRun();

      return;
    }
    if (source.message.id == searchTargetMessageId) {
      _flushActivityRun();
      _items.add(MessageTimelineItem(source));

      return;
    }

    _projectResolvedMessage(source, index);
  }

  void _projectResolvedMessage(ResolvedChatMessage source, int index) {
    final projection = _messageProjection(source, index);
    if (projection.hasActivity) {
      _projectActivityMessage(source, projection);

      return;
    }

    _flushActivityRun();
    final message = source.message;
    _items.add(
      MessageTimelineItem(
        source,
        showResponseActions:
            message.isUser || (!source.isStreaming && message.status == .sent),
      ),
    );
  }

  _MessageProjection _messageProjection(ResolvedChatMessage source, int index) {
    final message = source.message;
    final facts = _messageFacts(source, index);

    return (
      facts: facts,
      hasActivity: ChatTimelineMessagePolicy._hasActivity(message, facts),
      awaitsA2uiAction: ChatTimelineMessagePolicy.isAwaitingA2uiAction(message),
      isFinalResponse: ChatTimelineMessagePolicy._isFinalResponse(
        message,
        facts,
      ),
    );
  }

  _MessageFacts _messageFacts(ResolvedChatMessage source, int index) {
    final message = source.message;
    final responseFacts = ChatTimelineProjection._responseFacts(
      message,
      replayPayloadsByMessageId,
    );
    final sequenceFacts = ChatTimelineProjection._messageSequenceFacts(
      message,
      messages,
      index,
    );

    return (
      hasVisibleResponse: responseFacts.hasVisibleResponse,
      hasFollowingAssistantActivity:
          sequenceFacts.hasFollowingAssistantActivity,
      hasToolCalls: sequenceFacts.hasToolCalls,
      requiresMessageItem: responseFacts.requiresMessageItem,
    );
  }

  void _projectActivityMessage(
    ResolvedChatMessage source,
    _MessageProjection projection,
  ) {
    final message = source.message;
    if (_appendMessageItemForActivity(source, projection)) return;

    _activityRun.sources.add(source);
    _appendActivityContent(source, projection);
    if (projection.isFinalResponse) {
      _flushActivityRun(responseMessageId: message.id);
    }
  }

  bool _appendMessageItemForActivity(
    ResolvedChatMessage source,
    _MessageProjection projection,
  ) {
    final shouldAppend = ChatTimelineProjection._shouldRenderMessageForActivity(
      projection.facts.requiresMessageItem,
      projection.awaitsA2uiAction,
      projection.isFinalResponse,
    );
    if (!shouldAppend) return false;

    _activityRun.sources.add(source);
    _flushActivityRun();
    _items.add(
      ChatTimelineProjection._activityMessageItem(
        source,
        projection.isFinalResponse,
      ),
    );

    return true;
  }

  void _appendActivityContent(
    ResolvedChatMessage source,
    _MessageProjection projection,
  ) {
    if (!projection.facts.hasVisibleResponse || projection.isFinalResponse) {
      return;
    }
    if (projection.facts.requiresMessageItem) {
      final _ = _activityRun.richResponseMessageIds.add(source.message.id);
    } else {
      final _ = _activityRun.activityContentMessageIds.add(source.message.id);
    }
  }

  void _flushActivityRun({String? responseMessageId}) {
    if (_activityRun.isEmpty) return;
    final run = _activityRun.build(responseMessageId: responseMessageId);
    if (run.buildEntries().isNotEmpty) _items.add(ActivityRunTimelineItem(run));
    _activityRun.clear();
  }
}
