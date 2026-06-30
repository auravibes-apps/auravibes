import 'package:auravibes_agent/src/agent_iteration_context.dart';
import 'package:auravibes_agent/src/agent_iteration_decision.dart';
import 'package:auravibes_agent/src/agent_runtime.dart';
import 'package:auravibes_agent/src/continue_agent_result.dart';

const defaultAgentRateLimitRetryDelay = Duration(seconds: 60);

abstract interface class AgentProvider
    implements AgentConversationDataProvider {
  Future<ContinueAgentResult> continueAgent({
    required String conversationId,
    AgentIterationContext? context,
  });

  Future<AgentIterationDecision> runAllowedTools({
    required String conversationId,
    required String workspaceId,
  });

  Future<void> autoCompactConversation({
    required String conversationId,
  });
}

Future<void> _defaultAgentSleep(Duration duration) {
  return Future<void>.delayed(duration);
}

class AgentService {
  const AgentService({
    required this.provider,
    required this.sendQueueRuntime,
    required this.agentCancellationRuntime,
    required this.rateLimitRetryRuntime,
    this.rateLimitRetryDelay = defaultAgentRateLimitRetryDelay,
    this.now = DateTime.now,
    this.sleep = _defaultAgentSleep,
  });

  final AgentProvider provider;
  final AgentSendQueueRuntime sendQueueRuntime;
  final AgentCancellationRuntime agentCancellationRuntime;
  final AgentRateLimitRetryRuntime rateLimitRetryRuntime;
  final Duration rateLimitRetryDelay;
  final DateTime Function() now;
  final Future<void> Function(Duration duration) sleep;

  Future<AgentIterationDecision> call({
    required String conversationId,
    required AgentIterationContext context,
  }) async {
    final workspaceId = await provider.getWorkspaceId(conversationId);
    if (workspaceId == null) {
      throw Exception('Conversation not found');
    }

    agentCancellationRuntime.start(conversationId);

    try {
      return await _runLoop(
        conversationId: conversationId,
        workspaceId: workspaceId,
        context: context,
      );
    } finally {
      agentCancellationRuntime.clear(conversationId);
    }
  }

  Future<AgentIterationDecision> _runLoop({
    required String conversationId,
    required String workspaceId,
    required AgentIterationContext context,
  }) async {
    AgentIterationContext? currentContext = context;

    while (true) {
      final cancelDecision = await _cancelIfRequested(
        conversationId,
        currentContext,
      );
      if (cancelDecision != null) return cancelDecision;

      final _AgentIterationStep result;
      try {
        result = await _runIteration(
          conversationId: conversationId,
          workspaceId: workspaceId,
          context: currentContext,
        );
      } catch (error) {
        final retryDelay = _rateLimitRetryDelayFor(error);
        if (retryDelay == null) rethrow;

        final retryAt = now().add(retryDelay);
        rateLimitRetryRuntime.start(conversationId, retryAt);
        final cancelled = await _waitForRateLimitRetry(
          conversationId: conversationId,
          retryAt: retryAt,
          context: currentContext,
        );
        rateLimitRetryRuntime.clear(conversationId);
        if (cancelled != null) return cancelled;
        continue;
      }
      currentContext = result.context;
      if (result.decision != AgentIterationDecision.continueIteration) {
        return result.decision;
      }
    }
  }

  Future<_AgentIterationStep> _runIteration({
    required String conversationId,
    required String workspaceId,
    required AgentIterationContext? context,
  }) async {
    var currentContext = await _withQueuedDrafts(
      conversationId: conversationId,
      context: context,
    );
    final cancelDecision = await _cancelIfRequested(
      conversationId,
      currentContext,
    );
    if (cancelDecision != null) {
      return _AgentIterationStep(currentContext, cancelDecision);
    }

    await provider.autoCompactConversation(conversationId: conversationId);

    final continueResult = await provider.continueAgent(
      conversationId: conversationId,
      context: currentContext,
    );
    final postContinueCancel = await _cancelIfRequested(
      conversationId,
      currentContext,
    );
    if (postContinueCancel != null) {
      return _AgentIterationStep(currentContext, postContinueCancel);
    }

    currentContext = AgentIterationContext(
      origin: currentContext?.origin ?? AgentIterationOrigin.userMessage,
    );
    if (!continueResult.hasToolCalls) {
      return _continueAfterNoToolCalls(conversationId, currentContext);
    }

    final decision = await provider.runAllowedTools(
      conversationId: conversationId,
      workspaceId: workspaceId,
    );
    final postToolCancel = await _cancelIfRequested(
      conversationId,
      currentContext,
    );

    return _AgentIterationStep(
      currentContext,
      postToolCancel ?? decision,
    );
  }

  Future<_AgentIterationStep> _continueAfterNoToolCalls(
    String conversationId,
    AgentIterationContext currentContext,
  ) async {
    final queuedContext = await _withQueuedDrafts(
      conversationId: conversationId,
      context: currentContext,
    );
    final decision = queuedContext == currentContext
        ? AgentIterationDecision.done
        : AgentIterationDecision.continueIteration;

    return _AgentIterationStep(queuedContext, decision);
  }

  Future<AgentIterationDecision?> _cancelIfRequested(
    String conversationId,
    AgentIterationContext? context,
  ) async {
    if (!agentCancellationRuntime.isCancellationRequested(conversationId)) {
      return null;
    }

    await _markAckMessagesSent(context);
    sendQueueRuntime.clear(conversationId);

    return AgentIterationDecision.done;
  }

  Future<AgentIterationContext?> _withQueuedDrafts({
    required String conversationId,
    required AgentIterationContext? context,
  }) async {
    final queuedDrafts = sendQueueRuntime.dequeueAll(conversationId);
    if (queuedDrafts.isEmpty) {
      return context;
    }

    final createdMessages = await Future.wait(
      queuedDrafts.map(
        (queuedDraft) => provider.createQueuedUserMessage(
          conversationId: conversationId,
          content: queuedDraft.content,
        ),
      ),
    );

    return AgentIterationContext(
      origin: context?.origin ?? AgentIterationOrigin.userMessage,
      ackMessageIds: [
        ...context?.ackMessageIds ?? const [],
        ...createdMessages.map((message) => message.id),
      ],
    );
  }

  Future<void> _markAckMessagesSent(AgentIterationContext? context) async {
    final ackMessageIds = context?.ackMessageIds ?? const <String>[];
    if (ackMessageIds.isEmpty) return;

    await provider.markMessagesSent(ackMessageIds);
  }

  Future<AgentIterationDecision?> _waitForRateLimitRetry({
    required String conversationId,
    required DateTime retryAt,
    required AgentIterationContext? context,
  }) async {
    while (now().isBefore(retryAt)) {
      final cancelDecision = await _cancelIfRequested(conversationId, context);
      if (cancelDecision != null) return cancelDecision;

      final remaining = retryAt.difference(now());
      final delay = remaining > const Duration(seconds: 1)
          ? const Duration(seconds: 1)
          : remaining;
      if (delay > Duration.zero) {
        await sleep(delay);
      }
    }

    return _cancelIfRequested(conversationId, context);
  }

  Duration? _rateLimitRetryDelayFor(Object error) {
    final message = error.toString().toLowerCase();
    final isRateLimit =
        message.contains('ratelimitexception') ||
        message.contains('resource_exhausted') ||
        message.contains('rate limit') ||
        message.contains('429');
    if (!isRateLimit) return null;

    return _knownRateLimitDelay(message) ?? rateLimitRetryDelay;
  }

  Duration? _knownRateLimitDelay(String message) {
    final secondsMatch = RegExp(
      r'(?:retry[- ]?after|try again in)\D+(\d+)\s*(?:s|sec|second|seconds)',
    ).firstMatch(message);
    if (secondsMatch != null) {
      final seconds = int.tryParse(secondsMatch.group(1) ?? '');
      if (seconds != null) return Duration(seconds: seconds);
    }

    final minutesMatch = RegExp(
      r'(?:retry[- ]?after|try again in)\D+(\d+)\s*(?:m|min|minute|minutes)',
    ).firstMatch(message);
    if (minutesMatch != null) {
      final minutes = int.tryParse(minutesMatch.group(1) ?? '');
      if (minutes != null) return Duration(minutes: minutes);
    }

    return null;
  }
}

class _AgentIterationStep {
  const _AgentIterationStep(this.context, this.decision);

  final AgentIterationContext? context;
  final AgentIterationDecision decision;
}
