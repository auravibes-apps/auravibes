import 'package:auravibes_app/domain/entities/skill_template_tool_entity.dart';
import 'package:auravibes_app/features/skills/providers/cloud_skill_store_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'skill_template_tools_provider.g.dart';

@riverpod
Future<List<SkillTemplateToolEntity>> skillTemplateTools(
  Ref ref,
  String workspaceId,
  String skillId,
) {
  final cloud = ref.watch(cloudSkillStoreProvider(workspaceId));
  if (cloud != null) return cloud.tools(skillId);

  return ref.watch(skillTemplateToolsRepositoryProvider).getSkillTools(skillId);
}

@riverpod
// ignore: prefer-static-class (required framework top-level declaration)
Future<SkillTemplateToolEntity?> skillTemplateTool(
  Ref ref,
  String workspaceId,
  String toolId,
) {
  final cloud = ref.watch(cloudSkillStoreProvider(workspaceId));
  if (cloud != null) return cloud.tool(toolId);

  return ref.watch(skillTemplateToolsRepositoryProvider).getToolById(toolId);
}
