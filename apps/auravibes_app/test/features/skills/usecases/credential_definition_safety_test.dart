import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/skill_credential_definitions_repository.dart';
import 'package:auravibes_app/data/repositories/skill_credentials_repository.dart';
import 'package:auravibes_app/data/repositories/skill_template_tools_repository.dart';
import 'package:auravibes_app/data/repositories/skills_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/features/skills/usecases/check_skill_credential_readiness_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/create_skill_credential_definition_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/credential_definition_schema.dart';
import 'package:auravibes_app/features/skills/usecases/delete_skill_credential_definition_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/update_skill_credential_definition_usecase.dart';
import 'package:auravibes_app/services/secret_key_manager.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

const _secret = '{"token":{"description":"Token"}}';
const _mixed =
    '{"token":{"description":"Token","optional":true},'
    '"region":{"description":"Region","secret":false}}';
const _metadataOnly = '{"region":{"description":"Region","secret":false}}';

void main() {
  test('schema diff allows descriptions, order and required-to-optional', () {
    final previous = SkillCredentialAttributeDefinition.parseMap(_mixed);
    final safe = SkillCredentialAttributeDefinition.parseMap(
      '{"region":{"description":"New region","secret":false,'
      ' "optional":true},"token":{"description":"New token",'
      ' "optional":true}}',
    );
    expect(CredentialDefinitionSchema.diff(previous, safe), isEmpty);
  });

  test(
    'schema diff names removed, newly required and changed secret fields',
    () {
      final previous = SkillCredentialAttributeDefinition.parseMap(_mixed);
      final next = SkillCredentialAttributeDefinition.parseMap(
        '{"region":{"description":"Region","secret":true},'
        '"replacement":{"description":"Replacement"}}',
      );
      expect(
        CredentialDefinitionSchema.diff(previous, next)
            .map((change) => (variable: change.variable, kind: change.kind))
            .toList(),
        [
          (variable: 'token', kind: CredentialSchemaChangeKind.removed),
          (variable: 'region', kind: CredentialSchemaChangeKind.secretChanged),
        ],
      );
      final newlyRequired = SkillCredentialAttributeDefinition.parseMap(
        '{"token":{"description":"Token"},'
        '"region":{"description":"Region","secret":false}}',
      );
      expect(
        CredentialDefinitionSchema.diff(
          previous,
          newlyRequired,
        ).map((change) => change.kind),
        contains(CredentialSchemaChangeKind.required),
      );
    },
  );

  test('definition creation requires a secret attribute', () async {
    final harness = await _LocalHarness.open();
    addTearDown(harness.database.close);
    final create = harness.create;
    final secret = await create.call(
      harness.workspaceId,
      const .new(title: 'Secret Definition', attributesJson: _secret),
    );
    final mixed = await create.call(
      harness.workspaceId,
      const .new(title: 'Mixed Definition', attributesJson: _mixed),
    );
    expect(secret.title, 'Secret Definition');
    expect(mixed.title, 'Mixed Definition');
    await expectLater(
      create.call(
        harness.workspaceId,
        const .new(title: 'Metadata Definition', attributesJson: _metadataOnly),
      ),
      throwsA(isA<CredentialDefinitionValidationException>()),
    );
    await expectLater(
      harness.definitions.createDefinition(
        harness.workspaceId,
        const .new(title: 'Bypass', attributesJson: _metadataOnly),
      ),
      throwsFormatException,
    );
  });

  test(
    'destructive edits reject linked credentials and leave schema unchanged',
    () async {
      final harness = await _LocalHarness.open();
      addTearDown(harness.database.close);
      final definition = await harness.create.call(
        harness.workspaceId,
        const .new(title: 'Service', attributesJson: _mixed),
      );
      final _ = await harness.credentials.createCredential(
        harness.workspaceId,
        .new(
          credentialDefinitionId: definition.id,
          name: 'Saved',
          attributes: const {'token': 'test-value', 'region': 'us-east'},
        ),
      );
      for (final (:schema, :kind) in [
        (
          schema: '{"token":{"description":"Token","optional":true}}',
          kind: CredentialSchemaChangeKind.removed,
        ),
        (
          schema:
              '{"token":{"description":"Token"},'
              '"region":{"description":"Region","secret":false}}',
          kind: CredentialSchemaChangeKind.required,
        ),
        (
          schema:
              '{"token":{"description":"Token","optional":true},'
              '"region":{"description":"Region","secret":true}}',
          kind: CredentialSchemaChangeKind.secretChanged,
        ),
      ]) {
        final call = harness.update.call(
          definition.id,
          .new(attributesJson: schema),
        );
        await expectLater(
          call,
          throwsA(
            isA<CredentialDefinitionConflictException>()
                .having((error) => error.credentialCount, 'count', 1)
                .having(
                  (error) => error.changes.map((change) => change.kind),
                  'changes',
                  contains(kind),
                ),
          ),
        );
        expect(
          (await harness.definitions.getDefinitionById(definition.id))
              ?.attributesJson,
          _mixed,
        );
      }
    },
  );

  test('safe edits and destructive edits without credentials save', () async {
    final harness = await _LocalHarness.open();
    addTearDown(harness.database.close);
    final definition = await harness.create.call(
      harness.workspaceId,
      const .new(title: 'Service', attributesJson: _mixed),
    );
    final safe = await harness.update.call(
      definition.id,
      const .new(
        attributesJson:
            '{"region":{"description":"New","secret":false,'
            '"optional":true},"token":{"description":"Token",'
            '"optional":true}}',
      ),
    );
    expect(safe.attributesJson, contains('"description":"New"'));
    final removed = await harness.update.call(
      definition.id,
      const .new(attributesJson: _secret),
    );
    expect(removed.attributesJson, _secret);
    await expectLater(
      harness.update.call(
        definition.id,
        const .new(attributesJson: _metadataOnly),
      ),
      throwsA(isA<CredentialDefinitionValidationException>()),
    );
  });

  test(
    'legacy metadata-only definition stays visible and requires repair',
    () async {
      final harness = await _LocalHarness.open();
      addTearDown(harness.database.close);
      final legacy = await harness.database.skillCredentialDefinitionsDao
          .createDefinition(
            .new(
              workspaceId: .new(harness.workspaceId),
              title: const Value('Legacy'),
              slug: const Value('legacy'),
              attributesJson: const Value(_metadataOnly),
            ),
          );
      expect(await harness.definitions.getDefinitionById(legacy.id), isNotNull);
      await expectLater(
        harness.update.call(legacy.id, const .new(title: 'Renamed')),
        throwsA(isA<CredentialDefinitionValidationException>()),
      );
      expect(
        (await harness.definitions.getDefinitionById(legacy.id))?.title,
        'Legacy',
      );
    },
  );

  test(
    'delete counts disabled and metadata-only records without reading values',
    () async {
      final harness = await _LocalHarness.open();
      addTearDown(harness.database.close);
      final definition = await harness.create.call(
        harness.workspaceId,
        const .new(title: 'Service', attributesJson: _mixed),
      );
      final metadata = await harness.credentials.createCredential(
        harness.workspaceId,
        .new(
          credentialDefinitionId: definition.id,
          name: 'Metadata',
          attributes: const {'region': 'us-east'},
        ),
      );
      expect(
        await harness.credentials.getCredentialsForDefinition(
          workspaceId: harness.workspaceId,
          credentialDefinitionId: definition.id,
        ),
        [metadata],
      );
      expect(
        await harness.credentials.getUsableCredentialsForDefinition(
          workspaceId: harness.workspaceId,
          credentialDefinitionId: definition.id,
        ),
        isEmpty,
      );
      final _ = await harness.database.skillCredentialsDao.updateCredential(
        metadata.id,
        const .new(isEnabled: .new(false)),
      );
      final secret = await harness.credentials.createCredential(
        harness.workspaceId,
        .new(
          credentialDefinitionId: definition.id,
          name: 'Secret',
          attributes: const {'token': 'test-value', 'region': 'us-east'},
        ),
      );
      final skill = await harness.skills.createSkill(
        harness.workspaceId,
        .new(
          kind: .template,
          title: 'Service Skill',
          description: 'Test',
          content: 'Test',
          credentialDefinitionId: definition.id,
        ),
      );
      final readiness = CheckSkillCredentialReadinessUsecase(
        harness.credentials,
      );
      expect(
        await readiness.call(workspaceId: harness.workspaceId, skill: skill),
        isTrue,
      );
      final _ = await harness.tools.createTool(
        skill.id,
        const .new(
          templateType: .url,
          title: 'Call Service',
          description: 'Test',
          templateJson: '{"url":"https://example.com"}',
          inputsJson: '{}',
        ),
      );
      expect(
        await harness.credentials.countLinkedCredentials(
          workspaceId: harness.workspaceId,
          credentialDefinitionId: definition.id,
        ),
        2,
      );
      expect(
        await harness.credentials.getUsableCredentialsForDefinition(
          workspaceId: harness.workspaceId,
          credentialDefinitionId: definition.id,
        ),
        [secret],
      );
      await expectLater(
        harness.delete.call(definition.id),
        throwsA(
          isA<CredentialDefinitionConflictException>()
              .having((error) => error.credentialCount, 'credentials', 2)
              .having((error) => error.skillCount, 'skills', 1)
              .having((error) => error.toolCount, 'tools', 1),
        ),
      );
      expect(
        await harness.definitions.getDefinitionById(definition.id),
        isNotNull,
      );
      await harness.credentials.deleteCredential(secret.id);
      expect(
        await readiness.call(workspaceId: harness.workspaceId, skill: skill),
        isFalse,
      );
      await harness.credentials.deleteCredential(metadata.id);
      expect(await harness.delete.call(definition.id), isTrue);
    },
  );
}

class const _LocalHarness({
  required final AppDatabase database,
  required final String workspaceId,
  required final SkillCredentialDefinitionsRepository definitions,
  required final SkillCredentialsRepository credentials,
  required final SkillsRepository skills,
  required final SkillTemplateToolsRepository tools,
}) {
  CreateSkillCredentialDefinitionUsecase get create =>
      CreateSkillCredentialDefinitionUsecase(definitions);
  UpdateSkillCredentialDefinitionUsecase get update =>
      UpdateSkillCredentialDefinitionUsecase(
        definitions,
        credentialsRepository: credentials,
      );
  DeleteSkillCredentialDefinitionUsecase get delete =>
      DeleteSkillCredentialDefinitionUsecase(
        definitionsRepository: definitions,
        credentialsRepository: credentials,
        skillsRepository: skills,
        toolsRepository: tools,
      );

  static Future<_LocalHarness> open() async {
    final database = AppDatabase(
      connection: DatabaseConnection(NativeDatabase.memory()),
    );
    final workspace = await WorkspaceRepository(database)
        .createWorkspace(const .new(name: 'Test Workspace', type: .local));

    return _LocalHarness(
      database: database,
      workspaceId: workspace.id,
      definitions: .new(database),
      credentials: .new(
        database: database,
        encryptionService: .new(_FakeSecretKeyManager()),
      ),
      skills: .new(database),
      tools: .new(database),
    );
  }
}

class _FakeSecretKeyManager() extends SecretKeyManager {
  @override
  Future<SecretKey> getOrCreateSecretKey() async =>
      SecretKey(List<int>.generate(32, (index) => index));
}
