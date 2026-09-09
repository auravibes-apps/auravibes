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
              lifecycle: .pending,
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
      .new([
        message('old'),
        message('old-summary', role: .system, kind: .system, summary: true),
        message('through', role: .model),
        message('orphan', role: .model),
        message('excluded'),
        message(
          'summary',
          role: .system,
          kind: .system,
          summary: true,
          throughId: 'through',
          excludedIds: const ['excluded'],
        ),
        message('user'),
        message('tool', role: .model),
      ]),
    );

    expect(selection.messageIds, ['summary', 'user', 'tool']);
    expect(selection.messageIds.clear, throwsUnsupportedError);
  });

  test('selects safe range and reports no-range or unresolved tool', () {
    final selected = selectAgentCompactionRange(
      .new([
        message('error', status: .error),
        message('first'),
        message('model', role: .model),
        message('tail-user'),
        message('tail-model', role: .model),
      ]),
    ) as AgentCompactionRangeSelected;

    expect(selected.messageIds, ['first', 'model']);
    expect(selected.keptTailMessageIds, ['tail-user', 'tail-model']);
    expect(selected.fromMessageId, 'first');
    expect(selected.throughMessageId, 'model');
    expect(
      selectAgentCompactionRange(.new([message('one')])),
      isA<AgentCompactionNoRange>(),
    );
    expect(
      selectAgentCompactionRange(
        .new([
          message('first'),
          message('pending', role: .model, pendingTool: true),
          message('tail-user'),
          message('tail-model', role: .model),
        ]),
      ),
      isA<AgentCompactionUnsafeUnresolvedTool>(),
    );
  });
}
