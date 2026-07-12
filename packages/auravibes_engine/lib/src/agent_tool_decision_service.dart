import 'package:auravibes_engine/src/agent_iteration_decision.dart';

enum AgentToolCallState {
  pending,
  resolved,
  stopped,
}

AgentIterationDecision decideAgentToolIteration(
  List<AgentToolCallState>? toolCalls,
) {
  if (toolCalls == null || toolCalls.isEmpty) {
    return AgentIterationDecision.done;
  }
  if (toolCalls.contains(AgentToolCallState.stopped)) {
    return AgentIterationDecision.done;
  }
  if (toolCalls.contains(AgentToolCallState.pending)) {
    return AgentIterationDecision.waitForToolApproval;
  }

  return AgentIterationDecision.continueIteration;
}

// ignore: one_member_abstracts, provider interface keeps DB reads injectable.
abstract interface class AgentToolDecisionProvider {
  Future<List<AgentToolCallState>?> getToolCallStates(String messageId);
}

class AgentToolDecisionService {
  const AgentToolDecisionService({
    required this.provider,
  });

  final AgentToolDecisionProvider provider;

  Future<AgentIterationDecision> call({required String messageId}) async {
    final toolCalls = await provider.getToolCallStates(messageId);
    return decideAgentToolIteration(toolCalls);
  }
}
