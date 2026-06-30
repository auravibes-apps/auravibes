// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_agent/auravibes_agent.dart'
    show AgentIterationContext, AgentIterationDecision, AgentIterationOrigin;
import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_send_queue_runtime.dart';
import 'package:auravibes_app/features/chats/usecases/conversation_busy_state.dart';
import 'package:auravibes_app/services/agent_harness/aura_agent_service.dart';
import 'package:riverpod/riverpod.dart';

typedef ContinueAgentTurn =
    Future<AgentIterationDecision> Function({
      required String conversationId,
      required AgentIterationContext context,
    });

class SendMessageUsecase {
  const SendMessageUsecase({
    required this.continueAgentTurn,
    required this.messageRepository,
    required this.getConversationBusyStateUsecase,
    required this.sendQueueRuntime,
  });

  final ContinueAgentTurn continueAgentTurn;
  final MessageRepository messageRepository;
  final GetConversationBusyStateUsecase getConversationBusyStateUsecase;
  final ConversationSendQueueRuntime sendQueueRuntime;

  Future<void> call({
    required String conversationId,
    required String content,
  }) async {
    final busyState = await getConversationBusyStateUsecase.call(
      conversationId: conversationId,
    );
    if (busyState.isBusy) {
      final _ = sendQueueRuntime.enqueue(
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
    final _ = await continueAgentTurn(
      conversationId: conversationId,
      context: AgentIterationContext(
        origin: AgentIterationOrigin.userMessage,
        ackMessageIds: [createdMessage.id],
      ),
    );
  }
}

final sendMessageUsecaseProvider = Provider<SendMessageUsecase>((ref) {
  final agentService = ref.watch(auraAgentServiceProvider);

  return SendMessageUsecase(
    continueAgentTurn: agentService.agent.continueTurn,
    messageRepository: ref.watch(messageRepositoryProvider),
    getConversationBusyStateUsecase: ref.watch(
      getConversationBusyStateUsecaseProvider,
    ),
    sendQueueRuntime: ref.watch(conversationSendQueueRuntimeProvider),
  );
});
