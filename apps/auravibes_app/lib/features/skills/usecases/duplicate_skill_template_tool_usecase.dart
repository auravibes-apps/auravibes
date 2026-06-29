import 'package:auravibes_app/data/repositories/skill_template_tools_repository.dart';
import 'package:auravibes_app/domain/entities/skill_template_tool_entity.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/usecases/create_skill_template_tool_usecase.dart';
import 'package:auravibes_app/utils/generate_skill_slug.dart';
import 'package:riverpod/riverpod.dart';

class DuplicateSkillTemplateToolUsecase {
  const DuplicateSkillTemplateToolUsecase(
    this._skillTemplateToolsRepository, {
    required this.createSkillTemplateToolUsecase,
  });

  final SkillTemplateToolsRepository _skillTemplateToolsRepository;
  final CreateSkillTemplateToolUsecase createSkillTemplateToolUsecase;

  Future<SkillTemplateToolEntity> call(String toolId) async {
    final tool = await _skillTemplateToolsRepository.getToolById(toolId);
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
      final existing = await _skillTemplateToolsRepository.getToolBySlug(
        tool.skillId,
        generateSkillSlug(title),
      );
      if (existing == null) return title;
      suffix += 1;
    }
  }
}

final duplicateSkillTemplateToolUsecaseProvider =
    Provider<DuplicateSkillTemplateToolUsecase>((ref) {
      return DuplicateSkillTemplateToolUsecase(
        ref.watch(skillTemplateToolsRepositoryProvider),
        createSkillTemplateToolUsecase: ref.watch(
          createSkillTemplateToolUsecaseProvider,
        ),
      );
    });
