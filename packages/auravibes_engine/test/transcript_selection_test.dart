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
    int textCharacters = 0,
    int toolArgumentCharacters = 0,
    int toolResultCharacters = 0,
    bool pendingTool = false,
  }) => AgentTranscriptMessageSnapshot(
    id: id,
    role: role,
    kind: kind,
    status: status,
    textCharacterCount: textCharacters,
    toolCalls: [
      AgentTranscriptToolCallSnapshot(
        id: 'tool',
        lifecycle: pendingTool ? .pending : .success,
        argumentCharacterCount: toolArgumentCharacters,
        resultCharacterCount: toolResultCharacters,
      ),
    ],
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

  test('extends protected tail whole messages to recent token budget', () {
    final selected = selectAgentCompactionRange(
      .new([
        message('old-user', textCharacters: 400),
        message('old-model', role: .model, textCharacters: 400),
        message('recent-user', textCharacters: 120),
        message('recent-model', role: .model, textCharacters: 120),
        message('last-user', textCharacters: 80),
        message('last-model', role: .model, textCharacters: 80),
      ]),
      limitContext: 512,
      limitOutput: 128,
      reserveTokens: 128,
      keepRecentTokens: 70,
    ) as AgentCompactionRangeSelected;
    expect(selected.keptTailMessageIds, [
      'recent-model',
      'last-user',
      'last-model',
    ]);
    expect(selected.messageIds, ['old-user', 'old-model', 'recent-user']);
  });

  test('returns no range when protected tail plus reserve cannot fit', () {
    expect(
      selectAgentCompactionRange(
        .new([
          message('old', textCharacters: 400),
          message('last-user', textCharacters: 200),
          message('last-model', role: .model, textCharacters: 200),
        ]),
        limitContext: 128,
        limitOutput: 64,
        reserveTokens: 64,
        keepRecentTokens: 80,
      ),
      isA<AgentCompactionNoRange>(),
    );
  });

  test(
    'explicit older checkpoint keeps later source and ignores summaries',
    () {
      final selection = selectAgentPromptHistory(
        .new([
          message('source-1'),
          message(
            'summary-1',
            role: .system,
            kind: .system,
            summary: true,
            throughId: 'source-1',
            excludedIds: ['source-1'],
          ),
          message('later-user'),
          message('later-model', role: .model),
          message(
            'summary-2',
            role: .system,
            kind: .system,
            summary: true,
            throughId: 'later-model',
            excludedIds: ['later-user', 'later-model'],
          ),
          message('current-user'),
        ]),
        activeCompactionCheckpointId: 'summary-1',
      );
      expect(selection.messageIds, [
        'summary-1',
        'later-user',
        'later-model',
        'current-user',
      ]);
    },
  );

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
