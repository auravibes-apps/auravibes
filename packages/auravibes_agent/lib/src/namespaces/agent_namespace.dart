import 'package:auravibes_agent/src/agent_iteration_context.dart';
import 'package:auravibes_agent/src/agent_iteration_decision.dart';
import 'package:auravibes_agent/src/agent_service.dart';
import 'package:auravibes_agent/src/agent_stop_service.dart';
import 'package:auravibes_agent/src/providers/agent_data_provider.dart';
import 'package:auravibes_agent/src/providers/agent_model_provider.dart';
import 'package:auravibes_agent/src/providers/agent_runtime_provider.dart';
import 'package:auravibes_agent/src/providers/agent_tool_provider.dart';

class AgentNamespace<TTool extends Object> {
  AgentNamespace({
    required AgentDataProvider data,
    required AgentModelProvider models,
    required AgentToolProvider<TTool> tools,
    required AgentRuntimeProvider runtime,
  }) : _loop = AgentService(
         data: data,
         models: models,
         tools: tools,
         sendQueueRuntime: runtime.sendQueueRuntime,
         agentCancellationRuntime: runtime.cancellationRuntime,
         rateLimitRetryRuntime: runtime.rateLimitRetryRuntime,
       ),
       _stop = AgentStopService(
         agentCancellationRuntime: runtime.cancellationRuntime,
         sendQueueRuntime: runtime.sendQueueRuntime,
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
