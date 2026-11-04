import 'package:auravibes_app/services/agent_lifecycle_hook_config.dart';
import 'package:auravibes_app/services/agent_lifecycle_hook_runtime_api.dart';

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

abstract final class AgentLifecycleHookRuntimeFactory {
  static AgentLifecycleHookRuntime create() =>
      const AgentLifecycleHookRuntimeStub();
}
