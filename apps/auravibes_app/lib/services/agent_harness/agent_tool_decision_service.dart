// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_agent/auravibes_agent.dart' as agent;
import 'package:auravibes_agent/auravibes_agent_internal.dart'
    as agent_decision;
import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:riverpod/riverpod.dart';

class AppAgentToolCallDataProvider implements agent.AgentToolDecisionProvider {
  const AppAgentToolCallDataProvider({required this.messageRepository});
  final MessageRepository messageRepository;

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
      if (toolCall.isPending) return agent.AgentToolCallState.pending;

      return agent.AgentToolCallState.resolved;
    }).toList();
  }
}

class AgentToolDecisionService extends agent_decision.AgentToolDecisionService {
  AgentToolDecisionService({
    required MessageRepository messageRepository,
  }) : super(
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
