import 'package:auravibes_engine/src/agent_iteration_context.dart';
import 'package:auravibes_engine/src/continue_agent_result.dart';

abstract interface class AgentModelProvider {
  Future<ContinueAgentResult> continueAgent({
    required String conversationId,
    AgentIterationContext? context,
  });
}
