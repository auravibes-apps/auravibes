import 'package:auravibes_app/domain/entities/skill_template_tool_entity.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'skill_template_tools_provider.g.dart';

@riverpod
Future<List<SkillTemplateToolEntity>> skillTemplateTools(
  Ref ref,
  String skillId,
) {
  return ref.watch(skillTemplateToolsRepositoryProvider).getSkillTools(skillId);
}

@riverpod
Future<SkillTemplateToolEntity?> skillTemplateTool(
  Ref ref,
  String toolId,
) {
  return ref.watch(skillTemplateToolsRepositoryProvider).getToolById(toolId);
}
