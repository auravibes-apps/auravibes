import 'dart:async';

import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:test/test.dart';

void main() {
  test('starts independent tool calls concurrently', () async {
    final started = <String>[];
    final release = Completer<void>();
    final executor = AgentToolBatchExecutor<String>(
      runResolvedTool:
          ({required conversationId, required tool, required arguments}) async {
            started.add(tool);
            await release.future;

            return tool;
          },
      isCancellationRequested: (_) => false,
      logToolExecutionError: (_) {},
    );
    final future = executor.call([
      const AgentToolBatchCall(
        conversationId: 'conversation-1',
        messageId: 'message-1',
        toolCallId: 'call-1',
        tool: 'first',
        argumentsRaw: '{}',
      ),
      const AgentToolBatchCall(
        conversationId: 'conversation-1',
        messageId: 'message-1',
        toolCallId: 'call-2',
        tool: 'second',
        argumentsRaw: '{}',
      ),
    ]);

    try {
      await Future<void>.delayed(Duration.zero);
      expect(started, ['first', 'second']);
    } finally {
      if (!release.isCompleted) release.complete();
      await future;
    }
  });
}
