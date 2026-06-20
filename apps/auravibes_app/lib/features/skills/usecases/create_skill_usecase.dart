import 'package:auravibes_app/data/repositories/skills_repository.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/usecases/generate_skill_slug_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/validate_skill_title_usecase.dart';
import 'package:riverpod/riverpod.dart';

class CreateSkillUsecase {
  const CreateSkillUsecase(this._skillsRepository);

  final SkillsRepository _skillsRepository;

  Future<SkillEntity> call(String workspaceId, SkillToCreate skill) async {
    validateSkillTitle(skill.title);
    final existingTitle = await _skillsRepository.getSkillByTitle(
      workspaceId,
      skill.title.trim(),
    );
    if (existingTitle != null) {
      throw const SkillTitleValidationException(
        'A skill with this title already exists',
      );
    }

    final slug = generateSkillSlug(skill.title);
    final existingSlug = await _skillsRepository.getSkillBySlug(
      workspaceId,
      slug,
    );
    if (existingSlug != null) {
      throw const SkillTitleValidationException(
        'A skill with this slug already exists',
      );
    }

    return _skillsRepository.createSkill(workspaceId, skill);
  }
}

final createSkillUsecaseProvider = Provider<CreateSkillUsecase>((ref) {
  return CreateSkillUsecase(ref.watch(skillsRepositoryProvider));
});
