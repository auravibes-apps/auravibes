// ignore_for_file: member-ordering
// Required: Existing declaration order groups related UI and model members.
// Required: Existing test and UI helpers keep compact return flow.
// ignore_for_file: prefer-static-class
// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/domain/repositories/conversation_repository.dart';
import 'package:auravibes_app/domain/repositories/message_repository.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_send_queue_runtime.dart';
import 'package:auravibes_app/features/chats/providers/conversation_streaming_runtime.dart';
import 'package:auravibes_app/features/chats/usecases/agent_iteration_context.dart';
import 'package:auravibes_app/features/chats/usecases/agent_iteration_decision.dart';
import 'package:auravibes_app/features/chats/usecases/continue_agent_result.dart';
import 'package:auravibes_app/features/chats/usecases/maybe_auto_compact_conversation_usecase.dart';
import 'package:auravibes_app/features/tools/usecases/run_allowed_tools_usecase.dart';
import 'package:riverpod/riverpod.dart';

const defaultAgentRateLimitRetryDelay = Duration(seconds: 60);

Future<void> _defaultAgentSleep(Duration duration) {
  return Future<void>.delayed(duration);
}

class RunAgentIterationUsecase {
  const RunAgentIterationUsecase({
    required this.continueAgentUsecase,
    required this.runAllowedToolsUsecase,
    required this.maybeAutoCompactConversationUsecase,
    required this.conversationRepository,
    required this.messageRepository,
    required this.sendQueueRuntime,
    required this.agentCancellationRuntime,
    required this.rateLimitRetryRuntime,
    this.rateLimitRetryDelay = defaultAgentRateLimitRetryDelay,
    this.now = DateTime.now,
    this.sleep = _defaultAgentSleep,
  });

  final ContinueAgentUsecase continueAgentUsecase;
  final RunAllowedToolsUsecase runAllowedToolsUsecase;
  final MaybeAutoCompactConversationUsecase maybeAutoCompactConversationUsecase;
  final ConversationRepository conversationRepository;
  final MessageRepository messageRepository;
  final ConversationSendQueueRuntime sendQueueRuntime;
  final AgentCancellationRuntime agentCancellationRuntime;
  final ConversationRateLimitRetryRuntime rateLimitRetryRuntime;
  final Duration rateLimitRetryDelay;
  final DateTime Function() now;
  final Future<void> Function(Duration duration) sleep;

  Future<AgentIterationDecision> call({
    required String conversationId,
    required AgentIterationContext context,
  }) async {
    final conversation = await conversationRepository.getConversationById(
      conversationId,
    );
    if (conversation == null) {
      throw Exception('Conversation not found');
    }

    agentCancellationRuntime.start(conversationId);

    try {
      return await _runLoop(
        conversationId: conversationId,
        workspaceId: conversation.workspaceId,
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

    await maybeAutoCompactConversationUsecase.call(
      conversationId: conversationId,
    );

    final continueResult = await continueAgentUsecase.call(
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

    final decision = await runAllowedToolsUsecase.call(
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
        (queuedDraft) => messageRepository.createMessage(
          MessageToCreate(
            conversationId: conversationId,
            content: queuedDraft.content,
            messageType: MessageType.text,
            isUser: true,
            status: MessageStatus.sending,
          ),
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

    final _ = await Future.wait(
      ackMessageIds.map(
        (messageId) => messageRepository.patchMessage(
          messageId,
          const MessagePatch(status: MessageStatus.sent),
        ),
      ),
    );
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

final runAgentIterationUsecaseProvider = Provider<RunAgentIterationUsecase>((
  ref,
) {
  return RunAgentIterationUsecase(
    continueAgentUsecase: ref.watch(continueAgentUsecaseProvider),
    runAllowedToolsUsecase: ref.watch(runAllowedToolsUsecaseProvider),
    maybeAutoCompactConversationUsecase: ref.watch(
      maybeAutoCompactConversationUsecaseProvider,
    ),
    conversationRepository: ref.watch(conversationRepositoryProvider),
    messageRepository: ref.watch(messageRepositoryProvider),
    sendQueueRuntime: ref.watch(conversationSendQueueRuntimeProvider),
    agentCancellationRuntime: ref.watch(agentCancellationRuntimeProvider),
    rateLimitRetryRuntime: ref.watch(conversationRateLimitRetryRuntimeProvider),
  );
});
