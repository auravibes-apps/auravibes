import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/skill_resources_repository.dart';
import 'package:auravibes_app/data/repositories/skills_repository.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/domain/entities/skill_resource_entity.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('creates, updates, finds, and deletes skill resources', () async {
    final fixture = await _createFixture();
    addTearDown(fixture.database.close);

    final created = await fixture.resources.createResource(
      fixture.skillId,
      const SkillResourceToCreate(
        title: 'Refund Policy',
        description: 'Rules',
        content: '# Refunds',
      ),
    );

    expect(created.slug, 'refund_policy');
    expect(
      (await fixture.resources.getResourceBySlug(
        fixture.skillId,
        created.slug,
      ))?.content,
      '# Refunds',
    );

    final updated = await fixture.resources.updateResource(
      created.id,
      const SkillResourceToUpdate(title: 'Refund Rules', content: 'Updated'),
    );
    expect(updated.slug, created.slug);
    expect(updated.content, 'Updated');

    expect(await fixture.resources.deleteResource(created.id), isTrue);
    expect(await fixture.resources.getResourceById(created.id), isNull);
  });

  test('cascades resources when the parent skill is deleted', () async {
    final fixture = await _createFixture();
    addTearDown(fixture.database.close);

    final created = await fixture.resources.createResource(
      fixture.skillId,
      const SkillResourceToCreate(
        title: 'Guide',
        description: '',
        content: 'Content',
      ),
    );

    expect(await fixture.skills.deleteSkill(fixture.skillId), isTrue);
    expect(await fixture.resources.getResourceById(created.id), isNull);
  });
}

Future<
  ({
    AppDatabase database,
    SkillsRepository skills,
    SkillResourcesRepository resources,
    String skillId,
  })
>
_createFixture() async {
  final database = AppDatabase(
    connection: DatabaseConnection(NativeDatabase.memory()),
  );
  final workspace = await database.workspaceDao.insertWorkspace(
    .insert(name: 'Workspace', type: .local),
  );
  final skills = SkillsRepository(database);
  final resources = SkillResourcesRepository(database);
  final skill = await skills.createSkill(
    workspace.id,
    const SkillToCreate(
      kind: .template,
      title: 'Support',
      description: '',
      content: 'Instructions',
    ),
  );

  return (
    database: database,
    skills: skills,
    resources: resources,
    skillId: skill.id,
  );
}
