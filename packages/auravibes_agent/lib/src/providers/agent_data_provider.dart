import 'package:auravibes_agent/src/agent_runtime.dart';
import 'package:auravibes_agent/src/agent_stop_service.dart';

abstract interface class AgentDataProvider
    implements AgentConversationDataProvider, AgentStopProvider {
  Future<void> autoCompactConversation({
    required String conversationId,
  });
}
