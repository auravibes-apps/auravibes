import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/agent_tools_repository.dart';
import 'package:auravibes_app/data/repositories/agents_repository.dart';
import 'package:auravibes_app/features/agents/agent_adapters/cloud_agent_tools_repository.dart';
import 'package:auravibes_app/features/agents/providers/agent_repository_providers.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';

class _AppDatabase extends Mock implements AppDatabase {}

void main() {
  test('cloud provider resolves before local Drift construction', () {
    final container = ProviderContainer(
      overrides: [
        workspaceSessionProvider.overrideWithValue(
          const WorkspaceSession(
            CloudWorkspaceRef(
              localWorkspaceId: 'local',
              serverUrl: 'https://example.com',
              accountId: 'account',
              cloudWorkspaceId: 7,
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

    final repository = container.read(
      agentToolsRepositoryProvider('local'),
    );
    expect(repository, isA<AgentToolsRepositoryContract>());
    expect(repository, isA<CloudAgentToolsRepository>());
  });

  test('agent repository uses the workspace session scope', () {
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(_AppDatabase()),
        workspaceSessionProvider.overrideWithValue(
          const WorkspaceSession(
            LocalWorkspaceRef(localWorkspaceId: 'local'),
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
