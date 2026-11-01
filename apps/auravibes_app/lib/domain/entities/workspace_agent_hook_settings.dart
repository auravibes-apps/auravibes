class const WorkspaceAgentHookSettings({
  required final String workspaceId,
  required final bool enabled,
  final String? configPath,
  final String? trustedSourcePath,
  final String? trustedDigest,
}) {
  bool get isTrusted =>
      configPath != null &&
      trustedSourcePath == configPath &&
      trustedDigest != null;

  static WorkspaceAgentHookSettings defaults(String workspaceId) =>
      WorkspaceAgentHookSettings(workspaceId: workspaceId, enabled: false);
}
