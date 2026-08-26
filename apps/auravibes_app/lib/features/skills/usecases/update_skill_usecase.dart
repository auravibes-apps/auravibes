// ignore_for_file: implementation_imports
import 'package:auravibes_app/data/repositories/skills_repository.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/features/skills/providers/cloud_skill_store_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/services/cloud_skill_store.dart';
import 'package:auravibes_app/features/skills/usecases/validate_skill_title_usecase.dart';
import 'package:riverpod/src/providers/provider.dart';

class UpdateSkillUsecase {
  const UpdateSkillUsecase(this._skillsRepository, {this.cloudStore});
  final CloudSkillStore? cloudStore;

  final SkillsRepository? _skillsRepository;

  Future<SkillEntity> call(String skillId, SkillToUpdate skill) async {
    final title = skill.title;
    if (title != null) {
      ValidateSkillTitleUsecase.call(title);
      final existingSkill =
          await cloudStore?.skill(skillId) ??
          await _skillsRepository?.getSkillById(skillId);
      if (existingSkill == null) {
        throw StateError('Skill not found: $skillId');
      }

      final cloud = cloudStore;
      final repository = _skillsRepository;
      final duplicate = switch ((cloud: cloud, repository: repository)) {
        (cloud: final cloud?, repository: _) =>
          (await cloud.skills())
              .where((item) => item.title == title.trim())
              .firstOrNull,
        (cloud: _, repository: final repository?) =>
          await repository.getSkillByTitle(
            existingSkill.workspaceId,
            title.trim(),
          ),
        _ => throw StateError('Skill store is unavailable'),
      };
      if (duplicate != null && duplicate.id != skillId) {
        throw const SkillTitleValidationException(
          'A skill with this title already exists',
        );
      }
    }

    final cloud = cloudStore;
    if (cloud != null) return await cloud.updateSkill(skillId, skill);
    final repository = _skillsRepository;
    if (repository == null) throw StateError('Skill store is unavailable');

    return await repository.updateSkill(skillId, skill);
  }
}

final ProviderFamily<UpdateSkillUsecase, String> updateSkillUsecaseProvider =
    Provider.family<UpdateSkillUsecase, String>((ref, workspaceId) {
      final cloud = ref.watch(cloudSkillStoreProvider(workspaceId));

      return UpdateSkillUsecase(
        cloud == null ? ref.watch(skillsRepositoryProvider) : null,
        cloudStore: cloud,
      );
    });
