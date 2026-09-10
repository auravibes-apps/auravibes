import 'package:auravibes_app/data/database/drift/app_database.dart';
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

  Future<bool> deleteSkill(String skillId) async {
    final count = await (delete(
      skills,
    )..where((tbl) => tbl.id.equals(skillId))).go();

    return count > 0;
  }
}

extension SkillsDaoQueries on SkillsDao {
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
