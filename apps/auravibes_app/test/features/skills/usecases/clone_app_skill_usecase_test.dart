import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/skill_resources_repository.dart';
import 'package:auravibes_app/data/repositories/skills_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/features/skills/usecases/clone_app_skill_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/create_skill_usecase.dart';
import 'package:auravibes_app/services/skills/app_skill_registry.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:test/test.dart';

import '../../../data/database/drift/database_test_utils.dart';

void main() {
  final database = AppDatabase(
    connection: DatabaseConnection(NativeDatabase.memory()),
  );
  setUp(() => clearAppDatabase(database));
  tearDownAll(database.close);

  test('clones Connector tool references and Skill resources', () async {
    final workspace = await WorkspaceRepository(database).createWorkspace(
      const WorkspaceToCreate(name: 'Test Workspace', type: .local),
    );
    final skillsRepository = SkillsRepository(database);
    final resourcesRepository = SkillResourcesRepository(database);
    final registry = const AppSkillRegistry();
    final appSkill = registry.getBySlug('brave');
    if (appSkill == null) fail('Brave Skill fixture is missing.');
    final usecase = CloneAppSkillUsecase(
      registry,
      skillsRepository,
      CreateSkillUsecase(skillsRepository),
      resourceRepository: resourcesRepository,
    );

    final cloned = await usecase.call(workspace.id, 'brave');

    expect(cloned.kind, SkillKind.template);
    expect(cloned.title, 'Brave Search Copy');
    expect(cloned.connectorToolIds, appSkill.connectorToolIds);
    expect(await resourcesRepository.getSkillResources(cloned.id), hasLength(1));
  });

  test('does not clone native app controls', () async {
    final workspace = await WorkspaceRepository(database).createWorkspace(
      const WorkspaceToCreate(name: 'Test Workspace', type: .local),
    );
    final skillsRepository = SkillsRepository(database);
    final usecase = CloneAppSkillUsecase(
      const AppSkillRegistry(),
      skillsRepository,
      CreateSkillUsecase(skillsRepository),
      resourceRepository: SkillResourcesRepository(database),
    );

    expect(
      () => usecase.call(workspace.id, 'skills_manager'),
      throwsA(isA<StateError>()),
    );
  });
}
