import 'package:auravibes_app/features/models/models/cloud_model_resources.dart';
import 'package:auravibes_app/features/models/services/cloud_model_gateway.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';

typedef _CreateModelConnectionRequest = ({
  String id,
  String name,
  String providerId,
  String? secret,
  String? url,
});

typedef _UpdateModelConnectionRequest = ({
  CloudModelConnection connection,
  String name,
  String? secret,
  String? url,
});

typedef _SecretUpdate = ({
  ModelConnectionView connection,
  String resourceId,
  String? secret,
});

class const CloudModelConnectionUsecases(final CloudModelGateway _gateway) {}

extension CloudModelConnectionUsecasesActions on CloudModelConnectionUsecases {
  Stream<List<CloudModelConnection>> watchConnections() => _gateway
      .watchModelConnections()
      .map((items) => items.map(CloudModelConnection.fromView).toList());

  Stream<List<WorkspaceModelSelectionView>> watchSelections() =>
      _gateway.watchModelSelections();

  Future<ModelConnectionView> create(
    _CreateModelConnectionRequest request,
  ) async {
    final connection = await _gateway.createModelConnection(
      connectionId: request.id,
      name: request.name,
      providerId: request.providerId,
      url: request.url,
    );

    return await this._applySecret(_gateway, (
      connection: connection,
      resourceId: request.id,
      secret: request.secret,
    ));
  }

  Future<ModelSyncResult> testAndSync(String connectionId) =>
      _gateway.testAndSyncModelConnection(connectionId: connectionId);

  Future<ModelConnectionView> update(
    _UpdateModelConnectionRequest request,
  ) async {
    final connection = request.connection;
    final updated = await _gateway.updateModelConnection(
      connectionId: connection.id,
      expectedRevision: connection.revision,
      name: request.name,
      url: request.url,
    );

    return await this._applySecret(_gateway, (
      connection: updated,
      resourceId: connection.id,
      secret: request.secret,
    ));
  }

  Future<void> delete(CloudModelConnection connection) =>
      _gateway.deleteModelConnection(
        connectionId: connection.id,
        expectedRevision: connection.revision,
      );
}

extension on CloudModelConnectionUsecases {
  Future<ModelConnectionView> _applySecret(
    CloudModelGateway gateway,
    _SecretUpdate request,
  ) async {
    final secret = request.secret;
    if (secret == null) return request.connection;

    final secretState = await this._putSecret(
      gateway,
      request.resourceId,
      secret,
    );

    return request.connection.copyWith(
      hasSecret: secretState.configured,
      keySuffix: secretState.displaySuffix,
    );
  }

  Future<PutWorkspaceSecretResponse> _putSecret(
    CloudModelGateway gateway,
    String resourceId,
    String secret,
  ) => gateway.putSecret(
    requestId: const Uuid().v4(),
    secretKind: .provider,
    scope: .workspace,
    resourceId: resourceId,
    secret: secret,
  );
}
