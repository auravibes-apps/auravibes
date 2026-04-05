import 'package:auravibes_app/domain/repositories/message_repository.dart';
import 'package:auravibes_app/features/chats/notifiers/conversation_send_queue_notifier.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/usecases/agent_iteration_context.dart';
import 'package:auravibes_app/features/chats/usecases/get_conversation_busy_state_usecase.dart';
import 'package:auravibes_app/features/chats/usecases/run_agent_iteration_usecase.dart';
import 'package:riverpod/riverpod.dart';

class SendMessageUsecase {
  const SendMessageUsecase({
    required this.runAgentIterationUsecase,
    required this.messageRepository,
    required this.getConversationBusyStateUsecase,
    required this.conversationSendQueueNotifier,
  });

  final RunAgentIterationUsecase runAgentIterationUsecase;
  final MessageRepository messageRepository;
  final GetConversationBusyStateUsecase getConversationBusyStateUsecase;
  final ConversationSendQueue conversationSendQueueNotifier;

  Future<void> call({
    required String conversationId,
    required String content,
  }) async {
    final busyState = await getConversationBusyStateUsecase.call(
      conversationId: conversationId,
    );
    if (busyState.isBusy) {
      conversationSendQueueNotifier.enqueue(
        conversationId: conversationId,
        content: content,
      );
      return;
    }

    await _sendNow(
      conversationId: conversationId,
      content: content,
    );
  }

  Future<void> _sendNow({
    required String conversationId,
    required String content,
  }) async {
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
        ackMessageIds: [createdMessage.id],
      ),
    );
  }
}

final sendMessageUsecaseProvider = Provider<SendMessageUsecase>((ref) {
  return SendMessageUsecase(
    runAgentIterationUsecase: ref.watch(runAgentIterationUsecaseProvider),
    messageRepository: ref.watch(messageRepositoryProvider),
    getConversationBusyStateUsecase: ref.watch(
      getConversationBusyStateUsecaseProvider,
    ),
    conversationSendQueueNotifier: ref.watch(
      conversationSendQueueProvider.notifier,
    ),
  );
});
