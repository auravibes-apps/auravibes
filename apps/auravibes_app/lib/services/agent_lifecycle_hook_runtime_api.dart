import 'package:auravibes_app/services/agent_lifecycle_hook_config.dart';
import 'package:auravibes_engine/auravibes_engine.dart';

const maxAgentLifecycleHookInputBytes = 8 * 1024;
const maxAgentLifecycleHookExecutableBytes = 32 * 1024 * 1024;
const maxAgentLifecycleHookTrustedSourceBytes = 64 * 1024 * 1024;

class const AgentLifecycleHookSourceSnapshot({
  required final String canonicalPath,
  required final String digest,
  required final AgentLifecycleHookConfig config,
  required final Map<AgentLifecycleHookEvent, String> commandPaths,
  final List<String> sourceFilePaths = const [],
});

class const AgentLifecycleHookInvocationResult({
  required final AgentToolHookOutcome outcome,
  final String? stdout,
});

abstract interface class AgentLifecycleHookRuntime {
  bool get isSupported;

  Future<AgentLifecycleHookSourceSnapshot> inspect(String sourcePath);

  Future<AgentLifecycleHookInvocationResult> invoke({
    required AgentLifecycleHookSourceSnapshot snapshot,
    required AgentLifecycleHookDefinition hook,
    required String input,
    required AgentToolHookCancellationChecker isCancellationRequested,
    required String conversationId,
  });
}
