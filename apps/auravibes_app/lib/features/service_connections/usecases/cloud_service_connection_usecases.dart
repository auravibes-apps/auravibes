import 'package:auravibes_app/features/service_connections/models/cloud_service_connection.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_resource_store.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';

class CloudServiceConnectionUsecases {
  const CloudServiceConnectionUsecases(this._store);

  final CloudWorkspaceResourceStore _store;

  Stream<List<CloudServiceConnection>> watch() => _store
      .watch(WorkspaceResourceKind.serviceConnection)
      .map((items) => items.map(CloudServiceConnection.fromResource).toList());

  Future<CloudServiceConnection?> getById(String id) async {
    final items = await watch().first;

    return items.where((item) => item.id == id).firstOrNull;
  }

  Future<void> create({
    required String id,
    required String name,
    required String serviceId,
    required WorkspaceSecretKind secretKind,
    required WorkspaceSecretScope scope,
    required String secret,
  }) async {
    final _ = await _store.mutateCredential(
      operation: WorkspacePatchOperationKind.create,
      kind: WorkspaceResourceKind.serviceConnection,
      id: id,
      data: {
        'id': id,
        'name': name,
        'serviceId': serviceId,
        'scope': scope.name,
        'kind': 'appSkillCredential',
      },
      secretKind: secretKind,
      scope: scope,
      secret: secret,
    );
  }

  Future<void> updateGeneric({
    required CloudServiceConnection connection,
    required GenericServiceConnectionUpdate update,
  }) async {
    final changesSecret =
        update.secretEdit != ServiceConnectionSecretEdit.preserve;
    final replacement = update.secretEdit == ServiceConnectionSecretEdit.replace
        ? update.secret
        : null;
    final data = {
      'id': connection.id,
      'name': update.name,
      'serviceId': connection.serviceId,
      'scope': connection.scope.name,
      'kind': connection.kind,
    };
    if (!changesSecret) {
      await _store.update(
        kind: WorkspaceResourceKind.serviceConnection,
        id: connection.id,
        revision: connection.revision,
        data: data,
      );

      return;
    }

    final _ = await _store.mutateCredential(
      operation: WorkspacePatchOperationKind.update,
      kind: WorkspaceResourceKind.serviceConnection,
      id: connection.id,
      data: data,
      resourceRevision: connection.revision,
      secretKind: WorkspaceSecretKind.skillCredential,
      scope: connection.scope,
      secret: replacement,
      clearSecret: update.secretEdit == ServiceConnectionSecretEdit.clear,
      secretRevision: connection.secretRevision,
    );
  }

  Future<void> delete(CloudServiceConnection connection) =>
      _store.mutateCredential(
        operation: WorkspacePatchOperationKind.delete,
        kind: WorkspaceResourceKind.serviceConnection,
        id: connection.id,
        resourceRevision: connection.revision,
        secretKind: WorkspaceSecretKind.skillCredential,
        scope: connection.scope,
        secret: null,
        clearSecret: true,
        secretRevision: connection.secretRevision,
      );

  Future<void> deleteById(String id) async {
    final connection = await getById(id);
    if (connection == null) {
      throw StateError('Service connection not found: $id');
    }
    await delete(connection);
  }
}
