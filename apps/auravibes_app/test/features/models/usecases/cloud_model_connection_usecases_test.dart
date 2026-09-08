import 'package:auravibes_app/features/models/models/cloud_model_connection.dart';
import 'package:auravibes_app/features/models/services/cloud_model_gateway.dart';
import 'package:auravibes_app/features/models/usecases/cloud_model_connection_usecases.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_state_gateway.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'create stores provider secret and merges returned secret state',
    () async {
      PutWorkspaceSecretRequest? secretRequest;
      final gateway = CloudModelGateway.forTesting(
        stateGateway: _stateGateway(
          putSecret: (request) async {
            secretRequest = request;

            return _secretResponse();
          },
        ),
        create: (request) async => _connectionView(
          id: request.connectionId,
          name: request.name,
          providerId: request.providerId,
        ),
      );

      final connection = await CloudModelConnectionUsecases(gateway).create(
        id: 'connection-1',
        name: 'OpenAI',
        providerId: 'openai',
        secret: 'secret',
      );

      expect(connection.hasSecret, isTrue);
      expect(connection.keySuffix, 'cret');
      expect(secretRequest?.secret, 'secret');
      expect(secretRequest?.secretKind, WorkspaceSecretKind.provider);
      expect(secretRequest?.scope, WorkspaceSecretScope.workspace);
      expect(secretRequest?.resourceId, 'connection-1');
    },
  );

  test('update applies same provider secret policy', () async {
    PutWorkspaceSecretRequest? secretRequest;
    final gateway = CloudModelGateway.forTesting(
      stateGateway: _stateGateway(
        putSecret: (request) async {
          secretRequest = request;

          return _secretResponse();
        },
      ),
      update: (request) async => _connectionView(
        id: request.connectionId,
        name: request.name,
        providerId: 'openai',
        revision: request.expectedRevision + 1,
      ),
    );
    final existing = CloudModelConnection(
      id: 'connection-1',
      revision: 3,
      name: 'OpenAI',
      providerId: 'openai',
      hasSecret: false,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );

    final connection = await CloudModelConnectionUsecases(gateway).update(
      connection: existing,
      name: 'OpenAI updated',
      url: null,
      secret: 'new-secret',
    );

    expect(connection.hasSecret, isTrue);
    expect(connection.keySuffix, 'cret');
    expect(secretRequest?.resourceId, existing.id);
  });

  test('update without secret returns gateway response unchanged', () async {
    var putSecretCalls = 0;
    final gateway = CloudModelGateway.forTesting(
      stateGateway: _stateGateway(
        putSecret: (_) async {
          putSecretCalls++;

          return _secretResponse();
        },
      ),
      update: (request) async => _connectionView(
        id: request.connectionId,
        name: request.name,
        providerId: 'openai',
        revision: request.expectedRevision + 1,
        hasSecret: true,
        keySuffix: 'existing',
      ),
    );

    final connection = await CloudModelConnectionUsecases(gateway).update(
      connection: CloudModelConnection(
        id: 'connection-1',
        revision: 3,
        name: 'OpenAI',
        providerId: 'openai',
        hasSecret: true,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
        keySuffix: 'existing',
      ),
      name: 'OpenAI updated',
      url: null,
    );

    expect(connection.keySuffix, 'existing');
    expect(putSecretCalls, 0);
  });
}

CloudWorkspaceStateGateway _stateGateway({WorkspaceSecretPut? putSecret}) {
  return CloudWorkspaceStateGateway.forTesting(
    workspace: const CloudWorkspaceRef(
      localWorkspaceId: 'local',
      serverUrl: 'https://example.com',
      accountId: 'account',
      cloudWorkspaceId: 1,
    ),
    readState: (_) => throw UnimplementedError(),
    subscribe: (_) => const Stream.empty(),
    putSecret: putSecret,
  );
}

ModelConnectionView _connectionView({
  required String id,
  required String name,
  required String providerId,
  int revision = 1,
  bool hasSecret = false,
  String? keySuffix,
}) {
  return ModelConnectionView(
    id: id,
    name: name,
    providerId: providerId,
    hasSecret: hasSecret,
    keySuffix: keySuffix,
    revision: revision,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );
}

PutWorkspaceSecretResponse _secretResponse() {
  return PutWorkspaceSecretResponse(
    configured: true,
    displaySuffix: 'cret',
    revision: 1,
    sequence: 1,
  );
}
