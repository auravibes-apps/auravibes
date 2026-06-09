import 'package:auravibes_app/domain/entities/skill_template_tool_entity.dart';

abstract class SkillTemplateToolsRepository {
  Future<List<SkillTemplateToolEntity>> getSkillTools(String skillId);

  Future<SkillTemplateToolEntity?> getToolById(String toolId);

  Future<SkillTemplateToolEntity?> getToolBySlug(String skillId, String slug);

  Future<SkillTemplateToolEntity> createTool(
    String skillId,
    SkillTemplateToolToCreate tool,
  );

  Future<SkillTemplateToolEntity> updateTool(
    String toolId,
    SkillTemplateToolToUpdate tool,
  );

  Future<bool> deleteTool(String toolId);
}
