import 'package:auravibes_app/domain/repositories/message_repository.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/usecases/agent_iteration_context.dart';
import 'package:auravibes_app/features/chats/usecases/run_agent_iteration_usecase.dart';
import 'package:riverpod/riverpod.dart';

class SendMessageUsecase {
  const SendMessageUsecase({
    required this.runAgentIterationUsecase,
    required this.messageRepository,
  });

  final RunAgentIterationUsecase runAgentIterationUsecase;
  final MessageRepository messageRepository;
  Future<void> call({
    required String conversationId,
    required String content,
  }) async {
    // Persist the user message first so the chat history stays consistent.

    final createdMessage = await messageRepository.createMessage(
      .new(
        conversationId: conversationId,
        content: content,
        messageType: .text,
        isUser: true,
        status: .sending,
      ),
    );
    await runAgentIterationUsecase(
      conversationId: conversationId,
      context: AgentIterationContext(
        origin: AgentIterationOrigin.userMessage,
        ackMessageId: createdMessage.id,
      ),
    );
  }
}

final sendMessageUsecaseProvider = Provider<SendMessageUsecase>((ref) {
  return SendMessageUsecase(
    runAgentIterationUsecase: ref.watch(runAgentIterationUsecaseProvider),
    messageRepository: ref.watch(messageRepositoryProvider),
  );
});
