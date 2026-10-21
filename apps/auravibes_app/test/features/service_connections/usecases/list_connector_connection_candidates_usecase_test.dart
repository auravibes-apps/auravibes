import 'package:auravibes_app/data/database/drift/tables/service_connections.dart';
import 'package:auravibes_app/data/repositories/service_connection_repository.dart';
import 'package:auravibes_app/features/models/models/cloud_model_connection.dart';
import 'package:auravibes_app/features/service_connections/models/cloud_service_connection.dart';
import 'package:auravibes_app/features/service_connections/providers/service_connection_repository_provider.dart';
import 'package:auravibes_app/features/service_connections/usecases/list_connector_connection_candidates_usecase.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';

class _ServiceConnectionRepository extends Mock
    implements ServiceConnectionRepository;

void main() {
  setUpAll(() {
    registerFallbackValue((
      workspaceId: '',
      connectorId: '',
      compatibleModelProviderIds: <String>[],
    ));
  });

  test(
    'does not fall back to local Connections when cloud loading fails',
    () async {
      const session = WorkspaceSession(
        CloudWorkspaceRef(
          localWorkspaceId: 'cloud-workspace',
          serverUrl: 'https://example.com',
          accountId: 'account',
          cloudWorkspaceId: 1,
        ),
      );
      final container = ProviderContainer(
        overrides: [
          serviceConnectionRepositoryProvider.overrideWith(
            (_) => throw StateError('local repository touched'),
          ),
          workspaceSessionForRouteProvider('cloud-workspace')
              .overrideWith((_) async => session),
          cloudWorkspaceStateGatewayProvider(session)
              .overrideWith((_) async => throw StateError('cloud unavailable')),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container
            .read(listConnectorConnectionCandidatesUsecaseProvider)
            .forConnector(
              workspaceId: 'cloud-workspace',
              connector: _connector,
            ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('cloud unavailable'),
          ),
        ),
      );
    },
  );

  test(
    'filters cloud Connector Connections by identity and readiness',
    () async {
      final usecase = ListConnectorConnectionCandidatesUsecase(
        () => _ServiceConnectionRepository(),
        cloudServiceConnectionsReader: (_) async => const [
          CloudServiceConnection(
            id: 'matching',
            revision: 1,
            name: 'Work account',
            serviceId: 'example',
            hasSecret: true,
            scope: .workspace,
            kind: 'customHttp',
          ),
          CloudServiceConnection(
            id: 'other',
            revision: 1,
            name: 'Other Connector',
            serviceId: 'other',
            hasSecret: true,
            scope: .workspace,
            kind: 'customHttp',
          ),
          CloudServiceConnection(
            id: 'missing-secret',
            revision: 1,
            name: 'Incomplete',
            serviceId: 'example',
            hasSecret: false,
            scope: .workspace,
            kind: 'customHttp',
          ),
          CloudServiceConnection(
            id: 'disabled',
            revision: 1,
            name: 'Disabled',
            serviceId: 'example',
            hasSecret: true,
            scope: .workspace,
            kind: 'customHttp',
            isEnabled: false,
          ),
          CloudServiceConnection(
            id: 'model-kind',
            revision: 1,
            name: 'Wrong kind',
            serviceId: 'example',
            hasSecret: true,
            scope: .workspace,
            kind: 'modelProvider',
          ),
        ],
      );

      final candidates = await usecase.forConnector(
        workspaceId: 'workspace-1',
        connector: _connector,
      );

      expect(candidates.map((candidate) => candidate.id), ['service:matching']);
      expect(candidates.single.name, 'Work account');
    },
  );

  test(
    'includes matching model Connections for dual-capability Connectors',
    () async {
      final repository = _ServiceConnectionRepository();
      when(() => repository.listConnectorConnectionCandidates(any()))
          .thenAnswer((_) async => []);
      final usecase = ListConnectorConnectionCandidatesUsecase(
        () => repository,
        cloudServiceConnectionsReader: (_) async => const [],
        cloudModelConnectionsReader: (_) async => [
          CloudModelConnection(
            id: 'openai-key',
            revision: 1,
            name: 'OpenAI key',
            providerId: 'openai',
            hasSecret: true,
            createdAt: .utc(2026),
            updatedAt: .utc(2026),
          ),
          CloudModelConnection(
            id: 'other-provider',
            revision: 1,
            name: 'Other provider',
            providerId: 'anthropic',
            hasSecret: true,
            createdAt: .utc(2026),
            updatedAt: .utc(2026),
          ),
          CloudModelConnection(
            id: 'missing-secret',
            revision: 1,
            name: 'Incomplete OpenAI key',
            providerId: 'openai',
            hasSecret: false,
            createdAt: .utc(2026),
            updatedAt: .utc(2026),
          ),
        ],
      );

      final candidates = await usecase.forConnector(
        workspaceId: 'workspace-1',
        connector: _connector,
      );

      expect(candidates.map((candidate) => candidate.id), ['model:openai-key']);
    },
  );

  test(
    'loads local candidates by current Connector and provider IDs',
    () async {
      final repository = _ServiceConnectionRepository();
      when(() => repository.listConnectorConnectionCandidates(any()))
          .thenAnswer(
            (_) async => const [
              ServiceConnectionCandidate(
                id: 'connection-1',
                name: 'Work',
                serviceId: 'example',
                kind: ServiceConnectionKindTable.customHttp,
              ),
            ],
          );
      final usecase = ListConnectorConnectionCandidatesUsecase(
        () => repository,
      );

      final candidates = await usecase.forConnector(
        workspaceId: 'workspace-1',
        connector: _connector,
      );

      expect(candidates.map((candidate) => candidate.id), [
        'service:connection-1',
      ]);
      expect(candidates.single.name, 'Work');
      final request =
          verify(
                () =>
                    repository.listConnectorConnectionCandidates(captureAny()),
              ).captured.single
              as ({
                List<String> compatibleModelProviderIds,
                String connectorId,
                String workspaceId,
              });
      expect(request.workspaceId, 'workspace-1');
      expect(request.connectorId, 'example');
      expect(request.compatibleModelProviderIds, ['openai']);
    },
  );
}

const _connector = ConnectorDefinition(
  identifier: 'example',
  title: 'Example',
  description: 'Example Connector.',
  compatibleModelProviderIds: ['openai'],
);
