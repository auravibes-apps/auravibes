import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/skills_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/features/skills/usecases/create_skill_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/update_skill_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/validate_skill_title_usecase.dart';
import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../database/drift/database_test_utils.dart';

void main() {
  final database = AppDatabase(
    connection: DatabaseConnection(NativeDatabase.memory()),
  );

  setUp(() async => clearAppDatabase(database));
  tearDownAll(database.close);

  test('persists normalized Connector tool references', () async {
    final workspace = await WorkspaceRepository(database).createWorkspace(
      const WorkspaceToCreate(name: 'Workspace', type: .local),
    );
    final repository = SkillsRepository(database);
    final created = await CreateSkillUsecase(repository).call(
      workspace.id,
      const SkillToCreate(
        kind: .template,
        title: 'CRM workflow',
        description: 'Use Notion for CRM.',
        content: 'Search before creating records.',
        connectorToolIds: [
          'connector/notion/search',
          'connector/gmail/send',
          ' connector/notion/search ',
        ],
      ),
    );

    expect(created.connectorToolIds, [
      'connector/gmail/send',
      'connector/notion/search',
    ]);
    expect(
      (await repository.getSkillById(created.id))?.connectorToolIds,
      created.connectorToolIds,
    );

    final updated = await UpdateSkillUsecase(repository).call(
      created.id,
      const SkillToUpdate(
        connectorToolIds: ['connector/notion/search'],
      ),
    );

    expect(updated.connectorToolIds, ['connector/notion/search']);
  });

  test('partial Skill updates keep Connector references', () async {
    final workspace = await WorkspaceRepository(database).createWorkspace(
      const WorkspaceToCreate(name: 'Workspace', type: .local),
    );
    final repository = SkillsRepository(database);
    final created = await repository.createSkill(
      workspace.id,
      const SkillToCreate(
        kind: .template,
        title: 'CRM workflow',
        description: 'Use Notion for CRM.',
        content: 'Search before creating records.',
        connectorToolIds: ['connector/notion/search'],
      ),
    );

    final updated = await repository.updateSkill(
      created.id,
      const SkillToUpdate(title: 'CRM assistant'),
    );

    expect(updated.title, 'CRM assistant');
    expect(updated.connectorToolIds, ['connector/notion/search']);
  });

  test('rejects invalid and duplicate Skill titles', () async {
    final workspace = await WorkspaceRepository(database).createWorkspace(
      const WorkspaceToCreate(name: 'Workspace', type: .local),
    );
    final create = CreateSkillUsecase(SkillsRepository(database));
    const skill = SkillToCreate(
      kind: .template,
      title: 'CRM workflow',
      description: 'Use Notion for CRM.',
      content: 'Search before creating records.',
    );
    await create.call(workspace.id, skill);

    await expectLater(
      create.call(
        workspace.id,
        const SkillToCreate(
          kind: .template,
          title: 'Bad/Title',
          description: 'Invalid title',
          content: 'Invalid title',
        ),
      ),
      throwsA(isA<SkillTitleValidationException>()),
    );
    await expectLater(
      create.call(workspace.id, skill),
      throwsA(isA<SkillTitleValidationException>()),
    );
  });
}
