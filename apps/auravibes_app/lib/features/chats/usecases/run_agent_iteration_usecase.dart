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
import 'package:auravibes_app/features/tools/usecases/run_allowed_tools_usecase.dart';
import 'package:riverpod/riverpod.dart';

class RunAgentIterationUsecase {
  const RunAgentIterationUsecase({
    required this.continueAgentUsecase,
    required this.runAllowedToolsUsecase,
    required this.conversationRepository,
    required this.messageRepository,
    required this.sendQueueRuntime,
    required this.agentCancellationRuntime,
  });

  final ContinueAgentUsecase continueAgentUsecase;
  final RunAllowedToolsUsecase runAllowedToolsUsecase;
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
      var currentContext = context;

      while (true) {
        if (agentCancellationRuntime.isCancellationRequested(conversationId)) {
          await _markAckMessagesSent(currentContext);
          sendQueueRuntime.clear(conversationId);
          return AgentIterationDecision.done;
        }

        currentContext = await _withQueuedDrafts(
          conversationId: conversationId,
          context: currentContext,
        );

        if (agentCancellationRuntime.isCancellationRequested(conversationId)) {
          await _markAckMessagesSent(currentContext);
          sendQueueRuntime.clear(conversationId);
          return AgentIterationDecision.done;
        }

        final continueResult = await continueAgentUsecase.call(
          conversationId: conversationId,
          context: currentContext,
        );

        if (agentCancellationRuntime.isCancellationRequested(conversationId)) {
          await _markAckMessagesSent(currentContext);
          sendQueueRuntime.clear(conversationId);
          return AgentIterationDecision.done;
        }

        currentContext = AgentIterationContext(
          origin: currentContext?.origin ?? AgentIterationOrigin.userMessage,
        );

        if (!continueResult.hasToolCalls) {
          final queuedContext = await _withQueuedDrafts(
            conversationId: conversationId,
            context: currentContext,
          );
          if (queuedContext == currentContext) {
            return AgentIterationDecision.done;
          }

          currentContext = queuedContext;
          continue;
        }

        final decision = await runAllowedToolsUsecase.call(
          conversationId: conversationId,
          workspaceId: conversation.workspaceId,
        );

        if (agentCancellationRuntime.isCancellationRequested(conversationId)) {
          await _markAckMessagesSent(currentContext);
          sendQueueRuntime.clear(conversationId);
          return AgentIterationDecision.done;
        }

        if (decision != AgentIterationDecision.continueIteration) {
          return decision;
        }
      }
    } finally {
      agentCancellationRuntime.clear(conversationId);
    }
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

final runAgentIterationUsecaseProvider = Provider<RunAgentIterationUsecase>((
  ref,
) {
  return RunAgentIterationUsecase(
    continueAgentUsecase: ref.watch(continueAgentUsecaseProvider),
    runAllowedToolsUsecase: ref.watch(runAllowedToolsUsecaseProvider),
    conversationRepository: ref.watch(conversationRepositoryProvider),
    messageRepository: ref.watch(messageRepositoryProvider),
    sendQueueRuntime: ref.watch(conversationSendQueueRuntimeProvider),
    agentCancellationRuntime: ref.watch(agentCancellationRuntimeProvider),
  );
});
