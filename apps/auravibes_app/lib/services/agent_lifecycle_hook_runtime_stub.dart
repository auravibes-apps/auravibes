import 'package:auravibes_app/services/agent_lifecycle_hook_config.dart';
import 'package:auravibes_app/services/agent_lifecycle_hook_runtime_api.dart';
import 'package:auravibes_engine/auravibes_engine.dart';

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
  Future<AgentLifecycleHookInvocationResult> invoke({
    required AgentLifecycleHookSourceSnapshot snapshot,
    required AgentLifecycleHookDefinition hook,
    required String input,
    required AgentToolHookCancellationChecker isCancellationRequested,
    required String conversationId,
    Future<bool> Function()? isStillTrusted,
  }) async => const AgentLifecycleHookInvocationResult(outcome: .unavailable);
}
