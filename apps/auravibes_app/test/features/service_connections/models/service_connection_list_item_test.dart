import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/entities/skill_credential_definition_entity.dart';
import 'package:auravibes_app/domain/entities/skill_credential_entity.dart';
import 'package:auravibes_app/features/service_connections/models/service_connection_list_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ServiceConnectionListItem', () {
    test('maps model connection fields', () {
      final item = ServiceConnectionListItem.fromModelConnection(
        _modelConnection(
          id: 'model-1',
          workspaceId: 'workspace-1',
          name: 'OpenAI Main',
          modelId: 'gpt-4.1',
          keySuffix: 'sk-1',
        ),
      );

      expect(item.id, 'model-1');
      expect(item.workspaceId, 'workspace-1');
      expect(item.name, 'OpenAI Main');
      expect(item.serviceName, 'gpt-4.1');
      expect(item.kind, ServiceConnectionListItemKind.modelProvider);
      expect(item.keySuffix, 'sk-1');
      expect(item.credentialDefinitionId, isNull);
    });

    test('maps skill credential fields with definition title', () {
      final item = ServiceConnectionListItem.fromSkillCredential(
        credential: _credential(
          id: 'credential-1',
          workspaceId: 'workspace-1',
          credentialDefinitionId: 'definition-1',
          name: 'GitHub Token',
          keySuffix: 'gh-1',
        ),
        definition: _definition(
          id: 'definition-1',
          workspaceId: 'workspace-1',
          title: 'GitHub',
        ),
      );

      expect(item.id, 'credential-1');
      expect(item.workspaceId, 'workspace-1');
      expect(item.name, 'GitHub Token');
      expect(item.serviceName, 'GitHub');
      expect(item.kind, ServiceConnectionListItemKind.skillCredential);
      expect(item.keySuffix, 'gh-1');
      expect(item.credentialDefinitionId, 'definition-1');
    });

    test('keeps skill credential visible without matching definition', () {
      final item = ServiceConnectionListItem.fromSkillCredential(
        credential: _credential(
          id: 'credential-1',
          workspaceId: 'workspace-1',
          credentialDefinitionId: 'missing-definition',
          name: 'Stale Token',
          keySuffix: 'stale',
        ),
        definition: null,
      );

      expect(item.id, 'credential-1');
      expect(item.workspaceId, 'workspace-1');
      expect(item.name, 'Stale Token');
      expect(item.serviceName, isNull);
      expect(item.kind, ServiceConnectionListItemKind.skillCredential);
      expect(item.keySuffix, 'stale');
      expect(item.credentialDefinitionId, 'missing-definition');
    });
  });
}

ModelConnectionEntity _modelConnection({
  required String id,
  required String workspaceId,
  required String name,
  required String modelId,
  String? keySuffix,
}) {
  final timestamp = DateTime(2026);

  return ModelConnectionEntity(
    id: id,
    name: name,
    modelId: modelId,
    createdAt: timestamp,
    updatedAt: timestamp,
    workspaceId: workspaceId,
    hasKey: true,
    keySuffix: keySuffix,
  );
}

SkillCredentialEntity _credential({
  required String id,
  required String workspaceId,
  required String credentialDefinitionId,
  required String name,
  String? keySuffix,
}) {
  final timestamp = DateTime(2026);

  return SkillCredentialEntity(
    id: id,
    workspaceId: workspaceId,
    credentialDefinitionId: credentialDefinitionId,
    name: name,
    attributes: const {},
    isEnabled: true,
    createdAt: timestamp,
    updatedAt: timestamp,
    keySuffix: keySuffix,
  );
}

SkillCredentialDefinitionEntity _definition({
  required String id,
  required String workspaceId,
  required String title,
}) {
  final timestamp = DateTime(2026);

  return SkillCredentialDefinitionEntity(
    id: id,
    workspaceId: workspaceId,
    title: title,
    slug: title.toLowerCase(),
    attributesJson: '{}',
    createdAt: timestamp,
    updatedAt: timestamp,
  );
}
