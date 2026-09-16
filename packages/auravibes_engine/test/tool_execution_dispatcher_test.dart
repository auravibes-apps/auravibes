import 'package:auravibes_engine/src/tool_execution_dispatcher.dart';
import 'package:test/test.dart';

void main() {
  Future<AgentToolExecutionResult> run(Object result) {
    return AgentToolExecutionDispatcher<String>(
      runResolvedTool: ({
        required conversationId,
        required tool,
        required arguments,
      }) async => result,
      isCancellationRequested: (_) => false,
      logToolExecutionError: (request) {},
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

  test(
    'maps typed failures to execution errors and preserves diagnostics',
    () async {
      final error = StateError('provider detail');
      Object? loggedError;
      String? loggedPhase;
      final result =
          await AgentToolExecutionDispatcher<String>(
            runResolvedTool:
                ({
                  required conversationId,
                  required tool,
                  required arguments,
                }) async {
                  throw AgentToolExecutionFailure(
                    responseRaw:
                        '{"conversationId":"child-1","status":"error",'
                        '"content":"Sub-agent failed."}',
                    error: error,
                    stackTrace: StackTrace.current,
                    failurePhase: 'continueAgent',
                  );
                },
            isCancellationRequested: (_) => false,
            logToolExecutionError: (request) {
              loggedError = request.error;
              loggedPhase = request.failurePhase;
            },
          ).call(
            conversationId: 'conversation-1',
            toolCallId: 'call-1',
            tool: 'tool',
            argumentsRaw: '{}',
          );

      expect(result.resultStatus, AgentToolResultStatus.executionError);
      expect(result.responseRaw, contains('child-1'));
      expect(loggedError, same(error));
      expect(loggedPhase, 'continueAgent');
    },
  );
}
