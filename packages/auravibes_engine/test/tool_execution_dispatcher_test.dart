import 'package:auravibes_engine/src/tool_execution_dispatcher.dart';
import 'package:test/test.dart';

void main() {
  Future<AgentToolExecutionResult> run(Object result) {
    return AgentToolExecutionDispatcher<String>(
      runResolvedTool:
          ({
            required conversationId,
            required tool,
            required arguments,
          }) async => result,
      isCancellationRequested: (_) => false,
      logToolExecutionError:
          ({
            required conversationId,
            required toolCallId,
            required tool,
            required error,
            required stackTrace,
          }) {},
    ).call(
      conversationId: 'conversation-1',
      toolCallId: 'call-1',
      tool: 'tool',
      argumentsRaw: '{}',
    );
  }

  test('JSON encodes structured results', () async {
    expect((await run({'ok': true})).responseRaw, '{"ok":true}');
    expect((await run([1, 2])).responseRaw, '[1,2]');
  });

  test('preserves string results', () async {
    expect((await run('plain')).responseRaw, 'plain');
  });
}
