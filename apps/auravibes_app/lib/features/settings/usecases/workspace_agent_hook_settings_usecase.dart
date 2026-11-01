import 'package:auravibes_app/data/repositories/workspace_agent_hook_settings_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:auravibes_app/features/settings/models/workspace_agent_hook_config_review.dart';
import 'package:auravibes_app/services/agent_lifecycle_hook_config.dart';
import 'package:auravibes_app/services/agent_lifecycle_hook_runtime.dart';

class WorkspaceAgentHookSettingsUsecase {
  const WorkspaceAgentHookSettingsUsecase({
    required WorkspaceAgentHookSettingsRepository settingsRepository,
    required WorkspaceRepository workspaceRepository,
    required AgentLifecycleHookRuntime runtime,
  }) : _settingsRepository = settingsRepository,
       _workspaceRepository = workspaceRepository,
       _runtime = runtime;

  final WorkspaceAgentHookSettingsRepository _settingsRepository;
  final WorkspaceRepository _workspaceRepository;
  final AgentLifecycleHookRuntime _runtime;

  Future<void> selectConfig(String workspaceId, String sourcePath) async {
    await _requireLocalWorkspace(workspaceId);
    _requireSupported();
    final snapshot = await _inspect(sourcePath);
    await _settingsRepository.selectConfig(
      workspaceId,
      canonicalPath: snapshot.canonicalPath,
    );
  }

  Future<WorkspaceAgentHookConfigReview> reviewConfig(
    String workspaceId,
    String sourcePath,
  ) async {
    await _requireLocalWorkspace(workspaceId);
    _requireSupported();
    final settings = await _settingsRepository.get(workspaceId);
    final snapshot = await _inspect(sourcePath);
    if (snapshot.canonicalPath != settings.configPath) {
      throw const WorkspaceAgentHookSettingsException(
        'agent_lifecycle_hooks.configuration_changed',
      );
    }

    return _review(snapshot);
  }

  Future<void> trustReviewedConfig(
    String workspaceId,
    WorkspaceAgentHookConfigReview review,
  ) async {
    await _requireLocalWorkspace(workspaceId);
    _requireSupported();
    final settings = await _settingsRepository.get(workspaceId);
    if (settings.configPath != review.canonicalPath) {
      throw const WorkspaceAgentHookSettingsException(
        'agent_lifecycle_hooks.configuration_changed',
      );
    }

    final snapshot = await _inspect(review.canonicalPath);
    if (snapshot.canonicalPath != review.canonicalPath ||
        snapshot.digest != review.digest) {
      throw const WorkspaceAgentHookSettingsException(
        'agent_lifecycle_hooks.configuration_changed',
      );
    }
    await _settingsRepository.trustConfig(
      workspaceId,
      canonicalPath: review.canonicalPath,
      digest: review.digest,
    );
  }

  Future<void> setEnabled(String workspaceId, {required bool enabled}) async {
    if (enabled) {
      await _requireLocalWorkspace(workspaceId);
      _requireSupported();
      final settings = await _settingsRepository.get(workspaceId);
      final configPath = settings.configPath;
      if (!settings.isTrusted || configPath == null) {
        throw const WorkspaceAgentHookSettingsException(
          'agent_lifecycle_hooks.trust_required',
        );
      }

      final snapshot = await _inspect(configPath);
      if (snapshot.canonicalPath != settings.trustedSourcePath ||
          snapshot.digest != settings.trustedDigest) {
        throw const WorkspaceAgentHookSettingsException(
          'agent_lifecycle_hooks.configuration_changed',
        );
      }
    }

    await _settingsRepository.setEnabled(workspaceId, enabled: enabled);
  }

  Future<void> revokeTrust(String workspaceId) async {
    await _settingsRepository.revokeTrust(workspaceId);
  }

  Future<void> _requireLocalWorkspace(String workspaceId) async {
    final workspace = await _workspaceRepository.getWorkspaceById(workspaceId);
    if (workspace == null || workspace.type != WorkspaceType.local) {
      throw const WorkspaceAgentHookSettingsException(
        'agent_lifecycle_hooks.local_only',
      );
    }
  }

  void _requireSupported() {
    if (!_runtime.isSupported) {
      throw const WorkspaceAgentHookSettingsException(
        'agent_lifecycle_hooks.unsupported_platform',
      );
    }
  }

  Future<AgentLifecycleHookSourceSnapshot> _inspect(String sourcePath) async {
    try {
      return await _runtime.inspect(sourcePath);
    } on AgentLifecycleHookConfigException catch (error) {
      if (error.code == 'unsupported_platform') {
        throw const WorkspaceAgentHookSettingsException(
          'agent_lifecycle_hooks.unsupported_platform',
        );
      }
      throw const WorkspaceAgentHookSettingsException(
        'agent_lifecycle_hooks.invalid_configuration',
      );
    } on Object {
      throw const WorkspaceAgentHookSettingsException(
        'agent_lifecycle_hooks.invalid_configuration',
      );
    }
  }

  WorkspaceAgentHookConfigReview _review(
    AgentLifecycleHookSourceSnapshot snapshot,
  ) => WorkspaceAgentHookConfigReview(
    canonicalPath: snapshot.canonicalPath,
    digest: snapshot.digest,
    commands: [
      for (final hook in snapshot.config.hooks)
        WorkspaceAgentHookCommandReview(
          event: hook.event == AgentLifecycleHookEvent.beforeTool
              ? WorkspaceAgentHookEvent.beforeTool
              : WorkspaceAgentHookEvent.afterTool,
          canonicalCommandPath: snapshot.commandPaths[hook.event]!,
          arguments: hook.args,
        ),
    ],
    sourceFiles: snapshot.sourceFilePaths,
  );
}

class WorkspaceAgentHookSettingsException implements Exception {
  const WorkspaceAgentHookSettingsException(this.localizationKey);

  final String localizationKey;
}
