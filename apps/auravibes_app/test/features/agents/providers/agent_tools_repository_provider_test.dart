import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/agent_tools_repository.dart';
import 'package:auravibes_app/data/repositories/agents_repository.dart';
import 'package:auravibes_app/features/agents/agent_adapters/cloud_agent_tools_repository.dart';
import 'package:auravibes_app/features/agents/providers/agent_repository_providers.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_state_gateway.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';

class _AppDatabase extends Mock implements AppDatabase {}

void main() {
  test('cloud provider resolves before local Drift construction', () {
    final container = ProviderContainer(
      overrides: [
        workspaceSessionForRouteProvider('local').overrideWithValue(
          const AsyncData(
            WorkspaceSession(
              CloudWorkspaceRef(
                localWorkspaceId: 'local',
                serverUrl: 'https://example.com',
                accountId: 'account',
                cloudWorkspaceId: 7,
              ),
            ),
          ),
        ),
        cloudWorkspaceStateGatewayProvider.overrideWith(
          (_, _) => throw StateError('gateway should remain lazy'),
        ),
        appDatabaseProvider.overrideWith(
          (_) => throw StateError('Drift touched'),
        ),
      ],
    );
    addTearDown(container.dispose);

    final repository = container.read(agentToolsRepositoryProvider('local'));
    expect(repository, isA<AgentToolsRepositoryContract>());
    expect(repository, isA<CloudAgentToolsRepository>());
  });

  test('cloud agent tools tolerate an empty resource-page response', () async {
    const workspace = CloudWorkspaceRef(
      localWorkspaceId: 'cloud',
      serverUrl: 'https://example.com',
      accountId: 'account',
      cloudWorkspaceId: 7,
    );
    final gateway = CloudWorkspaceStateGateway.forTesting(
      workspace: workspace,
      readState: (_) async => ReadWorkspaceStateResponse(
        pages: [],
        currentSequence: 1,
        events: [],
        requiresSnapshot: false,
      ),
      subscribe: (_) => const Stream.empty(),
    );
    final container = ProviderContainer(
      overrides: [
        workspaceSessionForRouteProvider(
          'cloud',
        ).overrideWithValue(const AsyncData(WorkspaceSession(workspace))),
        cloudWorkspaceStateGatewayProvider.overrideWith(
          (_, _) async => gateway,
        ),
      ],
    );
    addTearDown(container.dispose);

    final repository = container.read(agentToolsRepositoryProvider('cloud'));

    expect(await repository.getAgentTools('agent'), isEmpty);
  });

  test('cloud agent tools reject multiple resource pages', () async {
    const workspace = CloudWorkspaceRef(
      localWorkspaceId: 'cloud',
      serverUrl: 'https://example.com',
      accountId: 'account',
      cloudWorkspaceId: 7,
    );
    final gateway = CloudWorkspaceStateGateway.forTesting(
      workspace: workspace,
      readState: (_) async => ReadWorkspaceStateResponse(
        pages: [
          WorkspaceResourcePage(
            resourceKind: WorkspaceResourceKind.agentAssociation,
            resources: [],
          ),
          WorkspaceResourcePage(
            resourceKind: WorkspaceResourceKind.agentAssociation,
            resources: [],
          ),
        ],
        currentSequence: 1,
        events: [],
        requiresSnapshot: false,
      ),
      subscribe: (_) => const Stream.empty(),
    );
    final container = ProviderContainer(
      overrides: [
        workspaceSessionForRouteProvider(
          'cloud',
        ).overrideWithValue(const AsyncData(WorkspaceSession(workspace))),
        cloudWorkspaceStateGatewayProvider.overrideWith(
          (_, _) async => gateway,
        ),
      ],
    );
    addTearDown(container.dispose);

    final repository = container.read(agentToolsRepositoryProvider('cloud'));

    await expectLater(repository.getAgentTools('agent'), throwsStateError);
  });

  test('agent repository uses the workspace session scope', () {
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(_AppDatabase()),
        workspaceSessionForRouteProvider('local').overrideWithValue(
          const AsyncData(
            WorkspaceSession(LocalWorkspaceRef(localWorkspaceId: 'local')),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(
      container.read(agentRepositoryProvider('local')),
      isA<AgentsRepository>(),
    );
  });
}
