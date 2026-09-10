import 'package:auravibes_app/features/service_connections/models/cloud_service_connection.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_resource_store.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';

typedef _CreateRequest = ({
  String id,
  String name,
  String serviceId,
  WorkspaceSecretKind secretKind,
  WorkspaceSecretScope scope,
  String secret,
});

typedef _UpdateRequest = ({
  CloudServiceConnection connection,
  GenericServiceConnectionUpdate update,
});

typedef _SecretUpdateRequest = ({
  CloudServiceConnection connection,
  GenericServiceConnectionUpdate update,
  Map<String, String> data,
});

typedef _SecretMutationRequest = ({
  CloudServiceConnection connection,
  Map<String, String> data,
  String? secret,
  bool clearSecret,
});

class const CloudServiceConnectionUsecases(
  final CloudWorkspaceResourceStore _store,
) {
  Future<void> Function({
    required String id,
    required String name,
    required String serviceId,
    required WorkspaceSecretKind secretKind,
    required WorkspaceSecretScope scope,
    required String secret,
  })
  get create =>
      ({
        required id,
        required name,
        required serviceId,
        required secretKind,
        required scope,
        required secret,
      }) => _create(_store, (
        id: id,
        name: name,
        serviceId: serviceId,
        secretKind: secretKind,
        scope: scope,
        secret: secret,
      ));

  Stream<List<CloudServiceConnection>> watch() =>
      _store.watch(.serviceConnection).map(_cloudConnections);

  Future<CloudServiceConnection?> getById(String id) => watch().first.then(
    (items) => items.where((item) => item.id == id).firstOrNull,
  );

  Future<void> updateGeneric({
    required CloudServiceConnection connection,
    required GenericServiceConnectionUpdate update,
  }) => _updateGeneric(_store, (connection: connection, update: update));

  Future<void> delete(CloudServiceConnection connection) =>
      _store.mutateCredential(
        operation: .delete,
        kind: .serviceConnection,
        id: connection.id,
        resourceRevision: connection.revision,
        secretKind: .skillCredential,
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

List<CloudServiceConnection> _cloudConnections(
  Iterable<WorkspaceResource> items,
) => items.map(CloudServiceConnection.fromResource).toList();

Future<void> _create(
  CloudWorkspaceResourceStore store,
  _CreateRequest request,
) async {
  await store.mutateCredential(
    operation: .create,
    kind: .serviceConnection,
    id: request.id,
    data: _createData(request),
    secretKind: request.secretKind,
    scope: request.scope,
    secret: request.secret,
  );
}

Map<String, String> _createData(_CreateRequest request) => {
  'id': request.id,
  'name': request.name,
  'serviceId': request.serviceId,
  'scope': request.scope.name,
  'kind': 'appSkillCredential',
};

Future<void> _updateGeneric(
  CloudWorkspaceResourceStore store,
  _UpdateRequest request,
) {
  final data = _updateData(request.connection, request.update);
  if (request.update.secretEdit == ServiceConnectionSecretEdit.preserve) {
    return _updateMetadata(store, request.connection, data);
  }

  return _updateSecret(store, (
    connection: request.connection,
    update: request.update,
    data: data,
  ));
}

Map<String, String> _updateData(
  CloudServiceConnection connection,
  GenericServiceConnectionUpdate update,
) => {
  'id': connection.id,
  'name': update.name,
  'serviceId': connection.serviceId,
  'scope': connection.scope.name,
  'kind': connection.kind,
};

Future<void> _updateMetadata(
  CloudWorkspaceResourceStore store,
  CloudServiceConnection connection,
  Map<String, String> data,
) async {
  await store.update(
    kind: .serviceConnection,
    id: connection.id,
    revision: connection.revision,
    data: data,
  );
}

Future<void> _updateSecret(
  CloudWorkspaceResourceStore store,
  _SecretUpdateRequest request,
) async {
  final connection = request.connection;
  final update = request.update;

  await _mutateSecret(store, (
    connection: connection,
    data: request.data,
    secret: _secretReplacement(update),
    clearSecret: update.secretEdit == ServiceConnectionSecretEdit.clear,
  ));
}

Future<void> _mutateSecret(
  CloudWorkspaceResourceStore store,
  _SecretMutationRequest request,
) {
  final connection = request.connection;

  return store.mutateCredential(
    operation: .update,
    kind: .serviceConnection,
    id: connection.id,
    data: request.data,
    resourceRevision: connection.revision,
    secretKind: .skillCredential,
    scope: connection.scope,
    secret: request.secret,
    clearSecret: request.clearSecret,
    secretRevision: connection.secretRevision,
  );
}

String? _secretReplacement(GenericServiceConnectionUpdate update) =>
    update.secretEdit == ServiceConnectionSecretEdit.replace
    ? update.secret
    : null;
