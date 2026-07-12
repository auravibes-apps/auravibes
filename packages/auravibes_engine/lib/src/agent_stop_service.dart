import 'package:auravibes_engine/src/agent_runtime.dart';

// ignore: one_member_abstracts, provider interface keeps DB writes injectable.
abstract interface class AgentStopProvider {
  Future<void> stopLatestPendingTools(String conversationId);
}

class AgentStopService {
  const AgentStopService({
    required this.cancellationEffects,
    required this.sendQueueRuntime,
    required this.provider,
  });

  final AgentCancellationEffects cancellationEffects;
  final AgentSendQueueRuntime sendQueueRuntime;
  final AgentStopProvider provider;

  Future<void> call({required String conversationId}) async {
    cancellationEffects.requestStop(conversationId);
    sendQueueRuntime.clear(conversationId);
    await provider.stopLatestPendingTools(conversationId);
  }
}
