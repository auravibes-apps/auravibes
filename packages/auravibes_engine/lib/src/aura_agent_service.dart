import 'package:auravibes_engine/src/agent_runtime.dart';
import 'package:auravibes_engine/src/agent_service.dart';
import 'package:auravibes_engine/src/namespaces/agent_namespace.dart';
import 'package:auravibes_engine/src/namespaces/conversations_namespace.dart';
import 'package:auravibes_engine/src/namespaces/tools_namespace.dart';
import 'package:auravibes_engine/src/providers/agent_data_provider.dart';
import 'package:auravibes_engine/src/providers/agent_model_provider.dart';
import 'package:auravibes_engine/src/tool_call_actions.dart';
import 'package:auravibes_engine/src/tool_resume_service.dart';

class AuraAgentService<TTool extends Object>({
  required AgentDataProvider data,
  required AgentModelProvider models,
  required AgentLoopToolProvider loopTools,
  required ApproveToolCallProvider<TTool> approvals,
  required SkipToolCallProvider skips,
  required StopPendingToolCallsProvider stopPending,
  required AgentToolResumeProvider resume,
  required AgentSendQueueRuntime sendQueueRuntime,
  required AgentCancellationEffects cancellationEffects,
  required AgentRateLimitRetryRuntime rateLimitRetryRuntime,
}) {
  final AgentNamespace agent = AgentNamespace(
    data: data,
    models: models,
    tools: loopTools,
    sendQueueRuntime: sendQueueRuntime,
    cancellationEffects: cancellationEffects,
    rateLimitRetryRuntime: rateLimitRetryRuntime,
  );
  final ConversationsNamespace conversations = ConversationsNamespace(
    data: data,
  );
  final ToolsNamespace<TTool> tools = ToolsNamespace<TTool>(
    approvals: approvals,
    skips: skips,
    stopPending: stopPending,
    resume: resume,
  );
}
