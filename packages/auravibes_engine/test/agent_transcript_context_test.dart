import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:test/test.dart';

void main() {
  test('adds, removes, and redefines tools in current order', () {
    final first = AgentTranscriptContextState(
      tools: [_tool('alpha'), _tool('beta')],
    );
    final second = AgentTranscriptContextState(
      tools: [
        _tool('beta', description: 'Updated'),
        _tool('gamma'),
      ],
    );
    final initial = diffAgentTranscriptContext(
      AgentTranscriptContextState(),
      first,
    )!;
    final changed = diffAgentTranscriptContext(first, second)!;

    expect(changed.toolsRemoved, ['alpha', 'beta']);
    expect(changed.toolsAdded.map((tool) => tool.name), ['beta', 'gamma']);
    expect(changed.toolOrder, ['beta', 'gamma']);
    expect(foldAgentTranscriptContext([initial, changed]).tools, second.tools);
  });

  test('keeps context changes immutable and skips no-op updates', () {
    final messages = <AgentContextMessage>[
      const AgentContextMessage(role: .system, content: 'Agent A'),
      const AgentContextMessage(role: .skill, content: 'Skill A'),
    ];
    final first = AgentTranscriptContextState(contextMessages: messages);
    final initial = diffAgentTranscriptContext(
      AgentTranscriptContextState(),
      first,
    )!;
    messages.clear();

    expect(initial.contextMessages, hasLength(2));
    expect(foldAgentTranscriptContext([initial]).contextMessages, hasLength(2));
    expect(diffAgentTranscriptContext(first, first), isNull);
  });

  test('reorders unchanged tool declarations without redefining them', () {
    final alpha = _tool('alpha');
    final beta = _tool('beta');
    final before = AgentTranscriptContextState(tools: [alpha, beta]);
    final after = AgentTranscriptContextState(tools: [beta, alpha]);
    final update = diffAgentTranscriptContext(before, after)!;

    expect(update.toolsAdded, isEmpty);
    expect(update.toolsRemoved, isEmpty);
    expect(update.toolOrder, ['beta', 'alpha']);
    expect(
      foldAgentTranscriptContext([
        snapshotAgentTranscriptContext(before),
        update,
      ]).tools,
      [beta, alpha],
    );
  });

  test('approval-only changes replay without changing tool declarations', () {
    final before = AgentTranscriptContextState(
      tools: [_tool('alpha')],
      approvalStates: const {'tool-id': 'needsConfirmation'},
    );
    final after = AgentTranscriptContextState(
      tools: [_tool('alpha')],
      approvalStates: const {'tool-id': 'granted'},
    );
    final update = diffAgentTranscriptContext(before, after)!;

    expect(update.toolsAdded, isEmpty);
    expect(update.toolsRemoved, isEmpty);
    expect(update.approvalStates, {'tool-id': 'granted'});
    expect(
      foldAgentTranscriptContext([
        snapshotAgentTranscriptContext(before),
        update,
      ]).approvalStates,
      after.approvalStates,
    );
    expect(diffAgentTranscriptContext(after, after), isNull);
  });

  test('checkpoint replaces stale changes after compaction', () {
    final initial = AgentTranscriptContextState(
      contextMessages: [
        const AgentContextMessage(role: .system, content: 'Agent A'),
      ],
      tools: [_tool('alpha')],
    );
    final beforeSummary = AgentTranscriptContextState(
      contextMessages: [
        const AgentContextMessage(role: .system, content: 'Agent B'),
      ],
      tools: [_tool('beta')],
    );
    final afterSummary = AgentTranscriptContextState(
      contextMessages: beforeSummary.contextMessages,
      tools: [_tool('beta'), _tool('gamma')],
    );
    final fullHistory = [
      snapshotAgentTranscriptContext(initial),
      diffAgentTranscriptContext(initial, beforeSummary)!,
      diffAgentTranscriptContext(beforeSummary, afterSummary)!,
    ];
    final activeHistory = [
      snapshotAgentTranscriptContext(
        foldAgentTranscriptContext(fullHistory.take(2)),
      ),
      fullHistory.last,
    ];

    expect(
      foldAgentTranscriptContext(activeHistory).tools,
      foldAgentTranscriptContext(fullHistory).tools,
    );
    expect(activeHistory, hasLength(2));
    expect(activeHistory.first.contextMessages?.single.content, 'Agent B');
  });

  test('rejects invalid replay instead of silently changing tool state', () {
    expect(
      () => foldAgentTranscriptContext([
        AgentTranscriptContextUpdate(toolsRemoved: ['missing']),
      ]),
      throwsA(isA<AgentTranscriptContextException>()),
    );
    expect(
      () => foldAgentTranscriptContext([
        AgentTranscriptContextUpdate(toolsAdded: [_tool('alpha')]),
        AgentTranscriptContextUpdate(toolsAdded: [_tool('alpha')]),
      ]),
      throwsA(isA<AgentTranscriptContextException>()),
    );
  });
}

ToolSpec _tool(String name, {String description = 'Tool'}) => ToolSpec(
  name: name,
  description: description,
  inputJsonSchema: const {'type': 'object'},
);
