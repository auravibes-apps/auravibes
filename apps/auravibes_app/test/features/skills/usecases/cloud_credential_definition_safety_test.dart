import 'dart:convert';

import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/features/skills/services/cloud_skill_store.dart';
import 'package:auravibes_app/features/skills/usecases/create_skill_credential_definition_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/credential_definition_schema.dart';
import 'package:auravibes_app/features/skills/usecases/delete_skill_credential_definition_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/update_skill_credential_definition_usecase.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_resource_store.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:flutter_test/flutter_test.dart';

const _secret = '{"token":{"description":"Token"}}';
const _mixed =
    '{"token":{"description":"Token"},'
    '"region":{"description":"Region","secret":false}}';
const _metadataOnly = '{"region":{"description":"Region","secret":false}}';

void main() {
  test('cloud create enforces secret-bearing definitions', () async {
    final fake = _FakeCloud();
    final create = CreateSkillCredentialDefinitionUsecase(
      null,
      cloudStore: fake.store,
    );
    final first = await create.call(
      'workspace-1',
      const .new(title: 'Secret Definition', attributesJson: _secret),
    );
    final second = await create.call(
      'workspace-1',
      const .new(title: 'Mixed Definition', attributesJson: _mixed),
    );
    expect(first.title, 'Secret Definition');
    expect(second.title, 'Mixed Definition');
    expect(fake.patches, 2);
    await expectLater(
      create.call(
        'workspace-1',
        const .new(title: 'Metadata Definition', attributesJson: _metadataOnly),
      ),
      throwsA(isA<CredentialDefinitionValidationException>()),
    );
    await expectLater(
      fake.store.createDefinition(
        const .new(title: 'Bypass', attributesJson: _metadataOnly),
      ),
      throwsFormatException,
    );
    expect(fake.patches, 2);
  });

  test(
    'cloud lists legacy metadata records but excludes them from readiness',
    () async {
      final fake = _FakeCloud();
      fake.resources.addAll([
        _definition(_mixed),
        _credential('metadata', hasSecret: false),
        _credential('secret', hasSecret: true),
        _credential('disabled', hasSecret: false, enabled: false),
      ]);
      expect((await fake.store.credentials('definition-1')).length, 2);
      expect(
        (await fake.store.usableCredentials('definition-1'))
            .map((credential) => credential.id),
        ['secret'],
      );
      expect(await fake.store.linkedCredentialCount('definition-1'), 3);
      final skill = SkillEntity(
        source: .user,
        id: 'skill-1',
        workspaceId: 'workspace-1',
        kind: .template,
        title: 'Service',
        slug: 'service',
        description: '',
        content: '',
        isEnabled: true,
        isCredentialOptional: false,
        credentialDefinitionId: 'definition-1',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      );
      expect(await fake.store.credentialReady(skill), isTrue);
      fake.resources.removeWhere((resource) => resource.resourceId == 'secret');
      expect(await fake.store.credentialReady(skill), isFalse);
      fake.resources[0] = _definition(_metadataOnly);
      expect((await fake.store.definitions()).single.id, 'definition-1');
      await expectLater(
        UpdateSkillCredentialDefinitionUsecase(
          null,
          cloudStore: fake.store,
        ).call('definition-1', const .new(title: 'Renamed')),
        throwsA(isA<CredentialDefinitionValidationException>()),
      );
    },
  );

  test('cloud update and delete block linked records without writes', () async {
    final fake = _FakeCloud();
    fake.resources.addAll([
      _definition(_mixed),
      _credential('metadata', hasSecret: false, enabled: false),
      _credential('secret', hasSecret: true),
      _skill(),
      _tool(),
    ]);
    final update = UpdateSkillCredentialDefinitionUsecase(
      null,
      cloudStore: fake.store,
    );
    final delete = DeleteSkillCredentialDefinitionUsecase(
      cloudStore: fake.store,
    );
    final safe = await update.call(
      'definition-1',
      const .new(
        attributesJson:
            '{"region":{"description":"New","secret":false},'
            '"token":{"description":"Token","optional":true}}',
      ),
    );
    expect(safe.attributesJson, contains('"optional":true'));
    expect(fake.patches, 1);
    await expectLater(
      update.call('definition-1', const .new(attributesJson: _secret)),
      throwsA(
        isA<CredentialDefinitionConflictException>().having(
          (error) => error.credentialCount,
          'credentials',
          2,
        ),
      ),
    );
    await expectLater(
      update.call(
        'definition-1',
        const .new(
          attributesJson:
              '{"token":{"description":"Token","optional":true},'
              '"region":{"description":"Region","secret":true}}',
        ),
      ),
      throwsA(
        isA<CredentialDefinitionConflictException>().having(
          (error) => error.changes.single.kind,
          'change',
          CredentialSchemaChangeKind.secretChanged,
        ),
      ),
    );
    await expectLater(
      delete.call('definition-1'),
      throwsA(
        isA<CredentialDefinitionConflictException>()
            .having((error) => error.credentialCount, 'credentials', 2)
            .having((error) => error.skillCount, 'skills', 1)
            .having((error) => error.toolCount, 'tools', 1),
      ),
    );
    expect(fake.patches, 1);
    expect(await fake.store.definition('definition-1'), isNotNull);
    fake.resources.removeWhere(
      (resource) => resource.resourceKind == .serviceConnection,
    );
    expect(await delete.call('definition-1'), isTrue);
    expect(fake.patches, 2);
  });
}

class _FakeCloud {
  final List<WorkspaceResource> resources = [];
  int patches = 0;

  CloudSkillStore get store => CloudSkillStore(
    CloudWorkspaceResourceStore.forTesting(
      watch: (kinds) => Stream.value(
        resources.where((item) => kinds.contains(item.resourceKind)).toList(),
      ),
      patch: ({required requestId, required operations}) async {
        patches++;
        return .new(resources: const [], sequence: patches);
      },
      putSecret: (_) async => PutWorkspaceSecretResponse(
        configured: false,
        revision: 0,
        sequence: 1,
      ),
      mutateCredential: (_) async => MutateWorkspaceCredentialResponse(
        resource: _definition(_secret),
        configured: false,
        sequence: 1,
      ),
    ),
    'workspace-1',
  );
}

WorkspaceResource _resource(
  WorkspaceResourceKind kind,
  String id,
  Map<String, Object?> data,
) => WorkspaceResource(
  workspaceId: 1,
  resourceKind: kind,
  resourceId: id,
  data: jsonEncode(data),
  revision: 1,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

WorkspaceResource _definition(String schema) => _resource(
  .skillDefinition,
  'definition-1',
  {'title': 'Service', 'slug': 'service', 'attributesJson': schema},
);

WorkspaceResource _credential(
  String id, {
  required bool hasSecret,
  bool enabled = true,
}) => _resource(.serviceConnection, id, {
  'kind': 'skillCredential',
  'credentialDefinitionId': 'definition-1',
  'name': id,
  'attributes': const <String, String>{},
  'isEnabled': enabled,
  'hasSecret': hasSecret,
});

WorkspaceResource _skill() => _resource(.skill, 'skill-1', {
  'kind': 'template',
  'title': 'Skill',
  'slug': 'skill',
  'description': '',
  'content': '',
  'isEnabled': true,
  'credentialDefinitionId': 'definition-1',
});

WorkspaceResource _tool() => _resource(.skillTemplateTool, 'tool-1', {
  'skillId': 'skill-1',
  'templateType': 'url',
  'title': 'Tool',
  'description': '',
  'slug': 'tool',
  'definitionJson': '{}',
  'requiresCredential': true,
});
