import 'dart:async';

import 'package:auravibes_app/data/repositories/service_connection_repository.dart';
import 'package:auravibes_app/features/service_connections/providers/service_connection_operations_provider.dart';
import 'package:auravibes_app/features/service_connections/providers/service_connection_repository_provider.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_state_gateway.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

class _MockServiceConnectionRepository extends Mock
    implements ServiceConnectionRepository;

void main() {
  test(
    'keeps local operations alive while async dependencies resolve',
    () async {
      final sessionReady = Completer<WorkspaceSession>();
      final gatewayReady = Completer<CloudWorkspaceStateGateway?>();
      const session = WorkspaceSession(
        LocalWorkspaceRef(localWorkspaceId: 'workspace'),
      );
      final container = ProviderContainer(
        overrides: [
          workspaceSessionForRouteProvider('workspace')
              .overrideWith((_) => sessionReady.future),
          cloudWorkspaceStateGatewayProvider.overrideWith(
            (_, _) => gatewayReady.future,
          ),
          serviceConnectionRepositoryProvider.overrideWithValue(
            _MockServiceConnectionRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final operations = container.read(
        serviceConnectionOperationsProvider('workspace').future,
      );
      await Future<void>.delayed(.zero);
      sessionReady.complete(session);
      await Future<void>.delayed(.zero);
      gatewayReady.complete(null);

      expect(await operations, isA<ServiceConnectionOperations>());
    },
  );

  test('cloud create never constructs local credential repository', () async {
    final gateway = CloudWorkspaceStateGateway.forTesting(
      workspace: const CloudWorkspaceRef(
        localWorkspaceId: 'workspace',
        serverUrl: 'https://example.com',
        accountId: 'account',
        cloudWorkspaceId: 1,
      ),
      readState: (_) => throw StateError('unused'),
      subscribe: (_) => const Stream.empty(),
    );
    final container = ProviderContainer(
      overrides: [
        workspaceSessionProvider(
          const WorkspaceSession(
            CloudWorkspaceRef(
              localWorkspaceId: 'workspace',
              serverUrl: 'https://example.com',
              accountId: 'account',
              cloudWorkspaceId: 1,
            ),
          ),
        ).overrideWithValue(
          const WorkspaceSession(
            CloudWorkspaceRef(
              localWorkspaceId: 'workspace',
              serverUrl: 'https://example.com',
              accountId: 'account',
              cloudWorkspaceId: 1,
            ),
          ),
        ),
        workspaceSessionForRouteProvider('workspace').overrideWithValue(
          const AsyncData(
            WorkspaceSession(
              CloudWorkspaceRef(
                localWorkspaceId: 'workspace',
                serverUrl: 'https://example.com',
                accountId: 'account',
                cloudWorkspaceId: 1,
              ),
            ),
          ),
        ),
        cloudWorkspaceStateGatewayProvider.overrideWith(
          (_, _) async => gateway,
        ),
        serviceConnectionRepositoryProvider.overrideWith(
          (_) => throw StateError('local credential repository touched'),
        ),
      ],
    );
    addTearDown(container.dispose);

    final operations = await container.read(
      serviceConnectionOperationsProvider('workspace').future,
    );
    expect(operations, isA<ServiceConnectionOperations>());
  });

  test('cloud generic edit lookup never constructs local repository', () async {
    final now = DateTime(2026);
    final gateway = CloudWorkspaceStateGateway.forTesting(
      workspace: const CloudWorkspaceRef(
        localWorkspaceId: 'workspace',
        serverUrl: 'https://example.com',
        accountId: 'account',
        cloudWorkspaceId: 1,
      ),
      readState: (_) async => ReadWorkspaceStateResponse(
        pages: [
          WorkspaceResourcePage(
            resourceKind: .serviceConnection,
            resources: [
              WorkspaceResource(
                workspaceId: 1,
                resourceKind: .serviceConnection,
                resourceId: 'connection',
                data:
                    '{"id":"connection","name":"GitHub",'
                    '"serviceId":"github","scope":"workspace",'
                    '"kind":"appSkillCredential","hasSecret":true, '
                    '"secretRevision":2}',
                revision: 3,
                createdAt: now,
                updatedAt: now,
              ),
            ],
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
        workspaceSessionProvider(
          const WorkspaceSession(
            CloudWorkspaceRef(
              localWorkspaceId: 'workspace',
              serverUrl: 'https://example.com',
              accountId: 'account',
              cloudWorkspaceId: 1,
            ),
          ),
        ).overrideWithValue(
          const WorkspaceSession(
            CloudWorkspaceRef(
              localWorkspaceId: 'workspace',
              serverUrl: 'https://example.com',
              accountId: 'account',
              cloudWorkspaceId: 1,
            ),
          ),
        ),
        workspaceSessionForRouteProvider('workspace').overrideWithValue(
          const AsyncData(
            WorkspaceSession(
              CloudWorkspaceRef(
                localWorkspaceId: 'workspace',
                serverUrl: 'https://example.com',
                accountId: 'account',
                cloudWorkspaceId: 1,
              ),
            ),
          ),
        ),
        cloudWorkspaceStateGatewayProvider.overrideWith(
          (_, _) async => gateway,
        ),
        serviceConnectionRepositoryProvider.overrideWith(
          (_) => throw StateError('local credential repository touched'),
        ),
      ],
    );
    addTearDown(container.dispose);

    final operations = await container.read(
      serviceConnectionOperationsProvider('workspace').future,
    );
    final connection = await operations.getGenericForEdit('connection');

    expect(connection?.revision, 3);
    expect(connection?.secretRevision, 2);
  });
}
