import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/daos/skill_credential_definitions_dao.dart';
import 'package:auravibes_app/data/database/drift/tables/skills.dart';
import 'package:drift/drift.dart';

part 'skills_dao.g.dart';

@DriftAccessor(tables: [Skills])
class SkillsDao(super.attachedDatabase)
    extends DatabaseAccessor<AppDatabase>
    with _$SkillsDaoMixin {
  Future<List<SkillsTable>> getWorkspaceSkills(String workspaceId) =>
      (select(skills)
            ..where((tbl) => tbl.workspaceId.equals(workspaceId))
            ..orderBy([(tbl) => OrderingTerm(expression: tbl.title)]))
          .get();

  Future<SkillsTable?> getSkillById(String skillId) => (select(
    skills,
  )..where((tbl) => tbl.id.equals(skillId))).getSingleOrNull();

  Future<SkillsTable?> getSkillBySlug(String workspaceId, String slug) =>
      _getUserSkill(workspaceId, (tbl) => tbl.slug.equals(slug));

  Future<SkillsTable?> getSkillByTitle(String workspaceId, String title) =>
      _getUserSkill(workspaceId, (tbl) => tbl.title.equals(title));

  Future<SkillsTable> createSkill(SkillsCompanion skill) =>
      transaction(() async {
        await attachedDatabase.skillCredentialDefinitionsDao
            .requireOwnedReference(
              skill.workspaceId.value,
              skill.credentialDefinitionId.value,
            );

        return await into(skills).insertReturning(skill);
      });

  Future<SkillsTable> updateSkill(String skillId, SkillsCompanion skill) =>
      transaction(() async {
        final current = await getSkillById(skillId);
        if (current == null) throw StateError('Skill was not found');
        await _requireUpdatedOwnership(current, skill);

        return await _writeSkill(skillId, skill);
      });

  Future<bool> deleteSkill(String skillId) async {
    final count = await (delete(
      skills,
    )..where((tbl) => tbl.id.equals(skillId))).go();

    return count > 0;
  }
}

extension SkillsDaoQueries on SkillsDao {
  Future<SkillsTable> _writeSkill(String skillId, SkillsCompanion skill) async {
    final _ = await (update(
      skills,
    )..where((tbl) => tbl.id.equals(skillId))).write(skill);
    final updated = await getSkillById(skillId);
    if (updated == null) {
      throw StateError('Updated skill was not found');
    }

    return updated;
  }

  Future<void> _requireUpdatedOwnership(
    SkillsTable current,
    SkillsCompanion update,
  ) async {
    final workspaceId = update.workspaceId.present
        ? update.workspaceId.value
        : current.workspaceId;
    await attachedDatabase.skillCredentialDefinitionsDao.requireOwnedReference(
      workspaceId,
      update.credentialDefinitionId.present
          ? update.credentialDefinitionId.value
          : current.credentialDefinitionId,
    );
    if (workspaceId == current.workspaceId) return;
    await _requireToolOwnership(current.id, workspaceId);
  }

  Future<void> _requireToolOwnership(String skillId, String workspaceId) async {
    final tools = await attachedDatabase.skillTemplateToolsDao.getSkillTools(
      skillId,
    );
    for (final tool in tools) {
      await attachedDatabase.skillCredentialDefinitionsDao
          .requireOwnedReference(workspaceId, tool.credentialDefinitionId);
    }
  }

  Future<SkillsTable?> _getUserSkill(
    String workspaceId,
    Expression<bool> Function($SkillsTable) matches,
  ) =>
      (select(skills)
            ..where((tbl) => _userSkillFilter(tbl, workspaceId, matches)))
          .getSingleOrNull();

  Expression<bool> _userSkillFilter(
    $SkillsTable tbl,
    String workspaceId,
    Expression<bool> Function($SkillsTable) matches,
  ) =>
      tbl.workspaceId.equals(workspaceId) &
      matches(tbl) &
      tbl.source.equalsValue(SkillSourceTable.user);
}
