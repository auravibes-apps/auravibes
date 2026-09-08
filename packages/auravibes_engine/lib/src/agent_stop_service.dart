import 'package:auravibes_engine/src/agent_runtime.dart';

abstract interface class AgentStopProvider {
  Future<void> stopLatestPendingTools(String conversationId);
}

class const AgentStopService({
  required final AgentCancellationEffects cancellationEffects,
  required final AgentSendQueueRuntime sendQueueRuntime,
  required final AgentStopProvider provider,
}) {
  Future<void> call({required String conversationId}) async {
    cancellationEffects.requestStop(conversationId);
    sendQueueRuntime.clear(conversationId);
    await provider.stopLatestPendingTools(conversationId);
  }
}
