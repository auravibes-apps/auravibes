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

  test('throws when conversation has no workspace', () async {
    final dataProvider = _FakeAgentConversationDataProvider(workspaceId: null);
    final usecase = AgentService(
      provider: dataProvider,
      sendQueueRuntime: _FakeAgentSendQueueRuntime(),
      agentCancellationRuntime: AgentCancellationRuntime(),
      rateLimitRetryRuntime: AgentRateLimitRetryRuntime(
        start: (_, _) {},
        clear: (_) {},
      ),
    );

    expect(
      () => usecase(
        conversationId: 'conversation-1',
        context: const AgentIterationContext(
          origin: AgentIterationOrigin.userMessage,
        ),
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('creates queued draft messages before continuation', () async {
    final dataProvider = _FakeAgentConversationDataProvider();
    final sendQueue = _FakeAgentSendQueueRuntime(
      drafts: const [AgentQueuedDraft(content: 'queued')],
    );
    final usecase = AgentService(
      provider: dataProvider,
      sendQueueRuntime: sendQueue,
      agentCancellationRuntime: AgentCancellationRuntime(),
      rateLimitRetryRuntime: AgentRateLimitRetryRuntime(
        start: (_, _) {},
        clear: (_) {},
      ),
    );

    final result = await usecase(
      conversationId: 'conversation-1',
      context: const AgentIterationContext(
        origin: AgentIterationOrigin.manualContinue,
        ackMessageIds: ['existing'],
      ),
    );

    expect(result, AgentIterationDecision.done);
    expect(dataProvider.createdContents, ['queued']);
    expect(dataProvider.continuationContexts.single!.ackMessageIds, [
      'existing',
      'created-1',
    ]);
  });

  test('runs allowed tools when continuation returns tool calls', () async {
    final dataProvider = _FakeAgentConversationDataProvider(
      continueResults: const [
        ContinueAgentResult(messageId: 'assistant-1', hasToolCalls: true),
      ],
      toolDecisions: const [AgentIterationDecision.done],
    );
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
    expect(dataProvider.allowedToolRuns, ['conversation-1:workspace-1']);
  });

  test('retries rate limits using known delay', () async {
    var currentTime = DateTime(2026);
    final retryEvents = <String>[];
    final sleeps = <Duration>[];
    final dataProvider = _FakeAgentConversationDataProvider(
      continueErrors: [Exception('RateLimitException: retry after 2 seconds')],
    );
    final usecase = AgentService(
      provider: dataProvider,
      sendQueueRuntime: _FakeAgentSendQueueRuntime(),
      agentCancellationRuntime: AgentCancellationRuntime(),
      rateLimitRetryRuntime: AgentRateLimitRetryRuntime(
        start: (_, retryAt) => retryEvents.add('start:$retryAt'),
        clear: (conversationId) => retryEvents.add('clear:$conversationId'),
      ),
      now: () => currentTime,
      sleep: (duration) {
        sleeps.add(duration);
        currentTime = currentTime.add(duration);

        return Future<void>.value();
      },
    );

    final result = await usecase(
      conversationId: 'conversation-1',
      context: const AgentIterationContext(
        origin: AgentIterationOrigin.userMessage,
      ),
    );

    expect(result, AgentIterationDecision.done);
    expect(sleeps, [const Duration(seconds: 1), const Duration(seconds: 1)]);
    expect(retryEvents, [
      'start:2026-01-01 00:00:02.000',
      'clear:conversation-1',
    ]);
    expect(dataProvider.continuationContexts, hasLength(2));
  });

  test('retries resource exhausted errors using minute delay', () async {
    var currentTime = DateTime(2026);
    final sleeps = <Duration>[];
    final dataProvider = _FakeAgentConversationDataProvider(
      continueErrors: [Exception('RESOURCE_EXHAUSTED: try again in 1 minute')],
    );
    final usecase = AgentService(
      provider: dataProvider,
      sendQueueRuntime: _FakeAgentSendQueueRuntime(),
      agentCancellationRuntime: AgentCancellationRuntime(),
      rateLimitRetryRuntime: AgentRateLimitRetryRuntime(
        start: (_, _) {},
        clear: (_) {},
      ),
      now: () => currentTime,
      sleep: (duration) {
        sleeps.add(duration);
        currentTime = currentTime.add(duration);

        return Future<void>.value();
      },
    );

    final result = await usecase(
      conversationId: 'conversation-1',
      context: const AgentIterationContext(
        origin: AgentIterationOrigin.userMessage,
      ),
    );

    expect(result, AgentIterationDecision.done);
    expect(sleeps, hasLength(60));
    expect(sleeps.toSet(), {const Duration(seconds: 1)});
  });

  test('cancels during rate-limit retry wait', () async {
    var currentTime = DateTime(2026);
    final cancellationRuntime = AgentCancellationRuntime();
    final dataProvider = _FakeAgentConversationDataProvider(
      continueErrors: [Exception('429')],
    );
    final sendQueue = _FakeAgentSendQueueRuntime();
    final usecase = AgentService(
      provider: dataProvider,
      sendQueueRuntime: sendQueue,
      agentCancellationRuntime: cancellationRuntime,
      rateLimitRetryRuntime: AgentRateLimitRetryRuntime(
        start: (_, _) => cancellationRuntime.requestStop('conversation-1'),
        clear: (_) {},
      ),
      now: () => currentTime,
      sleep: (duration) {
        currentTime = currentTime.add(duration);

        return Future<void>.value();
      },
    );

    final result = await usecase(
      conversationId: 'conversation-1',
      context: const AgentIterationContext(
        origin: AgentIterationOrigin.userMessage,
      ),
    );

    expect(result, AgentIterationDecision.done);
    expect(sendQueue.cleared, ['conversation-1']);
    expect(dataProvider.continuationContexts, hasLength(1));
  });

  test('rethrows non-rate-limit errors', () async {
    final dataProvider = _FakeAgentConversationDataProvider(
      continueErrors: [StateError('broken')],
    );
    final usecase = AgentService(
      provider: dataProvider,
      sendQueueRuntime: _FakeAgentSendQueueRuntime(),
      agentCancellationRuntime: AgentCancellationRuntime(),
      rateLimitRetryRuntime: AgentRateLimitRetryRuntime(
        start: (_, _) {},
        clear: (_) {},
      ),
    );

    expect(
      () => usecase(
        conversationId: 'conversation-1',
        context: const AgentIterationContext(
          origin: AgentIterationOrigin.userMessage,
        ),
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('cancels after queued drafts and marks ack messages sent', () async {
    final cancellationRuntime = AgentCancellationRuntime();
    final dataProvider = _FakeAgentConversationDataProvider(
      onAutoCompact: () => cancellationRuntime.requestStop('conversation-1'),
    );
    final sendQueue = _FakeAgentSendQueueRuntime(
      drafts: const [AgentQueuedDraft(content: 'queued')],
    );
    final usecase = AgentService(
      provider: dataProvider,
      sendQueueRuntime: sendQueue,
      agentCancellationRuntime: cancellationRuntime,
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
    expect(dataProvider.markedSent, ['created-1']);
    expect(sendQueue.cleared, ['conversation-1']);
    expect(dataProvider.continuationContexts, hasLength(1));
  });
}

class _FakeAgentConversationDataProvider implements AgentProvider {
  _FakeAgentConversationDataProvider({
    this.workspaceId = 'workspace-1',
    List<ContinueAgentResult>? continueResults,
    List<Object>? continueErrors,
    List<AgentIterationDecision>? toolDecisions,
    this.onAutoCompact,
  }) : continueResults = List.of(
         continueResults ??
             const [
               ContinueAgentResult(
                 messageId: 'assistant-1',
                 hasToolCalls: false,
               ),
             ],
       ),
       continueErrors = List.of(continueErrors ?? const []),
       toolDecisions = List.of(
         toolDecisions ?? const [AgentIterationDecision.done],
       );

  final String? workspaceId;
  final List<ContinueAgentResult> continueResults;
  final List<Object> continueErrors;
  final List<AgentIterationDecision> toolDecisions;
  final void Function()? onAutoCompact;
  final workspaceLookups = <String>[];
  final continuationContexts = <AgentIterationContext?>[];
  final createdContents = <String>[];
  final markedSent = <String>[];
  final allowedToolRuns = <String>[];

  @override
  Future<ContinueAgentResult> continueAgent({
    required String conversationId,
    AgentIterationContext? context,
  }) async {
    continuationContexts.add(context);
    if (continueErrors.isNotEmpty) {
      Error.throwWithStackTrace(continueErrors.removeAt(0), StackTrace.current);
    }

    return continueResults.isEmpty
        ? const ContinueAgentResult(
            messageId: 'assistant-1',
            hasToolCalls: false,
          )
        : continueResults.removeAt(0);
  }

  @override
  Future<AgentIterationDecision> runAllowedTools({
    required String conversationId,
    required String workspaceId,
  }) async {
    allowedToolRuns.add('$conversationId:$workspaceId');

    return toolDecisions.isEmpty
        ? AgentIterationDecision.done
        : toolDecisions.removeAt(0);
  }

  @override
  Future<void> autoCompactConversation({
    required String conversationId,
  }) async {
    onAutoCompact?.call();
  }

  @override
  Future<String?> getWorkspaceId(String conversationId) async {
    workspaceLookups.add(conversationId);

    return workspaceId;
  }

  @override
  Future<List<AgentConversationMessage>> getMessages(String conversationId) {
    throw StateError('messages should not be loaded');
  }

  @override
  Future<AgentCreatedMessage> createQueuedUserMessage({
    required String conversationId,
    required String content,
  }) async {
    createdContents.add(content);

    return AgentCreatedMessage(id: 'created-${createdContents.length}');
  }

  @override
  Future<void> markMessagesSent(List<String> messageIds) async {
    markedSent.addAll(messageIds);
  }
}

class _FakeAgentSendQueueRuntime implements AgentSendQueueRuntime {
  _FakeAgentSendQueueRuntime({
    this.drafts = const [],
  });

  final List<AgentQueuedDraft> drafts;
  final cleared = <String>[];
  var _didDequeue = false;

  @override
  void clear(String conversationId) {
    cleared.add(conversationId);
  }

  @override
  List<AgentQueuedDraft> dequeueAll(String conversationId) {
    if (_didDequeue) return const [];
    _didDequeue = true;

    return drafts;
  }
}
