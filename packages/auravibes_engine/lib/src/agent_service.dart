import 'package:auravibes_engine/src/agent_iteration_context.dart';
import 'package:auravibes_engine/src/agent_iteration_decision.dart';
import 'package:auravibes_engine/src/agent_runtime.dart';
import 'package:auravibes_engine/src/providers/agent_data_provider.dart';
import 'package:auravibes_engine/src/providers/agent_model_provider.dart';

const defaultAgentRateLimitRetryDelay = Duration(seconds: 60);
const defaultAgentRateLimitRetryCount = 1;

abstract interface class AgentLoopToolProvider {
  Future<AgentIterationDecision> runAllowedTools({
    required String conversationId,
    required String workspaceId,
  });
}

Future<void> _defaultAgentSleep(Duration duration) {
  return Future<void>.delayed(duration);
}

class const AgentService({
  required final AgentDataProvider data,
  required final AgentModelProvider models,
  required final AgentLoopToolProvider tools,
  required final AgentSendQueueRuntime sendQueueRuntime,
  required final AgentCancellationEffects cancellationEffects,
  required final AgentRateLimitRetryRuntime rateLimitRetryRuntime,
  final Duration rateLimitRetryDelay = defaultAgentRateLimitRetryDelay,
  final int rateLimitRetryCount = defaultAgentRateLimitRetryCount,
  final DateTime Function() now = DateTime.now,
  final Future<void> Function(Duration duration) sleep = _defaultAgentSleep,
}) {
  Future<AgentIterationDecision> call({
    required String conversationId,
    required AgentIterationContext context,
  }) async {
    final workspaceId = await data.getWorkspaceId(conversationId);
    if (workspaceId == null) {
      throw Exception('Conversation not found');
    }

    final cancellationScope = cancellationEffects.start(conversationId);

    try {
      return await _runLoop(
        conversationId: conversationId,
        workspaceId: workspaceId,
        context: context,
        cancellationScope: cancellationScope,
      );
    } finally {
      cancellationEffects.clear(conversationId, cancellationScope);
    }
  }

  Future<AgentIterationDecision> _runLoop({
    required String conversationId,
    required String workspaceId,
    required AgentIterationContext context,
    required AgentCancellationScope cancellationScope,
  }) async {
    AgentIterationContext? currentContext = context;
    var rateLimitRetries = 0;

    while (true) {
      final cancelDecision = await _cancelIfRequested(
        conversationId,
        cancellationScope,
        currentContext,
      );
      if (cancelDecision != null) return cancelDecision;

      final _AgentIterationStep result;
      try {
        result = await _runIteration(
          conversationId: conversationId,
          workspaceId: workspaceId,
          context: currentContext,
          cancellationScope: cancellationScope,
        );
      } catch (error) {
        final retryDelay = _rateLimitRetryDelayFor(error);
        if (retryDelay == null) rethrow;
        if (rateLimitRetries >= rateLimitRetryCount) rethrow;
        rateLimitRetries++;

        final retryAt = now().add(retryDelay);
        rateLimitRetryRuntime.start(conversationId, retryAt);
        final cancelled = await _waitForRateLimitRetry(
          conversationId: conversationId,
          retryAt: retryAt,
          context: currentContext,
          cancellationScope: cancellationScope,
        );
        rateLimitRetryRuntime.clear(conversationId);
        if (cancelled != null) return cancelled;
        continue;
      }
      rateLimitRetries = 0;
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
    required AgentCancellationScope cancellationScope,
  }) async {
    var currentContext = await _withQueuedDrafts(
      conversationId: conversationId,
      context: context,
    );
    final cancelDecision = await _cancelIfRequested(
      conversationId,
      cancellationScope,
      currentContext,
    );
    if (cancelDecision != null) {
      return _AgentIterationStep(currentContext, cancelDecision);
    }

    await data.autoCompactConversation(conversationId: conversationId);

    final continueResult = await models.continueAgent(
      conversationId: conversationId,
      context: currentContext,
    );
    final postContinueCancel = await _cancelIfRequested(
      conversationId,
      cancellationScope,
      currentContext,
    );
    if (postContinueCancel != null) {
      return _AgentIterationStep(currentContext, postContinueCancel);
    }

    currentContext = AgentIterationContext(
      origin: currentContext?.origin ?? AgentIterationOrigin.userMessage,
    );
    if (!continueResult.hasToolCalls) {
      return await _continueAfterNoToolCalls(
        conversationId,
        cancellationScope,
        currentContext,
      );
    }

    final decision = await tools.runAllowedTools(
      conversationId: conversationId,
      workspaceId: workspaceId,
    );
    final postToolCancel = await _cancelIfRequested(
      conversationId,
      cancellationScope,
      currentContext,
    );

    return _AgentIterationStep(currentContext, postToolCancel ?? decision);
  }

  Future<_AgentIterationStep> _continueAfterNoToolCalls(
    String conversationId,
    AgentCancellationScope cancellationScope,
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
    AgentCancellationScope cancellationScope,
    AgentIterationContext? context,
  ) async {
    if (!cancellationScope.isCancellationRequested) {
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
        (queuedDraft) => data.createQueuedUserMessage(
          conversationId: conversationId,
          content: queuedDraft.content,
          payload: queuedDraft.payload,
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

    await data.markMessagesSent(ackMessageIds);
  }

  Future<AgentIterationDecision?> _waitForRateLimitRetry({
    required String conversationId,
    required DateTime retryAt,
    required AgentIterationContext? context,
    required AgentCancellationScope cancellationScope,
  }) async {
    while (now().isBefore(retryAt)) {
      final cancelDecision = await _cancelIfRequested(
        conversationId,
        cancellationScope,
        context,
      );
      if (cancelDecision != null) return cancelDecision;

      final remaining = retryAt.difference(now());
      final delay = remaining > const Duration(seconds: 1)
          ? const Duration(seconds: 1)
          : remaining;
      if (delay > Duration.zero) {
        await sleep(delay);
      }
    }

    return await _cancelIfRequested(conversationId, cancellationScope, context);
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

class const _AgentIterationStep(
  final AgentIterationContext? context,
  final AgentIterationDecision decision,
);
