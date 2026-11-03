class const WorkspaceSetupPreflight({
  required final WorkspaceSetupPreflightOutcome outcome,
  required final List<WorkspaceSetupPreflightCheck> checks,
}) {
  WorkspaceSetupPreflightCheck check(WorkspaceSetupPreflightCheckId id) =>
      checks.firstWhere((check) => check.id == id);
}

enum WorkspaceSetupPreflightStatus { pass, warning, fail, unknown }

enum WorkspaceSetupPreflightOutcome { ready, needsSetup, blocked, unverified }

enum WorkspaceSetupPreflightCheckId {
  storage,
  providerCredentials,
  selectedModel,
  mcpConnections,
}

enum WorkspaceSetupPreflightRecovery {
  addProvider,
  reviewProvider,
  chooseModel,
  openConnections,
}

class const WorkspaceSetupPreflightCheck({
  required final WorkspaceSetupPreflightCheckId id,
  required final WorkspaceSetupPreflightStatus status,
  required final String messageKey,
  final WorkspaceSetupPreflightRecovery? recovery,
  final WorkspaceSetupModelCapabilities? modelCapabilities,
});

class const WorkspaceSetupModelCapabilities({
  required final String modelName,
  required final List<String> inputModalities,
  required final List<String> outputModalities,
  required final bool supportsReasoning,
  required final bool supportsToolCalls,
});

class const WorkspaceSetupProviderSnapshot({
  required final String connectionId,
  required final bool hasCredential,
});

class const WorkspaceSetupModelSnapshot({
  required final String selectionId,
  required final String providerConnectionId,
  required final String? modelName,
  required final bool capabilityMetadataAvailable,
  required final List<String> inputModalities,
  required final List<String> outputModalities,
  required final bool supportsReasoning,
  required final bool supportsToolCalls,
});

class const WorkspaceSetupMcpSnapshot({
  required final bool isEnabled,
  required final String? lastTestStatus,
  final bool connectionNeedsAttention = false,
});

/// Safe, minimal input contract for workspace setup mapping.
///
/// A `null` source means that the source could not be read. An empty list is a
/// successfully read source with no configured records.
class const WorkspaceSetupPreflightSnapshot({
  required final bool? storageAvailable,
  required final String? selectedModelId,
  required final bool selectedModelSourceAvailable,
  required final bool providerSourceAvailable,
  required final bool mcpSourceAvailable,
  required final List<WorkspaceSetupProviderSnapshot>? providers,
  required final WorkspaceSetupModelSnapshot? selectedModel,
  required final List<WorkspaceSetupMcpSnapshot>? mcpConnections,
});

typedef WorkspaceSetupPreflightLabels = ({
  String overallLabel,
  Map<WorkspaceSetupPreflightOutcome, String> outcomes,
  Map<WorkspaceSetupPreflightCheckId, String> checks,
  Map<WorkspaceSetupPreflightStatus, String> statuses,
  String generatedAt,
  String appVersion,
});
