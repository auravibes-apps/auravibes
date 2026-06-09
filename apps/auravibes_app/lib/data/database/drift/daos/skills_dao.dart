// ignore_for_file: prefer-async-await
// Required: Existing Future chains preserve callback flow.
// Required: Existing test and UI helpers keep compact return flow.
import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/skills.dart';
import 'package:drift/drift.dart';

part 'skills_dao.g.dart';

@DriftAccessor(tables: [Skills])
class SkillsDao extends DatabaseAccessor<AppDatabase> with _$SkillsDaoMixin {
  SkillsDao(super.attachedDatabase);

  Future<List<SkillsTable>> getWorkspaceSkills(String workspaceId) =>
      (select(skills)
            ..where((tbl) => tbl.workspaceId.equals(workspaceId))
            ..orderBy([(tbl) => OrderingTerm(expression: tbl.title)]))
          .get();

  Future<SkillsTable?> getSkillById(String skillId) => (select(
    skills,
  )..where((tbl) => tbl.id.equals(skillId))).getSingleOrNull();

  Future<SkillsTable?> getSkillBySlug(String workspaceId, String slug) =>
      (select(skills)..where(
            (tbl) =>
                tbl.workspaceId.equals(workspaceId) &
                tbl.slug.equals(slug) &
                tbl.source.equalsValue(SkillSourceTable.user),
          ))
          .getSingleOrNull();

  Future<SkillsTable?> getSkillByTitle(String workspaceId, String title) =>
      (select(skills)..where(
            (tbl) =>
                tbl.workspaceId.equals(workspaceId) &
                tbl.title.equals(title) &
                tbl.source.equalsValue(SkillSourceTable.user),
          ))
          .getSingleOrNull();

  Future<SkillsTable> createSkill(SkillsCompanion skill) =>
      into(skills).insertReturning(skill);

  Future<SkillsTable> updateSkill(String skillId, SkillsCompanion skill) async {
    final _ = await (update(
      skills,
    )..where((tbl) => tbl.id.equals(skillId))).write(skill);
    final updated = await getSkillById(skillId);
    if (updated == null) {
      throw StateError('Updated skill was not found');
    }

    return updated;
  }

  Future<bool> deleteSkill(String skillId) => (delete(
    skills,
  )..where((tbl) => tbl.id.equals(skillId))).go().then((count) => count > 0);
}
