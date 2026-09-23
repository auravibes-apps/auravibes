import 'package:auravibes_engine/src/tool_execution_dispatcher.dart';
import 'package:test/test.dart';

void main() {
  Future<AgentToolExecutionResult> run(
    Object result, {
    String argumentsRaw = '{}',
  }) {
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
      argumentsRaw: argumentsRaw,
    );
  }

  test('JSON encodes structured results', () async {
    expect((await run({'ok': true})).responseRaw, '{"ok":true}');
    expect((await run([1, 2])).responseRaw, '[1,2]');
  });

  test('preserves string results', () async {
    expect((await run('plain')).responseRaw, 'plain');
  });

  for (final argumentsRaw in ['[]', 'null', '"harmless operation"', '{']) {
    test('rejects non-object tool arguments: $argumentsRaw', () async {
      var executed = false;
      Object? loggedError;
      final result =
          await AgentToolExecutionDispatcher<String>(
            runResolvedTool:
                ({
                  required conversationId,
                  required tool,
                  required arguments,
                }) async {
                  executed = true;
                  return 'unexpected';
                },
            isCancellationRequested: (_) => false,
            logToolExecutionError: (request) => loggedError = request.error,
          ).call(
            conversationId: 'conversation-1',
            toolCallId: 'call-1',
            tool: 'tool',
            argumentsRaw: argumentsRaw,
          );

      expect(executed, isFalse);
      expect(loggedError, isA<FormatException>());
      expect(result.resultStatus, AgentToolResultStatus.executionError);
      expect(result.responseRaw, 'Tool execution failed.');
    });
  }

  test('preserves results when cancellation arrives after execution', () async {
    var cancellationChecks = 0;
    final result =
        await AgentToolExecutionDispatcher<String>(
          runResolvedTool: ({
            required conversationId,
            required tool,
            required arguments,
          }) async => '{"conversationId":"child-1","status":"stopped"}',
          isCancellationRequested: (_) => cancellationChecks++ > 0,
          logToolExecutionError: (_) {},
        ).call(
          conversationId: 'conversation-1',
          toolCallId: 'call-1',
          tool: 'tool',
          argumentsRaw: '{}',
        );

    expect(result.resultStatus, AgentToolResultStatus.stoppedByUser);
    expect(result.responseRaw, contains('child-1'));
  });

  test('does not dispatch when cancellation is already requested', () async {
    var dispatched = false;
    final result =
        await AgentToolExecutionDispatcher<String>(
          runResolvedTool:
              ({
                required conversationId,
                required tool,
                required arguments,
              }) async {
                dispatched = true;
                return 'unexpected';
              },
          isCancellationRequested: (_) => true,
          logToolExecutionError: (_) {},
        ).call(
          conversationId: 'conversation-1',
          toolCallId: 'call-1',
          tool: 'tool',
          argumentsRaw: '{}',
        );

    expect(dispatched, isFalse);
    expect(result.resultStatus, AgentToolResultStatus.stoppedByUser);
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
