import 'package:auravibes_app/features/models/models/cloud_model_resources.dart';
import 'package:auravibes_app/features/models/services/cloud_model_gateway.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';

class const CloudModelConnectionUsecases(final CloudModelGateway _gateway) {
  Stream<List<CloudModelConnection>> watchConnections() => _gateway
      .watchModelConnections()
      .map((items) => items.map(CloudModelConnection.fromView).toList());

  Stream<List<WorkspaceModelSelectionView>> watchSelections() =>
      _gateway.watchModelSelections();

  Future<ModelConnectionView> create({
    required String id,
    required String name,
    required String providerId,
    String? secret,
    String? url,
  }) => _withSecret(
    connection: _gateway.createModelConnection(
      connectionId: id,
      name: name,
      providerId: providerId,
      url: url,
    ),
    resourceId: id,
    secret: secret,
  );

  Future<ModelSyncResult> testAndSync(String connectionId) =>
      _gateway.testAndSyncModelConnection(connectionId: connectionId);

  Future<ModelConnectionView> update({
    required CloudModelConnection connection,
    required String name,
    required String? url,
    String? secret,
  }) => _withSecret(
    connection: _gateway.updateModelConnection(
      connectionId: connection.id,
      expectedRevision: connection.revision,
      name: name,
      url: url,
    ),
    resourceId: connection.id,
    secret: secret,
  );

  Future<void> delete(CloudModelConnection connection) =>
      _gateway.deleteModelConnection(
        connectionId: connection.id,
        expectedRevision: connection.revision,
      );

  Future<ModelConnectionView> _withSecret({
    required Future<ModelConnectionView> connection,
    required String resourceId,
    required String? secret,
  }) async {
    final resolvedConnection = await connection;
    if (secret case final value?) {
      final secretState = await _gateway.putSecret(
        requestId: const Uuid().v4(),
        secretKind: WorkspaceSecretKind.provider,
        scope: WorkspaceSecretScope.workspace,
        resourceId: resourceId,
        secret: value,
      );

      return resolvedConnection.copyWith(
        hasSecret: secretState.configured,
        keySuffix: secretState.displaySuffix,
      );
    }

    return resolvedConnection;
  }
}
