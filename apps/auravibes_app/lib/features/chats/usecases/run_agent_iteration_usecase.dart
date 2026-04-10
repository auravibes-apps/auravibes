import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:auravibes_app/domain/enums/message_types.dart';
import 'package:auravibes_app/domain/repositories/conversation_repository.dart';
import 'package:auravibes_app/domain/repositories/message_repository.dart';
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
  });

  final ContinueAgentUsecase continueAgentUsecase;
  final RunAllowedToolsUsecase runAllowedToolsUsecase;
  final ConversationRepository conversationRepository;
  final MessageRepository messageRepository;
  final ConversationSendQueueRuntime sendQueueRuntime;

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

    var currentContext = context;

    while (true) {
      currentContext = await _withQueuedDrafts(
        conversationId: conversationId,
        context: currentContext,
      );

      final continueResult = await continueAgentUsecase.call(
        conversationId: conversationId,
        context: currentContext,
      );

      currentContext = AgentIterationContext(
        origin: currentContext?.origin ?? AgentIterationOrigin.userMessage,
      );

      if (!continueResult.hasToolCalls) {
        return AgentIterationDecision.done;
      }

      final decision = await runAllowedToolsUsecase.call(
        conversationId: conversationId,
        workspaceId: conversation.workspaceId,
      );

      if (decision != AgentIterationDecision.continueIteration) {
        return decision;
      }
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

    final createdMessages = <String>[];
    for (final queuedDraft in queuedDrafts) {
      final createdMessage = await messageRepository.createMessage(
        MessageToCreate(
          conversationId: conversationId,
          content: queuedDraft.content,
          messageType: MessageType.text,
          isUser: true,
          status: MessageStatus.sending,
        ),
      );
      createdMessages.add(createdMessage.id);
    }

    return AgentIterationContext(
      origin: context?.origin ?? AgentIterationOrigin.userMessage,
      ackMessageIds: [
        ...context?.ackMessageIds ?? const [],
        ...createdMessages,
      ],
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
  );
});
