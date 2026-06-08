import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/entities/skill_credential_definition_entity.dart';
import 'package:auravibes_app/domain/entities/skill_credential_entity.dart';

enum ServiceConnectionListItemKind { modelProvider, skillCredential }

class ServiceConnectionListItem {
  const ServiceConnectionListItem({
    required this.id,
    required this.workspaceId,
    required this.name,
    required this.serviceName,
    required this.kind,
    required this.keySuffix,
    required this.credentialDefinitionId,
  });

  factory ServiceConnectionListItem.fromModelConnection(
    ModelConnectionEntity connection,
  ) {
    return ServiceConnectionListItem(
      id: connection.id,
      workspaceId: connection.workspaceId,
      name: connection.name,
      serviceName: connection.modelId,
      kind: ServiceConnectionListItemKind.modelProvider,
      keySuffix: connection.keySuffix,
      credentialDefinitionId: null,
    );
  }

  factory ServiceConnectionListItem.fromSkillCredential({
    required SkillCredentialEntity credential,
    required SkillCredentialDefinitionEntity? definition,
  }) {
    return ServiceConnectionListItem(
      id: credential.id,
      workspaceId: credential.workspaceId,
      name: credential.name,
      serviceName: definition?.title,
      kind: ServiceConnectionListItemKind.skillCredential,
      keySuffix: credential.keySuffix,
      credentialDefinitionId: credential.credentialDefinitionId,
    );
  }

  final String id;
  final String workspaceId;
  final String name;
  final String? serviceName;
  final ServiceConnectionListItemKind kind;
  final String? keySuffix;
  final String? credentialDefinitionId;
}
