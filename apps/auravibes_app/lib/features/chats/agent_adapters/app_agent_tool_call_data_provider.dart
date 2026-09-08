// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_engine/auravibes_engine.dart' as agent;
import 'package:riverpod/riverpod.dart';

class const AppAgentToolCallDataProvider({
  required final MessageRepository messageRepository,
}) implements agent.AgentToolDecisionProvider {
  @override
  Future<List<agent.AgentToolCallState>?> getToolCallStates(
    String messageId,
  ) async {
    final message = await messageRepository.getMessageById(messageId);
    if (message == null) {
      return null;
    }

    final toolCalls = message.metadata?.toolCalls ?? const [];

    return toolCalls.map((toolCall) {
      if (toolCall.resultStatus == ToolCallResultStatus.stoppedByUser) {
        return agent.AgentToolCallState.stopped;
      }
      if (toolCall.isAwaitingApproval) {
        return agent.AgentToolCallState.pending;
      }

      return agent.AgentToolCallState.resolved;
    }).toList();
  }
}

class AgentToolDecisionService({required MessageRepository messageRepository})
    extends agent.AgentToolDecisionRunner {
  this
    : super(
        provider: AppAgentToolCallDataProvider(
          messageRepository: messageRepository,
        ),
      );
}

final agentToolDecisionServiceProvider = Provider<AgentToolDecisionService>((
  ref,
) {
  return AgentToolDecisionService(
    messageRepository: ref.watch(messageRepositoryProvider),
  );
});
