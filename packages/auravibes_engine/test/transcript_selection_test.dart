import 'package:auravibes_engine/src/tool_calls.dart';
import 'package:auravibes_engine/src/transcript_context.dart';
import 'package:auravibes_engine/src/transcript_selection.dart';
import 'package:test/test.dart';

void main() {
  AgentTranscriptMessageSnapshot message(
    String id, {
    AgentTranscriptRole role = AgentTranscriptRole.user,
    AgentTranscriptKind kind = AgentTranscriptKind.text,
    AgentTranscriptStatus status = AgentTranscriptStatus.sent,
    bool summary = false,
    String? throughId,
    List<String> excludedIds = const [],
    bool pendingTool = false,
  }) => AgentTranscriptMessageSnapshot(
    id: id,
    role: role,
    kind: kind,
    status: status,
    textCharacterCount: 0,
    toolCalls: pendingTool
        ? const [
            AgentTranscriptToolCallSnapshot(
              id: 'tool',
              lifecycle: AgentToolCallLifecycle.pending,
              argumentCharacterCount: 0,
              resultCharacterCount: 0,
            ),
          ]
        : const [],
    latestCumulativeTokenCount: null,
    isCompactionSummary: summary,
    compactedThroughMessageId: throughId,
    excludedMessageIds: excludedIds,
  );

  test('selects latest valid summary and active user-led tail', () {
    final selection = selectAgentPromptHistory(
      AgentContextSnapshot([
        message('old'),
        message(
          'old-summary',
          role: AgentTranscriptRole.system,
          kind: AgentTranscriptKind.system,
          summary: true,
        ),
        message('through', role: AgentTranscriptRole.model),
        message('orphan', role: AgentTranscriptRole.model),
        message('excluded'),
        message(
          'summary',
          role: AgentTranscriptRole.system,
          kind: AgentTranscriptKind.system,
          summary: true,
          throughId: 'through',
          excludedIds: const ['excluded'],
        ),
        message('user'),
        message('tool', role: AgentTranscriptRole.model),
      ]),
    );

    expect(selection.messageIds, ['summary', 'user', 'tool']);
    expect(selection.messageIds.clear, throwsUnsupportedError);
  });

  test('selects safe range and reports no-range or unresolved tool', () {
    final selected = selectAgentCompactionRange(
      AgentContextSnapshot([
        message('error', status: AgentTranscriptStatus.error),
        message('first'),
        message('model', role: AgentTranscriptRole.model),
        message('tail-user'),
        message('tail-model', role: AgentTranscriptRole.model),
      ]),
    ) as AgentCompactionRangeSelected;

    expect(selected.messageIds, ['first', 'model']);
    expect(selected.keptTailMessageIds, ['tail-user', 'tail-model']);
    expect(selected.fromMessageId, 'first');
    expect(selected.throughMessageId, 'model');
    expect(
      selectAgentCompactionRange(AgentContextSnapshot([message('one')])),
      isA<AgentCompactionNoRange>(),
    );
    expect(
      selectAgentCompactionRange(
        AgentContextSnapshot([
          message('first'),
          message(
            'pending',
            role: AgentTranscriptRole.model,
            pendingTool: true,
          ),
          message('tail-user'),
          message('tail-model', role: AgentTranscriptRole.model),
        ]),
      ),
      isA<AgentCompactionUnsafeUnresolvedTool>(),
    );
  });
}
