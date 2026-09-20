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

const skillResourceDescriptionMaxCharacters = 240;
const skillResourceContentMaxCharacters = 50000;
const skillResourceLimit = 100;

class const ResolvedSkillResource({
  required final SkillResourceSummary summary,
  required final String content,
});

extension on SkillResourceEntity {
  SkillResourceSummary get summary =>
      SkillResourceSummary(slug: slug, title: title, description: description);
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
    final appSkill = _appSkillRegistry.getBySlug(skillSlug);
    if (appSkill != null) {
      return appSkill.resources
          .map((resource) => resource.summary)
          .toList(growable: false);
    }

    return (await _resources(
      workspaceId,
      skillSlug,
    )).map((resource) => resource.summary).toList(growable: false);
  }

  Future<ResolvedSkillResource?> get(
    String workspaceId,
    String skillSlug,
    String resourceSlug,
  ) async {
    final appSkill = _appSkillRegistry.getBySlug(skillSlug);
    if (appSkill != null) {
      final resource = appSkill.resources
          .where((candidate) => candidate.slug == resourceSlug)
          .firstOrNull;
      if (resource == null) return null;

      return ResolvedSkillResource(
        summary: resource.summary,
        content: resource.content,
      );
    }

    final resource = (await _resources(
      workspaceId,
      skillSlug,
    )).where((candidate) => candidate.slug == resourceSlug).firstOrNull;
    if (resource == null) return null;

    return ResolvedSkillResource(
      summary: resource.summary,
      content: resource.content,
    );
  }

  Future<List<SkillResourceEntity>> _resources(
    String workspaceId,
    String skillSlug,
  ) async {
    final cloud = cloudStore;
    if (cloud != null) {
      final skill = (await cloud.skills())
          .where((candidate) => candidate.slug == skillSlug)
          .firstOrNull;
      if (skill == null) return const [];

      return await cloud.resources(skill.id);
    }

    final skill = await _skillsRepository?.getSkillBySlug(
      workspaceId,
      skillSlug,
    );
    if (skill == null) return const [];
    final repository = _resourcesRepository;
    if (repository == null) {
      throw StateError('Skill resource store is unavailable');
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
    _validate(value.title, value.description, value.content);
    await _ensureCapacity(skillId);
    final cloud = cloudStore;
    if (cloud != null) return await cloud.createResource(skillId, value);
    final repository = _resourcesRepository;
    if (repository == null) {
      throw StateError('Skill resource store is unavailable');
    }

    return await repository.createResource(skillId, value);
  }

  Future<void> _ensureCapacity(String skillId) async {
    final cloud = cloudStore;
    final resources = cloud != null
        ? await cloud.resources(skillId)
        : await _resourcesRepository?.getSkillResources(skillId) ?? const [];
    if (resources.length >= skillResourceLimit) {
      throw StateError(
        'A skill cannot contain more than $skillResourceLimit resources.',
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
  ) async {
    if (value.title != null ||
        value.description != null ||
        value.content != null) {
      _validate(
        value.title ?? '',
        value.description ?? '',
        value.content ?? '',
        allowEmpty: true,
      );
    }
    final cloud = cloudStore;
    if (cloud != null) return await cloud.updateResource(resourceId, value);
    final repository = _resourcesRepository;
    if (repository == null) {
      throw StateError('Skill resource store is unavailable');
    }

    return await repository.updateResource(resourceId, value);
  }
}

Future<bool> deleteSkillResource(
  String resourceId, {
  required SkillResourcesRepository? resourcesRepository,
  required CloudSkillStore? cloudStore,
}) {
  if (cloudStore != null) return cloudStore.deleteResource(resourceId);
  final repository = resourcesRepository;
  if (repository == null) {
    throw StateError('Skill resource store is unavailable');
  }

  return repository.deleteResource(resourceId);
}

void _validate(
  String title,
  String description,
  String content, {
  bool allowEmpty = false,
}) {
  if (!allowEmpty && title.trim().isEmpty) {
    throw const FormatException('Resource title is required.');
  }
  if (description.length > skillResourceDescriptionMaxCharacters) {
    throw const FormatException('Resource description is too long.');
  }
  if (content.length > skillResourceContentMaxCharacters) {
    throw const FormatException('Resource content is too long.');
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

      return (resourceId) => deleteSkillResource(
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
