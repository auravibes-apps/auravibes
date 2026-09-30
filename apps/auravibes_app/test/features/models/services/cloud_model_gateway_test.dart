import 'package:auravibes_app/features/models/services/cloud_model_gateway.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_state_gateway.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses the feature-local create callback', () async {
    final gateway = CloudModelGateway.forTesting(
      stateGateway: _stateGateway(),
      create: (request) async => ModelConnectionView(
        id: request.connectionId,
        name: request.name,
        providerId: request.providerId,
        hasSecret: false,
        revision: 1,
        createdAt: .utc(2026),
        updatedAt: .utc(2026),
      ),
    );

    final connection = await gateway.createModelConnection(
      connectionId: 'connection',
      name: 'OpenAI',
      providerId: 'openai',
    );

    expect(connection.id, 'connection');
  });

  test('lists recent model selections through the cloud endpoint', () async {
    final gateway = CloudModelGateway.forTesting(
      stateGateway: _stateGateway(),
      listRecentSelections: (request) {
        expect(request.workspaceId, 1);

        return Future.value(['selection']);
      },
    );

    expect(await gateway.listRecentModelSelections(), ['selection']);
  });

  test('records recent model selections through the cloud endpoint', () async {
    String? recorded;
    final gateway = CloudModelGateway.forTesting(
      stateGateway: _stateGateway(),
      recordRecentSelection: (request) {
        expect(request.workspaceId, 1);
        recorded = request.selectionId;

        return Future.value();
      },
    );

    await gateway.recordRecentModelSelection('selection');

    expect(recorded, 'selection');
  });

  test(
    'updates a virtual selection tool sampling policy through cloud',
    () async {
      UpdateWorkspaceModelSelectionPolicyRequest? saved;
      final gateway = CloudModelGateway.forTesting(
        stateGateway: _stateGateway(),
        updateToolSamplingPolicy: (request) {
          saved = request;

          return Future<void>.value();
        },
      );

      await gateway.updateToolSamplingPolicy('selection-id', .require);

      expect(saved?.workspaceId, 1);
      expect(saved?.selectionId, 'selection-id');
      expect(saved?.toolSamplingPolicy, 'require');
    },
  );
}

CloudWorkspaceStateGateway _stateGateway() =>
    CloudWorkspaceStateGateway.forTesting(
      workspace: const CloudWorkspaceRef(
        localWorkspaceId: 'local',
        serverUrl: 'https://example.com',
        accountId: 'account',
        cloudWorkspaceId: 1,
      ),
      readState: (_) => throw UnimplementedError(),
      subscribe: (_) => const Stream.empty(),
    );
