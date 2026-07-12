import 'dart:collection';

import 'package:auravibes_engine/src/tool_calls.dart';

enum AgentTranscriptRole { user, model, system }

enum AgentTranscriptKind { text, image, toolCall, system }

enum AgentTranscriptStatus { sending, unfinished, sent, error }

class AgentTranscriptToolCallSnapshot {
  const AgentTranscriptToolCallSnapshot({
    required this.id,
    required this.lifecycle,
    required this.argumentCharacterCount,
    required this.resultCharacterCount,
  });

  final String id;
  final AgentToolCallLifecycle lifecycle;
  final int argumentCharacterCount;
  final int resultCharacterCount;
}

class AgentTranscriptMessageSnapshot {
  AgentTranscriptMessageSnapshot({
    required this.id,
    required this.role,
    required this.kind,
    required this.status,
    required this.textCharacterCount,
    required List<AgentTranscriptToolCallSnapshot> toolCalls,
    required this.latestCumulativeTokenCount,
    required this.isCompactionSummary,
    required this.compactedThroughMessageId,
    required List<String> excludedMessageIds,
  }) : toolCalls = UnmodifiableListView(List.of(toolCalls)),
       excludedMessageIds = UnmodifiableListView(List.of(excludedMessageIds));

  final String id;
  final AgentTranscriptRole role;
  final AgentTranscriptKind kind;
  final AgentTranscriptStatus status;
  final int textCharacterCount;
  final List<AgentTranscriptToolCallSnapshot> toolCalls;
  final int? latestCumulativeTokenCount;
  final bool isCompactionSummary;
  final String? compactedThroughMessageId;
  final List<String> excludedMessageIds;
}

class AgentContextSnapshot {
  AgentContextSnapshot(List<AgentTranscriptMessageSnapshot> messages)
    : messages = UnmodifiableListView(List.of(messages));

  final List<AgentTranscriptMessageSnapshot> messages;
}
