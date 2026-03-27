import 'package:auravibes_app/domain/repositories/message_repository.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/screens/usecases/continue_agent_usecase.dart';
import 'package:riverpod/riverpod.dart';

class SendMessageUsecase {
  const SendMessageUsecase({
    required this.continueAgentUsecase,
    required this.messageRepository,
  });

  final ContinueAgentUsecase continueAgentUsecase;
  final MessageRepository messageRepository;
  Future<void> call({
    required String conversationId,
    required String content,
  }) async {
    // Implement the logic to send a message here.
    // This might involve calling a repository method that interacts with an API or database.

    await messageRepository.createMessage(
      .new(
        conversationId: conversationId,
        content: content,
        messageType: .text,
        isUser: true,
        status: .sending,
      ),
    );
    await continueAgentUsecase(
      conversationId: conversationId,
    );
  }
}

final sendMessageUsecaseProvider = Provider<SendMessageUsecase>((ref) {
  return SendMessageUsecase(
    continueAgentUsecase: ref.watch(continueAgentUsecaseProvider),
    messageRepository: ref.watch(messageRepositoryProvider),
  );
});
