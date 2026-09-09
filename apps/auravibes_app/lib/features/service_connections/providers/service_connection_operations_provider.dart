import 'package:auravibes_app/data/repositories/service_connection_repository.dart';
import 'package:auravibes_app/features/service_connections/models/cloud_service_connection.dart';
import 'package:auravibes_app/features/service_connections/providers/service_connection_repository_provider.dart';
import 'package:auravibes_app/features/service_connections/usecases/cloud_service_connection_usecases.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_state_gateway.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/v7.dart';

part 'service_connection_operations.dart';
part 'service_connection_operations_provider.g.dart';

@riverpod
Future<ServiceConnectionOperations> serviceConnectionOperations(
  Ref ref,
  String workspaceId,
) async {
  final session = await ref.watch(
    workspaceSessionForRouteProvider(workspaceId).future,
  );
  final gateway = await ref.watch(
    cloudWorkspaceStateGatewayProvider(session).future,
  );
  if (gateway != null) {
    return _cloudServiceConnectionOperations(gateway);
  }
  final local = ref.watch(serviceConnectionRepositoryProvider);

  return _localServiceConnectionOperations(local, workspaceId);
}

typedef _CreateServiceConnection = Future<void> Function({
  required String workspaceId,
  required String appSkillServiceId,
  required String name,
  required String apiKey,
});
typedef _GetServiceConnection =
    Future<GenericServiceConnectionForEdit?> Function(String id);
typedef _UpdateServiceConnection = Future<void> Function(
  GenericServiceConnectionForEdit connection,
  GenericServiceConnectionUpdate update,
);
typedef _LocalUpdateRequest = ({
  ServiceConnectionRepository local,
  GenericServiceConnectionForEdit connection,
  GenericServiceConnectionUpdate update,
  String workspaceId,
});

ServiceConnectionOperations _cloudServiceConnectionOperations(
  CloudWorkspaceStateGateway gateway,
) {
  final cloud = _cloudServiceConnectionUsecases(gateway);

  return _serviceConnectionOperations(
    get: _cloudGetCallback(cloud),
    create: _cloudCreateCallback(cloud),
    update: _cloudUpdateCallback(cloud),
  );
}

CloudServiceConnectionUsecases _cloudServiceConnectionUsecases(
  CloudWorkspaceStateGateway gateway,
) => .new(.new(gateway));

ServiceConnectionOperations _serviceConnectionOperations({
  required _CreateServiceConnection create,
  required _GetServiceConnection get,
  required _UpdateServiceConnection update,
}) {
  return .new(
    createAppSkillCredential: create,
    getGenericForEdit: get,
    updateGeneric: update,
  );
}

_CreateServiceConnection _cloudCreateCallback(
  CloudServiceConnectionUsecases cloud,
) {
  return ({
    required workspaceId,
    required appSkillServiceId,
    required name,
    required apiKey,
  }) => _createCloudCredential(cloud, (
    workspaceId: workspaceId,
    appSkillServiceId: appSkillServiceId,
    name: name,
    apiKey: apiKey,
  ));
}

_GetServiceConnection _cloudGetCallback(CloudServiceConnectionUsecases cloud) {
  return (id) => _getCloudCredential(cloud, id);
}

_UpdateServiceConnection _cloudUpdateCallback(
  CloudServiceConnectionUsecases cloud,
) {
  return (connection, update) =>
      _updateCloudCredential(cloud, connection, update);
}

Future<void> _createCloudCredential(
  CloudServiceConnectionUsecases cloud,
  AppSkillCredentialCreateRequest request,
) {
  final _ = request.workspaceId;

  return cloud.create(
    id: const UuidV7().generate(),
    name: request.name,
    serviceId: request.appSkillServiceId,
    secretKind: .skillCredential,
    scope: .workspace,
    secret: request.apiKey,
  );
}

Future<GenericServiceConnectionForEdit?> _getCloudCredential(
  CloudServiceConnectionUsecases cloud,
  String id,
) async {
  final connection = await cloud.getById(id);
  if (connection == null || connection.kind != 'appSkillCredential') {
    return null;
  }

  return GenericServiceConnectionForEdit.fromCloud(connection);
}

Future<void> _updateCloudCredential(
  CloudServiceConnectionUsecases cloud,
  GenericServiceConnectionForEdit connection,
  GenericServiceConnectionUpdate update,
) async {
  final revision = connection.revision;
  if (revision == null) {
    throw StateError('Cloud service connection revision is missing');
  }

  await cloud.updateGeneric(
    connection: _cloudConnection(connection, revision),
    update: update,
  );
}

CloudServiceConnection _cloudConnection(
  GenericServiceConnectionForEdit connection,
  int revision,
) {
  return .new(
    id: connection.id,
    revision: revision,
    name: connection.name,
    serviceId: connection.serviceId,
    hasSecret: connection.hasSecret,
    scope: WorkspaceSecretScope.workspace,
    kind: 'appSkillCredential',
    secretRevision: connection.secretRevision,
    keySuffix: connection.keySuffix,
  );
}

ServiceConnectionOperations _localServiceConnectionOperations(
  ServiceConnectionRepository local,
  String workspaceId,
) {
  return _serviceConnectionOperations(
    get: _localGetCallback(local, workspaceId),
    create: _localCreateCallback(local),
    update: _localUpdateCallback(local, workspaceId),
  );
}

_CreateServiceConnection _localCreateCallback(
  ServiceConnectionRepository local,
) {
  return ({
    required workspaceId,
    required appSkillServiceId,
    required name,
    required apiKey,
  }) => _createLocalCredential(local, (
    workspaceId: workspaceId,
    appSkillServiceId: appSkillServiceId,
    name: name,
    apiKey: apiKey,
  ));
}

_GetServiceConnection _localGetCallback(
  ServiceConnectionRepository local,
  String workspaceId,
) {
  return (id) => _getLocalCredential(local, id, workspaceId: workspaceId);
}

_UpdateServiceConnection _localUpdateCallback(
  ServiceConnectionRepository local,
  String workspaceId,
) {
  return (connection, update) => _updateLocalCredential((
    local: local,
    connection: connection,
    update: update,
    workspaceId: workspaceId,
  ));
}

Future<void> _createLocalCredential(
  ServiceConnectionRepository local,
  AppSkillCredentialCreateRequest request,
) async {
  final _ = await local.createAppSkillCredential(request);
}

Future<GenericServiceConnectionForEdit?> _getLocalCredential(
  ServiceConnectionRepository local,
  String id, {
  required String workspaceId,
}) async {
  final connection = await local.getAppSkillCredentialForEdit(
    id,
    workspaceId: workspaceId,
  );
  if (connection == null) return null;

  return GenericServiceConnectionForEdit(
    id: connection.id,
    name: connection.name,
    serviceId: connection.serviceId,
    hasSecret: connection.hasSecret,
    keySuffix: connection.keySuffix,
  );
}

Future<void> _updateLocalCredential(_LocalUpdateRequest request) {
  final connection = request.connection;
  final update = request.update;

  return request.local.updateAppSkillCredential((
    id: connection.id,
    workspaceId: request.workspaceId,
    name: update.name,
    clearSecret: _shouldClearSecret(update),
    secret: _secretForUpdate(update),
  ));
}

bool _shouldClearSecret(GenericServiceConnectionUpdate update) =>
    update.secretEdit == ServiceConnectionSecretEdit.clear;

String? _secretForUpdate(GenericServiceConnectionUpdate update) =>
    update.secretEdit == ServiceConnectionSecretEdit.replace
    ? update.secret
    : null;
// Top-level API/provider declarations are required by their consumers.
