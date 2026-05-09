import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:auravibes_app/domain/enums/message_types.dart';
import 'package:auravibes_app/domain/repositories/conversation_repository.dart';
import 'package:auravibes_app/domain/repositories/message_repository.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/providers/send_queue_runtime_provider.dart';
import 'package:auravibes_app/features/chats/usecases/agent_iteration_context.dart';
import 'package:auravibes_app/features/chats/usecases/agent_iteration_decision.dart';
import 'package:auravibes_app/features/chats/usecases/continue_agent_usecase.dart';
import 'package:auravibes_app/features/chats/usecases/maybe_auto_compact_conversation_usecase.dart';
import 'package:auravibes_app/features/tools/usecases/run_allowed_tools_usecase.dart';
import 'package:riverpod/riverpod.dart';

class RunAgentIterationUsecase {
  const RunAgentIterationUsecase({
    required this.continueAgentUsecase,
    required this.runAllowedToolsUsecase,
    required this.maybeAutoCompactConversationUsecase,
    required this.conversationRepository,
    required this.messageRepository,
    required this.sendQueueRuntime,
    required this.agentCancellationRuntime,
  });

  final ContinueAgentUsecase continueAgentUsecase;
  final RunAllowedToolsUsecase runAllowedToolsUsecase;
  final MaybeAutoCompactConversationUsecase maybeAutoCompactConversationUsecase;
  final ConversationRepository conversationRepository;
  final MessageRepository messageRepository;
  final ConversationSendQueueRuntime sendQueueRuntime;
  final AgentCancellationRuntime agentCancellationRuntime;

  Future<AgentIterationDecision> call({
    required String conversationId,
    AgentIterationContext? context,
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
    required AgentIterationContext? context,
  }) async {
    var currentContext = context;

    while (true) {
      final cancelDecision = await _cancelIfRequested(
        conversationId,
        currentContext,
      );
      if (cancelDecision != null) return cancelDecision;

      final result = await _runIteration(
        conversationId: conversationId,
        workspaceId: workspaceId,
        context: currentContext,
      );
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

    try {
      await maybeAutoCompactConversationUsecase.call(
        conversationId: conversationId,
      );
    } on Exception {
      // Best-effort compaction – failures shouldn't block the agent loop.
    }

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

    await Future.wait(
      ackMessageIds.map(
        (messageId) => messageRepository.patchMessage(
          messageId,
          const MessagePatch(status: MessageStatus.sent),
        ),
      ),
    );
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
  );
});
