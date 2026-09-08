import 'package:auravibes_app/features/workspaces/services/cloud_resource_mapper.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';

class const CloudServiceConnection({
  required final String id,
  required final int revision,
  required final String name,
  required final String serviceId,
  required final bool hasSecret,
  required final WorkspaceSecretScope scope,
  required final String kind,
  final int? secretRevision,
  final String? keySuffix,
  final String? credentialDefinitionId,
  final bool isEnabled = true,
}) {
  factory fromResource(WorkspaceResource resource) {
    final data = CloudResourceMapper.decode(resource);

    return CloudServiceConnection(
      id: resource.resourceId,
      revision: resource.revision,
      name: data['name'] as String,
      serviceId: CloudResourceMapper.string(data, 'serviceId'),
      hasSecret: data['hasSecret'] as bool? ?? data['keySuffix'] != null,
      scope: WorkspaceSecretScope.fromJson(
        data['scope'] as String? ?? WorkspaceSecretScope.workspace.name,
      ),
      kind: data['kind'] as String? ?? 'appSkillCredential',
      secretRevision: data['secretRevision'] as int?,
      keySuffix: data['keySuffix'] as String?,
      credentialDefinitionId: data['credentialDefinitionId'] as String?,
      isEnabled: data['isEnabled'] as bool? ?? true,
    );
  }
}

enum ServiceConnectionSecretEdit { preserve, replace, clear }

class const GenericServiceConnectionForEdit({
  required final String id,
  required final String name,
  required final String serviceId,
  required final bool hasSecret,
  required final String? keySuffix,
  final int? revision,
  final int? secretRevision,
}) {
  factory fromCloud(CloudServiceConnection connection) =>
      GenericServiceConnectionForEdit(
        id: connection.id,
        name: connection.name,
        serviceId: connection.serviceId,
        hasSecret: connection.hasSecret,
        keySuffix: connection.keySuffix,
        revision: connection.revision,
        secretRevision: connection.secretRevision,
      );
}

class const GenericServiceConnectionUpdate({
  required final String name,
  required final ServiceConnectionSecretEdit secretEdit,
  final String? secret,
});
