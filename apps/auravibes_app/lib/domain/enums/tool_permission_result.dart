/// Result of checking tool permission based on conversation and workspace
/// rules.
///
/// Permission logic:
/// 1. If tool is NOT in workspace (not enabled/configured) → [notConfigured]
/// 2. If tool IS in workspace:
///    a. Check conversation rules first (takes priority):
///       - Conversation says DISABLED → [disabledInConversation]
///       - Conversation says ASK → [needsConfirmation]
///       - Conversation says GRANTED → [granted]
///    b. If no conversation rule, check workspace permissions:
///       - Workspace says GRANTED → [granted]
///       - Workspace says ASK → [needsConfirmation]
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

  /// Tool is disabled at workspace level.
  disabledInWorkspace,

  /// Tool is not configured in workspace (doesn't exist or isEnabled=false).
  /// A tool must be enabled in workspace before it can be used.
  notConfigured,
}

/// Extension methods for [ToolPermissionResult].
extension ToolPermissionResultX on ToolPermissionResult {
  /// Whether this result means the tool should be skipped entirely.
  ///
  /// Returns `true` for disabled/not configured states.
  /// Returns `false` for [granted] and [needsConfirmation].
  bool get shouldSkip => switch (this) {
    ToolPermissionResult.granted => false,
    ToolPermissionResult.needsConfirmation => false,
    ToolPermissionResult.disabledInConversation => true,
    ToolPermissionResult.disabledInWorkspace => true,
    ToolPermissionResult.notConfigured => true,
  };

  /// Whether this result means the tool can be executed.
  ///
  /// Only [granted] returns `true`.
  bool get canExecute => this == ToolPermissionResult.granted;

  /// Whether this result requires user confirmation.
  bool get requiresConfirmation =>
      this == ToolPermissionResult.needsConfirmation;

  /// Get skip reason string for storing in responseRaw field.
  ///
  /// Returns `null` for [granted] and [needsConfirmation] since those
  /// are not skip states.
  String? get skipReason => switch (this) {
    ToolPermissionResult.granted => null,
    ToolPermissionResult.needsConfirmation => null,
    ToolPermissionResult.disabledInConversation => 'disabled_in_conversation',
    ToolPermissionResult.disabledInWorkspace => 'disabled_in_workspace',
    ToolPermissionResult.notConfigured => 'not_configured',
  };
}
