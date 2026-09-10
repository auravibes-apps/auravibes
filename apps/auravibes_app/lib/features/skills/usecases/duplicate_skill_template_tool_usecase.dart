import 'package:auravibes_app/data/repositories/skill_template_tools_repository.dart';
import 'package:auravibes_app/domain/entities/skill_template_tool_entity.dart';
import 'package:auravibes_app/features/skills/providers/cloud_skill_store_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/services/cloud_skill_store.dart';
import 'package:auravibes_app/features/skills/usecases/create_skill_template_tool_usecase.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:riverpod/riverpod.dart';

class const DuplicateSkillTemplateToolUsecase(
  final SkillTemplateToolsRepository? _skillTemplateToolsRepository, {
  required final CreateSkillTemplateToolUsecase createSkillTemplateToolUsecase,
  final CloudSkillStore? cloudStore,
}) {
  Future<SkillTemplateToolEntity> call(String toolId) async {
    final tool = await _loadTool(toolId);
    final title = await _copyTitle(tool);

    return _createTool(tool, title);
  }

  Future<SkillTemplateToolEntity> _loadTool(String toolId) async {
    final cloud = cloudStore;
    final tool = cloud != null
        ? await cloud.tool(toolId)
        : await _skillTemplateToolsRepository?.getToolById(toolId);
    if (tool == null) {
      throw StateError('Skill template tool not found: $toolId');
    }

    return tool;
  }

  Future<SkillTemplateToolEntity> _createTool(
    SkillTemplateToolEntity tool,
    String title,
  ) {
    return createSkillTemplateToolUsecase.call(
      tool.skillId,
      .new(
        templateType: tool.templateType,
        title: title,
        description: tool.description,
        templateJson: tool.templateJson,
        inputsJson: tool.inputsJson,
        isEnabled: tool.isEnabled,
      ),
    );
  }

  Future<String> _copyTitle(SkillTemplateToolEntity tool) async {
    for (var suffix = 1; ; suffix++) {
      final title = _copyTitleValue(tool.title, suffix);
      if (!await _titleExists(tool.skillId, generateSkillSlug(title))) {
        return title;
      }
    }
  }

  String _copyTitleValue(String originalTitle, int suffix) =>
      suffix == 1 ? '$originalTitle Copy' : '$originalTitle Copy $suffix';

  Future<bool> _titleExists(String skillId, String slug) {
    final cloud = cloudStore;
    if (cloud != null) return _cloudTitleExists(cloud, skillId, slug);

    return _localTitleExists(skillId, slug);
  }

  Future<bool> _cloudTitleExists(
    CloudSkillStore cloud,
    String skillId,
    String slug,
  ) async => (await cloud.tools(skillId)).any((item) => item.slug == slug);

  Future<bool> _localTitleExists(String skillId, String slug) async {
    final repository = _skillTemplateToolsRepository;
    if (repository == null) {
      throw StateError('Skill template tool store is unavailable');
    }

    return await repository.getToolBySlug(skillId, slug) != null;
  }
}

final ProviderFamily<DuplicateSkillTemplateToolUsecase, String>
duplicateSkillTemplateToolUsecaseProvider =
    Provider.family<DuplicateSkillTemplateToolUsecase, String>((
      ref,
      workspaceId,
    ) {
      final cloud = ref.watch(cloudSkillStoreProvider(workspaceId));

      return DuplicateSkillTemplateToolUsecase(
        cloud == null ? ref.watch(skillTemplateToolsRepositoryProvider) : null,
        createSkillTemplateToolUsecase: ref.watch(
          createSkillTemplateToolUsecaseProvider(workspaceId),
        ),
        cloudStore: cloud,
      );
    });
