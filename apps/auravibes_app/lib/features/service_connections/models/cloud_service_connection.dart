import 'package:auravibes_app/features/workspaces/services/cloud_resource_mapper.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';

class CloudServiceConnection {
  const CloudServiceConnection({
    required this.id,
    required this.revision,
    required this.name,
    required this.serviceId,
    required this.hasSecret,
    required this.scope,
    required this.kind,
    this.secretRevision,
    this.keySuffix,
    this.credentialDefinitionId,
    this.isEnabled = true,
  });

  factory CloudServiceConnection.fromResource(WorkspaceResource resource) {
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

  final String id;
  final int revision;
  final String name;
  final String serviceId;
  final bool hasSecret;
  final WorkspaceSecretScope scope;
  final String kind;
  final int? secretRevision;
  final String? keySuffix;
  final String? credentialDefinitionId;
  final bool isEnabled;
}

enum ServiceConnectionSecretEdit { preserve, replace, clear }

class GenericServiceConnectionForEdit {
  const GenericServiceConnectionForEdit({
    required this.id,
    required this.name,
    required this.serviceId,
    required this.hasSecret,
    required this.keySuffix,
    this.revision,
    this.secretRevision,
  });

  factory GenericServiceConnectionForEdit.fromCloud(
    CloudServiceConnection connection,
  ) => GenericServiceConnectionForEdit(
    id: connection.id,
    name: connection.name,
    serviceId: connection.serviceId,
    hasSecret: connection.hasSecret,
    keySuffix: connection.keySuffix,
    revision: connection.revision,
    secretRevision: connection.secretRevision,
  );

  final String id;
  final String name;
  final String serviceId;
  final bool hasSecret;
  final String? keySuffix;
  final int? revision;
  final int? secretRevision;
}

class GenericServiceConnectionUpdate {
  const GenericServiceConnectionUpdate({
    required this.name,
    required this.secretEdit,
    this.secret,
  });

  final String name;
  final ServiceConnectionSecretEdit secretEdit;
  final String? secret;
}
