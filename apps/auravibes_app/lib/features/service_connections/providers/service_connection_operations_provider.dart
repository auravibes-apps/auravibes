import 'package:auravibes_app/features/service_connections/models/cloud_service_connection.dart';
import 'package:auravibes_app/features/service_connections/providers/service_connection_repository_provider.dart';
import 'package:auravibes_app/features/service_connections/usecases/cloud_service_connection_usecases.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_resource_store.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/v7.dart';

part 'service_connection_operations_provider.g.dart';

class ServiceConnectionOperations {
  const ServiceConnectionOperations({
    required this.createAppSkillCredential,
    required this.getGenericForEdit,
    required this.updateGeneric,
  });

  final Future<void> Function({
    required String workspaceId,
    required String appSkillServiceId,
    required String name,
    required String apiKey,
  })
  createAppSkillCredential;
  final Future<GenericServiceConnectionForEdit?> Function(String id)
  getGenericForEdit;
  final Future<void> Function(
    GenericServiceConnectionForEdit connection,
    GenericServiceConnectionUpdate update,
  )
  updateGeneric;
}

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
    final cloud = CloudServiceConnectionUsecases(
      CloudWorkspaceResourceStore(gateway),
    );

    return ServiceConnectionOperations(
      createAppSkillCredential:
          ({
            required workspaceId,
            required appSkillServiceId,
            required name,
            required apiKey,
          }) => cloud.create(
            id: const UuidV7().generate(),
            name: name,
            serviceId: appSkillServiceId,
            secretKind: WorkspaceSecretKind.skillCredential,
            scope: WorkspaceSecretScope.workspace,
            secret: apiKey,
          ),
      getGenericForEdit: (id) async {
        final connection = await cloud.getById(id);
        if (connection == null || connection.kind != 'appSkillCredential') {
          return null;
        }

        return GenericServiceConnectionForEdit.fromCloud(connection);
      },
      updateGeneric: (connection, update) async {
        final revision = connection.revision;
        if (revision == null) {
          throw StateError('Cloud service connection revision is missing');
        }
        await cloud.updateGeneric(
          connection: CloudServiceConnection(
            id: connection.id,
            revision: revision,
            name: connection.name,
            serviceId: connection.serviceId,
            hasSecret: connection.hasSecret,
            scope: WorkspaceSecretScope.workspace,
            kind: 'appSkillCredential',
            secretRevision: connection.secretRevision,
            keySuffix: connection.keySuffix,
          ),
          update: update,
        );
      },
    );
  }
  final local = ref.watch(serviceConnectionRepositoryProvider);

  return ServiceConnectionOperations(
    createAppSkillCredential:
        ({
          required workspaceId,
          required appSkillServiceId,
          required name,
          required apiKey,
        }) async {
          final _ = await local.createAppSkillCredential(
            workspaceId: workspaceId,
            appSkillServiceId: appSkillServiceId,
            name: name,
            apiKey: apiKey,
          );
        },
    getGenericForEdit: (id) async {
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
    },
    updateGeneric: (connection, update) async {
      await local.updateAppSkillCredential(
        id: connection.id,
        workspaceId: workspaceId,
        name: update.name,
        clearSecret: update.secretEdit == ServiceConnectionSecretEdit.clear,
        secret: update.secretEdit == ServiceConnectionSecretEdit.replace
            ? update.secret
            : null,
      );
    },
  );
}
