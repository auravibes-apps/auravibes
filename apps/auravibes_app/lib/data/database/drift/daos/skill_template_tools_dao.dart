// ignore_for_file: prefer-async-await
// Required: Existing Future chains preserve callback flow.
// ignore_for_file: format-comment
// Required: Existing comments use generated or domain-specific formatting.
// ignore_for_file: newline-before-return
// Required: Existing test and UI helpers keep compact return flow.
import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/skill_template_tools.dart';
import 'package:drift/drift.dart';

part 'skill_template_tools_dao.g.dart';

@DriftAccessor(tables: [SkillTemplateTools])
class SkillTemplateToolsDao extends DatabaseAccessor<AppDatabase>
    with _$SkillTemplateToolsDaoMixin {
  SkillTemplateToolsDao(super.attachedDatabase);

  Future<List<SkillTemplateToolsTable>> getSkillTools(String skillId) =>
      (select(skillTemplateTools)
            ..where((tbl) => tbl.skillId.equals(skillId))
            ..orderBy([(tbl) => OrderingTerm(expression: tbl.title)]))
          .get();

  Future<SkillTemplateToolsTable?> getToolById(String toolId) => (select(
    skillTemplateTools,
  )..where((tbl) => tbl.id.equals(toolId))).getSingleOrNull();

  Future<SkillTemplateToolsTable?> getToolBySlug(
    String skillId,
    String slug,
  ) =>
      (select(skillTemplateTools)..where(
            (tbl) => tbl.skillId.equals(skillId) & tbl.slug.equals(slug),
          ))
          .getSingleOrNull();

  Future<SkillTemplateToolsTable> createTool(
    SkillTemplateToolsCompanion tool,
  ) => into(skillTemplateTools).insertReturning(tool);

  Future<SkillTemplateToolsTable> updateTool(
    String toolId,
    SkillTemplateToolsCompanion tool,
  ) async {
    final _ = await (update(
      skillTemplateTools,
    )..where((tbl) => tbl.id.equals(toolId))).write(tool);
    final updated = await getToolById(toolId);
    if (updated == null) {
      throw StateError('Updated skill template tool was not found');
    }
    return updated;
  }

  Future<bool> deleteTool(String toolId) => (delete(
    skillTemplateTools,
  )..where((tbl) => tbl.id.equals(toolId))).go().then((count) => count > 0);
}
