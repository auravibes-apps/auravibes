import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/domain/entities/workspace_agent_hook_settings.dart';

class WorkspaceAgentHookSettingsRepository(
  final WorkspaceAgentHookSettingsDao _dao,
) {
  Stream<WorkspaceAgentHookSettings> watch(String workspaceId) => _dao
      .watchByWorkspaceId(workspaceId)
      .map(
        (row) => row == null
            ? WorkspaceAgentHookSettings.defaults(workspaceId)
            : _mapRow(row),
      );

  Future<WorkspaceAgentHookSettings> get(String workspaceId) async {
    final row = await _dao.getByWorkspaceId(workspaceId);

    return row == null
        ? WorkspaceAgentHookSettings.defaults(workspaceId)
        : _mapRow(row);
  }

  Future<WorkspaceAgentHookSettings> selectConfig(
    String workspaceId, {
    required String? canonicalPath,
  }) async {
    final row = await _dao.save(
      workspaceId,
      WorkspaceAgentHookSettingsCompanion(
        enabled: const .new(false),
        configPath: .new(canonicalPath),
        trustedSourcePath: const .new(null),
        trustedDigest: const .new(null),
      ),
    );

    return _mapRow(row);
  }

  Future<WorkspaceAgentHookSettings> trustConfig(
    String workspaceId, {
    required String canonicalPath,
    required String digest,
  }) async {
    final current = await get(workspaceId);
    if (current.configPath != canonicalPath) {
      throw StateError('Lifecycle hook configuration changed before trust');
    }
    final row = await _dao.save(
      workspaceId,
      WorkspaceAgentHookSettingsCompanion(
        trustedSourcePath: .new(canonicalPath),
        trustedDigest: .new(digest),
      ),
    );

    return _mapRow(row);
  }

  Future<WorkspaceAgentHookSettings> setEnabled(
    String workspaceId, {
    required bool enabled,
  }) async {
    final current = await get(workspaceId);
    if (enabled && !current.isTrusted) {
      throw StateError('Lifecycle hook configuration is not trusted');
    }
    final row = await _dao.save(
      workspaceId,
      WorkspaceAgentHookSettingsCompanion(enabled: .new(enabled)),
    );

    return _mapRow(row);
  }

  Future<WorkspaceAgentHookSettings> revokeTrust(String workspaceId) async {
    final row = await _dao.save(
      workspaceId,
      const WorkspaceAgentHookSettingsCompanion(
        enabled: .new(false),
        trustedSourcePath: .new(null),
        trustedDigest: .new(null),
      ),
    );

    return _mapRow(row);
  }
}

WorkspaceAgentHookSettings _mapRow(WorkspaceAgentHookSettingsTable row) =>
    WorkspaceAgentHookSettings(
      workspaceId: row.workspaceId,
      enabled: row.enabled,
      configPath: row.configPath,
      trustedSourcePath: row.trustedSourcePath,
      trustedDigest: row.trustedDigest,
    );
