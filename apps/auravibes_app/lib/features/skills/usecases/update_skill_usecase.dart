import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/domain/repositories/skills_repository.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/usecases/validate_skill_title_usecase.dart';
import 'package:riverpod/riverpod.dart';

class UpdateSkillUsecase {
  const UpdateSkillUsecase(
    this._skillsRepository,
    this._validateSkillTitleUsecase,
  );

  final SkillsRepository _skillsRepository;
  final ValidateSkillTitleUsecase _validateSkillTitleUsecase;

  Future<SkillEntity> call(String skillId, SkillToUpdate skill) async {
    final title = skill.title;
    if (title != null) {
      _validateSkillTitleUsecase.call(title);
      final existingSkill = await _skillsRepository.getSkillById(skillId);
      if (existingSkill == null) {
        throw StateError('Skill not found: $skillId');
      }

      final duplicate = await _skillsRepository.getSkillByTitle(
        existingSkill.workspaceId,
        title.trim(),
      );
      if (duplicate != null && duplicate.id != skillId) {
        throw const SkillTitleValidationException(
          'A skill with this title already exists',
        );
      }
    }

    return _skillsRepository.updateSkill(skillId, skill);
  }
}

final updateSkillUsecaseProvider = Provider<UpdateSkillUsecase>((ref) {
  return UpdateSkillUsecase(
    ref.watch(skillsRepositoryProvider),
    ref.watch(validateSkillTitleUsecaseProvider),
  );
});
