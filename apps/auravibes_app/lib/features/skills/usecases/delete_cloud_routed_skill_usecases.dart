// ignore_for_file: implementation_imports
import 'package:auravibes_app/features/skills/providers/cloud_skill_store_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:riverpod/src/providers/provider.dart';

final ProviderFamily<Future<void> Function(String), String>
deleteSkillProvider = Provider.family<Future<void> Function(String), String>((
  ref,
  workspaceId,
) {
  final cloud = ref.watch(cloudSkillStoreProvider(workspaceId));
  if (cloud != null) return cloud.deleteSkill;

  return (id) => ref.read(skillsRepositoryProvider).deleteSkill(id);
});

final ProviderFamily<Future<void> Function(String), String>
deleteSkillTemplateToolProvider =
    Provider.family<Future<void> Function(String), String>((ref, workspaceId) {
      final cloud = ref.watch(cloudSkillStoreProvider(workspaceId));
      if (cloud != null) return cloud.deleteTool;

      return (id) =>
          ref.read(skillTemplateToolsRepositoryProvider).deleteTool(id);
    });

final ProviderFamily<Future<void> Function(String), String>
deleteSkillCredentialDefinitionProvider =
    Provider.family<Future<void> Function(String), String>((ref, workspaceId) {
      final cloud = ref.watch(cloudSkillStoreProvider(workspaceId));
      if (cloud != null) return cloud.deleteDefinition;

      return (id) => ref
          .read(skillCredentialDefinitionsRepositoryProvider)
          .deleteDefinition(id);
    });
