import 'package:auravibes_app/data/repositories/skill_resources_repository.dart';
import 'package:auravibes_app/data/repositories/skills_repository.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/domain/entities/skill_resource_entity.dart';
import 'package:auravibes_app/features/skills/providers/cloud_skill_store_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/services/cloud_skill_store.dart';
import 'package:auravibes_app/features/skills/usecases/create_skill_usecase.dart';
import 'package:auravibes_app/services/skills/app_skill_registry.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:riverpod/misc.dart';
import 'package:riverpod/riverpod.dart';

class const CloneAppSkillUsecase(
  final AppSkillRegistry _appSkillRegistry,
  final SkillsRepository? _skillsRepository,
  final CreateSkillUsecase _createSkillUsecase, {
  final CloudSkillStore? cloudStore,
  final SkillResourcesRepository? resourceRepository,
}) {
  Future<SkillEntity> call(String workspaceId, String appSkillSlug) async {
    final appSkill = _cloneableAppSkill(appSkillSlug);
    final title = await _copyTitle(workspaceId, appSkill.title);
    final skill = await _createClone(workspaceId, title, appSkill);
    await _cloneResources(skill.id, appSkill.resources);

    return skill;
  }

  Future<void> _cloneResources(
    String skillId,
    List<AppSkillResourceDefinition> resources,
  ) async {
    for (final resource in resources) {
      await _cloneResource(skillId, resource);
    }
  }

  Future<void> _cloneResource(
    String skillId,
    AppSkillResourceDefinition resource,
  ) async {
    await _createResource(skillId, _resourceValue(resource));
  }

  SkillResourceToCreate _resourceValue(AppSkillResourceDefinition resource) =>
      SkillResourceToCreate(
        title: resource.title,
        description: resource.description,
        content: resource.content,
      );

  Future<void> _createResource(
    String skillId,
    SkillResourceToCreate value,
  ) async {
    final cloud = cloudStore;
    if (cloud != null) {
      final _ = await cloud.createResource(skillId, value);

      return;
    }
    final repository = resourceRepository;
    if (repository == null) {
      throw StateError('Skill resource store is unavailable');
    }
    final _ = await repository.createResource(skillId, value);
  }
}

extension _CloneAppSkillDefinitions on CloneAppSkillUsecase {
  AppSkillDefinition _cloneableAppSkill(String slug) {
    final appSkill =
        _appSkillRegistry.getBySlug(slug) ??
        _appSkillRegistry.getByIdentifier(slug);
    if (appSkill == null) throw StateError('App skill not found: $slug');
    if (appSkill.connectorToolIds.isEmpty) {
      throw StateError('Native app skills cannot be cloned.');
    }

    return appSkill;
  }

  Future<SkillEntity> _createClone(
    String workspaceId,
    String title,
    AppSkillDefinition appSkill,
  ) => _createSkillUsecase.call(
    workspaceId,
    .new(
      kind: SkillKind.template,
      title: title,
      description: appSkill.description,
      content: appSkill.content,
      connectorToolIds: appSkill.connectorToolIds,
    ),
  );

  Future<String> _copyTitle(String workspaceId, String originalTitle) async {
    for (var suffix = 1; ; suffix++) {
      final title = suffix == 1
          ? '$originalTitle Copy'
          : '$originalTitle Copy $suffix';
      if (!await _titleExists(workspaceId, title)) return title;
    }
  }

  Future<bool> _titleExists(String workspaceId, String title) async {
    final cloud = cloudStore;
    if (cloud != null) {
      return (await cloud.skills()).any((skill) => skill.title == title);
    }
    final repository = _skillsRepository;
    if (repository == null) throw StateError('Skill store is unavailable');

    return await repository.getSkillByTitle(workspaceId, title) != null;
  }
}

final ProviderFamily<CloneAppSkillUsecase, String>
cloneAppSkillUsecaseProvider = Provider.family<CloneAppSkillUsecase, String>((
  ref,
  workspaceId,
) {
  final cloud = ref.watch(cloudSkillStoreProvider(workspaceId));

  return CloneAppSkillUsecase(
    ref.watch(appSkillRegistryProvider),
    cloud == null ? ref.watch(skillsRepositoryProvider) : null,
    ref.watch(createSkillUsecaseProvider(workspaceId)),
    cloudStore: cloud,
    resourceRepository: cloud == null
        ? ref.watch(skillResourcesRepositoryProvider)
        : null,
  );
});
