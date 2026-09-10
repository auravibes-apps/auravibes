import 'package:auravibes_app/data/repositories/skills_repository.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/features/skills/providers/cloud_skill_store_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/services/cloud_skill_store.dart';
import 'package:auravibes_app/features/skills/usecases/validate_skill_title_usecase.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:riverpod/misc.dart';
import 'package:riverpod/riverpod.dart';

class const CreateSkillUsecase(
  final SkillsRepository? _skillsRepository, {
  final CloudSkillStore? cloudStore,
}) {
  Future<SkillEntity> call(String workspaceId, SkillToCreate skill) async {
    await _validateNewSkill(workspaceId, skill);

    return _createSkill(workspaceId, skill);
  }

  Future<void> _validateNewSkill(
    String workspaceId,
    SkillToCreate skill,
  ) async {
    ValidateSkillTitleUsecase.call(skill.title);
    final cloudSkills = await _cloudSkills();
    await _validateTitle(workspaceId, skill, cloudSkills);
    await _validateSlug(workspaceId, skill, cloudSkills);
  }

  Future<void> _validateTitle(
    String workspaceId,
    SkillToCreate skill,
    List<SkillEntity>? cloudSkills,
  ) async {
    final title = skill.title.trim();
    final existingTitle = await _existingTitle(workspaceId, title, cloudSkills);
    _throwIfDuplicateTitle(existingTitle);
  }

  Future<void> _validateSlug(
    String workspaceId,
    SkillToCreate skill,
    List<SkillEntity>? cloudSkills,
  ) async {
    final slug = generateSkillSlug(skill.title);
    final existingSlug = await _existingSlug(workspaceId, slug, cloudSkills);
    _throwIfDuplicateSlug(existingSlug);
  }

  Future<List<SkillEntity>?> _cloudSkills() async {
    final cloud = cloudStore;
    if (cloud == null) return null;

    return await cloud.skills();
  }

  Future<SkillEntity?> _existingTitle(
    String workspaceId,
    String title,
    List<SkillEntity>? cloudSkills,
  ) {
    if (cloudSkills != null) {
      return Future.value(
        cloudSkills.where((item) => item.title == title).firstOrNull,
      );
    }

    return _skillsRepository?.getSkillByTitle(workspaceId, title);
  }

  Future<SkillEntity?> _existingSlug(
    String workspaceId,
    String slug,
    List<SkillEntity>? cloudSkills,
  ) {
    if (cloudSkills != null) {
      return Future.value(
        cloudSkills.where((item) => item.slug == slug).firstOrNull,
      );
    }

    return _skillsRepository?.getSkillBySlug(workspaceId, slug);
  }

  void _throwIfDuplicateTitle(SkillEntity? existingTitle) {
    if (existingTitle != null) {
      throw const SkillTitleValidationException(
        'A skill with this title already exists',
      );
    }
  }

  void _throwIfDuplicateSlug(SkillEntity? existingSlug) {
    if (existingSlug != null) {
      throw const SkillTitleValidationException(
        'A skill with this slug already exists',
      );
    }
  }

  Future<SkillEntity> _createSkill(
    String workspaceId,
    SkillToCreate skill,
  ) async {
    final cloud = cloudStore;
    if (cloud != null) return await cloud.createSkill(skill);
    final repository = _skillsRepository;
    if (repository == null) throw StateError('Skill store is unavailable');

    return await repository.createSkill(workspaceId, skill);
  }
}

final ProviderFamily<CreateSkillUsecase, String> createSkillUsecaseProvider =
    Provider.family<CreateSkillUsecase, String>((ref, workspaceId) {
      final cloud = ref.watch(cloudSkillStoreProvider(workspaceId));

      return CreateSkillUsecase(
        cloud == null ? ref.watch(skillsRepositoryProvider) : null,
        cloudStore: cloud,
      );
    });
