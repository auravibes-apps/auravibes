import 'dart:async';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/skill_credential_definitions_repository.dart';
import 'package:auravibes_app/data/repositories/skill_credentials_repository.dart';
import 'package:auravibes_app/data/repositories/skill_template_tools_repository.dart';
import 'package:auravibes_app/data/repositories/skills_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/features/skills/usecases/check_skill_credential_readiness_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/create_skill_credential_definition_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/create_skill_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/credential_definition_schema.dart';
import 'package:auravibes_app/features/skills/usecases/delete_skill_credential_definition_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/list_credential_definition_usage_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/update_skill_credential_definition_usecase.dart';
import 'package:auravibes_app/services/encryption_service.dart';
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
  test('ownership: public skill create rejects a foreign definition', () async {
    final h = await _LocalHarness.open();
    addTearDown(h.database.close);
    final definition = await h.create.call(
      h.workspaceId,
      const .new(title: 'Owned', attributesJson: _secret),
    );
    final other = await WorkspaceRepository(h.database)
        .createWorkspace(const .new(name: 'Other', type: .local));
    await expectLater(
      CreateSkillUsecase(h.skills).call(
        other.id,
        .new(
          kind: .template,
          title: 'Foreign',
          description: '',
          content: '',
          credentialDefinitionId: definition.id,
        ),
      ),
      throwsStateError,
    );
    expect(await h.skills.getWorkspaceSkills(other.id), isEmpty);
  });
  test(
    'ownership: skill reassignment and tool writes reject foreign definitions',
    () async {
      final h = await _LocalHarness.open();
      addTearDown(h.database.close);
      final definition = await h.create.call(
        h.workspaceId,
        const .new(title: 'Owned', attributesJson: _secret),
      );
      final other = await WorkspaceRepository(h.database)
          .createWorkspace(const .new(name: 'Other', type: .local));
      final skill = await h.skills.createSkill(
        other.id,
        const .new(
          kind: .template,
          title: 'Other skill',
          description: '',
          content: '',
        ),
      );
      await expectLater(
        h.skills.updateSkill(
          skill.id,
          .new(credentialDefinitionId: definition.id),
        ),
        throwsStateError,
      );
      await expectLater(
        h.tools.createTool(
          skill.id,
          .new(
            templateType: .url,
            title: 'Foreign tool',
            description: '',
            templateJson: '{"url":"https://example.com"}',
            inputsJson: '{}',
            credentialDefinitionId: definition.id,
          ),
        ),
        throwsStateError,
      );
      final tool = await h.tools.createTool(
        skill.id,
        const .new(
          templateType: .url,
          title: 'Inherited tool',
          description: '',
          templateJson: '{"url":"https://example.com"}',
          inputsJson: '{}',
        ),
      );
      await expectLater(
        h.tools.updateTool(
          tool.id,
          .new(credentialDefinitionId: definition.id),
        ),
        throwsStateError,
      );
      expect(
        (await h.skills.getSkillById(skill.id))?.credentialDefinitionId,
        null,
      );
      expect(
        (await h.tools.getToolById(tool.id))?.credentialDefinitionId,
        null,
      );
    },
  );
  for (final reference in ['skill', 'tool']) {
    test(
      'ownership: preserves foreign $reference without exposing usage',
      () async {
        final h = await _LocalHarness.open();
        addTearDown(h.database.close);
        final definition = await h.create.call(
          h.workspaceId,
          const .new(title: 'Owned', attributesJson: _secret),
        );
        final other = await WorkspaceRepository(h.database)
            .createWorkspace(const .new(name: 'Other', type: .local));
        final skill = await h.skills.createSkill(
          other.id,
          const .new(
            kind: .template,
            title: 'Private skill',
            description: '',
            content: '',
            isEnabled: false,
          ),
        );
        final tool = await h.tools.createTool(
          skill.id,
          const .new(
            templateType: .url,
            title: 'Private tool',
            description: '',
            templateJson: '{"url":"https://example.com"}',
            inputsJson: '{}',
            isEnabled: false,
          ),
        );
        // Seed invalid legacy ownership outside the guarded public writes.
        if (reference == 'skill') {
          final _ =
              await (h.database.update(
                h.database.skills,
              )..where((t) => t.id.equals(skill.id))).write(
                SkillsCompanion(credentialDefinitionId: .new(definition.id)),
              );
        } else {
          final _ =
              await (h.database.update(
                h.database.skillTemplateTools,
              )..where((t) => t.id.equals(tool.id))).write(
                SkillTemplateToolsCompanion(
                  credentialDefinitionId: .new(definition.id),
                ),
              );
        }
        expect(
          (await h.definitions.getUsage(h.workspaceId, definition.id)).isEmpty,
          isTrue,
        );
        await expectLater(
          h.definitions.deleteDefinition(definition.id),
          throwsA(isA<CredentialDefinitionConflictException>()),
        );
        expect(await h.definitions.getDefinitionById(definition.id), isNotNull);
        final saved = reference == 'skill'
            ? (await h.skills.getSkillById(skill.id))?.credentialDefinitionId
            : (await h.tools.getToolById(tool.id))?.credentialDefinitionId;
        expect(saved, definition.id);
      },
    );
  }

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
          (variable: 'replacement', kind: CredentialSchemaChangeKind.required),
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

  test('usage reads disabled metadata and overrides without secrets', () async {
    final harness = await _LocalHarness.open();
    addTearDown(harness.database.close);
    final definition = await harness.create.call(
      harness.workspaceId,
      const .new(title: 'Usage', attributesJson: _secret),
    );
    final other = await harness.create.call(
      harness.workspaceId,
      const .new(title: 'Other', attributesJson: _secret),
    );
    final credential = await harness.credentials.createCredential(
      harness.workspaceId,
      .new(
        credentialDefinitionId: definition.id,
        name: 'Saved secret',
        attributes: const {'token': 'test'},
      ),
    );
    final _ = await harness.database.skillCredentialsDao.updateCredential(
      credential.id,
      const .new(
        isEnabled: .new(false),
        encryptedAuthValue: .new('must not decrypt'),
        metadataJson: .new('must not decode'),
      ),
    );
    final skill = await harness.skills.createSkill(
      harness.workspaceId,
      .new(
        kind: .template,
        title: 'Disabled skill',
        description: '',
        content: '',
        credentialDefinitionId: definition.id,
      ),
    );
    final _ = await harness.skills.updateSkill(
      skill.id,
      const .new(isEnabled: false),
    );
    final inherited = await harness.tools.createTool(
      skill.id,
      const .new(
        templateType: .url,
        title: 'Inherited',
        description: '',
        templateJson: '{"url":"https://example.com"}',
        inputsJson: '{}',
      ),
    );
    final _ = await harness.tools.updateTool(
      inherited.id,
      const .new(isEnabled: false),
    );
    final _ = await harness.tools.createTool(
      skill.id,
      .new(
        templateType: .url,
        title: 'Override',
        description: '',
        templateJson: '{"url":"https://example.com"}',
        inputsJson: '{}',
        credentialDefinitionId: other.id,
      ),
    );
    final usage = await ListCredentialDefinitionUsageUsecase(
      definitionsRepository: harness.definitions,
    ).call(workspaceId: harness.workspaceId, definitionId: definition.id);
    expect(usage.credentials.single.id, credential.id);
    expect(usage.credentials.single.title, 'Saved secret');
    expect(usage.credentials.single.isEnabled, isFalse);
    expect(usage.skills.single.id, skill.id);
    expect(usage.skills.single.isEnabled, isFalse);
    expect(usage.tools.single.id, inherited.id);
    expect(usage.tools.single.parentSkillId, skill.id);
    expect(usage.tools.single.isEnabled, isFalse);
    final secretFree = SkillCredentialsRepository(
      database: harness.database,
      encryptionService: _ThrowingEncryptionService(),
    );
    expect(
      (await secretFree.getLinkedCredentialSummaries(
        workspaceId: harness.workspaceId,
        credentialDefinitionId: definition.id,
      )).single.id,
      credential.id,
    );
    final _ = await harness.database.skillCredentialsDao.updateCredential(
      credential.id,
      const .new(metadataJson: .new('{}')),
    );
    await expectLater(
      secretFree.readCredentialAttributes(credential.id),
      throwsStateError,
    );
    await expectLater(
      ListCredentialDefinitionUsageUsecase(
        definitionsRepository: harness.definitions,
      ).call(workspaceId: 'another-workspace', definitionId: definition.id),
      throwsStateError,
    );
  });

  test(
    'local mutation waits for credential creation and rechecks usage',
    () async {
      final harness = await _LocalHarness.open();
      addTearDown(harness.database.close);
      final definition = await harness.create.call(
        harness.workspaceId,
        const .new(title: 'Race', attributesJson: _secret),
      );
      final encryption = _PausedEncryptionService();
      final repository = SkillCredentialsRepository(
        database: harness.database,
        encryptionService: encryption,
      );
      final creating = repository.createCredential(
        harness.workspaceId,
        .new(
          credentialDefinitionId: definition.id,
          name: 'Racing credential',
          attributes: const {'token': 'fixture'},
        ),
      );
      await encryption.started.future;
      final deleting = expectLater(
        harness.database.skillCredentialDefinitionsDao.deleteDefinition(
          definition.id,
        ),
        throwsA(isA<CredentialDefinitionConflictException>()),
      );
      final updating = expectLater(
        harness.database.skillCredentialDefinitionsDao.updateDefinition(
          definition.id,
          const .new(attributesJson: .new('{"token":{},"added":{}}')),
        ),
        throwsA(isA<CredentialDefinitionConflictException>()),
      );
      encryption.release.complete();
      final _ = await creating;
      await deleting;
      await updating;
      expect(
        (await harness.definitions.getDefinitionById(definition.id))
            ?.attributesJson,
        _secret,
      );
    },
  );

  test('deleted local definitions cannot accept new credential rows', () async {
    final harness = await _LocalHarness.open();
    addTearDown(harness.database.close);
    final definition = await harness.create.call(
      harness.workspaceId,
      const .new(title: 'Deleted', attributesJson: _secret),
    );
    expect(await harness.definitions.deleteDefinition(definition.id), isTrue);
    await expectLater(
      harness.credentials.createCredential(
        harness.workspaceId,
        .new(
          credentialDefinitionId: definition.id,
          name: 'Too late',
          attributes: const {'token': 'fixture'},
        ),
      ),
      throwsA(isA<SkillCredentialsException>()),
    );
    expect(
      await harness.credentials.countLinkedCredentials(
        workspaceId: harness.workspaceId,
        credentialDefinitionId: definition.id,
      ),
      0,
    );
  });

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

  test('destructive edits reject linked credentials without writing', () async {
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
        schema:
            '{"token":{"optional":true},"region":{"secret":false},"newKey":{}}',
        kind: CredentialSchemaChangeKind.required,
      ),
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
      await expectLater(
        harness.definitions.updateDefinition(
          definition.id,
          .new(attributesJson: schema),
        ),
        throwsA(isA<CredentialDefinitionConflictException>()),
      );
      expect(
        (await harness.definitions.getDefinitionById(definition.id))
            ?.attributesJson,
        _mixed,
      );
    }
  });

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
      await expectLater(
        harness.delete.call(definition.id),
        throwsA(isA<CredentialDefinitionConflictException>()),
      );
      await expectLater(
        harness.definitions.deleteDefinition(definition.id),
        throwsA(isA<CredentialDefinitionConflictException>()),
      );
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

class _ThrowingEncryptionService extends EncryptionService {
  new() : super(_FakeSecretKeyManager());
  @override
  Future<String> decrypt(String encryptedBase64) =>
      throw StateError('Secret reads forbidden');
}

class _PausedEncryptionService extends EncryptionService {
  new() : super(_FakeSecretKeyManager());
  final started = Completer<void>();
  final release = Completer<void>();
  @override
  Future<String> encrypt(String plaintext) async {
    started.complete();
    await release.future;

    return await super.encrypt(plaintext);
  }
}
