import 'package:auravibes_agent/auravibes_agent.dart';
import 'package:auravibes_agent/src/agent_tool_execution_service.dart';
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
        'tool-2': AgentToolPermissionResult.disabledInWorkspace,
        'tool-3': AgentToolPermissionResult.notConfigured,
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
      AgentToolResultStatus.disabledInWorkspace,
      AgentToolResultStatus.notConfigured,
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
      expect(provider.loggedErrors, ['tool-3']);
    },
  );
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

class _FakeExecutionProvider implements AgentToolExecutionProvider<String> {
  _FakeExecutionProvider({
    required this.latestToolCalls,
    this.cancellationRequested = false,
    this.decisions = const {},
    this.results = const {},
  });

  final LoadLatestMessageToolCallsResult<String> latestToolCalls;
  final bool cancellationRequested;
  final Map<String, AgentToolPermissionResult> decisions;
  final Map<String, Object?> results;
  final stoppedMessageIds = <String>[];
  final updates = <AgentToolResultUpdate>[];
  final loggedErrors = <String>[];

  @override
  Future<LoadLatestMessageToolCallsResult<String>> loadLatestToolCalls({
    required String conversationId,
  }) async {
    return latestToolCalls;
  }

  @override
  Future<AgentToolApprovalDecision> resolveToolApprovalDecision({
    required String conversationId,
    required String workspaceId,
    required String toolCallId,
    required String resolvedTool,
  }) async {
    return AgentToolApprovalDecision(
      permissionResult:
          decisions[toolCallId] ?? AgentToolPermissionResult.needsConfirmation,
    );
  }

  @override
  Future<Object?> runResolvedTool({
    required String conversationId,
    required String tool,
    required Map<String, dynamic> arguments,
  }) async {
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
    return cancellationRequested;
  }

  @override
  Future<void> stopPendingTools({required String messageId}) async {
    stoppedMessageIds.add(messageId);
  }

  @override
  Future<void> updateToolResults({
    required String messageId,
    required List<AgentToolResultUpdate> updates,
  }) async {
    this.updates.addAll(updates);
  }

  @override
  String toolIdentifier(String tool) {
    return tool;
  }

  @override
  void logToolExecutionError({
    required String conversationId,
    required String toolCallId,
    required String tool,
    required Object error,
    required StackTrace stackTrace,
  }) {
    loggedErrors.add(toolCallId);
  }
}
