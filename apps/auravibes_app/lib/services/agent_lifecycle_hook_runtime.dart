import 'package:auravibes_app/services/agent_lifecycle_hook_config.dart';
import 'package:auravibes_app/services/agent_lifecycle_hook_runtime_stub.dart'
    if (dart.library.io) 'package:auravibes_app/services/agent_lifecycle_hook_runtime_io.dart'
    as platform;
import 'package:auravibes_engine/auravibes_engine.dart';

abstract interface class AgentLifecycleHookRuntime {
  bool get isSupported;

  Future<AgentLifecycleHookSourceSnapshot> inspect(String sourcePath);

  /// Rechecks source fingerprints and optional host trust before launching.
  ///
  /// The host callback reads current workspace opt-in and trust after the
  /// runtime's final asynchronous inspection. A false result prevents launch.
  Future<AgentLifecycleHookInvocationResult> invoke({
    required AgentLifecycleHookSourceSnapshot snapshot,
    required AgentLifecycleHookDefinition hook,
    required String input,
    required AgentToolHookCancellationChecker isCancellationRequested,
    required String conversationId,
    Future<bool> Function()? isStillTrusted,
  });
}

const int maxAgentLifecycleHookInputBytes = 8 * 1024;
const int maxAgentLifecycleHookExecutableBytes = 32 * 1024 * 1024;
const int maxAgentLifecycleHookTrustedSourceBytes = 64 * 1024 * 1024;

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

AgentLifecycleHookRuntime createAgentLifecycleHookRuntime() =>
    platform.createAgentLifecycleHookRuntime();
