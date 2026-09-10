import 'dart:convert';

import 'package:auravibes_server_client/auravibes_server_client.dart';

/// The server-authoritative projection of one shared cloud conversation.
class const CloudConversationState({
  required final ConversationProjectionView conversation,
  required final List<ConversationMessageView> messages,
  required final List<ConversationMessageView> pendingMessages,
  required final ConversationExecutionView? activeExecution,
  required final List<ConversationToolCallView> toolCalls,
  required final int sequence,
  final String activeAssistantContent = '',

  /// Snapshot content plus transient text received since that snapshot.
  final String activeAssistantTransientContent = '',
  final Map<String, List<String>> a2uiMessagesByAssistantMessageId = const {},
  final Map<String, Map<String, List<String>>> a2uiIssuesByAssistantMessageId =
      const {},
  final Map<String, List<String>> a2uiMessageIssuesByAssistantMessageId =
      const {},
  final Map<String, int> transientA2uiSequenceByAssistantMessageId = const {},
  final Set<String> appliedTransientEventKeys = const {},
}) {
  const CloudConversationState._copy(
    CloudConversationState source, {
    required this.sequence,
    required this.activeAssistantContent,
    required this.activeAssistantTransientContent,
    required this.transientA2uiSequenceByAssistantMessageId,
    required this.appliedTransientEventKeys,
  }) : conversation = source.conversation,
       messages = source.messages,
       pendingMessages = source.pendingMessages,
       activeExecution = source.activeExecution,
       toolCalls = source.toolCalls,
       a2uiMessagesByAssistantMessageId =
           source.a2uiMessagesByAssistantMessageId,
       a2uiIssuesByAssistantMessageId = source.a2uiIssuesByAssistantMessageId,
       a2uiMessageIssuesByAssistantMessageId =
           source.a2uiMessageIssuesByAssistantMessageId;

  factory fromSnapshot(ConversationSnapshot snapshot) => CloudConversationState(
    conversation: snapshot.conversation,
    messages: snapshot.messages,
    pendingMessages: snapshot.pendingMessages,
    activeExecution: snapshot.activeExecution,
    toolCalls: snapshot.toolCalls,
    sequence: snapshot.sequence,
    a2uiMessagesByAssistantMessageId: _a2uiMessagesByAssistantId(
      snapshot.messages,
    ),
    a2uiIssuesByAssistantMessageId: _a2uiIssuesByAssistantId(snapshot.messages),
    a2uiMessageIssuesByAssistantMessageId: _a2uiMessageIssuesByAssistantId(
      snapshot.messages,
    ),
  );

  /// Complete text currently visible for the active assistant message.
  String get activeAssistantRenderedContent => activeAssistantContent;

  CloudConversationState preserveTransientA2uiFrom(
    CloudConversationState previous,
  ) => CloudConversationState(
    conversation: conversation,
    messages: messages,
    pendingMessages: pendingMessages,
    activeExecution: activeExecution,
    toolCalls: toolCalls,
    sequence: sequence,
    activeAssistantContent: activeAssistantContent,
    activeAssistantTransientContent: activeAssistantTransientContent,
    a2uiMessagesByAssistantMessageId: {
      ..._retainedPreviousA2uiMessages(this, previous),
      ..._retainedCurrentA2uiMessages(this, previous),
    },
    a2uiIssuesByAssistantMessageId: _preservedIssues(this, previous),
    a2uiMessageIssuesByAssistantMessageId: _preservedMessageIssues(
      this,
      previous,
    ),
    transientA2uiSequenceByAssistantMessageId: _preservedTransientSequences(
      this,
      previous,
    ),
    appliedTransientEventKeys: _preservedEventKeys(this, previous),
  );

  /// Applies only the next event in the durable ordering.
  CloudConversationState? apply(ConversationStreamEvent event) {
    if (event.kind == ConversationEventType.a2uiMessage) {
      return _applyA2uiMessage(event);
    }

    return _applyTextEvent(event);
  }
}

extension on CloudConversationState {
  CloudConversationState? _applyA2uiMessage(ConversationStreamEvent event) {
    if (event.sequence != sequence) return null;
    final assistantMessageId =
        _assistantMessageId(event.payloadJson) ??
        activeExecution?.assistantMessageId;
    if (assistantMessageId == null) return null;
    final messages = a2uiMessagesByAssistantMessageId[assistantMessageId];
    if (messages?.contains(event.payloadJson) ?? false) return this;

    return _withA2uiMessage(event, assistantMessageId);
  }

  CloudConversationState? _applyTextEvent(ConversationStreamEvent event) {
    final delta = event.transientTextDelta;
    final isTransientDelta = delta != null;
    if (!_isExpectedTextEvent(event, sequence, isTransientDelta)) return null;
    final transientEventKey = _transientEventKey(event, delta);
    if (_isAppliedTransientEvent(
      appliedTransientEventKeys,
      transientEventKey,
    )) {
      return this;
    }

    return _applyExpectedTextEvent((
      event: event,
      delta: delta,
      isTransientDelta: isTransientDelta,
      transientEventKey: transientEventKey,
    ));
  }

  CloudConversationState _applyExpectedTextEvent(_TextEventRequest request) {
    final textContent = _textContent((
      isTransientDelta: request.isTransientDelta,
      delta: request.delta,
      baseContent: request.isTransientDelta
          ? _activeAssistantBaseContent()
          : '',
      transientContent: activeAssistantTransientContent,
    ));

    return _withTextEvent((
      event: request.event,
      textContent: textContent,
      isTransientDelta: request.isTransientDelta,
      transientEventKey: request.transientEventKey,
    ));
  }

  CloudConversationState _withA2uiMessage(
    ConversationStreamEvent event,
    String assistantMessageId,
  ) => CloudConversationState(
    conversation: conversation,
    messages: messages,
    pendingMessages: pendingMessages,
    activeExecution: activeExecution,
    toolCalls: toolCalls,
    sequence: sequence,
    activeAssistantContent: activeAssistantContent,
    activeAssistantTransientContent: activeAssistantTransientContent,
    a2uiMessagesByAssistantMessageId: _appendA2uiMessage(
      a2uiMessagesByAssistantMessageId,
      assistantMessageId,
      event.payloadJson,
    ),
    a2uiIssuesByAssistantMessageId: a2uiIssuesByAssistantMessageId,
    a2uiMessageIssuesByAssistantMessageId:
        a2uiMessageIssuesByAssistantMessageId,
    transientA2uiSequenceByAssistantMessageId: {
      ...transientA2uiSequenceByAssistantMessageId,
      assistantMessageId: sequence,
    },
    appliedTransientEventKeys: appliedTransientEventKeys,
  );

  CloudConversationState _withTextEvent(_TextEventStateRequest request) =>
      CloudConversationState._copy(
        this,
        sequence: request.event.sequence,
        activeAssistantContent: request.textContent.active,
        activeAssistantTransientContent: request.textContent.transient,
        transientA2uiSequenceByAssistantMessageId: request.isTransientDelta
            ? transientA2uiSequenceByAssistantMessageId
            : const {},
        appliedTransientEventKeys: _eventKeysForTextEvent(
          request.isTransientDelta,
          request.transientEventKey,
        ),
      );

  String? _transientEventKey(ConversationStreamEvent event, String? delta) {
    if (delta == null) return null;

    return event.eventId ??
        '${event.sequence}:${event.createdAt.microsecondsSinceEpoch}:$delta';
  }

  String _activeAssistantBaseContent() {
    final assistantMessageId = activeExecution?.assistantMessageId;
    if (assistantMessageId == null) return '';
    for (final message in messages) {
      if (message.id == assistantMessageId) return message.content;
    }

    return '';
  }
}

typedef _TextContentRequest = ({
  bool isTransientDelta,
  String? delta,
  String baseContent,
  String transientContent,
});

typedef _TextContent = ({String active, String transient});

typedef _TextEventRequest = ({
  ConversationStreamEvent event,
  String? delta,
  bool isTransientDelta,
  String? transientEventKey,
});

typedef _TextEventStateRequest = ({
  ConversationStreamEvent event,
  _TextContent textContent,
  bool isTransientDelta,
  String? transientEventKey,
});

Map<String, List<String>> _appendA2uiMessage(
  Map<String, List<String>> messages,
  String assistantMessageId,
  String payload,
) => {
  ...messages,
  assistantMessageId: [...?messages[assistantMessageId], payload],
};

bool _isExpectedTextEvent(
  ConversationStreamEvent event,
  int sequence,
  bool isTransient,
) => isTransient ? event.sequence == sequence : event.sequence == sequence + 1;

bool _isAppliedTransientEvent(
  Set<String> appliedEventKeys,
  String? transientEventKey,
) => transientEventKey != null && appliedEventKeys.contains(transientEventKey);

_TextContent _textContent(_TextContentRequest request) => (
  active: request.isTransientDelta
      ? '${request.baseContent}${request.transientContent}${request.delta}'
      : '',
  transient: request.isTransientDelta
      ? '${request.transientContent}${request.delta}'
      : '',
);

Map<String, List<String>> _a2uiMessagesByAssistantId(
  Iterable<ConversationMessageView> messages,
) => {
  for (final message in messages)
    if (_a2uiMessages(message.metadataJson) case final values
        when values.isNotEmpty)
      message.id: values,
};

Map<String, Map<String, List<String>>> _a2uiIssuesByAssistantId(
  Iterable<ConversationMessageView> messages,
) => {
  for (final message in messages)
    if (_a2uiIssues(message.metadataJson) case final values
        when values.isNotEmpty)
      message.id: values,
};

Map<String, List<String>> _a2uiMessageIssuesByAssistantId(
  Iterable<ConversationMessageView> messages,
) => {
  for (final message in messages)
    if (_a2uiMessageIssues(message.metadataJson) case final values
        when values.isNotEmpty)
      message.id: values,
};

Map<String, List<String>> _retainedPreviousA2uiMessages(
  CloudConversationState current,
  CloudConversationState previous,
) => {
  for (final entry in previous.a2uiMessagesByAssistantMessageId.entries)
    if ((previous.transientA2uiSequenceByAssistantMessageId[entry.key] ?? -1) >=
        current.sequence)
      entry.key: {
        ...entry.value,
        ...?current.a2uiMessagesByAssistantMessageId[entry.key],
      }.toList(),
};

Map<String, List<String>> _retainedCurrentA2uiMessages(
  CloudConversationState current,
  CloudConversationState previous,
) => {
  for (final entry in current.a2uiMessagesByAssistantMessageId.entries)
    if ((previous.transientA2uiSequenceByAssistantMessageId[entry.key] ?? -1) <
        current.sequence)
      entry.key: entry.value,
};

Map<String, Map<String, List<String>>> _preservedIssues(
  CloudConversationState current,
  CloudConversationState previous,
) => {
  ...current.a2uiIssuesByAssistantMessageId,
  for (final entry in previous.a2uiIssuesByAssistantMessageId.entries)
    if ((previous.transientA2uiSequenceByAssistantMessageId[entry.key] ?? -1) >=
        current.sequence)
      entry.key: entry.value,
};

Map<String, List<String>> _preservedMessageIssues(
  CloudConversationState current,
  CloudConversationState previous,
) => {
  ...current.a2uiMessageIssuesByAssistantMessageId,
  for (final entry in previous.a2uiMessageIssuesByAssistantMessageId.entries)
    if ((previous.transientA2uiSequenceByAssistantMessageId[entry.key] ?? -1) >=
        current.sequence)
      entry.key: entry.value,
};

Map<String, int> _preservedTransientSequences(
  CloudConversationState current,
  CloudConversationState previous,
) => {
  ...current.transientA2uiSequenceByAssistantMessageId,
  for (final entry
      in previous.transientA2uiSequenceByAssistantMessageId.entries)
    if (entry.value >= current.sequence) entry.key: entry.value,
};

Set<String> _preservedEventKeys(
  CloudConversationState current,
  CloudConversationState previous,
) => current.sequence == previous.sequence
    ? {
        ...previous.appliedTransientEventKeys,
        ...current.appliedTransientEventKeys,
      }
    : current.appliedTransientEventKeys;

Set<String> _eventKeysForTextEvent(
  bool isTransientDelta,
  String? transientEventKey,
) => isTransientDelta && transientEventKey != null
    ? {transientEventKey}
    : const {};

List<String> _a2uiMessages(String? metadataJson) {
  if (metadataJson == null) return const [];
  try {
    final metadata = jsonDecode(metadataJson);
    final messages = metadata is Map ? metadata['a2uiMessages'] : null;

    return messages is List ? messages.whereType<String>().toList() : const [];
  } on Object catch (_) {
    return const [];
  }
}

Map<String, List<String>> _a2uiIssues(String? metadataJson) {
  if (metadataJson == null) return const {};
  try {
    final metadata = jsonDecode(metadataJson);
    final issues = metadata is Map ? metadata['a2uiIssuesBySurface'] : null;
    if (issues is! Map) return const {};

    return _stringListMap(issues);
  } on Object catch (_) {
    return const {};
  }
}

Map<String, List<String>> _stringListMap(Map<dynamic, dynamic> values) => {
  for (final entry in values.entries)
    if (entry.key is String && entry.value is List)
      entry.key as String: (entry.value as List).whereType<String>().toList(),
};

List<String> _a2uiMessageIssues(String? metadataJson) {
  if (metadataJson == null) return const [];
  try {
    final metadata = jsonDecode(metadataJson);
    final issues = metadata is Map ? metadata['a2uiMessageIssues'] : null;

    return issues is List ? issues.whereType<String>().toList() : const [];
  } on Object catch (_) {
    return const [];
  }
}

String? _assistantMessageId(String payloadJson) {
  try {
    final payload = jsonDecode(payloadJson);

    return payload is Map && payload['assistantMessageId'] is String
        ? payload['assistantMessageId'] as String
        : null;
  } on Object catch (_) {
    return null;
  }
}
