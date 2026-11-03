import 'package:auravibes_app/services/agent_lifecycle_hook_config.dart';
import 'package:auravibes_app/services/agent_lifecycle_hook_runtime_api.dart';

AgentLifecycleHookRuntime createAgentLifecycleHookRuntime() =>
    const AgentLifecycleHookRuntimeStub();

class const AgentLifecycleHookRuntimeStub()
    implements AgentLifecycleHookRuntime {
  @override
  bool get isSupported => false;

  @override
  Future<AgentLifecycleHookSourceSnapshot> inspect(String sourcePath) async {
    throw const AgentLifecycleHookConfigException('unsupported_platform');
  }

  @override
  Future<AgentLifecycleHookInvocationResult> invoke(
    AgentLifecycleHookInvocationRequest request,
  ) async => const AgentLifecycleHookInvocationResult(outcome: .unavailable);
}
