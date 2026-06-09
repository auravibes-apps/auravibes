import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/domain/entities/skill_template_tool_entity.dart';
import 'package:auravibes_app/domain/repositories/skill_template_tools_repository.dart';
import 'package:auravibes_app/domain/repositories/skills_repository.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/usecases/create_skill_usecase.dart';
import 'package:riverpod/riverpod.dart';

class DuplicateSkillUsecase {
  const DuplicateSkillUsecase(
    this._skillsRepository,
    this._skillTemplateToolsRepository,
    this._createSkillUsecase,
  );

  final SkillsRepository _skillsRepository;
  final SkillTemplateToolsRepository _skillTemplateToolsRepository;
  final CreateSkillUsecase _createSkillUsecase;

  Future<SkillEntity> call(String skillId) async {
    final skill = await _skillsRepository.getSkillById(skillId);
    if (skill == null || skill.source != SkillSource.user) {
      throw StateError('User skill not found: $skillId');
    }

    final title = await _copyTitle(
      workspaceId: skill.workspaceId,
      originalTitle: skill.title,
    );
    final duplicate = await _createSkillUsecase.call(
      skill.workspaceId,
      SkillToCreate(
        kind: skill.kind,
        title: title,
        description: skill.description,
        content: skill.content,
        credentialDefinitionId: skill.credentialDefinitionId,
        isEnabled: skill.isEnabled,
      ),
    );
    final tools = await _skillTemplateToolsRepository.getSkillTools(skill.id);
    for (final tool in tools) {
      final _ = await _skillTemplateToolsRepository.createTool(
        duplicate.id,
        SkillTemplateToolToCreate(
          templateType: tool.templateType,
          title: tool.title,
          description: tool.description,
          templateJson: tool.templateJson,
          inputsJson: tool.inputsJson,
          isEnabled: tool.isEnabled,
        ),
      );
    }

    return duplicate;
  }

  Future<String> _copyTitle({
    required String workspaceId,
    required String originalTitle,
  }) async {
    var suffix = 1;
    while (true) {
      final title = suffix == 1
          ? '$originalTitle Copy'
          : '$originalTitle Copy $suffix';
      final existing = await _skillsRepository.getSkillByTitle(
        workspaceId,
        title,
      );
      if (existing == null) return title;
      suffix += 1;
    }
  }
}

final duplicateSkillUsecaseProvider = Provider<DuplicateSkillUsecase>((ref) {
  return DuplicateSkillUsecase(
    ref.watch(skillsRepositoryProvider),
    ref.watch(skillTemplateToolsRepositoryProvider),
    ref.watch(createSkillUsecaseProvider),
  );
});
