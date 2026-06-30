import 'package:auravibes_agent/auravibes_agent.dart';
import 'package:test/test.dart';

void main() {
  test('exposes agent and conversation modules', () async {
    final provider = _FakeAgentProvider();
    final service = _service(provider);

    final decision = await service.agent.continueTurn(
      conversationId: 'conversation-1',
      context: const AgentIterationContext(
        origin: AgentIterationOrigin.userMessage,
      ),
    );
    final message = await service.conversations.create(
      conversationId: 'conversation-1',
      content: 'hello',
    );
    final messages = await service.conversations.getMessages(
      conversationId: 'conversation-1',
    );

    expect(decision, AgentIterationDecision.done);
    expect(message.id, 'created-1');
    expect(messages.single.content, 'hello');
    expect(provider.createdContents, ['hello']);
  });
}

AuraAgentService<String> _service(_FakeAgentProvider provider) {
  return AuraAgentService<String>(
    data: provider,
    tools: _FakeToolProvider(),
    runtime: _FakeRuntimeProvider(),
  );
}

class _FakeAgentProvider implements AgentDataProvider {
  final createdContents = <String>[];

  @override
  Future<void> autoCompactConversation({
    required String conversationId,
  }) async {}

  @override
  Future<AgentCreatedMessage> createQueuedUserMessage({
    required String conversationId,
    required String content,
  }) async {
    createdContents.add(content);

    return const AgentCreatedMessage(id: 'created-1');
  }

  @override
  Future<ContinueAgentResult> continueAgent({
    required String conversationId,
    AgentIterationContext? context,
  }) async {
    return const ContinueAgentResult(
      messageId: 'message-1',
      hasToolCalls: false,
    );
  }

  @override
  Future<String?> getWorkspaceId(String conversationId) async => 'workspace-1';

  @override
  Future<List<AgentConversationMessage>> getMessages(
    String conversationId,
  ) async {
    return [
      AgentConversationMessage(
        id: 'message-1',
        conversationId: conversationId,
        content: 'hello',
        type: 'text',
        status: 'sent',
        isUser: true,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    ];
  }

  @override
  Future<void> markMessagesSent(List<String> messageIds) async {}

  @override
  Future<void> stopLatestPendingTools(String conversationId) async {}

  @override
  Future<AgentIterationDecision> runAllowedTools({
    required String conversationId,
    required String workspaceId,
  }) async {
    return AgentIterationDecision.done;
  }
}

class _FakeToolProvider implements AgentToolProvider<String> {
  @override
  Future<List<AgentToolMessage>> loadMessages(String conversationId) async {
    return const [AgentToolMessage(id: 'message-1', isUser: false)];
  }

  @override
  Future<LoadLatestMessageToolCallsResult<String>> loadLatestToolCalls({
    required String conversationId,
  }) async {
    return const LoadLatestMessageToolCallsResult(
      messageId: 'message-1',
      hasToolCalls: false,
      toolsToRun: [],
      notFoundToolCallIds: [],
      previouslyFailedToolCallIds: [],
    );
  }

  @override
  String? resolveTool(String toolName) => 'tool';

  @override
  Future<AgentToolApprovalDecision> resolveToolApprovalDecision({
    required String conversationId,
    required String workspaceId,
    required String toolCallId,
    required String resolvedTool,
  }) async {
    return const AgentToolApprovalDecision(
      permissionResult: AgentToolPermissionResult.granted,
    );
  }

  @override
  Future<Object?> runResolvedTool({
    required String conversationId,
    required String tool,
    required Map<String, dynamic> arguments,
  }) async {
    return null;
  }

  @override
  Future<AgentIterationDecision> getAgentIterationDecision({
    required String messageId,
  }) async {
    return AgentIterationDecision.done;
  }

  @override
  Future<List<AgentToolCallState>?> getToolCallStates(String messageId) async {
    return const [];
  }

  @override
  Future<AgentToolResumeReference?> getResumeReference(String messageId) async {
    return null;
  }

  @override
  Future<void> continueAgent({
    required String conversationId,
    required AgentIterationContext context,
  }) async {}

  @override
  Future<AgentIterationDecision> runAllowedTools({
    required String conversationId,
    required String workspaceId,
  }) async {
    return AgentIterationDecision.done;
  }

  @override
  bool isCancellationRequested(String conversationId) => false;

  @override
  Future<void> stopPendingTools({required String messageId}) async {}

  @override
  Future<void> stopPendingToolCalls({required String messageId}) async {}

  @override
  Future<void> updateToolResults({
    required String messageId,
    required List<AgentToolResultUpdate> updates,
  }) async {}

  @override
  String toolIdentifier(String tool) => tool;

  @override
  Future<AgentApprovableToolCall?> loadToolCall({
    required String messageId,
    required String toolCallId,
  }) async {
    return null;
  }

  @override
  Future<void> grantToolForConversation({
    required String conversationId,
    required String tool,
  }) async {}

  @override
  Future<void> updateToolCallResult({
    required String messageId,
    required String toolCallId,
    required AgentToolResultStatus resultStatus,
    String? responseRaw,
  }) async {}

  @override
  Future<void> resumeConversationIfReady({required String messageId}) async {}

  @override
  Future<bool> skipToolCall({
    required String messageId,
    required String toolCallId,
  }) async {
    return false;
  }

  @override
  void logToolExecutionError({
    required String conversationId,
    required String toolCallId,
    required String tool,
    required Object error,
    required StackTrace stackTrace,
  }) {}
}

class _EmptySendQueueRuntime implements AgentSendQueueRuntime {
  const _EmptySendQueueRuntime();

  @override
  void clear(String conversationId) {}

  @override
  List<AgentQueuedDraft> dequeueAll(String conversationId) => const [];
}

class _FakeRuntimeProvider implements AgentRuntimeProvider {
  _FakeRuntimeProvider();

  @override
  final AgentCancellationRuntime cancellationRuntime =
      AgentCancellationRuntime();

  @override
  final AgentRateLimitRetryRuntime rateLimitRetryRuntime =
      AgentRateLimitRetryRuntime(
        start: (_, _) {},
        clear: (_) {},
      );

  @override
  final AgentSendQueueRuntime sendQueueRuntime = const _EmptySendQueueRuntime();
}
