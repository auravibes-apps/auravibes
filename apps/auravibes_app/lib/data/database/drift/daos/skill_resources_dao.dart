import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/skill_resources.dart';
import 'package:drift/drift.dart';

part 'skill_resources_dao.g.dart';

@DriftAccessor(tables: [SkillResources])
class SkillResourcesDao(super.attachedDatabase)
    extends DatabaseAccessor<AppDatabase>
    with _$SkillResourcesDaoMixin {
  Future<List<SkillResourcesTable>> getSkillResources(String skillId) =>
      (select(skillResources)
            ..where((tbl) => tbl.skillId.equals(skillId))
            ..orderBy([(tbl) => OrderingTerm(expression: tbl.title)]))
          .get();

  Future<SkillResourcesTable?> getResourceById(String resourceId) => (select(
    skillResources,
  )..where((tbl) => tbl.id.equals(resourceId))).getSingleOrNull();

  Future<SkillResourcesTable?> getResourceBySlug(String skillId, String slug) =>
      (select(skillResources)..where(
            (tbl) => tbl.skillId.equals(skillId) & tbl.slug.equals(slug),
          ))
          .getSingleOrNull();

  Future<int> deleteSkillResources(String skillId) => (delete(
    skillResources,
  )..where((tbl) => tbl.skillId.equals(skillId))).go();

  Future<SkillResourcesTable> createResource(SkillResourcesCompanion value) =>
      into(skillResources).insertReturning(value);

  Future<SkillResourcesTable> updateResource(
    String resourceId,
    SkillResourcesCompanion value,
  ) async {
    final _ = await (update(
      skillResources,
    )..where((tbl) => tbl.id.equals(resourceId))).write(value);
    final updated = await getResourceById(resourceId);
    if (updated == null) {
      throw StateError('Updated skill resource was not found');
    }

    return updated;
  }

  Future<bool> deleteResource(String resourceId) async {
    final count = await (delete(
      skillResources,
    )..where((tbl) => tbl.id.equals(resourceId))).go();

    return count > 0;
  }
}
