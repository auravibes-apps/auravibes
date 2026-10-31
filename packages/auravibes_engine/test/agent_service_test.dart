import 'dart:async';

import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_engine/src/agent_service.dart';
import 'package:genkit/plugin.dart' show GenkitException;
import 'package:test/test.dart';

import 'support/fake_cancellation_effects.dart';

AgentService _buildAgentService(
  _FakeAgentConversationDataProvider dataProvider, {
  AgentSendQueueRuntime? sendQueueRuntime,
  AgentCancellationEffects? cancellationEffects,
  AgentRateLimitRetryRuntime? rateLimitRetryRuntime,
  Duration? rateLimitRetryDelay,
  int? iterationLimit,
  DateTime Function()? now,
  Future<void> Function(Duration)? sleep,
}) {
  return AgentService(
    data: dataProvider,
    models: dataProvider,
    tools: dataProvider,
    sendQueueRuntime: sendQueueRuntime ?? _FakeAgentSendQueueRuntime(),
    cancellationEffects: cancellationEffects ?? FakeCancellationEffects(),
    rateLimitRetryRuntime:
        rateLimitRetryRuntime ??
        AgentRateLimitRetryRuntime(start: (_, _) {}, clear: (_) {}),
    rateLimitRetryDelay: rateLimitRetryDelay ?? defaultAgentRateLimitRetryDelay,
    iterationLimit: iterationLimit ?? defaultAgentIterationLimit,
    now: now ?? DateTime.now,
    sleep: sleep ?? Future<void>.delayed,
  );
}

void main() {
  test('returns done when continuation has no tool calls', () async {
    final dataProvider = _FakeAgentConversationDataProvider();
    final usecase = _buildAgentService(dataProvider);

    final result = await usecase(
      conversationId: 'conversation-1',
      context: const AgentIterationContext(origin: .userMessage),
    );

    expect(result, AgentIterationDecision.done);
    expect(dataProvider.workspaceLookups, ['conversation-1']);
  });

  test('throws when conversation has no workspace', () async {
    final dataProvider = _FakeAgentConversationDataProvider(workspaceId: null);
    final usecase = _buildAgentService(dataProvider);

    await expectLater(
      () => usecase(
        conversationId: 'conversation-1',
        context: const AgentIterationContext(origin: .userMessage),
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('creates queued draft messages before continuation', () async {
    final dataProvider = _FakeAgentConversationDataProvider();
    final sendQueue = _FakeAgentSendQueueRuntime(
      drafts: const [AgentQueuedDraft(content: 'queued')],
    );
    final usecase = _buildAgentService(
      dataProvider,
      sendQueueRuntime: sendQueue,
    );

    final result = await usecase(
      conversationId: 'conversation-1',
      context: const AgentIterationContext(
        origin: .manualContinue,
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
    final usecase = _buildAgentService(dataProvider);

    final result = await usecase(
      conversationId: 'conversation-1',
      context: const AgentIterationContext(origin: .userMessage),
    );

    expect(result, AgentIterationDecision.done);
    expect(dataProvider.allowedToolRuns, ['conversation-1:workspace-1']);
  });

  test('waits for all allowed tools before the next model request', () async {
    final releaseTools = Completer<void>();
    final dataProvider = _FakeAgentConversationDataProvider(
      continueResults: const [
        ContinueAgentResult(messageId: 'assistant-1', hasToolCalls: true),
        ContinueAgentResult(messageId: 'assistant-2', hasToolCalls: false),
      ],
      toolDecisions: const [
        AgentIterationDecision.continueIteration,
        AgentIterationDecision.done,
      ],
      onRunAllowedTools: () => releaseTools.future,
    );
    final usecase = _buildAgentService(dataProvider);

    final result = usecase(
      conversationId: 'conversation-1',
      context: const AgentIterationContext(origin: .userMessage),
    );
    await Future<void>.delayed(const Duration(milliseconds: 1));

    expect(dataProvider.continuationContexts, hasLength(1));
    releaseTools.complete();

    expect(await result, AgentIterationDecision.done);
    expect(dataProvider.continuationContexts, hasLength(2));
  });

  test('stops a continuing tool loop at the iteration limit', () async {
    final dataProvider = _FakeAgentConversationDataProvider(
      continueResults: List.filled(
        4,
        const ContinueAgentResult(messageId: 'assistant-1', hasToolCalls: true),
      ),
      toolDecisions: List.filled(4, AgentIterationDecision.continueIteration),
    );
    final usecase = _buildAgentService(dataProvider, iterationLimit: 3);

    final result = await usecase(
      conversationId: 'conversation-1',
      context: const AgentIterationContext(origin: .userMessage),
    );

    expect(result, AgentIterationDecision.iterationLimitReached);
    expect(dataProvider.continuationContexts, hasLength(3));
    expect(dataProvider.allowedToolRuns, hasLength(3));
  });

  test('does not retry rate limits inferred from message text', () async {
    final error = Exception('RateLimitException: retry after 2 seconds');
    final dataProvider = _FakeAgentConversationDataProvider(
      continueErrors: [error],
    );
    final usecase = _buildAgentService(dataProvider);

    await expectLater(
      () => usecase(
        conversationId: 'conversation-1',
        context: const AgentIterationContext(origin: .userMessage),
      ),
      throwsA(same(error)),
    );

    expect(dataProvider.continuationContexts, hasLength(1));
  });

  test('retries rate limits using known delay', () async {
    var currentTime = DateTime(2026);
    final retryEvents = <String>[];
    final sleeps = <Duration>[];
    final dataProvider = _FakeAgentConversationDataProvider(
      continueErrors: [
        AgentRateLimitRetryException(
          providerException: GenkitException(
            'Provider rate limit.',
            status: .resourceExhausted,
          ),
          retryAfter: const Duration(seconds: 2),
        ),
      ],
    );
    final usecase = _buildAgentService(
      dataProvider,
      rateLimitRetryRuntime: .new(
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
      context: const AgentIterationContext(origin: .userMessage),
    );

    expect(result, AgentIterationDecision.done);
    expect(sleeps, [const Duration(seconds: 1), const Duration(seconds: 1)]);
    expect(retryEvents, [
      'start:2026-01-01 00:00:02.000',
      'clear:conversation-1',
    ]);
    expect(dataProvider.continuationContexts, hasLength(2));
  });

  test('does not retry quota exhaustion without Retry-After', () async {
    final error = GenkitException(
      'RESOURCE_EXHAUSTED: try again in 1 minute',
      status: .resourceExhausted,
    );
    final dataProvider = _FakeAgentConversationDataProvider(
      continueErrors: [error],
    );
    final usecase = _buildAgentService(dataProvider);

    await expectLater(
      () => usecase(
        conversationId: 'conversation-1',
        context: const AgentIterationContext(origin: .userMessage),
      ),
      throwsA(same(error)),
    );

    expect(dataProvider.continuationContexts, hasLength(1));
  });

  test('preserves acknowledgement identity until the exact retry delay', () async {
    final started = DateTime.utc(2026);
    var currentTime = started;
    final sleeps = <Duration>[];
    final dataProvider = _FakeAgentConversationDataProvider(
      continueErrors: [
        AgentRateLimitRetryException(
          providerException: ProviderHttpFailureException(429, 'Rate limited.'),
          retryAfter: const Duration(seconds: 12),
        ),
      ],
      continueResults: const [
        ContinueAgentResult(messageId: 'assistant-1', hasToolCalls: true),
      ],
      onRunAllowedTools: () async {
        expect(currentTime.difference(started), const Duration(seconds: 12));
      },
    );
    final usecase = _buildAgentService(
      dataProvider,
      now: () => currentTime,
      sleep: (duration) async {
        expect(dataProvider.continuationContexts, hasLength(1));
        expect(dataProvider.allowedToolRuns, isEmpty);
        sleeps.add(duration);
        currentTime = currentTime.add(duration);
      },
    );

    final result = await usecase(
      conversationId: 'conversation-1',
      context: const AgentIterationContext(
        origin: .userMessage,
        ackMessageIds: ['original-user'],
      ),
    );

    expect(result, AgentIterationDecision.done);
    expect(
      sleeps.fold(Duration.zero, (total, duration) => total + duration),
      const Duration(seconds: 12),
    );
    expect(dataProvider.continuationContexts, hasLength(2));
    for (final context in dataProvider.continuationContexts) {
      expect(context?.ackMessageIds, ['original-user']);
    }
    expect(dataProvider.allowedToolRuns, ['conversation-1:workspace-1']);
  });

  test('caps explicit Retry-After delays at 60 seconds', () async {
    for (final retryAfter in [
      const Duration(seconds: 120),
      const Duration(minutes: 10),
    ]) {
      var currentTime = DateTime(2026);
      final retryAt = <DateTime>[];
      final dataProvider = _FakeAgentConversationDataProvider(
        continueErrors: [
          AgentRateLimitRetryException(
            providerException: GenkitException(
              'Provider rate limit.',
              status: .resourceExhausted,
            ),
            retryAfter: retryAfter,
          ),
        ],
      );
      final usecase = _buildAgentService(
        dataProvider,
        rateLimitRetryRuntime: .new(
          start: (_, value) => retryAt.add(value),
          clear: (_) {},
        ),
        now: () => currentTime,
        sleep: (duration) {
          currentTime = currentTime.add(duration);
          return Future<void>.value();
        },
      );

      expect(
        await usecase(
          conversationId: 'conversation-1',
          context: const AgentIterationContext(origin: .userMessage),
        ),
        AgentIterationDecision.done,
      );
      expect(retryAt.single, DateTime(2026).add(const Duration(seconds: 60)));
    }
  });

  test('does not retry a bare HTTP 429 message', () async {
    final error = Exception('HTTP 429');
    final dataProvider = _FakeAgentConversationDataProvider(
      continueErrors: [error],
    );
    final usecase = _buildAgentService(dataProvider);

    await expectLater(
      () => usecase(
        conversationId: 'conversation-1',
        context: const AgentIterationContext(origin: .userMessage),
      ),
      throwsA(same(error)),
    );

    expect(dataProvider.continuationContexts, hasLength(1));
  });

  test(
    'uses provider Retry-After hints and caps delay at 60 seconds',
    () async {
      for (final testCase in [
        (
          retryAfter: const Duration(seconds: 2),
          expectedDelay: const Duration(seconds: 2),
        ),
        (
          retryAfter: const Duration(seconds: 120),
          expectedDelay: const Duration(seconds: 60),
        ),
      ]) {
        var currentTime = DateTime(2026);
        final retryAt = <DateTime>[];
        final dataProvider = _FakeAgentConversationDataProvider(
          continueErrors: [
            AgentRateLimitRetryException(
              providerException: GenkitException(
                'Provider API request failed.',
              ),
              retryAfter: testCase.retryAfter,
            ),
          ],
        );
        final usecase = _buildAgentService(
          dataProvider,
          rateLimitRetryRuntime: .new(
            start: (_, value) => retryAt.add(value),
            clear: (_) {},
          ),
          now: () => currentTime,
          sleep: (duration) {
            currentTime = currentTime.add(duration);
            return Future<void>.value();
          },
        );

        expect(
          await usecase(
            conversationId: 'conversation-1',
            context: const AgentIterationContext(origin: .userMessage),
          ),
          AgentIterationDecision.done,
        );
        expect(retryAt.single, DateTime(2026).add(testCase.expectedDelay));
      }
    },
  );

  test(
    'preserves provider Retry-After provenance after retry budget exhaustion',
    () async {
      var currentTime = DateTime(2026);
      final retryAt = <DateTime>[];
      final providerException = GenkitException(
        'Provider API request failed (HTTP 429).',
      );
      final retryError = AgentRateLimitRetryException(
        providerException: providerException,
        retryAfter: const Duration(seconds: 2),
      );
      final sendQueue = _FakeAgentSendQueueRuntime(
        drafts: const [AgentQueuedDraft(content: 'queued')],
      );
      final dataProvider = _FakeAgentConversationDataProvider(
        continueErrors: [retryError, retryError],
      );
      final usecase = _buildAgentService(
        dataProvider,
        sendQueueRuntime: sendQueue,
        rateLimitRetryRuntime: .new(
          start: (_, value) => retryAt.add(value),
          clear: (_) {},
        ),
        now: () => currentTime,
        sleep: (duration) {
          currentTime = currentTime.add(duration);
          return Future<void>.value();
        },
      );

      await expectLater(
        () => usecase(
          conversationId: 'conversation-1',
          context: const AgentIterationContext(origin: .userMessage),
        ),
        throwsA(same(retryError)),
      );
      expect(retryAt.single, DateTime(2026).add(const Duration(seconds: 2)));
      expect(dataProvider.continuationContexts, hasLength(2));
      expect(dataProvider.markedErrored, ['created-1']);
    },
  );

  test('stops after one consecutive rate-limit retry', () async {
    var currentTime = DateTime(2026);
    final dataProvider = _FakeAgentConversationDataProvider(
      continueErrors: [
        for (var attempt = 0; attempt < 2; attempt++)
          AgentRateLimitRetryException(
            providerException: GenkitException(
              'Provider rate limit.',
              status: .resourceExhausted,
            ),
            retryAfter: const Duration(seconds: 1),
          ),
      ],
    );
    final usecase = _buildAgentService(
      dataProvider,
      rateLimitRetryDelay: const Duration(seconds: 1),
      now: () => currentTime,
      sleep: (duration) {
        currentTime = currentTime.add(duration);

        return Future<void>.value();
      },
    );

    await expectLater(
      usecase(
        conversationId: 'conversation-1',
        context: const AgentIterationContext(origin: .userMessage),
      ),
      throwsA(isA<Exception>()),
    );
    expect(dataProvider.continuationContexts, hasLength(2));
  });

  test('cancels during rate-limit retry wait', () async {
    var currentTime = DateTime(2026);
    final retryEvents = <String>[];
    final cancellationRuntime = FakeCancellationEffects();
    final dataProvider = _FakeAgentConversationDataProvider(
      continueErrors: [
        AgentRateLimitRetryException(
          providerException: GenkitException(
            'Provider rate limit.',
            status: .resourceExhausted,
          ),
          retryAfter: const Duration(seconds: 1),
        ),
      ],
    );
    final sendQueue = _FakeAgentSendQueueRuntime(
      drafts: const [AgentQueuedDraft(content: 'queued')],
    );
    final usecase = _buildAgentService(
      dataProvider,
      sendQueueRuntime: sendQueue,
      cancellationEffects: cancellationRuntime,
      rateLimitRetryRuntime: .new(
        start: (_, _) => cancellationRuntime.requestStop('conversation-1'),
        clear: (conversationId) => retryEvents.add('clear:$conversationId'),
      ),
      now: () => currentTime,
      sleep: (duration) {
        currentTime = currentTime.add(duration);

        return Future<void>.value();
      },
    );

    final result = await usecase(
      conversationId: 'conversation-1',
      context: const AgentIterationContext(origin: .userMessage),
    );

    expect(result, AgentIterationDecision.done);
    expect(sendQueue.cleared, ['conversation-1']);
    expect(dataProvider.markedSent, ['created-1']);
    expect(dataProvider.continuationContexts, hasLength(1));
    expect(retryEvents, ['clear:conversation-1']);
  });

  test('rethrows non-rate-limit errors', () async {
    final dataProvider = _FakeAgentConversationDataProvider(
      continueErrors: [StateError('broken')],
    );
    final usecase = _buildAgentService(dataProvider);

    await expectLater(
      () => usecase(
        conversationId: 'conversation-1',
        context: const AgentIterationContext(
          origin: .userMessage,
          ackMessageIds: ['message-1'],
        ),
      ),
      throwsA(isA<StateError>()),
    );
    expect(dataProvider.markedErrored, ['message-1']);
  });

  test('cancels after queued drafts and marks ack messages sent', () async {
    final cancellationRuntime = FakeCancellationEffects();
    final dataProvider = _FakeAgentConversationDataProvider(
      onAutoCompact: () => cancellationRuntime.requestStop('conversation-1'),
    );
    final sendQueue = _FakeAgentSendQueueRuntime(
      drafts: const [AgentQueuedDraft(content: 'queued')],
    );
    final usecase = _buildAgentService(
      dataProvider,
      sendQueueRuntime: sendQueue,
      cancellationEffects: cancellationRuntime,
    );

    final result = await usecase(
      conversationId: 'conversation-1',
      context: const AgentIterationContext(origin: .userMessage),
    );

    expect(result, AgentIterationDecision.done);
    expect(dataProvider.markedSent, ['created-1']);
    expect(sendQueue.cleared, ['conversation-1']);
    expect(dataProvider.continuationContexts, hasLength(1));
  });
}

class _FakeAgentConversationDataProvider
    implements AgentDataProvider, AgentModelProvider, AgentLoopToolProvider {
  new({
    this.workspaceId = 'workspace-1',
    List<ContinueAgentResult>? continueResults,
    List<Object>? continueErrors,
    List<AgentIterationDecision>? toolDecisions,
    this.onAutoCompact,
    this.onRunAllowedTools,
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
  final Future<void> Function()? onRunAllowedTools;
  final workspaceLookups = <String>[];
  final continuationContexts = <AgentIterationContext?>[];
  final createdContents = <String>[];
  final markedSent = <String>[];
  final markedErrored = <String>[];
  final allowedToolRuns = <String>[];

  @override
  Future<ContinueAgentResult> continueAgent({
    required String conversationId,
    AgentIterationContext? context,
  }) async {
    continuationContexts.add(context);
    if (continueErrors.isNotEmpty) {
      Error.throwWithStackTrace(continueErrors.removeAt(0), .current);
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
    final wait = onRunAllowedTools;
    if (wait != null) await wait();

    return toolDecisions.isEmpty
        ? AgentIterationDecision.done
        : toolDecisions.removeAt(0);
  }

  @override
  Future<void> autoCompactConversation({required String conversationId}) async {
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
    Object? payload,
  }) async {
    createdContents.add(content);

    return AgentCreatedMessage(id: 'created-${createdContents.length}');
  }

  @override
  Future<void> markMessagesSent(List<String> messageIds) async {
    markedSent.addAll(messageIds);
  }

  @override
  Future<void> markMessagesErrored(List<String> messageIds) async {
    markedErrored.addAll(messageIds);
  }

  @override
  Future<void> stopLatestPendingTools(String conversationId) async {}
}

class _FakeAgentSendQueueRuntime({
  final List<AgentQueuedDraft> drafts = const [],
}) implements AgentSendQueueRuntime {
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
