import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/daos/skill_credential_definitions_dao.dart';
import 'package:auravibes_app/data/database/drift/tables/skill_template_tools.dart';
import 'package:drift/drift.dart';

part 'skill_template_tools_dao.g.dart';

@DriftAccessor(tables: [SkillTemplateTools])
class SkillTemplateToolsDao(super.attachedDatabase)
    extends DatabaseAccessor<AppDatabase>
    with _$SkillTemplateToolsDaoMixin {
  Future<List<SkillTemplateToolsTable>> getSkillTools(String skillId) =>
      (select(skillTemplateTools)
            ..where((tbl) => tbl.skillId.equals(skillId))
            ..orderBy([(tbl) => OrderingTerm(expression: tbl.title)]))
          .get();

  Future<SkillTemplateToolsTable?> getToolById(String toolId) => (select(
    skillTemplateTools,
  )..where((tbl) => tbl.id.equals(toolId))).getSingleOrNull();

  Future<SkillTemplateToolsTable?> getToolBySlug(String skillId, String slug) =>
      (select(skillTemplateTools)..where(
            (tbl) => tbl.skillId.equals(skillId) & tbl.slug.equals(slug),
          ))
          .getSingleOrNull();

  Future<SkillTemplateToolsTable> createTool(
    SkillTemplateToolsCompanion tool,
  ) => transaction(() async {
    await _requireOwnedReference(
      tool.skillId.value,
      tool.credentialDefinitionId.value,
    );

    return await into(skillTemplateTools).insertReturning(tool);
  });

  Future<SkillTemplateToolsTable> updateTool(
    String toolId,
    SkillTemplateToolsCompanion tool,
  ) => transaction(() async {
    final current = await getToolById(toolId);
    if (current == null) throw StateError('Skill template tool was not found');
    await _requireUpdatedOwnership(current, tool);

    return await _writeTool(toolId, tool);
  });

  Future<bool> deleteTool(String toolId) async {
    final count = await (delete(
      skillTemplateTools,
    )..where((tbl) => tbl.id.equals(toolId))).go();

    return count > 0;
  }
}

extension SkillTemplateToolOwnership on SkillTemplateToolsDao {
  Future<void> _requireUpdatedOwnership(
    SkillTemplateToolsTable current,
    SkillTemplateToolsCompanion update,
  ) => _requireOwnedReference(
    update.skillId.present ? update.skillId.value : current.skillId,
    update.credentialDefinitionId.present
        ? update.credentialDefinitionId.value
        : current.credentialDefinitionId,
  );

  Future<SkillTemplateToolsTable> _writeTool(
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

  Future<void> _requireOwnedReference(
    String skillId,
    String? definitionId,
  ) async {
    final parent = await attachedDatabase.skillsDao.getSkillById(skillId);
    if (parent == null) throw StateError('Skill was not found');
    await attachedDatabase.skillCredentialDefinitionsDao.requireOwnedReference(
      parent.workspaceId,
      definitionId ?? parent.credentialDefinitionId,
    );
  }
}
