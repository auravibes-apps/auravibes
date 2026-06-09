import 'package:auravibes_app/domain/repositories/skill_template_tools_repository.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:riverpod/riverpod.dart';

class DeleteSkillTemplateToolUsecase {
  const DeleteSkillTemplateToolUsecase(this._skillTemplateToolsRepository);

  final SkillTemplateToolsRepository _skillTemplateToolsRepository;

  Future<bool> call(String toolId) {
    return _skillTemplateToolsRepository.deleteTool(toolId);
  }
}

final deleteSkillTemplateToolUsecaseProvider =
    Provider<DeleteSkillTemplateToolUsecase>((ref) {
      return DeleteSkillTemplateToolUsecase(
        ref.watch(skillTemplateToolsRepositoryProvider),
      );
    });
