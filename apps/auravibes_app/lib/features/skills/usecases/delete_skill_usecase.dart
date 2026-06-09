import 'package:auravibes_app/domain/repositories/skills_repository.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:riverpod/riverpod.dart';

class DeleteSkillUsecase {
  const DeleteSkillUsecase(this._skillsRepository);

  final SkillsRepository _skillsRepository;

  Future<bool> call(String skillId) {
    return _skillsRepository.deleteSkill(skillId);
  }
}

final deleteSkillUsecaseProvider = Provider<DeleteSkillUsecase>((ref) {
  return DeleteSkillUsecase(ref.watch(skillsRepositoryProvider));
});
