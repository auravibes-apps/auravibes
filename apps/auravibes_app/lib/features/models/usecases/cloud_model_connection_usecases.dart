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
  }) async {
    final connection = await _gateway.createModelConnection(
      connectionId: id,
      name: name,
      providerId: providerId,
      url: url,
    );
    if (secret case final value?) {
      final secretState = await _gateway.putSecret(
        requestId: const Uuid().v4(),
        secretKind: WorkspaceSecretKind.provider,
        scope: WorkspaceSecretScope.workspace,
        resourceId: id,
        secret: value,
      );

      return connection.copyWith(
        hasSecret: secretState.configured,
        keySuffix: secretState.displaySuffix,
      );
    }

    return connection;
  }

  Future<ModelSyncResult> testAndSync(String connectionId) =>
      _gateway.testAndSyncModelConnection(connectionId: connectionId);

  Future<ModelConnectionView> update({
    required CloudModelConnection connection,
    required String name,
    required String? url,
    String? secret,
  }) async {
    final updated = await _gateway.updateModelConnection(
      connectionId: connection.id,
      expectedRevision: connection.revision,
      name: name,
      url: url,
    );
    if (secret case final value?) {
      final secretState = await _gateway.putSecret(
        requestId: const Uuid().v4(),
        secretKind: WorkspaceSecretKind.provider,
        scope: WorkspaceSecretScope.workspace,
        resourceId: connection.id,
        secret: value,
      );

      return updated.copyWith(
        hasSecret: secretState.configured,
        keySuffix: secretState.displaySuffix,
      );
    }

    return updated;
  }

  Future<void> delete(CloudModelConnection connection) =>
      _gateway.deleteModelConnection(
        connectionId: connection.id,
        expectedRevision: connection.revision,
      );
}
