import 'package:auravibes_app/data/database/drift/app_database.dart';

class AppSkillWorkspaceSettingsRepository(AppDatabase database) {
  final AppSkillWorkspaceSettingsDao _dao =
      database.appSkillWorkspaceSettingsDao;

  Future<bool> isAppSkillEnabled(
    String workspaceId,
    String appSkillIdentifier,
  ) {
    return _dao.isAppSkillEnabled(workspaceId, appSkillIdentifier);
  }

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
