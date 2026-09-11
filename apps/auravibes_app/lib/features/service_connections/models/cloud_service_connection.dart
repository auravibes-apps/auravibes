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
  new _fromResourceFields(
    WorkspaceResource resource,
    _CloudServiceConnectionFields fields,
  ) : this(
        id: resource.resourceId,
        revision: resource.revision,
        name: fields.name,
        serviceId: fields.serviceId,
        hasSecret: fields.hasSecret,
        scope: fields.scope,
        kind: fields.kind,
        secretRevision: fields.secretRevision,
        keySuffix: fields.keySuffix,
        credentialDefinitionId: fields.credentialDefinitionId,
        isEnabled: fields.isEnabled,
      );

  factory fromResource(WorkspaceResource resource) {
    final data = CloudResourceMapper.decode(resource);

    return _fromResourceData(resource, data);
  }

  bool isConfigured() => hasSecret;

  static CloudServiceConnection _fromResourceData(
    WorkspaceResource resource,
    Map<String, dynamic> data,
  ) => CloudServiceConnection._fromResourceFields(
    resource,
    _cloudServiceConnectionFields(data),
  );
}

typedef _CloudServiceConnectionFields = ({
  String name,
  String serviceId,
  bool hasSecret,
  WorkspaceSecretScope scope,
  String kind,
  int? secretRevision,
  String? keySuffix,
  String? credentialDefinitionId,
  bool isEnabled,
});

_CloudServiceConnectionFields _cloudServiceConnectionFields(
  Map<String, dynamic> data,
) => (
  name: _requiredString(data, 'name'),
  serviceId: CloudResourceMapper.string(data, 'serviceId'),
  hasSecret: _hasSecret(data),
  scope: _scope(data),
  kind: _kind(data),
  secretRevision: _optionalInt(data, 'secretRevision'),
  keySuffix: _optionalString(data, 'keySuffix'),
  credentialDefinitionId: _optionalString(data, 'credentialDefinitionId'),
  isEnabled: _isEnabled(data),
);

String _requiredString(Map<String, dynamic> data, String key) =>
    data[key] as String;

String? _optionalString(Map<String, dynamic> data, String key) =>
    data[key] as String?;

int? _optionalInt(Map<String, dynamic> data, String key) => data[key] as int?;

bool _hasSecret(Map<String, dynamic> data) =>
    data['hasSecret'] as bool? ?? data['keySuffix'] != null;

WorkspaceSecretScope _scope(Map<String, dynamic> data) =>
    .fromJson(data['scope'] as String? ?? WorkspaceSecretScope.workspace.name);

String _kind(Map<String, dynamic> data) =>
    data['kind'] as String? ?? 'appSkillCredential';

bool _isEnabled(Map<String, dynamic> data) =>
    data['isEnabled'] as bool? ?? true;

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

  bool hasConfiguredSecret() => hasSecret;
}

class const GenericServiceConnectionUpdate({
  required final String name,
  required final ServiceConnectionSecretEdit secretEdit,
  final String? secret,
});
