import 'package:auravibes_app/data/repositories/workspace_agent_hook_settings_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/domain/entities/workspace_agent_hook_settings.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:auravibes_app/features/settings/models/workspace_agent_hook_config_review.dart';
import 'package:auravibes_app/services/agent_lifecycle_hook_config.dart';
import 'package:auravibes_app/services/agent_lifecycle_hook_runtime.dart';

class const WorkspaceAgentHookSettingsUsecase({
  required final WorkspaceAgentHookSettingsRepository settingsRepository,
  required final WorkspaceRepository workspaceRepository,
  required final AgentLifecycleHookRuntime runtime,
}) {
  Future<void> selectConfig(String workspaceId, String sourcePath) async {
    await _requireLocalWorkspace(workspaceRepository, workspaceId);
    _requireSupported(runtime);
    final snapshot = await _inspect(runtime, sourcePath);
    final _ = await settingsRepository.selectConfig(
      workspaceId,
      canonicalPath: snapshot.canonicalPath,
    );
  }

  Future<WorkspaceAgentHookConfigReview> reviewConfig(
    String workspaceId,
    String sourcePath,
  ) async {
    await _requireLocalWorkspace(workspaceRepository, workspaceId);
    _requireSupported(runtime);
    final settings = await settingsRepository.get(workspaceId);
    final snapshot = await _inspect(runtime, sourcePath);
    if (snapshot.canonicalPath != settings.configPath) {
      throw const WorkspaceAgentHookSettingsException(
        'agent_lifecycle_hooks.configuration_changed',
      );
    }

    return _configReview(snapshot);
  }

  Future<void> trustReviewedConfig(
    String workspaceId,
    WorkspaceAgentHookConfigReview review,
  ) async {
    await _requireLocalWorkspace(workspaceRepository, workspaceId);
    _requireSupported(runtime);
    final settings = await settingsRepository.get(workspaceId);
    await _validateReviewedConfig(runtime, settings, review);
    final _ = await settingsRepository.trustConfig(
      workspaceId,
      canonicalPath: review.canonicalPath,
      digest: review.digest,
    );
  }

  Future<void> setEnabled(String workspaceId, {required bool enabled}) async {
    if (enabled) {
      await _validateCanEnable(
        workspaceId,
        workspaceRepository,
        settingsRepository,
        runtime,
      );
    }

    final _ = await settingsRepository.setEnabled(
      workspaceId,
      enabled: enabled,
    );
  }

  Future<void> revokeTrust(String workspaceId) async {
    final _ = await settingsRepository.revokeTrust(workspaceId);
  }
}

Future<void> _requireLocalWorkspace(
  WorkspaceRepository workspaceRepository,
  String workspaceId,
) async {
  final workspace = await workspaceRepository.getWorkspaceById(workspaceId);
  if (workspace == null || workspace.type != WorkspaceType.local) {
    throw const WorkspaceAgentHookSettingsException(
      'agent_lifecycle_hooks.local_only',
    );
  }
}

void _requireSupported(AgentLifecycleHookRuntime runtime) {
  if (!runtime.isSupported) {
    throw const WorkspaceAgentHookSettingsException(
      'agent_lifecycle_hooks.unsupported_platform',
    );
  }
}

Future<AgentLifecycleHookSourceSnapshot> _inspect(
  AgentLifecycleHookRuntime runtime,
  String sourcePath,
) async {
  try {
    return await runtime.inspect(sourcePath);
  } on AgentLifecycleHookConfigException catch (error, stackTrace) {
    final key = error.code == 'unsupported_platform'
        ? 'agent_lifecycle_hooks.unsupported_platform'
        : 'agent_lifecycle_hooks.invalid_configuration';
    Error.throwWithStackTrace(
      WorkspaceAgentHookSettingsException(key),
      stackTrace,
    );
  } on Object catch (_, stackTrace) {
    Error.throwWithStackTrace(
      const WorkspaceAgentHookSettingsException(
        'agent_lifecycle_hooks.invalid_configuration',
      ),
      stackTrace,
    );
  }
}

Future<void> _validateReviewedConfig(
  AgentLifecycleHookRuntime runtime,
  WorkspaceAgentHookSettings settings,
  WorkspaceAgentHookConfigReview review,
) async {
  if (settings.configPath != review.canonicalPath) {
    throw _configurationChanged();
  }

  final snapshot = await _inspect(runtime, review.canonicalPath);
  if (snapshot.canonicalPath != review.canonicalPath ||
      snapshot.digest != review.digest) {
    throw _configurationChanged();
  }
}

Future<void> _validateCanEnable(
  String workspaceId,
  WorkspaceRepository workspaceRepository,
  WorkspaceAgentHookSettingsRepository settingsRepository,
  AgentLifecycleHookRuntime runtime,
) async {
  await _requireLocalWorkspace(workspaceRepository, workspaceId);
  _requireSupported(runtime);
  final settings = await settingsRepository.get(workspaceId);
  await _validateEnabledSettings(settings, runtime);
}

Future<void> _validateEnabledSettings(
  WorkspaceAgentHookSettings settings,
  AgentLifecycleHookRuntime runtime,
) async {
  final configPath = _trustedConfigPath(settings);
  final snapshot = await _inspect(runtime, configPath);
  _requireMatchingTrust(settings, snapshot);
}

String _trustedConfigPath(WorkspaceAgentHookSettings settings) {
  final path = settings.configPath;
  if (settings.isTrusted && path != null) return path;

  throw const WorkspaceAgentHookSettingsException(
    'agent_lifecycle_hooks.trust_required',
  );
}

void _requireMatchingTrust(
  WorkspaceAgentHookSettings settings,
  AgentLifecycleHookSourceSnapshot snapshot,
) {
  if (settings.trustsSource(
    canonicalPath: snapshot.canonicalPath,
    digest: snapshot.digest,
  )) {
    return;
  }
  throw _configurationChanged();
}

WorkspaceAgentHookConfigReview _configReview(
  AgentLifecycleHookSourceSnapshot snapshot,
) => WorkspaceAgentHookConfigReview(
  canonicalPath: snapshot.canonicalPath,
  digest: snapshot.digest,
  commands: _commandReviews(snapshot),
  sourceFiles: snapshot.sourceFilePaths,
);

List<WorkspaceAgentHookCommandReview> _commandReviews(
  AgentLifecycleHookSourceSnapshot snapshot,
) => [
  for (final hook in snapshot.config.hooks)
    WorkspaceAgentHookCommandReview(
      event: _reviewEvent(hook.event),
      canonicalCommandPath: snapshot.commandPaths[hook.event]!,
      arguments: hook.args,
    ),
];

WorkspaceAgentHookEvent _reviewEvent(AgentLifecycleHookEvent event) =>
    event == AgentLifecycleHookEvent.beforeTool
    ? WorkspaceAgentHookEvent.beforeTool
    : WorkspaceAgentHookEvent.afterTool;

WorkspaceAgentHookSettingsException _configurationChanged() =>
    const WorkspaceAgentHookSettingsException(
      'agent_lifecycle_hooks.configuration_changed',
    );

class WorkspaceAgentHookSettingsException implements Exception {
  const new(this.localizationKey);

  final String localizationKey;

  @override
  String toString() => localizationKey;
}
