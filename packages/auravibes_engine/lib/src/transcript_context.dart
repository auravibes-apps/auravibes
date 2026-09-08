import 'dart:collection';

import 'package:auravibes_engine/src/tool_calls.dart';

enum AgentTranscriptRole { user, model, system }

enum AgentTranscriptKind { text, image, toolCall, system }

enum AgentTranscriptStatus { sending, unfinished, sent, error }

class const AgentTranscriptToolCallSnapshot({
  required final String id,
  required final AgentToolCallLifecycle lifecycle,
  required final int argumentCharacterCount,
  required final int resultCharacterCount,
});

class AgentTranscriptMessageSnapshot({
  required final String id,
  required final AgentTranscriptRole role,
  required final AgentTranscriptKind kind,
  required final AgentTranscriptStatus status,
  required final int textCharacterCount,
  required List<AgentTranscriptToolCallSnapshot> toolCalls,
  required final int? latestCumulativeTokenCount,
  required final bool isCompactionSummary,
  required final String? compactedThroughMessageId,
  required List<String> excludedMessageIds,
}) {
  final List<AgentTranscriptToolCallSnapshot> toolCalls = UnmodifiableListView(
    List.of(toolCalls),
  );
  final List<String> excludedMessageIds = UnmodifiableListView(
    List.of(excludedMessageIds),
  );
}

class AgentContextSnapshot(List<AgentTranscriptMessageSnapshot> messages) {
  final List<AgentTranscriptMessageSnapshot> messages = UnmodifiableListView(
    List.of(messages),
  );
}
