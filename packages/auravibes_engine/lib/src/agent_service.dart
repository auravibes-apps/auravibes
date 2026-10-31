import 'package:auravibes_engine/src/agent_iteration_context.dart';
import 'package:auravibes_engine/src/agent_iteration_decision.dart';
import 'package:auravibes_engine/src/agent_loop_tool_result.dart';
import 'package:auravibes_engine/src/agent_rate_limit_retry_exception.dart';
import 'package:auravibes_engine/src/agent_runtime.dart';
import 'package:auravibes_engine/src/agent_tool_loop_guard.dart';
import 'package:auravibes_engine/src/providers/agent_data_provider.dart';
import 'package:auravibes_engine/src/providers/agent_model_provider.dart';

const defaultAgentRateLimitRetryDelay = Duration(seconds: 60);
const defaultAgentRateLimitRetryCount = 1;
const defaultAgentIterationLimit = 16;

abstract interface class AgentLoopToolProvider {
  Future<AgentLoopToolResult> runAllowedTools({
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
  final int iterationLimit = defaultAgentIterationLimit,
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
    var iterations = 0;
    final recentToolFingerprints = <String>[];

    while (true) {
      final cancelDecision = await _cancelIfRequested(
        conversationId,
        cancellationScope,
        currentContext,
      );
      if (cancelDecision != null) return cancelDecision;
      if (iterations >= iterationLimit) {
        return AgentIterationDecision.iterationLimitReached;
      }
      iterations++;

      final _AgentIterationStep result;
      try {
        currentContext = await _withQueuedDrafts(
          conversationId: conversationId,
          context: currentContext,
        );
        result = await _runIteration(
          conversationId: conversationId,
          workspaceId: workspaceId,
          context: currentContext,
          cancellationScope: cancellationScope,
        );
      } on Object catch (error, stackTrace) {
        final retryDelay = _rateLimitRetryDelayFor(error);
        if (retryDelay == null || rateLimitRetries >= rateLimitRetryCount) {
          await _markAckMessagesErrored(currentContext);
          Error.throwWithStackTrace(error, stackTrace);
        }
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
      final fingerprint = result.toolFingerprint;
      if (fingerprint == null) continue;
      if (hasRepeatedNoProgressToolCycle(recentToolFingerprints, fingerprint)) {
        return AgentIterationDecision.repeatedToolLoopDetected;
      }
      recentToolFingerprints.add(fingerprint);
      if (recentToolFingerprints.length > maxRecentAgentToolLoopFingerprints) {
        recentToolFingerprints.removeAt(0);
      }
    }
  }

  Future<_AgentIterationStep> _runIteration({
    required String conversationId,
    required String workspaceId,
    required AgentIterationContext? context,
    required AgentCancellationScope cancellationScope,
  }) async {
    var currentContext = context;
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

    final toolResult = await tools.runAllowedTools(
      conversationId: conversationId,
      workspaceId: workspaceId,
    );
    final postToolCancel = await _cancelIfRequested(
      conversationId,
      cancellationScope,
      currentContext,
    );

    return _AgentIterationStep(
      currentContext,
      postToolCancel ?? toolResult.decision,
      toolFingerprint: postToolCancel == null ? toolResult.fingerprint : null,
    );
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

  Future<void> _markAckMessagesErrored(AgentIterationContext? context) async {
    final ackMessageIds = context?.ackMessageIds ?? const <String>[];
    if (ackMessageIds.isEmpty) return;

    try {
      await data.markMessagesErrored(ackMessageIds);
    } on Object {
      // Preserve the original continuation failure when cleanup fails.
    }
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
      if (delay > .zero) {
        await sleep(delay);
      }
    }

    return await _cancelIfRequested(conversationId, cancellationScope, context);
  }

  Duration? _rateLimitRetryDelayFor(Object error) {
    if (error is! AgentRateLimitRetryException) return null;

    final delay = error.retryAfter;
    return delay > defaultAgentRateLimitRetryDelay
        ? defaultAgentRateLimitRetryDelay
        : delay;
  }
}

class const _AgentIterationStep(
  final AgentIterationContext? context,
  final AgentIterationDecision decision, {
  final String? toolFingerprint,
}) {
  final String? toolFingerprint = toolFingerprint;
}
