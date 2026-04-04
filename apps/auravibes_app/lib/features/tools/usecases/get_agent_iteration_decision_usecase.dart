import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/domain/repositories/message_repository.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/usecases/agent_iteration_decision.dart';
import 'package:riverpod/riverpod.dart';

class GetAgentIterationDecisionUsecase {
  const GetAgentIterationDecisionUsecase({
    required this.messageRepository,
  });

  final MessageRepository messageRepository;

  Future<AgentIterationDecision> call({required String messageId}) async {
    final message = await messageRepository.getMessageById(messageId);
    if (message == null) {
      return AgentIterationDecision.done;
    }

    final metadata = message.metadata ?? const MessageMetadataEntity();
    if (metadata.toolCalls.isEmpty) {
      return AgentIterationDecision.done;
    }

    final shouldStop = metadata.toolCalls.any(
      (toolCall) => toolCall.resultStatus == ToolCallResultStatus.stoppedByUser,
    );
    if (shouldStop) {
      return AgentIterationDecision.done;
    }

    final hasPendingTools = metadata.toolCalls.any(
      (toolCall) => toolCall.isPending,
    );
    if (hasPendingTools) {
      return AgentIterationDecision.waitForToolApproval;
    }

    return AgentIterationDecision.continueIteration;
  }
}

final getAgentIterationDecisionUsecaseProvider =
    Provider<GetAgentIterationDecisionUsecase>((ref) {
      return GetAgentIterationDecisionUsecase(
        messageRepository: ref.watch(messageRepositoryProvider),
      );
    });
