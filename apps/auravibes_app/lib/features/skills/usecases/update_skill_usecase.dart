import 'package:auravibes_app/data/repositories/skills_repository.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/features/skills/providers/cloud_skill_store_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/services/cloud_skill_store.dart';
import 'package:auravibes_app/features/skills/usecases/validate_skill_title_usecase.dart';
import 'package:riverpod/misc.dart';
import 'package:riverpod/riverpod.dart';

class const UpdateSkillUsecase(
  final SkillsRepository? _skillsRepository, {
  final CloudSkillStore? cloudStore,
}) {
  Future<SkillEntity> call(String skillId, SkillToUpdate skill) async {
    await _validateSkillUpdate(skillId, skill);

    return await _updateSkill(skillId, skill);
  }

  Future<SkillEntity> _updateSkill(String skillId, SkillToUpdate skill) async {
    final cloud = cloudStore;
    if (cloud != null) return await cloud.updateSkill(skillId, skill);
    final repository = _skillsRepository;
    if (repository == null) throw StateError('Skill store is unavailable');

    return await repository.updateSkill(skillId, skill);
  }

  Future<void> _validateSkillUpdate(String skillId, SkillToUpdate skill) async {
    final title = skill.title;
    if (title == null) return;

    ValidateSkillTitleUsecase.call(title);
    final existingSkill = await _existingSkill(skillId);
    if (existingSkill == null) {
      throw StateError('Skill not found: $skillId');
    }

    final duplicate = await _duplicateSkillTitle(existingSkill, title);
    if (duplicate != null && duplicate.id != skillId) {
      throw const SkillTitleValidationException(
        'A skill with this title already exists',
      );
    }
  }

  Future<SkillEntity?> _existingSkill(String skillId) {
    return cloudStore?.skill(skillId) ??
        _skillsRepository?.getSkillById(skillId);
  }

  Future<SkillEntity?> _duplicateSkillTitle(
    SkillEntity existingSkill,
    String title,
  ) {
    final cloud = cloudStore;
    if (cloud != null) return _cloudDuplicateSkillTitle(cloud, title);
    final repository = _skillsRepository;
    if (repository == null) {
      throw StateError('Skill store is unavailable');
    }

    return repository.getSkillByTitle(existingSkill.workspaceId, title.trim());
  }

  Future<SkillEntity?> _cloudDuplicateSkillTitle(
    CloudSkillStore cloud,
    String title,
  ) => cloud.skills().then(
    (skills) => skills.where((item) => item.title == title.trim()).firstOrNull,
  );
}

final ProviderFamily<UpdateSkillUsecase, String> updateSkillUsecaseProvider =
    Provider.family<UpdateSkillUsecase, String>((ref, workspaceId) {
      final cloud = ref.watch(cloudSkillStoreProvider(workspaceId));

      return UpdateSkillUsecase(
        cloud == null ? ref.watch(skillsRepositoryProvider) : null,
        cloudStore: cloud,
      );
    });
