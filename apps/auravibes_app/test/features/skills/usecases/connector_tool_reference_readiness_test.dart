import 'package:auravibes_app/data/repositories/service_connection_repository.dart';
import 'package:auravibes_app/features/service_connections/usecases/list_connector_connection_candidates_usecase.dart';
import 'package:auravibes_app/features/skills/models/skill_access_summary.dart';
import 'package:auravibes_app/features/skills/usecases/connector_tool_reference_readiness.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _ServiceConnectionRepository extends Mock
    implements ServiceConnectionRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue((
      workspaceId: '',
      connectorId: '',
      compatibleModelProviderIds: <String>[],
    ));
  });

  test(
    'checks shared credential pools once and preserves input order',
    () async {
      final fixture = _candidateFixture(availableConnectorIds: {'brave'});
      final toolIds = [
        _toolId('brave', 'web_search'),
        _toolId('brave', 'news_search'),
        _toolId('brave', 'web_search'),
        _toolId('kagi', 'search'),
      ];
      final braveCredentials = _tool(
        'brave',
        'web_search',
      ).urlTemplate!.credentialDefinitions;
      final kagiCredentials = _tool(
        'kagi',
        'search',
      ).urlTemplate!.credentialDefinitions;
      expect(braveCredentials.keys, ['apiKey']);
      expect(kagiCredentials.keys, ['apiKey']);

      final statuses =
          await ConnectorToolReferenceReadiness.readinessForTools(
            connectorToolIds: toolIds,
            workspaceId: 'workspace-1',
            credentialCandidates: fixture.usecase,
          );

      expect(statuses, [
        SkillToolAccessStatus.available,
        SkillToolAccessStatus.available,
        SkillToolAccessStatus.available,
        SkillToolAccessStatus.missing,
      ]);
      expect(
        fixture.requestedConnectorIds,
        unorderedEquals(['brave', 'kagi']),
      );
    },
  );

  test(
    'isolates a failed connector read from other tool results',
    () async {
      final fixture = _candidateFixture(
        availableConnectorIds: {'kagi'},
        failingConnectorIds: {'brave'},
      );

      final statuses = await ConnectorToolReferenceReadiness.readinessForTools(
        connectorToolIds: [
          _toolId('brave', 'web_search'),
          _toolId('kagi', 'search'),
        ],
        workspaceId: 'workspace-1',
        credentialCandidates: fixture.usecase,
      );

      expect(statuses, [
        SkillToolAccessStatus.unknown,
        SkillToolAccessStatus.available,
      ]);
      expect(
        fixture.requestedConnectorIds,
        unorderedEquals(['brave', 'kagi']),
      );
    },
  );

  test(
    'keeps unknown tool IDs missing without reading a credential pool',
    () async {
      final fixture = _candidateFixture(availableConnectorIds: const {});

      final statuses =
          await ConnectorToolReferenceReadiness.readinessForTools(
            connectorToolIds: const ['connector/unknown/tool'],
            workspaceId: 'workspace-1',
            credentialCandidates: fixture.usecase,
          );

      expect(statuses, [SkillToolAccessStatus.missing]);
      expect(fixture.requestedConnectorIds, isEmpty);
    },
  );

  test(
    'areReady deduplicates shared pools and preserves error behavior',
    () async {
      final readyFixture = _candidateFixture(
        availableConnectorIds: {'brave'},
      );

      expect(
        await ConnectorToolReferenceReadiness.areReady(
          connectorToolIds: [
            _toolId('brave', 'web_search'),
            _toolId('brave', 'news_search'),
          ],
          workspaceId: 'workspace-1',
          credentialCandidates: readyFixture.usecase,
        ),
        isTrue,
      );
      expect(readyFixture.requestedConnectorIds, ['brave']);

      final failingFixture = _candidateFixture(
        availableConnectorIds: const {},
        failingConnectorIds: {'brave'},
      );
      await expectLater(
        ConnectorToolReferenceReadiness.areReady(
          connectorToolIds: [_toolId('brave', 'web_search')],
          workspaceId: 'workspace-1',
          credentialCandidates: failingFixture.usecase,
        ),
        throwsA(isA<StateError>()),
      );
    },
  );
}

typedef _CandidateFixture = ({
  ListConnectorConnectionCandidatesUsecase usecase,
  List<String> requestedConnectorIds,
});

_CandidateFixture _candidateFixture({
  required Set<String> availableConnectorIds,
  Set<String> failingConnectorIds = const {},
}) {
  final repository = _ServiceConnectionRepository();
  final requestedConnectorIds = <String>[];
  when(
    () => repository.listConnectorConnectionCandidates(any()),
  ).thenAnswer((invocation) async {
    final request = invocation.positionalArguments.single
        as ({
          List<String> compatibleModelProviderIds,
          String connectorId,
          String workspaceId,
        });
    requestedConnectorIds.add(request.connectorId);
    if (failingConnectorIds.contains(request.connectorId)) {
      throw StateError('Synthetic ${request.connectorId} lookup failure.');
    }
    if (availableConnectorIds.contains(request.connectorId)) {
      return [
        ServiceConnectionCandidate(
          id: 'connection-${request.connectorId}',
          name: 'Synthetic connection',
          serviceId: request.connectorId,
          kind: .customHttp,
        ),
      ];
    }

    return [];
  });

  return (
    usecase: ListConnectorConnectionCandidatesUsecase(() => repository),
    requestedConnectorIds: requestedConnectorIds,
  );
}

String _toolId(String connectorId, String slug) {
  final tool = _tool(connectorId, slug);
  final connector = connectorDefinitions.singleWhere(
    (candidate) => candidate.identifier == connectorId,
  );

  return connectorToolId(connector, tool);
}

ConnectorToolDefinition _tool(String connectorId, String slug) {
  final connector = connectorDefinitions.singleWhere(
    (candidate) => candidate.identifier == connectorId,
  );
  return connector.tools.singleWhere(
    (candidate) => candidate.slug == slug,
  );
}
