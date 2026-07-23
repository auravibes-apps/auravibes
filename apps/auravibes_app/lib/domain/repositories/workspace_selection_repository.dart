abstract interface class WorkspaceSelectionRepository {
  Future<String?> read();

  Future<void> save(String workspaceId);

  Future<void> clearIfMatches(String workspaceId);
}
