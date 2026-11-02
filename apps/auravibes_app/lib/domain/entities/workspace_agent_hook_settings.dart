class const WorkspaceAgentHookSettings({
  required final String workspaceId,
  required final bool enabled,
  final String? configPath,
  final String? trustedSourcePath,
  final String? trustedDigest,
}) {
  const new defaults(String workspaceId)
    : this(workspaceId: workspaceId, enabled: false);

  bool get isTrusted =>
      configPath != null &&
      trustedSourcePath == configPath &&
      trustedDigest != null;
}
