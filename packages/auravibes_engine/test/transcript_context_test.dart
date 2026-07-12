import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:test/test.dart';

void main() {
  test('defensively freezes transcript collections', () {
    final toolCalls = <AgentTranscriptToolCallSnapshot>[
      const AgentTranscriptToolCallSnapshot(
        id: 'tool-1',
        lifecycle: AgentToolCallLifecycle.pending,
        argumentCharacterCount: 2,
        resultCharacterCount: 0,
      ),
    ];
    final excludedIds = <String>['message-1'];
    final message = AgentTranscriptMessageSnapshot(
      id: 'summary-1',
      role: AgentTranscriptRole.system,
      kind: AgentTranscriptKind.system,
      status: AgentTranscriptStatus.sent,
      textCharacterCount: 7,
      toolCalls: toolCalls,
      latestCumulativeTokenCount: 12,
      isCompactionSummary: true,
      compactedThroughMessageId: 'message-1',
      excludedMessageIds: excludedIds,
    );
    final messages = <AgentTranscriptMessageSnapshot>[message];
    final context = AgentContextSnapshot(messages);

    toolCalls.clear();
    excludedIds.clear();
    messages.clear();

    expect(message.toolCalls, hasLength(1));
    expect(message.excludedMessageIds, ['message-1']);
    expect(context.messages, [message]);
    expect(message.toolCalls.clear, throwsUnsupportedError);
    expect(message.excludedMessageIds.clear, throwsUnsupportedError);
    expect(context.messages.clear, throwsUnsupportedError);
  });
}
