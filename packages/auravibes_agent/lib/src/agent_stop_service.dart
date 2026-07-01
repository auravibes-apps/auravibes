import 'package:auravibes_agent/src/agent_runtime.dart';

// ignore: one_member_abstracts, provider interface keeps DB writes injectable.
abstract interface class AgentStopProvider {
  Future<void> stopLatestPendingTools(String conversationId);
}

class AgentStopService {
  const AgentStopService({
    required this.agentCancellationRuntime,
    required this.sendQueueRuntime,
    required this.provider,
  });

  final AgentCancellationRuntime agentCancellationRuntime;
  final AgentSendQueueRuntime sendQueueRuntime;
  final AgentStopProvider provider;

  Future<void> call({required String conversationId}) async {
    agentCancellationRuntime.requestStop(conversationId);
    sendQueueRuntime.clear(conversationId);
    await provider.stopLatestPendingTools(conversationId);
  }
}
