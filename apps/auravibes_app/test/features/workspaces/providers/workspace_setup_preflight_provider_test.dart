import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/entities/model_providers_type.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:auravibes_app/features/chats/notifiers/new_chat_state.dart';
import 'package:auravibes_app/features/models/models/model_connection_store.dart';
import 'package:auravibes_app/features/models/providers/chat_model_connections_provider.dart';
import 'package:auravibes_app/features/models/providers/model_store_providers.dart';
import 'package:auravibes_app/features/service_connections/models/service_connection_list_item.dart';
import 'package:auravibes_app/features/service_connections/providers/service_connections_provider.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_setup_preflight.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_setup_preflight_provider.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  test('provider reads stay scoped to the requested workspace', () async {
    const session = WorkspaceSession(LocalWorkspaceRef(localWorkspaceId: 'A'));
    final otherWorkspaceConnection = ModelConnectionEntity(
      id: 'B-only-connection',
      name: 'DO-NOT-LEAK-provider-name',
      modelId: 'provider-b',
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
      workspaceId: 'B',
      hasKey: true,
      url: 'DO-NOT-LEAK-provider-url',
    );
    final otherWorkspaceMcp = ServiceConnectionListItem(
      id: 'B-only-mcp',
      workspaceId: 'B',
      name: 'DO-NOT-LEAK-mcp-name',
      serviceName: 'DO-NOT-LEAK-mcp-host',
      kind: .mcpServer,
      keySuffix: null,
      mcpServerId: 'B-only-mcp',
      authenticationType: null,
      displayStatus: ServiceConnectionDisplayStatus.connected,
      expiresAt: null,
      lastRefreshedAt: null,
      lastAuthError: null,
      metadataValues: const [],
      canRefresh: false,
      canReconnect: false,
    );
    final container = ProviderContainer(
      overrides: [
        workspaceByIdProvider('A').overrideWith((_) async =>
            WorkspaceEntity(
              id: 'A',
              name: 'Alpha',
              type: .local,
              createdAt: DateTime.utc(2026),
              updatedAt: DateTime.utc(2026),
            )),
        workspaceSessionForRouteProvider('A').overrideWith(
          (_) async => session,
        ),
        chatModelConnectionsProvider('A').overrideWith(
          (_) => Stream.value([otherWorkspaceConnection]),
        ),
        serviceConnectionsProvider(
          'A',
        ).overrideWith((_) => Stream.value([otherWorkspaceMcp])),
      ],
      retry: (_, _) => null,
    );
    addTearDown(container.dispose);

    final result = await container.read(workspaceSetupPreflightProvider('A').future);

    expect(result.outcome, WorkspaceSetupPreflightOutcome.needsSetup);
    expect(
      result
          .check(WorkspaceSetupPreflightCheckId.providerCredentials)
          .messageKey,
      'workspace_setup_preflight.provider_not_configured',
    );
    expect(
      result.check(WorkspaceSetupPreflightCheckId.mcpConnections).messageKey,
      'workspace_setup_preflight.mcp_not_configured',
    );
  });

  test('cloud configuration is read only after explicit refresh', () async {
    const session = WorkspaceSession(
      CloudWorkspaceRef(
        localWorkspaceId: 'A',
        serverUrl: 'https://cloud.example',
        accountId: 'account-a',
        cloudWorkspaceId: 1,
      ),
    );
    var cloudReadCount = 0;
    final container = ProviderContainer(
      overrides: [
        workspaceByIdProvider('A').overrideWith(
          (_) async => WorkspaceEntity(
            id: 'A',
            name: 'Cloud workspace',
            type: WorkspaceType.remote,
            createdAt: DateTime.utc(2026),
            updatedAt: DateTime.utc(2026),
            url: 'https://cloud.example',
            cloudAccountId: 'account-a',
            cloudWorkspaceId: '1',
          ),
        ),
        workspaceSessionForRouteProvider('A').overrideWith(
          (_) async => session,
        ),
        cloudWorkspaceConfigurationProvider(session).overrideWith(
          (_) {
            cloudReadCount++;

            return Stream.value(const []);
          },
        ),
        chatModelConnectionsProvider('A').overrideWith(
          (_) => Stream.value(const []),
        ),
        serviceConnectionsProvider('A').overrideWith(
          (_) => Stream.value(const []),
        ),
      ],
      retry: (_, _) => null,
    );
    addTearDown(container.dispose);

    final initial = await container.read(workspaceSetupPreflightProvider('A').future);

    expect(cloudReadCount, 0);
    expect(
      initial.check(WorkspaceSetupPreflightCheckId.storage).status,
      WorkspaceSetupPreflightStatus.unknown,
    );

    container
        .read(workspaceSetupPreflightRefreshProvider('A').notifier)
        .requestSavedConfigurationRefresh();
    final refreshed = await container.read(
      workspaceSetupPreflightProvider('A').future,
    );

    expect(cloudReadCount, 1);
    expect(
      refreshed.check(WorkspaceSetupPreflightCheckId.storage).status,
      WorkspaceSetupPreflightStatus.pass,
    );
  });

  test('selected models from another workspace are rejected', () async {
    const selectionId = 'B-only-selection';
    final otherWorkspaceModel = WorkspaceModelSelectionWithConnectionEntity(
      workspaceModelSelection: WorkspaceModelSelectionEntity(
        id: selectionId,
        modelId: 'model-b',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
        modelConnectionId: 'B-only-connection',
        modelName: 'DO-NOT-LEAK-model-name',
      ),
      modelConnection: ModelConnectionEntity(
        id: 'B-only-connection',
        name: 'DO-NOT-LEAK-provider-name',
        modelId: 'provider-b',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
        workspaceId: 'B',
        hasKey: true,
        url: 'DO-NOT-LEAK-provider-url',
      ),
      modelsProvider: const ApiModelProviderEntity(
        id: 'provider-b',
        name: 'DO-NOT-LEAK-catalog-provider',
        type: .openai,
      ),
    );
    final container = ProviderContainer(
      overrides: [
        workspaceByIdProvider('A').overrideWith(
          (_) async => WorkspaceEntity(
            id: 'A',
            name: 'Alpha',
            type: .local,
            createdAt: DateTime.utc(2026),
            updatedAt: DateTime.utc(2026),
          ),
        ),
        workspaceSessionForRouteProvider('A').overrideWith(
          (_) async => const WorkspaceSession(
            LocalWorkspaceRef(localWorkspaceId: 'A'),
          ),
        ),
        newChatProvider('A').overrideWithValue(
          const NewChatState(modelId: selectionId),
        ),
        modelSelectionStoreProvider('A').overrideWith(
          (_) async => _SelectionStore(otherWorkspaceModel),
        ),
        chatModelConnectionsProvider('A').overrideWith(
          (_) => Stream.value([otherWorkspaceModel.modelConnection]),
        ),
        serviceConnectionsProvider('A').overrideWith(
          (_) => Stream.value(const []),
        ),
      ],
      retry: (_, _) => null,
    );
    addTearDown(container.dispose);

    final result = await container.read(workspaceSetupPreflightProvider('A').future);

    final model = result.check(WorkspaceSetupPreflightCheckId.selectedModel);
    expect(model.status, WorkspaceSetupPreflightStatus.fail);
    expect(model.modelCapabilities, isNull);
    expect(result.outcome, WorkspaceSetupPreflightOutcome.blocked);
    expect(
      model.messageKey,
      'workspace_setup_preflight.model_missing',
    );
    expect(
      result.check(WorkspaceSetupPreflightCheckId.providerCredentials).messageKey,
      'workspace_setup_preflight.provider_for_model_missing',
    );
  });
}

class _SelectionStore implements ModelSelectionStore {
  const _SelectionStore(this.selection);

  final WorkspaceModelSelectionWithConnectionEntity selection;

  @override
  Future<WorkspaceModelSelectionWithConnectionEntity?> getById(String id) async =>
      id == selection.workspaceModelSelection.id ? selection : null;

  @override
  Future<void> updateToolSamplingPolicy(
    String selectionId,
    ToolSamplingPolicy? policy,
  ) async {}

  @override
  Stream<List<WorkspaceModelSelectionWithConnectionEntity>> watch(
    String workspaceId,
  ) =>
      Stream.value(
        selection.modelConnection.workspaceId == workspaceId
            ? [selection]
            : const [],
      );
}
