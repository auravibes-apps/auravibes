import 'package:auravibes_app/features/skills/providers/cloud_skill_store_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:riverpod/riverpod.dart';

final deleteSkillProvider = Provider<Future<void> Function(String)>((ref) {
  final cloud = ref.watch(cloudSkillStoreProvider);
  if (cloud != null) return cloud.deleteSkill;

  return (id) => ref.read(skillsRepositoryProvider).deleteSkill(id);
});

final deleteSkillTemplateToolProvider = Provider<Future<void> Function(String)>(
  (ref) {
    final cloud = ref.watch(cloudSkillStoreProvider);
    if (cloud != null) return cloud.deleteTool;

    return (id) =>
        ref.read(skillTemplateToolsRepositoryProvider).deleteTool(id);
  },
);

final deleteSkillCredentialDefinitionProvider =
    Provider<Future<void> Function(String)>((ref) {
      final cloud = ref.watch(cloudSkillStoreProvider);
      if (cloud != null) return cloud.deleteDefinition;

      return (id) => ref
          .read(skillCredentialDefinitionsRepositoryProvider)
          .deleteDefinition(id);
    });
