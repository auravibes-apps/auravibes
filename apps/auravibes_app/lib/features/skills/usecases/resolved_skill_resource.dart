import 'package:auravibes_app/data/repositories/skill_resources_repository.dart';
import 'package:auravibes_app/data/repositories/skills_repository.dart';
import 'package:auravibes_app/domain/entities/skill_resource_entity.dart';
import 'package:auravibes_app/features/skills/providers/cloud_skill_store_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/services/cloud_skill_store.dart';
import 'package:auravibes_app/services/skills/app_skill_registry.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:riverpod/misc.dart';
import 'package:riverpod/riverpod.dart';

const _skillResourceStoreUnavailable = 'Skill resource store is unavailable';

class const ResolvedSkillResource({
  required final SkillResourceSummary summary,
  required final String content,
});

abstract final class SkillResourceSummaryMapper {
  static SkillResourceSummary from(SkillResourceEntity resource) =>
      SkillResourceSummary(
        slug: resource.slug,
        title: resource.title,
        description: resource.description,
      );
}

class const SkillResourceResolver(
  final SkillsRepository? _skillsRepository,
  final SkillResourcesRepository? _resourcesRepository,
  final AppSkillRegistry _appSkillRegistry, {
  final CloudSkillStore? cloudStore,
}) {
  Future<List<SkillResourceSummary>> list(
    String workspaceId,
    String skillSlug,
  ) async {
    final appSkill = _appSkillRegistry.getRuntimeBySlug(skillSlug);
    if (appSkill != null) {
      return appSkill.resources
          .map((resource) => resource.summary)
          .toList(growable: false);
    }

    return (await _resources(
      workspaceId,
      skillSlug,
    )).map(SkillResourceSummaryMapper.from).toList(growable: false);
  }

  Future<ResolvedSkillResource?> get(
    String workspaceId,
    String skillSlug,
    String resourceSlug,
  ) async {
    final appSkill = _appSkillRegistry.getRuntimeBySlug(skillSlug);
    if (appSkill != null) return _appResource(appSkill, resourceSlug);

    return await _userResource(workspaceId, skillSlug, resourceSlug);
  }

  ResolvedSkillResource? _appResource(
    AppSkillDefinition skill,
    String resourceSlug,
  ) {
    final resource = skill.resources
        .where((candidate) => candidate.slug == resourceSlug)
        .firstOrNull;
    if (resource == null) return null;

    return ResolvedSkillResource(
      summary: resource.summary,
      content: resource.content,
    );
  }

  Future<ResolvedSkillResource?> _userResource(
    String workspaceId,
    String skillSlug,
    String resourceSlug,
  ) async {
    final resource = (await _resources(
      workspaceId,
      skillSlug,
    )).where((candidate) => candidate.slug == resourceSlug).firstOrNull;
    if (resource == null) return null;

    return ResolvedSkillResource(
      summary: SkillResourceSummaryMapper.from(resource),
      content: resource.content,
    );
  }

  Future<List<SkillResourceEntity>> _resources(
    String workspaceId,
    String skillSlug,
  ) {
    final cloud = cloudStore;
    if (cloud != null) return _cloudResources(cloud, skillSlug);

    return _localResources(workspaceId, skillSlug);
  }

  Future<List<SkillResourceEntity>> _cloudResources(
    CloudSkillStore cloud,
    String skillSlug,
  ) async {
    final skill = (await cloud.skills())
        .where((candidate) => candidate.slug == skillSlug)
        .firstOrNull;
    if (skill == null) return const [];

    return await cloud.resources(skill.id);
  }

  Future<List<SkillResourceEntity>> _localResources(
    String workspaceId,
    String skillSlug,
  ) async {
    final skill = await _skillsRepository?.getSkillBySlug(
      workspaceId,
      skillSlug,
    );
    if (skill == null) return const [];
    final repository = _resourcesRepository;
    if (repository == null) {
      throw StateError(_skillResourceStoreUnavailable);
    }

    return await repository.getSkillResources(skill.id);
  }
}

class const CreateSkillResourceUsecase(
  final SkillResourcesRepository? _resourcesRepository, {
  final CloudSkillStore? cloudStore,
}) {
  Future<SkillResourceEntity> call(
    String skillId,
    SkillResourceToCreate value,
  ) async {
    _SkillResourceValidation.validate(
      value.title,
      value.description,
      value.content,
    );
    await _ensureCapacity(skillId);
    final cloud = cloudStore;
    if (cloud != null) return await cloud.createResource(skillId, value);
    final repository = _resourcesRepository;
    if (repository == null) {
      throw StateError(_skillResourceStoreUnavailable);
    }

    return await repository.createResource(skillId, value);
  }

  Future<void> _ensureCapacity(String skillId) async {
    final cloud = cloudStore;
    final resources = cloud != null
        ? await cloud.resources(skillId)
        : await _resourcesRepository?.getSkillResources(skillId) ?? const [];
    if (resources.length >= _SkillResourceValidation.limit) {
      throw StateError(
        'A skill cannot contain more than '
        '${_SkillResourceValidation.limit} resources.',
      );
    }
  }
}

class const UpdateSkillResourceUsecase(
  final SkillResourcesRepository? _resourcesRepository, {
  final CloudSkillStore? cloudStore,
}) {
  Future<SkillResourceEntity> call(
    String resourceId,
    SkillResourceToUpdate value,
  ) {
    _validateUpdate(value);

    return _updateResource(resourceId, value);
  }

  void _validateUpdate(SkillResourceToUpdate value) {
    if (value.title == null &&
        value.description == null &&
        value.content == null) {
      return;
    }

    _SkillResourceValidation.validate(
      value.title ?? '',
      value.description ?? '',
      value.content ?? '',
      allowEmpty: true,
    );
  }

  Future<SkillResourceEntity> _updateResource(
    String resourceId,
    SkillResourceToUpdate value,
  ) async {
    final cloud = cloudStore;
    if (cloud != null) return await cloud.updateResource(resourceId, value);
    final repository = _resourcesRepository;
    if (repository == null) {
      throw StateError(_skillResourceStoreUnavailable);
    }

    return await repository.updateResource(resourceId, value);
  }
}

abstract final class SkillResourceOperations {
  static Future<bool> delete(
    String resourceId, {
    required SkillResourcesRepository? resourcesRepository,
    required CloudSkillStore? cloudStore,
  }) {
    if (cloudStore != null) return cloudStore.deleteResource(resourceId);
    final repository = resourcesRepository;
    if (repository == null) {
      throw StateError(_skillResourceStoreUnavailable);
    }

    return repository.deleteResource(resourceId);
  }
}

abstract final class _SkillResourceValidation {
  static const descriptionMaxCharacters = 240;
  static const contentMaxCharacters = 50000;
  static const limit = 100;

  static void validate(
    String title,
    String description,
    String content, {
    bool allowEmpty = false,
  }) {
    if (!allowEmpty && title.trim().isEmpty) {
      throw const FormatException('Resource title is required.');
    }
    if (description.length > descriptionMaxCharacters) {
      throw const FormatException('Resource description is too long.');
    }
    if (content.length > contentMaxCharacters) {
      throw const FormatException('Resource content is too long.');
    }
  }
}

final ProviderFamily<CreateSkillResourceUsecase, String>
createSkillResourceUsecaseProvider =
    Provider.family<CreateSkillResourceUsecase, String>((ref, workspaceId) {
      final cloud = ref.watch(cloudSkillStoreProvider(workspaceId));

      return CreateSkillResourceUsecase(
        cloud == null ? ref.watch(skillResourcesRepositoryProvider) : null,
        cloudStore: cloud,
      );
    });

final ProviderFamily<UpdateSkillResourceUsecase, String>
updateSkillResourceUsecaseProvider =
    Provider.family<UpdateSkillResourceUsecase, String>((ref, workspaceId) {
      final cloud = ref.watch(cloudSkillStoreProvider(workspaceId));

      return UpdateSkillResourceUsecase(
        cloud == null ? ref.watch(skillResourcesRepositoryProvider) : null,
        cloudStore: cloud,
      );
    });

final ProviderFamily<Future<bool> Function(String), String>
deleteSkillResourceProvider =
    Provider.family<Future<bool> Function(String), String>((ref, workspaceId) {
      final cloud = ref.watch(cloudSkillStoreProvider(workspaceId));
      final repository = cloud == null
          ? ref.watch(skillResourcesRepositoryProvider)
          : null;

      return (resourceId) => SkillResourceOperations.delete(
        resourceId,
        resourcesRepository: repository,
        cloudStore: cloud,
      );
    });

final ProviderFamily<SkillResourceResolver, String>
skillResourceResolverProvider = Provider.family<SkillResourceResolver, String>((
  ref,
  workspaceId,
) {
  final cloud = ref.watch(cloudSkillStoreProvider(workspaceId));

  return SkillResourceResolver(
    cloud == null ? ref.watch(skillsRepositoryProvider) : null,
    cloud == null ? ref.watch(skillResourcesRepositoryProvider) : null,
    ref.watch(appSkillRegistryProvider),
    cloudStore: cloud,
  );
});
