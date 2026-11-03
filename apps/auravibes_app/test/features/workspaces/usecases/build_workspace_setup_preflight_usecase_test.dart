import 'package:auravibes_app/features/workspaces/models/workspace_setup_preflight.dart';
import 'package:auravibes_app/features/workspaces/usecases/build_workspace_setup_preflight_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const usecase = BuildWorkspaceSetupPreflightUsecase();

  test('no provider and no model needs setup with both recovery actions', () {
    final result = usecase(
      _snapshot(
        providers: const [],
        selectedModelId: null,
        selectedModel: null,
      ),
    );

    expect(result.outcome, WorkspaceSetupPreflightOutcome.needsSetup);
    _expectStatus(result.check(.providerCredentials).status, .warning);
    _expectRecovery(result.check(.providerCredentials).recovery, .addProvider);
    _expectStatus(result.check(.selectedModel).status, .warning);
    _expectRecovery(result.check(.selectedModel).recovery, .chooseModel);
  });

  test('configured provider with credential but no model needs setup', () {
    final result = usecase(
      _snapshot(
        providers: const [
          WorkspaceSetupProviderSnapshot(
            connectionId: 'provider-a',
            hasCredential: true,
          ),
        ],
        selectedModelId: null,
        selectedModel: null,
      ),
    );

    expect(result.outcome, WorkspaceSetupPreflightOutcome.needsSetup);
    _expectRecovery(result.check(.selectedModel).recovery, .chooseModel);
  });

  test('saved model and credential are ready without optional MCP', () {
    final result = usecase(
      _snapshot(
        providers: const [
          WorkspaceSetupProviderSnapshot(
            connectionId: 'provider-a',
            hasCredential: true,
          ),
        ],
        selectedModelId: 'selection-a',
        selectedModel: _model(),
      ),
    );

    expect(result.outcome, WorkspaceSetupPreflightOutcome.ready);
    _expectStatus(result.check(.mcpConnections).status, .pass);
  });

  test('workspace storage distinguishes unavailable from missing records', () {
    final unknown = usecase(
      _snapshot(
        providers: const [],
        selectedModelId: null,
        selectedModel: null,
        storageAvailable: null,
      ),
    );
    final missing = usecase(
      _snapshot(
        providers: const [],
        selectedModelId: null,
        selectedModel: null,
        storageAvailable: false,
      ),
    );

    _expectStatus(unknown.check(.storage).status, .unknown);
    _expectStatus(missing.check(.storage).status, .fail);
  });

  test('unknown optional MCP status does not block workspace readiness', () {
    final result = usecase(
      _snapshot(
        providers: const [
          WorkspaceSetupProviderSnapshot(
            connectionId: 'provider-a',
            hasCredential: true,
          ),
        ],
        selectedModelId: 'selection-a',
        selectedModel: _model(),
        mcpConnections: null,
        mcpSourceAvailable: false,
      ),
    );

    expect(result.outcome, WorkspaceSetupPreflightOutcome.ready);
    _expectStatus(result.check(.mcpConnections).status, .unknown);
  });

  test('provider absence is a warning when no model requires it', () {
    final result = usecase(
      _snapshot(
        providers: const [
          WorkspaceSetupProviderSnapshot(
            connectionId: 'provider-a',
            hasCredential: false,
          ),
        ],
        selectedModelId: null,
        selectedModel: null,
      ),
    );

    final provider = result.check(.providerCredentials);
    expect(provider.status, WorkspaceSetupPreflightStatus.warning);
    expect(
      provider.messageKey,
      'workspace_setup_preflight.provider_credential_missing_optional',
    );
    expect(result.outcome, WorkspaceSetupPreflightOutcome.needsSetup);
  });

  test(
    'missing saved credential fails when the selected model requires it',
    () {
      final result = usecase(
        _snapshot(
          providers: const [
            WorkspaceSetupProviderSnapshot(
              connectionId: 'provider-a',
              hasCredential: false,
            ),
          ],
          selectedModelId: 'selection-a',
          selectedModel: _model(),
        ),
      );

      expect(result.outcome, WorkspaceSetupPreflightOutcome.blocked);
      _expectStatus(result.check(.providerCredentials).status, .fail);
    },
  );

  test(
    'unknown source and missing selected model metadata stay unverified',
    () {
      final unavailable = usecase(
        _snapshot(
          providers: null,
          selectedModelId: 'selection-a',
          selectedModel: null,
          providerSourceAvailable: false,
          selectedModelSourceAvailable: false,
        ),
      );
      final missingMetadata = usecase(
        _snapshot(
          providers: const [
            WorkspaceSetupProviderSnapshot(
              connectionId: 'provider-a',
              hasCredential: true,
            ),
          ],
          selectedModelId: 'selection-a',
          selectedModel: _model(capabilityMetadataAvailable: false),
        ),
      );

      expect(unavailable.outcome, WorkspaceSetupPreflightOutcome.unverified);
      _expectStatus(unavailable.check(.providerCredentials).status, .unknown);
      expect(
        missingMetadata.outcome,
        WorkspaceSetupPreflightOutcome.unverified,
      );
      _expectStatus(missingMetadata.check(.selectedModel).status, .unknown);
    },
  );

  test('saved model name without capability metadata stays unknown', () {
    final result = usecase(
      _snapshot(
        providers: const [
          WorkspaceSetupProviderSnapshot(
            connectionId: 'provider-a',
            hasCredential: true,
          ),
        ],
        selectedModelId: 'selection-a',
        selectedModel: _model(capabilityMetadataAvailable: false),
      ),
    );

    final model = result.check(.selectedModel);
    _expectStatus(model.status, .unknown);
    expect(model.modelCapabilities, isNull);
  });

  test('stale selected model blocks and offers a recovery action', () {
    final result = usecase(
      _snapshot(
        providers: const [
          WorkspaceSetupProviderSnapshot(
            connectionId: 'provider-a',
            hasCredential: true,
          ),
        ],
        selectedModelId: 'stale-selection',
        selectedModel: null,
      ),
    );

    expect(result.outcome, WorkspaceSetupPreflightOutcome.blocked);
    _expectStatus(result.check(.selectedModel).status, .fail);
    _expectRecovery(result.check(.selectedModel).recovery, .chooseModel);
  });

  test('saved MCP failures warn, and no saved test stays unknown', () {
    final failed = usecase(
      _snapshot(
        providers: const [],
        selectedModelId: null,
        selectedModel: null,
        mcpConnections: const [
          WorkspaceSetupMcpSnapshot(isEnabled: true, lastTestStatus: 'network'),
        ],
      ),
    );
    final notTested = usecase(
      _snapshot(
        providers: const [],
        selectedModelId: null,
        selectedModel: null,
        mcpConnections: const [
          WorkspaceSetupMcpSnapshot(isEnabled: true, lastTestStatus: null),
        ],
      ),
    );

    _expectStatus(failed.check(.mcpConnections).status, .warning);
    _expectStatus(notTested.check(.mcpConnections).status, .unknown);
  });

  test(
    'support summary contains only allowlisted labels and safe metadata',
    () {
      final result = usecase(
        _snapshot(
          providers: const [
            WorkspaceSetupProviderSnapshot(
              connectionId: 'SECRET-provider-name',
              hasCredential: true,
            ),
          ],
          selectedModelId: 'PROMPT-selection-id',
          selectedModel: _model(
            selectionId: 'PROMPT-selection-id',
            modelName: 'TRANSCRIPT-model-name',
            providerConnectionId: 'SECRET-provider-name',
          ),
          mcpConnections: const [
            WorkspaceSetupMcpSnapshot(
              isEnabled: true,
              lastTestStatus: 'success',
            ),
          ],
        ),
      );
      final summary = usecase.formatSupportSummary(
        result: result,
        generatedAt: .utc(2026, 11, 3),
        appVersion: '1.2.3',
        labels: (
          overallLabel: 'Overall',
          outcomes: const {
            WorkspaceSetupPreflightOutcome.ready: 'Ready',
            WorkspaceSetupPreflightOutcome.needsSetup: 'Needs setup',
            WorkspaceSetupPreflightOutcome.blocked: 'Blocked',
            WorkspaceSetupPreflightOutcome.unverified: 'Unverified',
          },
          checks: const {
            WorkspaceSetupPreflightCheckId.storage: 'Storage',
            WorkspaceSetupPreflightCheckId.providerCredentials: 'Provider',
            WorkspaceSetupPreflightCheckId.selectedModel: 'Model',
            WorkspaceSetupPreflightCheckId.mcpConnections: 'MCP',
          },
          statuses: const {
            WorkspaceSetupPreflightStatus.pass: 'Pass',
            WorkspaceSetupPreflightStatus.warning: 'Warning',
            WorkspaceSetupPreflightStatus.fail: 'Fail',
            WorkspaceSetupPreflightStatus.unknown: 'Unknown',
          },
          generatedAt: 'Generated at',
          appVersion: 'App version',
        ),
      );

      expect(summary, contains('Overall: Ready'));
      expect(summary, contains('App version: 1.2.3'));
      expect(summary, isNot(contains('SECRET')));
      expect(summary, isNot(contains('PROMPT')));
      expect(summary, isNot(contains('TRANSCRIPT')));
    },
  );
}

void _expectStatus(
  WorkspaceSetupPreflightStatus actual,
  WorkspaceSetupPreflightStatus expected,
) {
  expect(actual, expected);
}

void _expectRecovery(
  WorkspaceSetupPreflightRecovery? actual,
  WorkspaceSetupPreflightRecovery expected,
) {
  expect(actual, expected);
}

WorkspaceSetupPreflightSnapshot _snapshot({
  required List<WorkspaceSetupProviderSnapshot>? providers,
  required String? selectedModelId,
  required WorkspaceSetupModelSnapshot? selectedModel,
  List<WorkspaceSetupMcpSnapshot>? mcpConnections = const [],
  bool? storageAvailable = true,
  bool providerSourceAvailable = true,
  bool selectedModelSourceAvailable = true,
  bool mcpSourceAvailable = true,
}) => WorkspaceSetupPreflightSnapshot(
  storageAvailable: storageAvailable,
  selectedModelId: selectedModelId,
  selectedModelSourceAvailable: selectedModelSourceAvailable,
  providerSourceAvailable: providerSourceAvailable,
  mcpSourceAvailable: mcpSourceAvailable,
  providers: providers,
  selectedModel: selectedModel,
  mcpConnections: mcpConnections,
);

WorkspaceSetupModelSnapshot _model({
  String selectionId = 'selection-a',
  String? modelName = 'Model',
  bool? capabilityMetadataAvailable,
  String providerConnectionId = 'provider-a',
}) => WorkspaceSetupModelSnapshot(
  selectionId: selectionId,
  providerConnectionId: providerConnectionId,
  modelName: modelName,
  capabilityMetadataAvailable: capabilityMetadataAvailable ?? modelName != null,
  inputModalities: const ['text'],
  outputModalities: const ['text'],
  supportsReasoning: false,
  supportsToolCalls: true,
);
