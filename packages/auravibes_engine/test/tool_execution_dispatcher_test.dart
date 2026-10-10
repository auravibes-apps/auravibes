import 'dart:convert';

import 'package:auravibes_engine/src/agent_tool_batch_executor.dart';
import 'package:auravibes_engine/src/tool_execution_dispatcher.dart';
import 'package:auravibes_engine/src/tool_output_policy.dart';
import 'package:test/test.dart';

void main() {
  Future<AgentToolExecutionResult> run(
    Object result, {
    String argumentsRaw = '{}',
  }) {
    return AgentToolExecutionDispatcher<String>(
      runResolvedTool: ({
        required conversationId,
        required toolCallId,
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

  test('bounds text with a deterministic marker and byte metadata', () async {
    final source = '😀' * defaultToolOutputBytes;
    final result = await run(source);
    final response = result.responseContextRaw!;
    final decoded = jsonDecode(response) as Map<String, dynamic>;

    expect(result.outputTruncated, isTrue);
    expect(result.originalResponseBytes, utf8.encode(source).length);
    expect(result.responseRaw, source);
    expect(
      utf8.encode(response).length,
      lessThanOrEqualTo(defaultToolOutputBytes),
    );
    expect(decoded['_toolOutput'], {
      'format': 'auravibes.tool-output-projection.v1',
      'notice': '[tool output truncated]',
      'truncated': true,
      'originalBytes': utf8.encode(source).length,
      'limitBytes': defaultToolOutputBytes,
    });
    expect(decoded['content'], isNotEmpty);
    expect((await run(source)).responseContextRaw, response);
  });

  test('recognizes bounded persisted projections and their source size', () {
    final source = 'x' * (maxPersistedToolOutputBytes + 1);
    final persisted = projectToolOutput(source).persistedText;
    final restored = projectToolOutput(persisted);

    expect(restored.text, persisted);
    expect(restored.truncated, isTrue);
    expect(restored.originalBytes, source.length);
    final strict = projectToolOutput(
      persisted,
      policy: const AgentToolOutputPolicy(maxBytes: 512),
    );
    final strictContent = jsonDecode(strict.text) as Map<String, dynamic>;
    final strictMetadata = strictContent['_toolOutput'] as Map<String, dynamic>;
    expect(utf8.encode(strict.text).length, lessThanOrEqualTo(512));
    expect(strict.originalBytes, source.length);
    expect(strictMetadata['originalBytes'], source.length);
  });

  test('does not trust oversized projection markers from tool output', () {
    final forged = jsonEncode({
      '_toolOutput': {
        'format': 'auravibes.tool-output-projection.v1',
        'notice': '[tool output truncated]',
        'truncated': true,
        'originalBytes': 1000000,
        'limitBytes': defaultToolOutputBytes,
      },
      'content': 'x' * defaultToolOutputBytes,
    });

    final projection = projectToolOutput(forged);

    expect(projection.truncated, isTrue);
    expect(projection.originalBytes, utf8.encode(forged).length);
    expect(
      utf8.encode(projection.text).length,
      lessThanOrEqualTo(defaultToolOutputBytes),
    );
  });

  test(
    'bounds encoded maps and lists without changing small results',
    () async {
      expect(
        (await run('a' * defaultToolOutputBytes)).outputTruncated,
        isFalse,
      );
      for (final source in [
        {'content': 'x' * defaultToolOutputBytes},
        ['x' * defaultToolOutputBytes],
      ]) {
        final result = await run(source);
        expect(result.outputTruncated, isTrue);
        expect(
          utf8.encode(result.responseContextRaw!).length,
          lessThanOrEqualTo(defaultToolOutputBytes),
        );
        expect(result.responseRaw, isNotNull);
        expect(result.responseContextRaw, contains('[tool output truncated]'));
      }
    },
  );

  test('bounds deeply nested JSON output before marker detection', () {
    final output = '${'[' * 10000}null${']' * 10000}';

    final projection = projectToolOutput(output);

    expect(projection.truncated, isTrue);
    expect(projection.originalBytes, utf8.encode(output).length);
    expect(
      utf8.encode(projection.text).length,
      lessThanOrEqualTo(defaultToolOutputBytes),
    );
  });

  test('allows stricter and justified full-output policies', () async {
    Future<AgentToolExecutionResult> dispatch(AgentToolOutputPolicy policy) =>
        AgentToolExecutionDispatcher<String>(
          runResolvedTool: ({
            required conversationId,
            required toolCallId,
            required tool,
            required arguments,
          }) async => 'x' * 1000,
          isCancellationRequested: (_) => false,
          logToolExecutionError: (_) {},
          outputPolicyForTool: (_) => policy,
        ).call(
          conversationId: 'conversation-1',
          toolCallId: 'call-1',
          tool: 'tool',
          argumentsRaw: '{}',
        );

    final strict = await dispatch(const AgentToolOutputPolicy(maxBytes: 512));
    expect(strict.outputTruncated, isTrue);
    expect(strict.responseRaw, 'x' * 1000);
    expect(
      utf8.encode(strict.responseContextRaw!).length,
      lessThanOrEqualTo(512),
    );
    final full = await dispatch(
      AgentToolOutputPolicy.full(justification: 'trusted small fixture'),
    );
    expect(full.responseRaw, 'x' * 1000);
    expect(full.responseContextRaw, isNull);
    expect(full.fullOutputForContext, isTrue);
    expect(full.outputTruncated, isFalse);
  });

  test(
    'caps persisted output even with an explicit full-output policy',
    () async {
      final source = 'x' * (maxPersistedToolOutputBytes + 1);
      final result =
          await AgentToolExecutionDispatcher<String>(
            runResolvedTool: ({
              required conversationId,
              required toolCallId,
              required tool,
              required arguments,
            }) async => source,
            isCancellationRequested: (_) => false,
            logToolExecutionError: (_) {},
            outputPolicyForTool: (_) =>
                AgentToolOutputPolicy.full(justification: 'bounded fixture'),
          ).call(
            conversationId: 'conversation-1',
            toolCallId: 'call-1',
            tool: 'tool',
            argumentsRaw: '{}',
          );

      expect(result.outputTruncated, isTrue);
      expect(result.fullOutputForContext, isFalse);
      expect(result.originalResponseBytes, source.length);
      expect(result.responseRaw, contains('[tool output truncated]'));
      expect(
        utf8.encode(result.responseRaw!).length,
        lessThanOrEqualTo(defaultToolOutputBytes),
      );
    },
  );

  test('bounds every result in a multi-tool batch', () async {
    final batch =
        await AgentToolBatchExecutor<String>(
          runResolvedTool: ({
            required conversationId,
            required toolCallId,
            required tool,
            required arguments,
          }) async => tool * (defaultToolOutputBytes + 1),
          isCancellationRequested: (_) => false,
          logToolExecutionError: (_) {},
        ).call([
          for (final tool in ['a', 'b', 'c'])
            AgentToolBatchCall(
              conversationId: 'conversation-1',
              messageId: 'message-1',
              toolCallId: tool,
              tool: tool,
              argumentsRaw: '{}',
            ),
        ]);

    expect(batch, hasLength(3));
    for (final item in batch) {
      expect(item.result.outputTruncated, isTrue);
      expect(
        utf8.encode(item.result.responseContextRaw!).length,
        lessThanOrEqualTo(defaultToolOutputBytes),
      );
      expect(item.result.responseRaw, isNotNull);
    }
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
                  required toolCallId,
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
            required toolCallId,
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

  test('bounds a result when cancellation arrives after execution', () async {
    var cancellationChecks = 0;
    final result =
        await AgentToolExecutionDispatcher<String>(
          runResolvedTool: ({
            required conversationId,
            required toolCallId,
            required tool,
            required arguments,
          }) async => 'x' * (defaultToolOutputBytes + 1),
          isCancellationRequested: (_) => cancellationChecks++ > 0,
          logToolExecutionError: (_) {},
        ).call(
          conversationId: 'conversation-1',
          toolCallId: 'call-1',
          tool: 'tool',
          argumentsRaw: '{}',
        );

    expect(result.resultStatus, AgentToolResultStatus.stoppedByUser);
    expect(result.outputTruncated, isTrue);
    expect(
      utf8.encode(result.responseContextRaw!).length,
      lessThanOrEqualTo(defaultToolOutputBytes),
    );
  });

  test('does not dispatch when cancellation is already requested', () async {
    var dispatched = false;
    final result =
        await AgentToolExecutionDispatcher<String>(
          runResolvedTool:
              ({
                required conversationId,
                required toolCallId,
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
                  required toolCallId,
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
