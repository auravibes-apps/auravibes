import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_engine/src/agent_tool_execution_service.dart';
import 'package:test/test.dart';

void main() {
  test('already requested approval skips permission re-evaluation', () async {
    final provider = _FakeExecutionProvider(
      latestToolCalls: const LoadLatestMessageToolCallsResult(
        messageId: 'message-1',
        hasToolCalls: true,
        toolsToRun: [],
        pendingApprovalToolCallIds: ['manual-id'],
        notFoundToolCallIds: [],
        previouslyFailedToolCallIds: [],
      ),
      decisions: const {'manual-id': AgentToolPermissionResult.granted},
    );
    final result = await AgentToolExecutionService<String>(provider: provider)(
      conversationId: 'conversation-1',
      workspaceId: 'workspace-1',
    );
    expect(result, AgentIterationDecision.waitForToolApproval);
    expect(provider.approvalArgumentsRaw, isEmpty);
    expect(provider.updates, isEmpty);
  });

  test('stops pending tools when cancellation is already requested', () async {
    final provider = _FakeExecutionProvider(
      latestToolCalls: _latestToolCalls(),
      cancellationRequested: true,
    );
    final service = AgentToolExecutionService<String>(provider: provider);

    final result = await service(
      conversationId: 'conversation-1',
      workspaceId: 'workspace-1',
    );

    expect(result, AgentIterationDecision.done);
    expect(provider.stoppedMessageIds, ['message-1']);
  });

  test('writes not-found and previously-failed tool updates', () async {
    final provider = _FakeExecutionProvider(
      latestToolCalls: const LoadLatestMessageToolCallsResult(
        messageId: 'message-1',
        hasToolCalls: true,
        toolsToRun: [],
        notFoundToolCallIds: ['missing-1'],
        previouslyFailedToolCallIds: ['failed-1'],
      ),
    );
    final service = AgentToolExecutionService<String>(provider: provider);

    final result = await service(
      conversationId: 'conversation-1',
      workspaceId: 'workspace-1',
    );

    expect(result, AgentIterationDecision.continueIteration);
    expect(provider.updates.map((update) => update.resultStatus), [
      AgentToolResultStatus.toolNotFound,
      AgentToolResultStatus.executionError,
    ]);
  });

  test('writes permission-denied tool updates', () async {
    final provider = _FakeExecutionProvider(
      latestToolCalls: _latestToolCalls(),
      decisions: const {
        'tool-1': AgentToolPermissionResult.disabledInConversation,
        'tool-2': AgentToolPermissionResult.disabledByAgent,
        'tool-3': AgentToolPermissionResult.disabledInWorkspace,
      },
    );
    final service = AgentToolExecutionService<String>(provider: provider);

    final result = await service(
      conversationId: 'conversation-1',
      workspaceId: 'workspace-1',
    );

    expect(result, AgentIterationDecision.continueIteration);
    expect(provider.updates.map((update) => update.resultStatus), [
      AgentToolResultStatus.disabledInConversation,
      AgentToolResultStatus.disabledByAgent,
      AgentToolResultStatus.disabledInWorkspace,
    ]);
    expect(
      provider.updates.map((update) => update.responseRaw),
      everyElement(contains('Tool "')),
    );
  });

  test('preserves typed screenshot media in tool result updates', () async {
    final media = AgentToolResultMedia(
      bytes: Uint8List.fromList([1, 2, 3]),
      mimeType: 'image/png',
      fileName: 'browser-viewport.png',
    );
    final provider = _FakeExecutionProvider(
      latestToolCalls: const LoadLatestMessageToolCallsResult(
        messageId: 'message-1',
        hasToolCalls: true,
        toolsToRun: [
          AgentToolToCall(
            tool: 'browser_capture_screenshot',
            id: 'screenshot-call',
            argumentsRaw: '{}',
          ),
        ],
        notFoundToolCallIds: [],
        previouslyFailedToolCallIds: [],
      ),
      decisions: const {'screenshot-call': AgentToolPermissionResult.granted},
      results: {
        'browser_capture_screenshot': AgentToolExecutionOutput(
          output: const {'screenshotCaptured': true},
          media: [media],
        ),
      },
    );

    final result = await AgentToolExecutionService<String>(provider: provider)(
      conversationId: 'conversation-1',
      workspaceId: 'workspace-1',
    );

    expect(result, AgentIterationDecision.continueIteration);
    expect(provider.updates.single.responseRaw, contains('screenshotCaptured'));
    expect(provider.updates.single.media, [media]);
  });

  test(
    'executes granted tools and stores success and failure updates',
    () async {
      final provider = _FakeExecutionProvider(
        latestToolCalls: _latestToolCalls(),
        decisions: const {
          'tool-1': AgentToolPermissionResult.granted,
          'tool-2': AgentToolPermissionResult.granted,
          'tool-3': AgentToolPermissionResult.granted,
        },
        results: {
          'tool-a': 'ok',
          'tool-b': null,
          'tool-c': const FormatException('bad input'),
        },
      );
      final service = AgentToolExecutionService<String>(provider: provider);

      final result = await service(
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
      );

      expect(result, AgentIterationDecision.continueIteration);
      expect(provider.updates.map((update) => update.resultStatus), [
        AgentToolResultStatus.success,
        AgentToolResultStatus.toolNotFound,
        AgentToolResultStatus.executionError,
      ]);
      expect(
        provider.updates
            .singleWhere((update) => update.toolCallId == 'tool-3')
            .responseRaw,
        contains('"code":"invalid_request"'),
      );
      expect(provider.loggedErrors, ['tool-3']);
    },
  );

  test('changes loop fingerprints when full tool output changes', () async {
    Future<({String? fingerprint, String? responseContextRaw})> fingerprintFor(
      String result,
    ) async {
      final provider = _FakeExecutionProvider(
        latestToolCalls: const LoadLatestMessageToolCallsResult(
          messageId: 'message-1',
          hasToolCalls: true,
          toolsToRun: [
            AgentToolToCall(
              tool: 'search',
              id: 'tool-1',
              argumentsRaw: '{"query":"cats"}',
            ),
          ],
          notFoundToolCallIds: [],
          previouslyFailedToolCallIds: [],
        ),
        decisions: const {'tool-1': AgentToolPermissionResult.granted},
        results: {'search': '${'x' * 400}$result'},
      );

      final loopResult =
          await AgentToolExecutionService<String>(
            provider: provider,
            outputPolicyForTool: (_) =>
                const AgentToolOutputPolicy(maxBytes: 256),
          ).runAgentLoopIteration(
            conversationId: 'conversation-1',
            workspaceId: 'workspace-1',
          );

      return (
        fingerprint: loopResult.fingerprint,
        responseContextRaw: provider.updates.single.responseContextRaw,
      );
    }

    final first = await fingerprintFor('first result');
    final unchanged = await fingerprintFor('first result');
    final changed = await fingerprintFor('other result');

    expect(first.fingerprint, isNotNull);
    expect(unchanged.fingerprint, first.fingerprint);
    expect(changed.responseContextRaw, first.responseContextRaw);
    expect(changed.fingerprint, isNot(first.fingerprint));
  });

  test('fingerprints permission-denied tool outcomes', () async {
    final provider = _FakeExecutionProvider(
      latestToolCalls: const LoadLatestMessageToolCallsResult(
        messageId: 'message-1',
        hasToolCalls: true,
        toolsToRun: [
          AgentToolToCall(tool: 'tool-a', id: 'tool-1', argumentsRaw: '{}'),
          AgentToolToCall(tool: 'tool-b', id: 'tool-2', argumentsRaw: '{}'),
          AgentToolToCall(tool: 'tool-c', id: 'tool-3', argumentsRaw: '{}'),
          AgentToolToCall(tool: 'tool-d', id: 'tool-4', argumentsRaw: '{}'),
        ],
        notFoundToolCallIds: [],
        previouslyFailedToolCallIds: [],
        allToolCalls: [
          AgentMessageToolCall(
            id: 'tool-1',
            name: 'model-tool-a',
            argumentsRaw: '{}',
          ),
          AgentMessageToolCall(
            id: 'tool-2',
            name: 'model-tool-b',
            argumentsRaw: '{}',
          ),
          AgentMessageToolCall(
            id: 'tool-3',
            name: 'model-tool-c',
            argumentsRaw: '{}',
          ),
          AgentMessageToolCall(
            id: 'tool-4',
            name: 'model-tool-d',
            argumentsRaw: '{}',
          ),
        ],
      ),
      decisions: const {
        'tool-1': AgentToolPermissionResult.disabledInConversation,
        'tool-2': AgentToolPermissionResult.disabledByAgent,
        'tool-3': AgentToolPermissionResult.disabledInWorkspace,
        'tool-4': AgentToolPermissionResult.notConfigured,
      },
    );

    final result = await AgentToolExecutionService<String>(provider: provider)
        .runAgentLoopIteration(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
        );

    expect(result.decision, AgentIterationDecision.continueIteration);
    expect(result.fingerprint, isNotNull);
    expect(provider.updates.map((update) => update.resultStatus), [
      AgentToolResultStatus.disabledInConversation,
      AgentToolResultStatus.disabledByAgent,
      AgentToolResultStatus.disabledInWorkspace,
      AgentToolResultStatus.notConfigured,
    ]);
  });

  test('fingerprints unresolved and previously failed tool calls', () async {
    final provider = _FakeExecutionProvider(
      latestToolCalls: const LoadLatestMessageToolCallsResult(
        messageId: 'message-1',
        hasToolCalls: true,
        toolsToRun: [],
        notFoundToolCallIds: ['missing-id'],
        previouslyFailedToolCallIds: ['failed-id'],
        allToolCalls: [
          AgentMessageToolCall(
            id: 'failed-id',
            name: 'failed-tool',
            argumentsRaw: '{}',
          ),
        ],
      ),
    );

    final result = await AgentToolExecutionService<String>(provider: provider)
        .runAgentLoopIteration(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
        );

    expect(result.decision, AgentIterationDecision.continueIteration);
    expect(result.fingerprint, isNotNull);
    expect(provider.updates.map((update) => update.resultStatus), [
      AgentToolResultStatus.toolNotFound,
      AgentToolResultStatus.executionError,
    ]);
  });

  test('stores each granted tool result as it finishes', () async {
    final slow = Completer<Object?>();
    final fast = Completer<Object?>();
    final provider = _FakeExecutionProvider(
      latestToolCalls: const LoadLatestMessageToolCallsResult(
        messageId: 'message-1',
        hasToolCalls: true,
        toolsToRun: [
          AgentToolToCall(tool: 'slow', id: 'slow-id', argumentsRaw: '{}'),
          AgentToolToCall(tool: 'fast', id: 'fast-id', argumentsRaw: '{}'),
        ],
        notFoundToolCallIds: [],
        previouslyFailedToolCallIds: [],
      ),
      decisions: const {
        'slow-id': AgentToolPermissionResult.granted,
        'fast-id': AgentToolPermissionResult.granted,
      },
      resultFutures: {'slow': slow.future, 'fast': fast.future},
    );
    final service = AgentToolExecutionService<String>(provider: provider);

    final resultFuture = service(
      conversationId: 'conversation-1',
      workspaceId: 'workspace-1',
    );

    await _flushMicrotasks();
    fast.complete('fast result');
    await _flushMicrotasks();

    expect(provider.updateBatches, hasLength(1));
    expect(provider.updateBatches.single.single.toolCallId, 'fast-id');

    slow.complete('slow result');
    final result = await resultFuture;

    expect(result, AgentIterationDecision.continueIteration);
    expect(provider.updateBatches, hasLength(2));
    expect(provider.updateBatches.last.single.toolCallId, 'slow-id');
  });

  test('applies per-tool output policy in the execution service', () async {
    final provider = _FakeExecutionProvider(
      latestToolCalls: const LoadLatestMessageToolCallsResult(
        messageId: 'message-1',
        hasToolCalls: true,
        toolsToRun: [
          AgentToolToCall(tool: 'large', id: 'large-id', argumentsRaw: '{}'),
        ],
        notFoundToolCallIds: [],
        previouslyFailedToolCallIds: [],
      ),
      decisions: const {'large-id': AgentToolPermissionResult.granted},
      results: {'large': 'x' * defaultToolOutputBytes},
    );

    await AgentToolExecutionService<String>(
      provider: provider,
      outputPolicyForTool: (_) => const AgentToolOutputPolicy(maxBytes: 512),
    )(conversationId: 'conversation-1', workspaceId: 'workspace-1');

    final update = provider.updates.single;
    final response = update.responseContextRaw!;
    expect(update.responseRaw, 'x' * defaultToolOutputBytes);
    expect(utf8.encode(response).length, lessThanOrEqualTo(512));
    expect(response, contains('[tool output truncated]'));
    expect(update.outputTruncated, isTrue);
    expect(update.originalResponseBytes, defaultToolOutputBytes);
  });

  test('waits for approvals after storing execution error', () async {
    final provider = _FakeExecutionProvider(
      latestToolCalls: const LoadLatestMessageToolCallsResult(
        messageId: 'message-1',
        hasToolCalls: true,
        toolsToRun: [
          AgentToolToCall(
            tool: 'blocked',
            id: 'blocked-id',
            argumentsRaw: '{}',
          ),
          AgentToolToCall(tool: 'manual', id: 'manual-id', argumentsRaw: '{}'),
        ],
        notFoundToolCallIds: [],
        previouslyFailedToolCallIds: [],
      ),
      decisions: const {
        'blocked-id': AgentToolPermissionResult.granted,
        'manual-id': AgentToolPermissionResult.needsConfirmation,
      },
      results: {'blocked': Exception('blocked')},
    );
    final service = AgentToolExecutionService<String>(provider: provider);

    final result = await service(
      conversationId: 'conversation-1',
      workspaceId: 'workspace-1',
    );

    expect(result, AgentIterationDecision.waitForToolApproval);
    expect(provider.updates.first.approvalRequested, isTrue);
    expect(provider.updates.first.resultStatus, isNull);
    expect(
      provider.updates.last.resultStatus,
      AgentToolResultStatus.executionError,
    );
  });

  test('passes original arguments to approval before execution', () async {
    const argumentsRaw = '{"slug":"research","revision":"r1"}';
    final provider = _FakeExecutionProvider(
      latestToolCalls: const LoadLatestMessageToolCallsResult(
        messageId: 'message-1',
        hasToolCalls: true,
        toolsToRun: [
          AgentToolToCall(
            tool: activateSkillToolName,
            id: 'tool-1',
            argumentsRaw: argumentsRaw,
          ),
        ],
        notFoundToolCallIds: [],
        previouslyFailedToolCallIds: [],
      ),
    );

    await AgentToolExecutionService<String>(provider: provider)(
      conversationId: 'conversation-1',
      workspaceId: 'workspace-1',
    );

    expect(provider.approvalArgumentsRaw['tool-1'], argumentsRaw);
  });

  test('does not execute a tool stopped during permission lookup', () async {
    final decision = Completer<AgentToolApprovalDecision>();
    var cancellationRequested = false;
    final provider = _FakeExecutionProvider(
      latestToolCalls: const LoadLatestMessageToolCallsResult(
        messageId: 'message-1',
        hasToolCalls: true,
        toolsToRun: [
          AgentToolToCall(tool: 'tool-a', id: 'tool-1', argumentsRaw: '{}'),
        ],
        notFoundToolCallIds: [],
        previouslyFailedToolCallIds: [],
      ),
      cancellationRequestedOverride: () => cancellationRequested,
      decisionFutures: {'tool-1': decision.future},
      results: const {'tool-a': 'unexpected'},
    );

    final resultFuture = AgentToolExecutionService<String>(provider: provider)(
      conversationId: 'conversation-1',
      workspaceId: 'workspace-1',
    );
    await _flushMicrotasks();
    cancellationRequested = true;
    decision.complete(
      const AgentToolApprovalDecision(permissionResult: .granted),
    );

    final result = await resultFuture;

    expect(result, AgentIterationDecision.done);
    expect(provider.executedTools, isEmpty);
    expect(provider.updates, [
      isA<AgentToolResultUpdate>()
          .having((update) => update.toolCallId, 'toolCallId', 'tool-1')
          .having(
            (update) => update.resultStatus,
            'resultStatus',
            AgentToolResultStatus.stoppedByUser,
          ),
    ]);
  });

  test('a pre-tool block is persisted and prevents tool execution', () async {
    final provider = _FakeExecutionProvider(
      latestToolCalls: _singleToolCall(),
      decisions: const {'tool-1': AgentToolPermissionResult.granted},
      results: const {'tool-a': 'must not run'},
    );
    final service = AgentToolExecutionService<String>(
      provider: provider,
      lifecycleHookRunner: _FakeLifecycleHookRunner(
        beforeResult: const AgentPreToolHookResult(
          outcome: AgentToolHookOutcome.block,
          reason: 'Policy denied this call.',
        ),
      ),
    );

    await service(conversationId: 'conversation-1', workspaceId: 'workspace-1');

    expect(provider.executedTools, isEmpty);
    final update = provider.updates.single;
    expect(update.resultStatus, AgentToolResultStatus.executionError);
    final response = jsonDecode(update.responseRaw!) as Map<String, dynamic>;
    expect(response['code'], 'hook_blocked');
    expect(response['reason'], 'Policy denied this call.');
  });

  test('an allowing hook still requires the existing tool approval', () async {
    final provider = _FakeExecutionProvider(
      latestToolCalls: _singleToolCall(),
      decisions: const {'tool-1': AgentToolPermissionResult.needsConfirmation},
      results: const {'tool-a': 'must wait'},
    );
    final hooks = _FakeLifecycleHookRunner();

    await AgentToolExecutionService<String>(
      provider: provider,
      lifecycleHookRunner: hooks,
    )(conversationId: 'conversation-1', workspaceId: 'workspace-1');

    expect(hooks.events, isEmpty);
    expect(provider.executedTools, isEmpty);
    expect(provider.updates.single.approvalRequested, isTrue);
  });

  test('pre and post hooks run around an approved tool in order', () async {
    final events = <String>[];
    final provider = _FakeExecutionProvider(
      latestToolCalls: _singleToolCall(),
      decisions: const {'tool-1': AgentToolPermissionResult.granted},
      results: const {'tool-a': 'tool result'},
      events: events,
    );
    final hooks = _FakeLifecycleHookRunner(events: events);

    await AgentToolExecutionService<String>(
      provider: provider,
      lifecycleHookRunner: hooks,
    )(conversationId: 'conversation-1', workspaceId: 'workspace-1');

    expect(events, ['approval', 'pre', 'execute', 'post']);
  });

  test(
    'post-hook context is bounded and does not rewrite tool output',
    () async {
      final provider = _FakeExecutionProvider(
        latestToolCalls: _singleToolCall(),
        decisions: const {'tool-1': AgentToolPermissionResult.granted},
        results: const {'tool-a': 'tool result'},
      );
      final hooks = _FakeLifecycleHookRunner(
        afterResult: AgentPostToolHookResult(
          outcome: AgentToolHookOutcome.success,
          context: 'h' * (4096 + 1),
        ),
      );

      await AgentToolExecutionService<String>(
        provider: provider,
        lifecycleHookRunner: hooks,
      )(conversationId: 'conversation-1', workspaceId: 'workspace-1');

      final update = provider.updates.single;
      expect(update.responseRaw, 'tool result');
      expect(
        utf8.encode(update.responseContextRaw!).length,
        lessThanOrEqualTo(defaultToolOutputBytes),
      );
      expect(update.responseContextRaw, startsWith('Post-tool hook context:'));
      expect(update.responseContextRaw, contains('h' * 4096));
      expect(update.responseContextRaw, contains('Tool output:\ntool result'));
    },
  );

  test('post-hook context appends to explicitly full tool output', () async {
    final provider = _FakeExecutionProvider(
      latestToolCalls: _singleToolCall(),
      decisions: const {'tool-1': AgentToolPermissionResult.granted},
      results: const {'tool-a': 'full tool result'},
    );
    final hooks = _FakeLifecycleHookRunner(
      afterResult: const AgentPostToolHookResult(
        outcome: AgentToolHookOutcome.success,
        context: 'additional context',
      ),
    );

    await AgentToolExecutionService<String>(
      provider: provider,
      lifecycleHookRunner: hooks,
      outputPolicyForTool: (_) =>
          AgentToolOutputPolicy.full(justification: 'test fixture'),
    )(conversationId: 'conversation-1', workspaceId: 'workspace-1');

    final update = provider.updates.single;
    expect(update.responseRaw, 'full tool result');
    expect(update.fullOutputForContext, isTrue);
    expect(update.responseContextRaw, contains('additional context'));
    expect(update.responseContextRaw, contains('full tool result'));
  });

  test('post-hook failure leaves successful tool result intact', () async {
    final provider = _FakeExecutionProvider(
      latestToolCalls: _singleToolCall(),
      decisions: const {'tool-1': AgentToolPermissionResult.granted},
      results: const {'tool-a': 'completed'},
    );
    final hooks = _FakeLifecycleHookRunner(
      afterResult: const AgentPostToolHookResult(
        outcome: AgentToolHookOutcome.timedOut,
      ),
    );

    await AgentToolExecutionService<String>(
      provider: provider,
      lifecycleHookRunner: hooks,
    )(conversationId: 'conversation-1', workspaceId: 'workspace-1');

    final update = provider.updates.single;
    expect(update.resultStatus, AgentToolResultStatus.success);
    expect(update.responseRaw, 'completed');
    expect(update.responseContextRaw, isNull);
    expect(provider.loggedHookFailures, ['lifecycle_hook_post_timeout']);
  });

  test(
    'post-hook logging failure leaves successful tool result intact',
    () async {
      final provider = _FakeExecutionProvider(
        latestToolCalls: _singleToolCall(),
        decisions: const {'tool-1': AgentToolPermissionResult.granted},
        results: const {'tool-a': 'completed'},
        throwOnErrorLog: true,
      );

      await AgentToolExecutionService<String>(
        provider: provider,
        lifecycleHookRunner: _FakeLifecycleHookRunner(
          afterResult: const AgentPostToolHookResult(
            outcome: AgentToolHookOutcome.timedOut,
          ),
        ),
      )(conversationId: 'conversation-1', workspaceId: 'workspace-1');

      expect(
        provider.updates.single.resultStatus,
        AgentToolResultStatus.success,
      );
      expect(provider.updates.single.responseRaw, 'completed');
    },
  );

  test('pre-hook failure stays fail-closed when logging fails', () async {
    final provider = _FakeExecutionProvider(
      latestToolCalls: _singleToolCall(),
      decisions: const {'tool-1': AgentToolPermissionResult.granted},
      results: const {'tool-a': 'must not run'},
      throwOnErrorLog: true,
    );

    await AgentToolExecutionService<String>(
      provider: provider,
      lifecycleHookRunner: _FakeLifecycleHookRunner(
        beforeResult: const AgentPreToolHookResult(
          outcome: AgentToolHookOutcome.timedOut,
        ),
      ),
    )(conversationId: 'conversation-1', workspaceId: 'workspace-1');

    expect(provider.executedTools, isEmpty);
    expect(
      provider.updates.single.resultStatus,
      AgentToolResultStatus.executionError,
    );
  });

  test('cancellation returned by a pre-hook prevents tool execution', () async {
    final provider = _FakeExecutionProvider(
      latestToolCalls: _singleToolCall(),
      decisions: const {'tool-1': AgentToolPermissionResult.granted},
      results: const {'tool-a': 'must not run'},
    );
    final hooks = _FakeLifecycleHookRunner(
      beforeResult: const AgentPreToolHookResult(
        outcome: AgentToolHookOutcome.cancelled,
      ),
    );

    await AgentToolExecutionService<String>(
      provider: provider,
      lifecycleHookRunner: hooks,
    )(conversationId: 'conversation-1', workspaceId: 'workspace-1');

    expect(provider.executedTools, isEmpty);
    expect(
      provider.updates.single.resultStatus,
      AgentToolResultStatus.stoppedByUser,
    );
  });
}

Future<void> _flushMicrotasks() async {
  await Future<void>.delayed(.zero);
}

LoadLatestMessageToolCallsResult<String> _latestToolCalls() {
  return const LoadLatestMessageToolCallsResult(
    messageId: 'message-1',
    hasToolCalls: true,
    toolsToRun: [
      AgentToolToCall(tool: 'tool-a', id: 'tool-1', argumentsRaw: '{}'),
      AgentToolToCall(tool: 'tool-b', id: 'tool-2', argumentsRaw: '{}'),
      AgentToolToCall(tool: 'tool-c', id: 'tool-3', argumentsRaw: '{}'),
    ],
    notFoundToolCallIds: [],
    previouslyFailedToolCallIds: [],
  );
}

LoadLatestMessageToolCallsResult<String> _singleToolCall() =>
    const LoadLatestMessageToolCallsResult(
      messageId: 'message-1',
      hasToolCalls: true,
      toolsToRun: [
        AgentToolToCall(tool: 'tool-a', id: 'tool-1', argumentsRaw: '{}'),
      ],
      notFoundToolCallIds: [],
      previouslyFailedToolCallIds: [],
    );

class _FakeLifecycleHookRunner implements AgentToolLifecycleHookRunner<String> {
  _FakeLifecycleHookRunner({
    this.beforeResult = const AgentPreToolHookResult(
      outcome: AgentToolHookOutcome.allow,
    ),
    this.afterResult = const AgentPostToolHookResult(
      outcome: AgentToolHookOutcome.success,
    ),
    this.events,
  });

  final AgentPreToolHookResult beforeResult;
  final AgentPostToolHookResult afterResult;
  final List<String>? events;

  @override
  Future<AgentPreToolHookResult> beforeTool({
    required AgentToolLifecycleHookRequest<String> request,
    required AgentToolHookCancellationChecker isCancellationRequested,
  }) async {
    events?.add('pre');

    return beforeResult;
  }

  @override
  Future<AgentPostToolHookResult> afterTool({
    required AgentToolLifecycleHookRequest<String> request,
    required bool toolSucceeded,
    required AgentToolHookCancellationChecker isCancellationRequested,
  }) async {
    events?.add('post');

    return afterResult;
  }
}

class _FakeExecutionProvider({
  required final LoadLatestMessageToolCallsResult<String> latestToolCalls,
  final bool cancellationRequested = false,
  final bool Function()? cancellationRequestedOverride,
  final Map<String, AgentToolPermissionResult> decisions = const {},
  final Map<String, Future<AgentToolApprovalDecision>> decisionFutures =
      const {},
  final Map<String, Object?> results = const {},
  final Map<String, Future<Object?>> resultFutures = const {},
  final List<String>? events,
  final bool throwOnErrorLog = false,
}) implements AgentToolExecutionProvider<String> {
  final stoppedMessageIds = <String>[];
  final updateBatches = <List<AgentToolResultUpdate>>[];
  final updates = <AgentToolResultUpdate>[];
  final loggedErrors = <String>[];
  final loggedHookFailures = <String>[];
  final approvalArgumentsRaw = <String, String>{};
  final executedTools = <String>[];

  @override
  Future<LoadLatestMessageToolCallsResult<String>> loadLatestToolCalls({
    required String conversationId,
  }) async {
    return latestToolCalls;
  }

  @override
  Future<AgentToolApprovalDecision> resolveToolApprovalDecision(
    AgentToolApprovalRequest<String> request,
  ) async {
    approvalArgumentsRaw[request.toolCallId] = request.argumentsRaw ?? '{}';
    events?.add('approval');
    final decisionFuture = decisionFutures[request.toolCallId];
    if (decisionFuture != null) return await decisionFuture;

    return AgentToolApprovalDecision(
      permissionResult:
          decisions[request.toolCallId] ??
          AgentToolPermissionResult.needsConfirmation,
    );
  }

  @override
  Future<Object?> runResolvedTool({
    required String conversationId,
    required String toolCallId,
    required String tool,
    required Map<String, dynamic> arguments,
  }) async {
    executedTools.add(tool);
    events?.add('execute');
    final future = resultFutures[tool];
    if (future != null) return await future;

    final result = results[tool];
    if (result is Object) {
      if (result is Exception) throw result;

      return result;
    }

    return null;
  }

  @override
  Future<AgentIterationDecision> getAgentIterationDecision({
    required String messageId,
  }) async {
    return AgentIterationDecision.continueIteration;
  }

  @override
  bool isCancellationRequested(String conversationId) {
    return cancellationRequestedOverride?.call() ?? cancellationRequested;
  }

  @override
  Future<void> stopPendingTools({
    required String messageId,
    required String conversationId,
  }) async {
    stoppedMessageIds.add(messageId);
  }

  @override
  Future<void> updateToolResults({
    required String conversationId,
    required String messageId,
    required List<AgentToolResultUpdate> updates,
  }) async {
    updateBatches.add(updates);
    this.updates.addAll(updates);
  }

  @override
  String toolIdentifier(String tool) {
    return tool;
  }

  @override
  void logToolExecutionError(AgentToolExecutionErrorRequest<String> request) {
    if (throwOnErrorLog) throw StateError('logger failed');

    loggedErrors.add(request.toolCallId);
    final phase = request.failurePhase;
    if (phase != null && phase.startsWith('lifecycle_hook_post_')) {
      loggedHookFailures.add(phase);
    }
  }
}
