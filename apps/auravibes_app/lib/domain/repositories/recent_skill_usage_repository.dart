abstract interface class RecentSkillUsageRepository {
  Future<List<String>> readRecentSkillSlugs(String workspaceId);

  Future<void> recordUseNow({
    required String workspaceId,
    required String skillSlug,
  });
}
