import 'package:auravibes_app/domain/repositories/conversation_repository.dart';
import 'package:auravibes_app/domain/repositories/message_repository.dart';
import 'package:auravibes_app/features/chats/notifiers/conversation_send_queue_notifier.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
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
    required this.conversationSendQueueNotifier,
  });

  final ContinueAgentUsecase continueAgentUsecase;
  final RunAllowedToolsUsecase runAllowedToolsUsecase;
  final ConversationRepository conversationRepository;
  final MessageRepository messageRepository;
  final ConversationSendQueue conversationSendQueueNotifier;

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
      final continueResult = await continueAgentUsecase.call(
        conversationId: conversationId,
        context: currentContext,
      );
      if (!continueResult.hasToolCalls) {
        final queuedDrafts = conversationSendQueueNotifier.dequeueAll(
          conversationId,
        );
        if (queuedDrafts.isEmpty) {
          return AgentIterationDecision.done;
        }

        final createdMessages = <String>[];
        for (final queuedDraft in queuedDrafts) {
          final createdMessage = await messageRepository.createMessage(
            .new(
              conversationId: conversationId,
              content: queuedDraft.content,
              messageType: .text,
              isUser: true,
              status: .sending,
            ),
          );
          createdMessages.add(createdMessage.id);
        }

        currentContext = AgentIterationContext(
          origin: AgentIterationOrigin.userMessage,
          ackMessageIds: createdMessages,
        );
        continue;
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
}

final runAgentIterationUsecaseProvider = Provider<RunAgentIterationUsecase>((
  ref,
) {
  return RunAgentIterationUsecase(
    continueAgentUsecase: ref.watch(continueAgentUsecaseProvider),
    runAllowedToolsUsecase: ref.watch(runAllowedToolsUsecaseProvider),
    conversationRepository: ref.watch(conversationRepositoryProvider),
    messageRepository: ref.watch(messageRepositoryProvider),
    conversationSendQueueNotifier: ref.watch(
      conversationSendQueueProvider.notifier,
    ),
  );
});
