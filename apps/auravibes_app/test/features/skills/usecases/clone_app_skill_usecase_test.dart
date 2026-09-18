import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/skill_credential_definitions_repository.dart';
import 'package:auravibes_app/data/repositories/skill_template_tools_repository.dart';
import 'package:auravibes_app/data/repositories/skills_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/features/skills/usecases/clone_app_skill_usecase.dart';
import 'package:auravibes_app/services/skills/app_skill_registry.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:test/test.dart';

void main() {
  test('clones declarative app skills without credential values', () async {
    final database = AppDatabase(
      connection: DatabaseConnection(NativeDatabase.memory()),
    );
    addTearDown(database.close);
    final workspace = await WorkspaceRepository(database).createWorkspace(
      const WorkspaceToCreate(name: 'Test Workspace', type: .local),
    );
    final skillsRepository = SkillsRepository(database);
    final definitionsRepository = SkillCredentialDefinitionsRepository(
      database,
    );
    final toolsRepository = SkillTemplateToolsRepository(database);
    final usecase = CloneAppSkillUsecase(
      const AppSkillRegistry(),
      skillsRepository,
      .new(skillsRepository),
      .new(definitionsRepository),
      .new(
        toolsRepository,
        skillsRepository: skillsRepository,
        skillCredentialDefinitionsRepository: definitionsRepository,
      ),
    );

    final cloned = await usecase.call(workspace.id, 'brave');

    expect(cloned.kind, SkillKind.template);
    expect(cloned.title, 'Brave Search Copy');
    final tools = await toolsRepository.getSkillTools(cloned.id);
    expect(tools, isNotEmpty);
    for (final tool in tools) {
      expect(tool.definitionJson, contains('"version":1'));
      final credentialDefinitionId = tool.credentialDefinitionId;
      if (credentialDefinitionId == null) {
        fail('Cloned tool must have a credential definition.');
      }
      final definition = await definitionsRepository.getDefinitionById(
        credentialDefinitionId,
      );
      if (definition == null) {
        fail('Cloned credential definition must be persisted.');
      }
      final attributes =
          jsonDecode(definition.attributesJson) as Map<String, Object?>;
      expect(attributes.values, everyElement(isA<Map<String, Object?>>()));
      expect(attributes.values, everyElement(isNot(contains('value'))));
    }
  });

  test('does not clone native app controls', () async {
    final database = AppDatabase(
      connection: DatabaseConnection(NativeDatabase.memory()),
    );
    addTearDown(database.close);
    final workspace = await WorkspaceRepository(database).createWorkspace(
      const WorkspaceToCreate(name: 'Test Workspace', type: .local),
    );
    final skillsRepository = SkillsRepository(database);
    final definitionsRepository = SkillCredentialDefinitionsRepository(
      database,
    );
    final usecase = CloneAppSkillUsecase(
      const AppSkillRegistry(),
      skillsRepository,
      .new(skillsRepository),
      .new(definitionsRepository),
      .new(
        .new(database),
        skillsRepository: skillsRepository,
        skillCredentialDefinitionsRepository: definitionsRepository,
      ),
    );

    final _ = await expectLater(
      usecase.call(workspace.id, 'skills_manager'),
      throwsA(isA<StateError>()),
    );
  });
}
