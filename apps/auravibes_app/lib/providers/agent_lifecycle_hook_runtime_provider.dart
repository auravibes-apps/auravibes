import 'package:auravibes_app/services/agent_lifecycle_hook_runtime.dart';
import 'package:riverpod/riverpod.dart';

final agentLifecycleHookRuntimeProvider = Provider<AgentLifecycleHookRuntime>(
  (_) => createAgentLifecycleHookRuntime(),
);
