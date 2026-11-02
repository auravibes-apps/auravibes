import 'package:auravibes_app/data/repositories/workspace_agent_hook_settings_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_repository.dart';
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
    await _requireLocalWorkspace(workspaceId);
    _requireSupported();
    final snapshot = await _inspect(sourcePath);
    final _ = await settingsRepository.selectConfig(
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
    final settings = await settingsRepository.get(workspaceId);
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
    final settings = await settingsRepository.get(workspaceId);
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
    final _ = await settingsRepository.trustConfig(
      workspaceId,
      canonicalPath: review.canonicalPath,
      digest: review.digest,
    );
  }

  Future<void> setEnabled(String workspaceId, {required bool enabled}) async {
    if (enabled) {
      await _requireLocalWorkspace(workspaceId);
      _requireSupported();
      final settings = await settingsRepository.get(workspaceId);
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

    final _ = await settingsRepository.setEnabled(
      workspaceId,
      enabled: enabled,
    );
  }

  Future<void> revokeTrust(String workspaceId) async {
    final _ = await settingsRepository.revokeTrust(workspaceId);
  }

  Future<void> _requireLocalWorkspace(String workspaceId) async {
    final workspace = await workspaceRepository.getWorkspaceById(workspaceId);
    if (workspace == null || workspace.type != WorkspaceType.local) {
      throw const WorkspaceAgentHookSettingsException(
        'agent_lifecycle_hooks.local_only',
      );
    }
  }

  void _requireSupported() {
    if (!runtime.isSupported) {
      throw const WorkspaceAgentHookSettingsException(
        'agent_lifecycle_hooks.unsupported_platform',
      );
    }
  }

  Future<AgentLifecycleHookSourceSnapshot> _inspect(String sourcePath) async {
    try {
      return await runtime.inspect(sourcePath);
    } on AgentLifecycleHookConfigException catch (error, stackTrace) {
      if (error.code == 'unsupported_platform') {
        Error.throwWithStackTrace(
          const WorkspaceAgentHookSettingsException(
            'agent_lifecycle_hooks.unsupported_platform',
          ),
          stackTrace,
        );
      }
      Error.throwWithStackTrace(
        const WorkspaceAgentHookSettingsException(
          'agent_lifecycle_hooks.invalid_configuration',
        ),
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
  const new(this.localizationKey);

  final String localizationKey;
}
