import 'package:auravibes_engine/src/agent_iteration_context.dart';
import 'package:auravibes_engine/src/agent_iteration_decision.dart';
import 'package:auravibes_engine/src/agent_runtime.dart';
import 'package:auravibes_engine/src/agent_service.dart';
import 'package:auravibes_engine/src/agent_stop_service.dart';
import 'package:auravibes_engine/src/providers/agent_data_provider.dart';
import 'package:auravibes_engine/src/providers/agent_model_provider.dart';

class AgentNamespace {
  AgentNamespace({
    required AgentDataProvider data,
    required AgentModelProvider models,
    required AgentLoopToolProvider tools,
    required AgentSendQueueRuntime sendQueueRuntime,
    required AgentCancellationEffects cancellationEffects,
    required AgentRateLimitRetryRuntime rateLimitRetryRuntime,
  }) : _loop = AgentService(
         data: data,
         models: models,
         tools: tools,
         sendQueueRuntime: sendQueueRuntime,
         cancellationEffects: cancellationEffects,
         rateLimitRetryRuntime: rateLimitRetryRuntime,
       ),
       _stop = AgentStopService(
         cancellationEffects: cancellationEffects,
         sendQueueRuntime: sendQueueRuntime,
         provider: data,
       );

  final AgentService _loop;
  final AgentStopService _stop;

  Future<AgentIterationDecision> continueTurn({
    required String conversationId,
    required AgentIterationContext context,
  }) {
    return _loop.call(conversationId: conversationId, context: context);
  }

  Future<void> stop({required String conversationId}) {
    return _stop.call(conversationId: conversationId);
  }
}
