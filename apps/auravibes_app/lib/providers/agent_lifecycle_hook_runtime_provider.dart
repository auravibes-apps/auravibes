import 'package:auravibes_app/services/agent_lifecycle_hook_runtime.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'agent_lifecycle_hook_runtime_provider.g.dart';

@Riverpod(keepAlive: true)
AgentLifecycleHookRuntime agentLifecycleHookRuntime(Ref _) =>
    createAgentLifecycleHookRuntime();
