// ignore_for_file: implementation_imports
import 'package:auravibes_app/data/repositories/skill_template_tools_repository.dart';
import 'package:auravibes_app/domain/entities/skill_template_tool_entity.dart';
import 'package:auravibes_app/features/skills/providers/cloud_skill_store_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/services/cloud_skill_store.dart';
import 'package:auravibes_app/features/skills/usecases/create_skill_template_tool_usecase.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:riverpod/src/providers/provider.dart';

class DuplicateSkillTemplateToolUsecase {
  const DuplicateSkillTemplateToolUsecase(
    this._skillTemplateToolsRepository, {
    required this.createSkillTemplateToolUsecase,
    this.cloudStore,
  });

  final SkillTemplateToolsRepository? _skillTemplateToolsRepository;
  final CreateSkillTemplateToolUsecase createSkillTemplateToolUsecase;
  final CloudSkillStore? cloudStore;

  Future<SkillTemplateToolEntity> call(String toolId) async {
    final cloud = cloudStore;
    final tool = cloud != null
        ? await cloud.tool(toolId)
        : await _skillTemplateToolsRepository?.getToolById(toolId);
    if (tool == null) {
      throw StateError('Skill template tool not found: $toolId');
    }

    final title = await _copyTitle(tool);

    return createSkillTemplateToolUsecase.call(
      tool.skillId,
      SkillTemplateToolToCreate(
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
    var suffix = 1;
    while (true) {
      final title = suffix == 1
          ? '${tool.title} Copy'
          : '${tool.title} Copy $suffix';
      final slug = generateSkillSlug(title);
      final cloud = cloudStore;
      final repository = _skillTemplateToolsRepository;
      final existing = switch ((cloud: cloud, repository: repository)) {
        (cloud: final cloud?, repository: _) => (await cloud.tools(
          tool.skillId,
        )).where((item) => item.slug == slug).firstOrNull,
        (cloud: _, repository: final repository?) =>
          await repository.getToolBySlug(
            tool.skillId,
            slug,
          ),
        _ => throw StateError('Skill template tool store is unavailable'),
      };
      if (existing == null) return title;
      suffix += 1;
    }
  }
}

final ProviderFamily<DuplicateSkillTemplateToolUsecase, String>
duplicateSkillTemplateToolUsecaseProvider =
    Provider.family<DuplicateSkillTemplateToolUsecase, String>(
      (ref, workspaceId) {
        final cloud = ref.watch(cloudSkillStoreProvider(workspaceId));

        return DuplicateSkillTemplateToolUsecase(
          cloud == null
              ? ref.watch(skillTemplateToolsRepositoryProvider)
              : null,
          createSkillTemplateToolUsecase: ref.watch(
            createSkillTemplateToolUsecaseProvider(workspaceId),
          ),
          cloudStore: cloud,
        );
      },
    );
