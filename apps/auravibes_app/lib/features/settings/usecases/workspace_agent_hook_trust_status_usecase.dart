import 'package:auravibes_app/domain/entities/workspace_agent_hook_settings.dart';
import 'package:auravibes_app/features/settings/models/workspace_agent_hook_trust_status.dart';
import 'package:auravibes_app/services/agent_lifecycle_hook_runtime.dart';

class const WorkspaceAgentHookTrustStatusUsecase(
  final AgentLifecycleHookRuntime runtime,
) {
  Future<WorkspaceAgentHookTrustStatus> call(
    WorkspaceAgentHookSettings settings,
  ) async {
    final path = settings.configPath;
    if (path == null) return .notConfigured;
    if (!settings.isTrusted) return .trustRequired;

    try {
      final snapshot = await runtime.inspect(path);

      return settings.trustsSource(
            canonicalPath: snapshot.canonicalPath,
            digest: snapshot.digest,
          )
          ? .trusted
          : .changed;
    } on Object {
      return .invalid;
    }
  }
}
