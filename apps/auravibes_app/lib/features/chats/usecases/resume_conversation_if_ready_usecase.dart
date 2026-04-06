import 'package:auravibes_app/domain/repositories/conversation_repository.dart';
import 'package:auravibes_app/domain/repositories/message_repository.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/usecases/agent_iteration_context.dart';
import 'package:auravibes_app/features/chats/usecases/agent_iteration_decision.dart';
import 'package:auravibes_app/features/chats/usecases/run_agent_iteration_usecase.dart';
import 'package:auravibes_app/features/tools/usecases/run_allowed_tools_usecase.dart';
import 'package:riverpod/riverpod.dart';

class ResumeConversationIfReadyUsecase {
  const ResumeConversationIfReadyUsecase({
    required MessageRepository messageRepository,
    required ConversationRepository conversationRepository,
    required RunAllowedToolsUsecase runAllowedToolsUsecase,
    required RunAgentIterationUsecase runAgentIterationUsecase,
  }) : _messageRepository = messageRepository,
       _conversationRepository = conversationRepository,
       _runAllowedToolsUsecase = runAllowedToolsUsecase,
       _runAgentIterationUsecase = runAgentIterationUsecase;

  final MessageRepository _messageRepository;
  final ConversationRepository _conversationRepository;
  final RunAllowedToolsUsecase _runAllowedToolsUsecase;
  final RunAgentIterationUsecase _runAgentIterationUsecase;

  Future<void> call({required String messageId}) async {
    final message = await _messageRepository.getMessageById(messageId);
    if (message == null) return;

    final conversation = await _conversationRepository.getConversationById(
      message.conversationId,
    );
    if (conversation == null) return;

    final decision = await _runAllowedToolsUsecase.call(
      conversationId: conversation.id,
      workspaceId: conversation.workspaceId,
    );
    if (decision != AgentIterationDecision.continueIteration) return;

    await _runAgentIterationUsecase.call(
      conversationId: conversation.id,
      context: const AgentIterationContext(
        origin: AgentIterationOrigin.toolResume,
      ),
    );
  }
}

final resumeConversationIfReadyUsecaseProvider =
    Provider<ResumeConversationIfReadyUsecase>((ref) {
      return ResumeConversationIfReadyUsecase(
        messageRepository: ref.watch(messageRepositoryProvider),
        conversationRepository: ref.watch(conversationRepositoryProvider),
        runAllowedToolsUsecase: ref.watch(runAllowedToolsUsecaseProvider),
        runAgentIterationUsecase: ref.watch(runAgentIterationUsecaseProvider),
      );
    });
