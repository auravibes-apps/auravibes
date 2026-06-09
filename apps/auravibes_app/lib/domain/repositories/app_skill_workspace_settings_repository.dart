abstract class AppSkillWorkspaceSettingsRepository {
  Future<bool> isAppSkillEnabled(String workspaceId, String appSkillIdentifier);

  Future<void> setAppSkillEnabled(
    String workspaceId,
    String appSkillIdentifier, {
    required bool isEnabled,
  });
}
