import 'package:auravibes_agent/src/agent_iteration_context.dart';
import 'package:auravibes_agent/src/continue_agent_result.dart';

// ignore: one_member_abstracts, provider interface keeps model calls injectable.
abstract interface class AgentModelProvider {
  Future<ContinueAgentResult> continueAgent({
    required String conversationId,
    AgentIterationContext? context,
  });
}
