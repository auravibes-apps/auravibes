// Required: Tests use numeric fixtures.

import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/skill_credential_definitions_repository.dart';
import 'package:auravibes_app/data/repositories/skill_credentials_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/features/skills/usecases/create_skill_credential_definition_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/duplicate_credential_definition_usecase.dart';
import 'package:auravibes_app/services/secret_key_manager.dart';
import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'duplicates schema with a unique title but not credential values',
    () async {
      final database = AppDatabase(
        connection: DatabaseConnection(NativeDatabase.memory()),
      );
      addTearDown(database.close);
      final workspace = await WorkspaceRepository(database)
          .createWorkspace(const .new(name: 'Test Workspace', type: .local));
      final definitionsRepository = SkillCredentialDefinitionsRepository(
        database,
      );
      final createUsecase = CreateSkillCredentialDefinitionUsecase(
        definitionsRepository,
      );
      final duplicateUsecase = DuplicateCredentialDefinitionUsecase(
        definitionsRepository,
        createSkillCredentialDefinitionUsecase: createUsecase,
      );
      final credentialsRepository = SkillCredentialsRepository(
        database: database,
        encryptionService: .new(_FakeSecretKeyManager()),
      );
      final source = await createUsecase.call(
        workspace.id,
        const .new(
          title: 'Example Service',
          attributesJson: '{"api_key":{"description":"API key"}}',
        ),
      );
      final _ = await createUsecase.call(
        workspace.id,
        const .new(
          title: 'Example Service Copy',
          attributesJson: '{"other":{"description":"Other"}}',
        ),
      );
      final credential = await credentialsRepository.createCredential(
        workspace.id,
        .new(
          credentialDefinitionId: source.id,
          name: 'Production',
          attributes: const {'api_key': 'secret-token'},
        ),
      );

      final duplicate = await duplicateUsecase.call(source.id);

      expect(duplicate.title, 'Example Service Copy 2');
      expect(duplicate.slug, 'example_service_copy_2');
      expect(
        jsonDecode(duplicate.attributesJson),
        jsonDecode(source.attributesJson),
      );
      expect(
        await credentialsRepository.getCredentialsForDefinition(
          workspaceId: workspace.id,
          credentialDefinitionId: duplicate.id,
        ),
        isEmpty,
      );
      expect(
        await credentialsRepository.readCredentialAttributes(credential.id),
        const {'api_key': 'secret-token'},
      );
    },
  );
}

class _FakeSecretKeyManager() extends SecretKeyManager {
  @override
  Future<SecretKey> getOrCreateSecretKey() async {
    return SecretKey(List<int>.generate(32, (index) => index));
  }
}
