import 'dart:collection';

import 'package:auravibes_engine/src/tool_calls.dart';
import 'package:auravibes_engine/src/transcript_context.dart';

class AgentPromptHistorySelection(List<String> messageIds) {
  final List<String> messageIds = UnmodifiableListView(List.of(messageIds));
}

sealed class const AgentCompactionRangeSelection();

class AgentCompactionRangeSelected({
  required final String fromMessageId,
  required final String throughMessageId,
  required List<String> messageIds,
  required List<String> keptTailMessageIds,
}) extends AgentCompactionRangeSelection {
  final List<String> messageIds = UnmodifiableListView(List.of(messageIds));
  final List<String> keptTailMessageIds = UnmodifiableListView(
    List.of(keptTailMessageIds),
  );
}

class const AgentCompactionNoRange() extends AgentCompactionRangeSelection;

class const AgentCompactionUnsafeUnresolvedTool()
    extends AgentCompactionRangeSelection;

AgentPromptHistorySelection selectAgentPromptHistory(
  AgentContextSnapshot context,
) {
  final messages = context.messages;
  final latestSummaryIndex = messages.lastIndexWhere(
    (message) =>
        message.role == AgentTranscriptRole.system &&
        message.isCompactionSummary &&
        message.status == AgentTranscriptStatus.sent,
  );
  if (latestSummaryIndex == -1) {
    return AgentPromptHistorySelection(
      messages.map((message) => message.id).toList(),
    );
  }

  final summary = messages[latestSummaryIndex];
  final excludedIds = summary.excludedMessageIds.toSet();
  final throughId = summary.compactedThroughMessageId;
  final throughIndex = throughId == null
      ? -1
      : messages.indexWhere((message) => message.id == throughId);
  final tailStart = throughIndex >= 0 && throughIndex < latestSummaryIndex
      ? throughIndex + 1
      : latestSummaryIndex + 1;
  final tail = messages
      .sublist(tailStart)
      .where(
        (message) =>
            message.id != summary.id &&
            !excludedIds.contains(message.id) &&
            !message.isCompactionSummary,
      );
  final tailList = tail.toList();
  final firstUserIndex = tailList.indexWhere(
    (message) => message.role == AgentTranscriptRole.user,
  );

  return AgentPromptHistorySelection([
    summary.id,
    if (firstUserIndex >= 0)
      ...tailList.skip(firstUserIndex).map((message) => message.id),
  ]);
}

AgentCompactionRangeSelection selectAgentCompactionRange(
  AgentContextSnapshot context,
) {
  final messages = context.messages;
  if (messages.length < 3) return const AgentCompactionNoRange();

  final lastUserIndex = _lastUserIndex(messages);
  final lastModelTextIndex = _lastModelTextIndex(messages);
  if (lastUserIndex <= 0 || lastModelTextIndex == -1) {
    return const AgentCompactionNoRange();
  }

  if (_hasUnresolvedToolBeforeTail(messages, lastUserIndex)) {
    return const AgentCompactionUnsafeUnresolvedTool();
  }

  final compactable = messages
      .take(lastUserIndex)
      .where(_isCompactable)
      .toList();
  if (compactable.isEmpty) return const AgentCompactionNoRange();

  return AgentCompactionRangeSelected(
    fromMessageId: compactable.first.id,
    throughMessageId: compactable.last.id,
    messageIds: compactable.map((message) => message.id).toList(),
    keptTailMessageIds: messages
        .skip(lastUserIndex)
        .map((message) => message.id)
        .toList(),
  );
}

int _lastUserIndex(List<AgentTranscriptMessageSnapshot> messages) => messages
    .lastIndexWhere((message) => message.role == AgentTranscriptRole.user);

int _lastModelTextIndex(List<AgentTranscriptMessageSnapshot> messages) =>
    messages.lastIndexWhere(
      (message) =>
          message.role == AgentTranscriptRole.model &&
          message.kind == AgentTranscriptKind.text,
    );

bool _hasUnresolvedToolBeforeTail(
  List<AgentTranscriptMessageSnapshot> messages,
  int lastUserIndex,
) {
  for (var index = lastUserIndex; index >= 0; index--) {
    final message = messages[index];
    if (message.role == AgentTranscriptRole.user && index != lastUserIndex) {
      return false;
    }
    if (message.role != AgentTranscriptRole.user && _hasPendingTool(message)) {
      return true;
    }
  }
  return false;
}

bool _isCompactable(AgentTranscriptMessageSnapshot message) =>
    message.status == AgentTranscriptStatus.sent &&
    !message.isCompactionSummary &&
    (message.role == AgentTranscriptRole.user || !_hasPendingTool(message));

bool _hasPendingTool(AgentTranscriptMessageSnapshot message) => message
    .toolCalls
    .any((toolCall) => toolCall.lifecycle == AgentToolCallLifecycle.pending);
