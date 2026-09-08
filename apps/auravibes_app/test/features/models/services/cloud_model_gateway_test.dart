import 'package:auravibes_app/features/models/services/cloud_model_gateway.dart';
import 'package:auravibes_app/features/models/usecases/cloud_model_connection_usecases.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_state_gateway.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('merges provider secret state after create', () async {
    final gateway = CloudModelGateway.forTesting(
      stateGateway: _stateGateway(),
      create: (request) async => ModelConnectionView(
        id: request.connectionId,
        name: request.name,
        providerId: request.providerId,
        hasSecret: false,
        revision: 1,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ),
    );

    final connection = await CloudModelConnectionUsecases(gateway).create(
      id: 'connection',
      name: 'OpenAI',
      providerId: 'openai',
      secret: 'secret',
    );
    expect(connection.hasSecret, isTrue);
  });
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
      putSecret: (_) async => PutWorkspaceSecretResponse(
        configured: true,
        revision: 1,
        sequence: 1,
      ),
    );
