import 'package:auravibes_app/features/workspaces/models/workspace_setup_preflight.dart';
import 'package:collection/collection.dart';

class const BuildWorkspaceSetupPreflightUsecase() {
  WorkspaceSetupPreflight call(WorkspaceSetupPreflightSnapshot snapshot) {
    final storage = _storageCheck(snapshot.storageAvailable);
    final model = _modelCheck(snapshot);
    final provider = _providerCheck(snapshot);
    final mcp = _mcpCheck(snapshot);
    final checks = [storage, provider, model, mcp];

    return WorkspaceSetupPreflight(
      outcome: _outcome(snapshot, checks),
      checks: checks,
    );
  }

  String formatSupportSummary({
    required WorkspaceSetupPreflight result,
    required DateTime generatedAt,
    required String appVersion,
    required WorkspaceSetupPreflightLabels labels,
  }) {
    final lines = <String>[
      '${labels.overallLabel}: ${labels.outcomes[result.outcome] ?? result.outcome.name}',
      '${labels.generatedAt}: ${generatedAt.toUtc().toIso8601String()}',
      '${labels.appVersion}: $appVersion',
      for (final check in result.checks)
        '${labels.checks[check.id] ?? check.id.name}: '
            '${labels.statuses[check.status] ?? check.status.name}',
    ];

    return lines.join('\n');
  }

  WorkspaceSetupPreflightCheck _storageCheck(bool? available) => switch (
    available
  ) {
    true => const WorkspaceSetupPreflightCheck(
      id: .storage,
      status: .pass,
      messageKey: 'workspace_setup_preflight.storage_available',
    ),
    false => const WorkspaceSetupPreflightCheck(
      id: .storage,
      status: .fail,
      messageKey: 'workspace_setup_preflight.storage_unavailable',
    ),
    null => const WorkspaceSetupPreflightCheck(
      id: .storage,
      status: .unknown,
      messageKey: 'workspace_setup_preflight.storage_unverified',
    ),
  };

  WorkspaceSetupPreflightCheck _modelCheck(
    WorkspaceSetupPreflightSnapshot snapshot,
  ) {
    if (snapshot.selectedModelId == null) {
      return const WorkspaceSetupPreflightCheck(
        id: .selectedModel,
        status: .warning,
        messageKey: 'workspace_setup_preflight.model_not_selected',
        recovery: .chooseModel,
      );
    }
    if (!snapshot.selectedModelSourceAvailable) {
      return const WorkspaceSetupPreflightCheck(
        id: .selectedModel,
        status: .unknown,
        messageKey: 'workspace_setup_preflight.model_unverified',
        recovery: .chooseModel,
      );
    }
    final model = snapshot.selectedModel;
    if (model == null || model.selectionId != snapshot.selectedModelId) {
      return const WorkspaceSetupPreflightCheck(
        id: .selectedModel,
        status: .fail,
        messageKey: 'workspace_setup_preflight.model_missing',
        recovery: .chooseModel,
      );
    }
    final modelName = model.modelName;
    if (!model.capabilityMetadataAvailable ||
        modelName == null ||
        modelName.trim().isEmpty) {
      return const WorkspaceSetupPreflightCheck(
        id: .selectedModel,
        status: .unknown,
        messageKey: 'workspace_setup_preflight.model_metadata_unavailable',
        recovery: .chooseModel,
      );
    }

    return WorkspaceSetupPreflightCheck(
      id: .selectedModel,
      status: .pass,
      messageKey: 'workspace_setup_preflight.model_metadata_available',
      modelCapabilities: WorkspaceSetupModelCapabilities(
        modelName: modelName,
        inputModalities: model.inputModalities,
        outputModalities: model.outputModalities,
        supportsReasoning: model.supportsReasoning,
        supportsToolCalls: model.supportsToolCalls,
      ),
    );
  }

  WorkspaceSetupPreflightCheck _providerCheck(
    WorkspaceSetupPreflightSnapshot snapshot,
  ) {
    final providers = snapshot.providers;
    if (!snapshot.providerSourceAvailable || providers == null) {
      return const WorkspaceSetupPreflightCheck(
        id: .providerCredentials,
        status: .unknown,
        messageKey: 'workspace_setup_preflight.provider_unverified',
        recovery: .reviewProvider,
      );
    }
    if (providers.isEmpty && snapshot.selectedModelId == null) {
      return const WorkspaceSetupPreflightCheck(
        id: .providerCredentials,
        status: .warning,
        messageKey: 'workspace_setup_preflight.provider_not_configured',
        recovery: .addProvider,
      );
    }
    if (providers.isEmpty) {
      return const WorkspaceSetupPreflightCheck(
        id: .providerCredentials,
        status: .fail,
        messageKey: 'workspace_setup_preflight.provider_for_model_missing',
        recovery: .reviewProvider,
      );
    }
    if (snapshot.selectedModelId == null) {
      return providers.any((provider) => provider.hasCredential)
          ? const WorkspaceSetupPreflightCheck(
              id: .providerCredentials,
              status: .pass,
              messageKey: 'workspace_setup_preflight.provider_saved',
            )
          : const WorkspaceSetupPreflightCheck(
              id: .providerCredentials,
              status: .warning,
              messageKey: 'workspace_setup_preflight.provider_credential_missing_optional',
              recovery: .reviewProvider,
            );
    }
    if (!snapshot.selectedModelSourceAvailable) {
      return const WorkspaceSetupPreflightCheck(
        id: .providerCredentials,
        status: .unknown,
        messageKey: 'workspace_setup_preflight.provider_unverified',
        recovery: .reviewProvider,
      );
    }
    final model = snapshot.selectedModel;
    if (model == null || model.selectionId != snapshot.selectedModelId) {
      return const WorkspaceSetupPreflightCheck(
        id: .providerCredentials,
        status: .fail,
        messageKey: 'workspace_setup_preflight.provider_for_model_missing',
        recovery: .reviewProvider,
      );
    }
    final selectedProvider = providers
        .where((provider) => provider.connectionId == model.providerConnectionId)
        .firstOrNull;
    if (selectedProvider == null) {
      return const WorkspaceSetupPreflightCheck(
        id: .providerCredentials,
        status: .fail,
        messageKey: 'workspace_setup_preflight.provider_for_model_missing',
        recovery: .reviewProvider,
      );
    }
    if (!selectedProvider.hasCredential) {
      return const WorkspaceSetupPreflightCheck(
        id: .providerCredentials,
        status: .fail,
        messageKey: 'workspace_setup_preflight.provider_credential_missing_required',
        recovery: .reviewProvider,
      );
    }

    return const WorkspaceSetupPreflightCheck(
      id: .providerCredentials,
      status: .pass,
      messageKey: 'workspace_setup_preflight.provider_saved',
    );
  }

  WorkspaceSetupPreflightCheck _mcpCheck(
    WorkspaceSetupPreflightSnapshot snapshot,
  ) {
    final connections = snapshot.mcpConnections;
    if (!snapshot.mcpSourceAvailable || connections == null) {
      return const WorkspaceSetupPreflightCheck(
        id: .mcpConnections,
        status: .unknown,
        messageKey: 'workspace_setup_preflight.mcp_unverified',
        recovery: .openConnections,
      );
    }
    if (connections.isEmpty) {
      return const WorkspaceSetupPreflightCheck(
        id: .mcpConnections,
        status: .pass,
        messageKey: 'workspace_setup_preflight.mcp_not_configured',
      );
    }
    if (connections.any((connection) => !connection.isEnabled)) {
      return const WorkspaceSetupPreflightCheck(
        id: .mcpConnections,
        status: .warning,
        messageKey: 'workspace_setup_preflight.mcp_disabled',
        recovery: .openConnections,
      );
    }
    if (connections.any((connection) => connection.connectionNeedsAttention)) {
      return const WorkspaceSetupPreflightCheck(
        id: .mcpConnections,
        status: .warning,
        messageKey: 'workspace_setup_preflight.mcp_attention',
        recovery: .openConnections,
      );
    }
    if (connections.any((connection) => connection.lastTestStatus == null)) {
      return const WorkspaceSetupPreflightCheck(
        id: .mcpConnections,
        status: .unknown,
        messageKey: 'workspace_setup_preflight.mcp_not_tested',
        recovery: .openConnections,
      );
    }
    if (connections.any((connection) => connection.lastTestStatus != 'success')) {
      return const WorkspaceSetupPreflightCheck(
        id: .mcpConnections,
        status: .warning,
        messageKey: 'workspace_setup_preflight.mcp_attention',
        recovery: .openConnections,
      );
    }

    return const WorkspaceSetupPreflightCheck(
      id: .mcpConnections,
      status: .pass,
      messageKey: 'workspace_setup_preflight.mcp_last_test_passed',
    );
  }

  WorkspaceSetupPreflightOutcome _outcome(
    WorkspaceSetupPreflightSnapshot snapshot,
    List<WorkspaceSetupPreflightCheck> checks,
  ) {
    if (checks.any((check) => check.status == .fail)) {
      return .blocked;
    }
    if (snapshot.selectedModelId == null ||
        (snapshot.providerSourceAvailable && snapshot.providers?.isEmpty == true)) {
      return .needsSetup;
    }
    final requiredChecks = checks
        .where((check) => check.id != .mcpConnections)
        .toList();
    if (requiredChecks.any((check) => check.status == .unknown)) {
      return .unverified;
    }
    if (requiredChecks.any((check) => check.status != .pass)) {
      return .unverified;
    }

    return .ready;
  }

}
