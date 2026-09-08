/// Result of checking tool permission based on conversation and workspace
/// rules.
///
/// Permission logic:
/// 1. If the tool is not in the workspace, return [notConfigured].
/// 2. If the tool is in the workspace, check conversation rules first because
///    they take priority. Disabled, ask, and granted rules return
///    [disabledInConversation], [needsConfirmation], and [granted].
/// 3. If no conversation rule exists, check agent permissions.
/// 4. If no agent rule exists, check workspace permissions. Granted and ask
///    rules return [granted] and [needsConfirmation].
enum ToolPermissionResult {
  /// Tool can be executed immediately without user confirmation.
  granted,

  /// Tool needs user confirmation before execution.
  /// The tool call should be left pending (responseRaw = null) until
  /// the user approves or denies it.
  needsConfirmation,

  /// Tool is disabled at conversation level.
  /// Conversation rules override workspace rules, so this takes priority even
  /// if workspace allows the tool.
  disabledInConversation,

  /// Tool is denied by the selected agent's tool permissions.
  disabledByAgent,

  /// Tool is disabled at workspace level.
  disabledInWorkspace,

  /// Tool is not configured in workspace (doesn't exist or isEnabled=false).
  /// A tool must be enabled in workspace before it can be used.
  notConfigured,
}
