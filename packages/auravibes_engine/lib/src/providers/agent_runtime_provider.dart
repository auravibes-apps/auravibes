import 'package:auravibes_engine/src/agent_runtime.dart';

abstract interface class AgentRuntimeProvider {
  AgentSendQueueRuntime get sendQueueRuntime;

  AgentCancellationRuntime get cancellationRuntime;

  AgentRateLimitRetryRuntime get rateLimitRetryRuntime;
}
