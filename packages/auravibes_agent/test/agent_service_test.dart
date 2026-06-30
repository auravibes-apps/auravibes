import 'package:auravibes_agent/auravibes_agent.dart';
import 'package:auravibes_agent/src/agent_service.dart';
import 'package:test/test.dart';

void main() {
  test('returns done when continuation has no tool calls', () async {
    final dataProvider = _FakeAgentConversationDataProvider();
    final usecase = AgentService(
      provider: dataProvider,
      sendQueueRuntime: _FakeAgentSendQueueRuntime(),
      agentCancellationRuntime: AgentCancellationRuntime(),
      rateLimitRetryRuntime: AgentRateLimitRetryRuntime(
        start: (_, _) {},
        clear: (_) {},
      ),
    );

    final result = await usecase(
      conversationId: 'conversation-1',
      context: const AgentIterationContext(
        origin: AgentIterationOrigin.userMessage,
      ),
    );

    expect(result, AgentIterationDecision.done);
    expect(dataProvider.workspaceLookups, ['conversation-1']);
  });
}

class _FakeAgentConversationDataProvider implements AgentProvider {
  final workspaceLookups = <String>[];

  @override
  Future<ContinueAgentResult> continueAgent({
    required String conversationId,
    AgentIterationContext? context,
  }) async {
    return const ContinueAgentResult(
      messageId: 'assistant-1',
      hasToolCalls: false,
    );
  }

  @override
  Future<AgentIterationDecision> runAllowedTools({
    required String conversationId,
    required String workspaceId,
  }) {
    throw StateError('tools should not run');
  }

  @override
  Future<void> autoCompactConversation({
    required String conversationId,
  }) async {}

  @override
  Future<String?> getWorkspaceId(String conversationId) async {
    workspaceLookups.add(conversationId);

    return 'workspace-1';
  }

  @override
  Future<List<AgentConversationMessage>> getMessages(String conversationId) {
    throw StateError('messages should not be loaded');
  }

  @override
  Future<AgentCreatedMessage> createQueuedUserMessage({
    required String conversationId,
    required String content,
  }) {
    throw StateError('queued messages should not be created');
  }

  @override
  Future<void> markMessagesSent(List<String> messageIds) {
    throw StateError('messages should not be marked sent');
  }
}

class _FakeAgentSendQueueRuntime implements AgentSendQueueRuntime {
  @override
  void clear(String conversationId) {}

  @override
  List<AgentQueuedDraft> dequeueAll(String conversationId) {
    return const [];
  }
}
