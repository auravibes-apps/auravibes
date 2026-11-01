import 'agent_lifecycle_hook_runtime_api.dart';
import 'agent_lifecycle_hook_runtime_stub.dart'
    if (dart.library.io) 'agent_lifecycle_hook_runtime_io.dart'
    as platform;

export 'agent_lifecycle_hook_runtime_api.dart';

AgentLifecycleHookRuntime createAgentLifecycleHookRuntime() =>
    platform.createAgentLifecycleHookRuntime();
