import 'package:auravibes_app/features/workspaces/models/workspace_setup_preflight.dart';
import 'package:collection/collection.dart';

const _optionalCredentialMissingMessageKey =
    'workspace_setup_preflight.provider_credential_missing_optional';

class const BuildWorkspaceSetupPreflightUsecase() {
  WorkspaceSetupPreflight call(WorkspaceSetupPreflightSnapshot snapshot) {
    final checks = [
      _storageCheck(snapshot.storageAvailable),
      _providerCheck(snapshot),
      _modelCheck(snapshot),
      _mcpCheck(snapshot),
    ];

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
    final outcome = labels.outcomes[result.outcome] ?? result.outcome.name;
    final lines = <String>[
      '${labels.overallLabel}: $outcome',
      '${labels.generatedAt}: ${generatedAt.toUtc().toIso8601String()}',
      '${labels.appVersion}: $appVersion',
      for (final check in result.checks) _checkSummary(check, labels),
    ];

    return lines.join('\n');
  }
}

WorkspaceSetupPreflightCheck _storageCheck(bool? available) =>
    switch (available) {
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
  if (snapshot.selectedModelId == null) return _modelNotSelected();
  if (!snapshot.selectedModelSourceAvailable) return _modelUnverified();

  final model = snapshot.selectedModel;
  if (model == null || model.selectionId != snapshot.selectedModelId) {
    return _modelMissing();
  }
  final modelName = _compatibleModelName(model);
  if (modelName == null) return _modelMetadataUnavailable();

  return _modelReady(model, modelName);
}

String? _compatibleModelName(WorkspaceSetupModelSnapshot model) {
  final modelName = model.modelName;
  if (!model.capabilityMetadataAvailable || modelName == null) return null;
  if (modelName.trim().isEmpty) return null;

  return modelName;
}

WorkspaceSetupPreflightCheck _modelNotSelected() =>
    const WorkspaceSetupPreflightCheck(
      id: .selectedModel,
      status: .warning,
      messageKey: 'workspace_setup_preflight.model_not_selected',
      recovery: .chooseModel,
    );

WorkspaceSetupPreflightCheck _modelUnverified() =>
    const WorkspaceSetupPreflightCheck(
      id: .selectedModel,
      status: .unknown,
      messageKey: 'workspace_setup_preflight.model_unverified',
      recovery: .chooseModel,
    );

WorkspaceSetupPreflightCheck _modelMissing() =>
    const WorkspaceSetupPreflightCheck(
      id: .selectedModel,
      status: .fail,
      messageKey: 'workspace_setup_preflight.model_missing',
      recovery: .chooseModel,
    );

WorkspaceSetupPreflightCheck _modelMetadataUnavailable() =>
    const WorkspaceSetupPreflightCheck(
      id: .selectedModel,
      status: .unknown,
      messageKey: 'workspace_setup_preflight.model_metadata_unavailable',
      recovery: .chooseModel,
    );

WorkspaceSetupPreflightCheck _modelReady(
  WorkspaceSetupModelSnapshot model,
  String modelName,
) => WorkspaceSetupPreflightCheck(
  id: .selectedModel,
  status: .pass,
  messageKey: 'workspace_setup_preflight.model_metadata_available',
  modelCapabilities: .new(
    modelName: modelName,
    inputModalities: model.inputModalities,
    outputModalities: model.outputModalities,
    supportsReasoning: model.supportsReasoning,
    supportsToolCalls: model.supportsToolCalls,
  ),
);

WorkspaceSetupPreflightCheck _providerCheck(
  WorkspaceSetupPreflightSnapshot snapshot,
) {
  final providers = snapshot.providers;
  if (!snapshot.providerSourceAvailable || providers == null) {
    return _providerUnverified();
  }

  return _configuredProviderCheck(snapshot, providers);
}

WorkspaceSetupPreflightCheck _configuredProviderCheck(
  WorkspaceSetupPreflightSnapshot snapshot,
  List<WorkspaceSetupProviderSnapshot> providers,
) {
  if (snapshot.selectedModelId == null) {
    return _optionalProviderCheck(providers);
  }
  if (providers.isEmpty) return _providerForModelMissing();
  if (!snapshot.selectedModelSourceAvailable) return _providerUnverified();

  return _selectedModelProviderCheck(snapshot, providers);
}

WorkspaceSetupPreflightCheck _selectedModelProviderCheck(
  WorkspaceSetupPreflightSnapshot snapshot,
  List<WorkspaceSetupProviderSnapshot> providers,
) {
  final model = snapshot.selectedModel;
  if (model == null || model.selectionId != snapshot.selectedModelId) {
    return _providerForModelMissing();
  }

  return _selectedProviderCheck(providers, model);
}

WorkspaceSetupPreflightCheck _optionalProviderCheck(
  List<WorkspaceSetupProviderSnapshot> providers,
) {
  if (providers.isEmpty) return _providerNotConfigured();
  if (providers.any((provider) => provider.hasCredential)) {
    return _providerSaved();
  }

  return _optionalCredentialMissing();
}

WorkspaceSetupPreflightCheck _selectedProviderCheck(
  List<WorkspaceSetupProviderSnapshot> providers,
  WorkspaceSetupModelSnapshot model,
) {
  final provider = providers.firstWhereOrNull(
    (item) => item.connectionId == model.providerConnectionId,
  );
  if (provider == null) return _providerForModelMissing();
  if (!provider.hasCredential) return _requiredCredentialMissing();

  return _providerSaved();
}

WorkspaceSetupPreflightCheck _providerUnverified() =>
    const WorkspaceSetupPreflightCheck(
      id: .providerCredentials,
      status: .unknown,
      messageKey: 'workspace_setup_preflight.provider_unverified',
      recovery: .reviewProvider,
    );

WorkspaceSetupPreflightCheck _providerNotConfigured() =>
    const WorkspaceSetupPreflightCheck(
      id: .providerCredentials,
      status: .warning,
      messageKey: 'workspace_setup_preflight.provider_not_configured',
      recovery: .addProvider,
    );

WorkspaceSetupPreflightCheck _providerForModelMissing() =>
    const WorkspaceSetupPreflightCheck(
      id: .providerCredentials,
      status: .fail,
      messageKey: 'workspace_setup_preflight.provider_for_model_missing',
      recovery: .reviewProvider,
    );

WorkspaceSetupPreflightCheck _optionalCredentialMissing() =>
    const WorkspaceSetupPreflightCheck(
      id: .providerCredentials,
      status: .warning,
      messageKey: _optionalCredentialMissingMessageKey,
      recovery: .reviewProvider,
    );

WorkspaceSetupPreflightCheck _requiredCredentialMissing() =>
    const WorkspaceSetupPreflightCheck(
      id: .providerCredentials,
      status: .fail,
      messageKey:
          'workspace_setup_preflight.provider_credential_missing_required',
      recovery: .reviewProvider,
    );

WorkspaceSetupPreflightCheck _providerSaved() =>
    const WorkspaceSetupPreflightCheck(
      id: .providerCredentials,
      status: .pass,
      messageKey: 'workspace_setup_preflight.provider_saved',
    );

WorkspaceSetupPreflightCheck _mcpCheck(
  WorkspaceSetupPreflightSnapshot snapshot,
) {
  final connections = snapshot.mcpConnections;
  if (!snapshot.mcpSourceAvailable || connections == null) {
    return _mcpUnverified();
  }

  return _configuredMcpCheck(connections);
}

WorkspaceSetupPreflightCheck _configuredMcpCheck(
  List<WorkspaceSetupMcpSnapshot> connections,
) {
  if (connections.isEmpty) return _mcpNotConfigured();
  if (_hasDisabledConnection(connections)) return _mcpDisabled();
  if (_hasConnectionNeedingAttention(connections)) return _mcpNeedsAttention();
  if (_hasUntestedConnection(connections)) return _mcpNotTested();
  if (_hasFailedConnectionTest(connections)) return _mcpNeedsAttention();

  return _mcpTestPassed();
}

bool _hasDisabledConnection(List<WorkspaceSetupMcpSnapshot> connections) =>
    connections.any((connection) => !connection.isEnabled);

bool _hasConnectionNeedingAttention(
  List<WorkspaceSetupMcpSnapshot> connections,
) => connections.any((connection) => connection.connectionNeedsAttention);

bool _hasUntestedConnection(List<WorkspaceSetupMcpSnapshot> connections) =>
    connections.any((connection) => connection.lastTestStatus == null);

bool _hasFailedConnectionTest(List<WorkspaceSetupMcpSnapshot> connections) =>
    connections.any((connection) => connection.lastTestStatus != 'success');

WorkspaceSetupPreflightCheck _mcpUnverified() =>
    const WorkspaceSetupPreflightCheck(
      id: .mcpConnections,
      status: .unknown,
      messageKey: 'workspace_setup_preflight.mcp_unverified',
      recovery: .openConnections,
    );

WorkspaceSetupPreflightCheck _mcpNotConfigured() =>
    const WorkspaceSetupPreflightCheck(
      id: .mcpConnections,
      status: .pass,
      messageKey: 'workspace_setup_preflight.mcp_not_configured',
    );

WorkspaceSetupPreflightCheck _mcpDisabled() =>
    const WorkspaceSetupPreflightCheck(
      id: .mcpConnections,
      status: .warning,
      messageKey: 'workspace_setup_preflight.mcp_disabled',
      recovery: .openConnections,
    );

WorkspaceSetupPreflightCheck _mcpNeedsAttention() =>
    const WorkspaceSetupPreflightCheck(
      id: .mcpConnections,
      status: .warning,
      messageKey: 'workspace_setup_preflight.mcp_attention',
      recovery: .openConnections,
    );

WorkspaceSetupPreflightCheck _mcpNotTested() =>
    const WorkspaceSetupPreflightCheck(
      id: .mcpConnections,
      status: .unknown,
      messageKey: 'workspace_setup_preflight.mcp_not_tested',
      recovery: .openConnections,
    );

WorkspaceSetupPreflightCheck _mcpTestPassed() =>
    const WorkspaceSetupPreflightCheck(
      id: .mcpConnections,
      status: .pass,
      messageKey: 'workspace_setup_preflight.mcp_last_test_passed',
    );

WorkspaceSetupPreflightOutcome _outcome(
  WorkspaceSetupPreflightSnapshot snapshot,
  List<WorkspaceSetupPreflightCheck> checks,
) {
  if (checks.any((check) => check.status == .fail)) return .blocked;
  if (_needsSetup(snapshot)) return .needsSetup;
  if (_hasUnverifiedRequiredCheck(checks)) return .unverified;
  if (_hasNonPassingRequiredCheck(checks)) return .unverified;

  return .ready;
}

bool _needsSetup(WorkspaceSetupPreflightSnapshot snapshot) =>
    snapshot.selectedModelId == null ||
    (snapshot.providerSourceAvailable && snapshot.providers?.isEmpty == true);

bool _hasUnverifiedRequiredCheck(List<WorkspaceSetupPreflightCheck> checks) =>
    _requiredChecks(checks).any((check) => check.status == .unknown);

bool _hasNonPassingRequiredCheck(List<WorkspaceSetupPreflightCheck> checks) =>
    _requiredChecks(checks).any((check) => check.status != .pass);

Iterable<WorkspaceSetupPreflightCheck> _requiredChecks(
  List<WorkspaceSetupPreflightCheck> checks,
) => checks.where((check) => check.id != .mcpConnections);

String _checkSummary(
  WorkspaceSetupPreflightCheck check,
  WorkspaceSetupPreflightLabels labels,
) {
  final checkLabel = labels.checks[check.id] ?? check.id.name;
  final statusLabel = labels.statuses[check.status] ?? check.status.name;

  return '$checkLabel: $statusLabel';
}
