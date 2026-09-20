import 'package:auravibes_app/domain/entities/skill_resource_entity.dart';
import 'package:auravibes_app/features/skills/providers/cloud_skill_store_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/services/cloud_skill_store.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'skill_resources_provider.g.dart';

@riverpod
Future<List<SkillResourceEntity>> skillResources(
  Ref ref,
  String workspaceId,
  String skillId,
) {
  final cloud = ref.watch(cloudSkillStoreProvider(workspaceId));
  if (cloud != null) return cloud.resources(skillId);

  return ref.watch(skillResourcesRepositoryProvider).getSkillResources(skillId);
}

@riverpod
Future<SkillResourceEntity?> skillResource(
  Ref ref,
  String workspaceId,
  String resourceId,
) {
  final cloud = ref.watch(cloudSkillStoreProvider(workspaceId));
  if (cloud != null) return cloud.resource(resourceId);

  return ref
      .watch(skillResourcesRepositoryProvider)
      .getResourceById(resourceId);
}
