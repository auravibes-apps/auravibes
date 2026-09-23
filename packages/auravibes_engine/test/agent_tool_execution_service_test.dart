import 'dart:async';

import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_engine/src/agent_tool_execution_service.dart';
import 'package:test/test.dart';

void main() {
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
        'Tool execution failed.',
      );
      expect(provider.loggedErrors, ['tool-3']);
    },
  );

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
    expect(
      provider.updates.single.resultStatus,
      AgentToolResultStatus.executionError,
    );
  });

  test('passes original arguments to approval before execution', () async {
    const argumentsRaw =
        '{"skill":"research","tool":"search","args":{},"revision":"r1"}';
    final provider = _FakeExecutionProvider(
      latestToolCalls: const LoadLatestMessageToolCallsResult(
        messageId: 'message-1',
        hasToolCalls: true,
        toolsToRun: [
          AgentToolToCall(
            tool: callSkillToolName,
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

class _FakeExecutionProvider({
  required final LoadLatestMessageToolCallsResult<String> latestToolCalls,
  final bool cancellationRequested = false,
  final bool Function()? cancellationRequestedOverride,
  final Map<String, AgentToolPermissionResult> decisions = const {},
  final Map<String, Future<AgentToolApprovalDecision>> decisionFutures =
      const {},
  final Map<String, Object?> results = const {},
  final Map<String, Future<Object?>> resultFutures = const {},
}) implements AgentToolExecutionProvider<String> {
  final stoppedMessageIds = <String>[];
  final updateBatches = <List<AgentToolResultUpdate>>[];
  final updates = <AgentToolResultUpdate>[];
  final loggedErrors = <String>[];
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
    required String tool,
    required Map<String, dynamic> arguments,
  }) async {
    executedTools.add(tool);
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
    loggedErrors.add(request.toolCallId);
  }
}
