import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:auravibes_app/features/models/providers/chat_model_connections_provider.dart';
import 'package:auravibes_app/features/service_connections/models/service_connection_list_item.dart';
import 'package:auravibes_app/features/service_connections/providers/service_connections_provider.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_setup_preflight.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_setup_preflight_provider.dart';
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
          (_, _) => Stream.value([otherWorkspaceConnection]),
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
          (_, _) => Stream.value(const []),
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
}
