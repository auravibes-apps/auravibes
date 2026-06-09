import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/daos/app_skill_workspace_settings_dao.dart';
import 'package:auravibes_app/domain/repositories/app_skill_workspace_settings_repository.dart';

class AppSkillWorkspaceSettingsRepositoryImpl
    implements AppSkillWorkspaceSettingsRepository {
  AppSkillWorkspaceSettingsRepositoryImpl(AppDatabase database)
    : _dao = database.appSkillWorkspaceSettingsDao;

  final AppSkillWorkspaceSettingsDao _dao;

  @override
  Future<bool> isAppSkillEnabled(
    String workspaceId,
    String appSkillIdentifier,
  ) {
    return _dao.isAppSkillEnabled(workspaceId, appSkillIdentifier);
  }

  @override
  Future<void> setAppSkillEnabled(
    String workspaceId,
    String appSkillIdentifier, {
    required bool isEnabled,
  }) async {
    final _ = await _dao.setAppSkillEnabled(
      workspaceId,
      appSkillIdentifier,
      isEnabled: isEnabled,
    );
  }
}
