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

  const WorkspaceAgentHookSettings.defaults(String workspaceId)
    : this(workspaceId: workspaceId, enabled: false);
}
