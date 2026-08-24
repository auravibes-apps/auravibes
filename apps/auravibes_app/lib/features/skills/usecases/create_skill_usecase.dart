// ignore_for_file: implementation_imports
import 'package:auravibes_app/data/repositories/skills_repository.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/features/skills/providers/cloud_skill_store_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/services/cloud_skill_store.dart';
import 'package:auravibes_app/features/skills/usecases/validate_skill_title_usecase.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:riverpod/src/providers/provider.dart';

class CreateSkillUsecase {
  const CreateSkillUsecase(this._skillsRepository, {this.cloudStore});
  final CloudSkillStore? cloudStore;

  final SkillsRepository? _skillsRepository;

  Future<SkillEntity> call(String workspaceId, SkillToCreate skill) async {
    ValidateSkillTitleUsecase.call(skill.title);
    final cloud = cloudStore;
    final cloudSkills = cloud == null ? null : await cloud.skills();
    final existingTitle =
        cloudSkills
            ?.where((item) => item.title == skill.title.trim())
            .firstOrNull ??
        await _skillsRepository?.getSkillByTitle(
          workspaceId,
          skill.title.trim(),
        );
    if (existingTitle != null) {
      throw const SkillTitleValidationException(
        'A skill with this title already exists',
      );
    }

    final slug = generateSkillSlug(skill.title);
    final existingSlug =
        cloudSkills?.where((item) => item.slug == slug).firstOrNull ??
        await _skillsRepository?.getSkillBySlug(workspaceId, slug);
    if (existingSlug != null) {
      throw const SkillTitleValidationException(
        'A skill with this slug already exists',
      );
    }

    if (cloud != null) return cloud.createSkill(skill);
    final repository = _skillsRepository;
    if (repository == null) throw StateError('Skill store is unavailable');

    return repository.createSkill(workspaceId, skill);
  }
}

final ProviderFamily<CreateSkillUsecase, String> createSkillUsecaseProvider =
    Provider.family<CreateSkillUsecase, String>(
      (ref, workspaceId) {
        final cloud = ref.watch(cloudSkillStoreProvider(workspaceId));

        return CreateSkillUsecase(
          cloud == null ? ref.watch(skillsRepositoryProvider) : null,
          cloudStore: cloud,
        );
      },
    );
