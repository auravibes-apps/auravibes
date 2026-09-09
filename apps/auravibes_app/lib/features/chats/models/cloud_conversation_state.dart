// ignore_for_file: type=warning
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
  factory fromSnapshot(ConversationSnapshot snapshot) => CloudConversationState(
    conversation: snapshot.conversation,
    messages: snapshot.messages,
    pendingMessages: snapshot.pendingMessages,
    activeExecution: snapshot.activeExecution,
    toolCalls: snapshot.toolCalls,
    sequence: snapshot.sequence,
    a2uiMessagesByAssistantMessageId: {
      for (final message in snapshot.messages)
        if (_a2uiMessages(message.metadataJson) case final messages
            when messages.isNotEmpty)
          message.id: messages,
    },
    a2uiIssuesByAssistantMessageId: {
      for (final message in snapshot.messages)
        if (_a2uiIssues(message.metadataJson) case final issues
            when issues.isNotEmpty)
          message.id: issues,
    },
    a2uiMessageIssuesByAssistantMessageId: {
      for (final message in snapshot.messages)
        if (_a2uiMessageIssues(message.metadataJson) case final issues
            when issues.isNotEmpty)
          message.id: issues,
    },
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
      for (final entry in previous.a2uiMessagesByAssistantMessageId.entries)
        if ((previous.transientA2uiSequenceByAssistantMessageId[entry.key] ??
                -1) >=
            sequence)
          entry.key: {
            ...entry.value,
            ...?a2uiMessagesByAssistantMessageId[entry.key],
          }.toList(),
      for (final entry in a2uiMessagesByAssistantMessageId.entries)
        if ((previous.transientA2uiSequenceByAssistantMessageId[entry.key] ??
                -1) <
            sequence)
          entry.key: entry.value,
    },
    a2uiIssuesByAssistantMessageId: {
      ...a2uiIssuesByAssistantMessageId,
      for (final entry in previous.a2uiIssuesByAssistantMessageId.entries)
        if ((previous.transientA2uiSequenceByAssistantMessageId[entry.key] ??
                -1) >=
            sequence)
          entry.key: entry.value,
    },
    a2uiMessageIssuesByAssistantMessageId: {
      ...a2uiMessageIssuesByAssistantMessageId,
      for (final entry
          in previous.a2uiMessageIssuesByAssistantMessageId.entries)
        if ((previous.transientA2uiSequenceByAssistantMessageId[entry.key] ??
                -1) >=
            sequence)
          entry.key: entry.value,
    },
    transientA2uiSequenceByAssistantMessageId: {
      ...transientA2uiSequenceByAssistantMessageId,
      for (final entry
          in previous.transientA2uiSequenceByAssistantMessageId.entries)
        if (entry.value >= sequence) entry.key: entry.value,
    },
    appliedTransientEventKeys: sequence == previous.sequence
        ? {...previous.appliedTransientEventKeys, ...appliedTransientEventKeys}
        : appliedTransientEventKeys,
  );

  /// Applies only the next event in the durable ordering.
  CloudConversationState? apply(ConversationStreamEvent event) {
    if (event.kind == ConversationEventType.a2uiMessage) {
      return _applyA2uiMessage(event);
    }

    return _applyTextEvent(event);
  }

  CloudConversationState? _applyA2uiMessage(ConversationStreamEvent event) {
    if (event.sequence != sequence) return null;
    final assistantMessageId =
        _assistantMessageId(event.payloadJson) ??
        activeExecution?.assistantMessageId;
    if (assistantMessageId == null) return null;
    final messages = a2uiMessagesByAssistantMessageId[assistantMessageId];
    if (messages?.contains(event.payloadJson) ?? false) return this;

    return CloudConversationState(
      conversation: conversation,
      messages: this.messages,
      pendingMessages: pendingMessages,
      activeExecution: activeExecution,
      toolCalls: toolCalls,
      sequence: sequence,
      activeAssistantContent: activeAssistantContent,
      activeAssistantTransientContent: activeAssistantTransientContent,
      a2uiMessagesByAssistantMessageId: {
        ...a2uiMessagesByAssistantMessageId,
        assistantMessageId: [...?messages, event.payloadJson],
      },
      a2uiIssuesByAssistantMessageId: a2uiIssuesByAssistantMessageId,
      a2uiMessageIssuesByAssistantMessageId:
          a2uiMessageIssuesByAssistantMessageId,
      transientA2uiSequenceByAssistantMessageId: {
        ...transientA2uiSequenceByAssistantMessageId,
        assistantMessageId: sequence,
      },
      appliedTransientEventKeys: appliedTransientEventKeys,
    );
  }

  CloudConversationState? _applyTextEvent(ConversationStreamEvent event) {
    final delta = event.transientTextDelta;
    final isTransientDelta = delta != null;
    if (isTransientDelta
        ? event.sequence != sequence
        : event.sequence != sequence + 1) {
      return null;
    }
    final transientEventKey = _transientEventKey(event, delta);
    if (transientEventKey != null &&
        appliedTransientEventKeys.contains(transientEventKey)) {
      return this;
    }

    return CloudConversationState(
      conversation: conversation,
      messages: messages,
      pendingMessages: pendingMessages,
      activeExecution: activeExecution,
      toolCalls: toolCalls,
      sequence: event.sequence,
      activeAssistantContent: isTransientDelta
          ? '${_activeAssistantBaseContent()}$activeAssistantTransientContent'
                '$delta'
          : '',
      activeAssistantTransientContent: isTransientDelta
          ? '$activeAssistantTransientContent$delta'
          : '',
      a2uiMessagesByAssistantMessageId: a2uiMessagesByAssistantMessageId,
      a2uiIssuesByAssistantMessageId: a2uiIssuesByAssistantMessageId,
      a2uiMessageIssuesByAssistantMessageId:
          a2uiMessageIssuesByAssistantMessageId,
      transientA2uiSequenceByAssistantMessageId: isTransientDelta
          ? transientA2uiSequenceByAssistantMessageId
          : const {},
      appliedTransientEventKeys: isTransientDelta
          ? {...appliedTransientEventKeys, ?transientEventKey}
          : const {},
    );
  }

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

    return {
      for (final entry in issues.entries)
        if (entry.key is String && entry.value is List)
          entry.key as String: (entry.value as List)
              .whereType<String>()
              .toList(),
    };
  } on Object catch (_) {
    return const {};
  }
}

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
