import 'package:auravibes_app/data/repositories/skill_credential_definitions_repository.dart';
import 'package:auravibes_app/data/repositories/skills_repository.dart';
import 'package:auravibes_app/features/skills/providers/cloud_skill_store_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/services/cloud_skill_store.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:riverpod/riverpod.dart';

class const LoadSkillCredentialDefinitionsUsecase({
  final CloudSkillStore? cloudStore,
  final SkillsRepository? skillsRepository,
  final SkillCredentialDefinitionsRepository?
  skillCredentialDefinitionsRepository,
}) {
  Future<Map<String, SkillCredentialAttributeDefinition>> call(
    String skillId,
  ) async {
    final cloud = cloudStore;
    if (cloud != null) {
      final skill = await cloud.skill(skillId);
      final credentialDefinitionId = skill?.credentialDefinitionId;
      if (credentialDefinitionId == null) return const {};
      final definition = await cloud.definition(credentialDefinitionId);
      if (definition == null) return const {};

      return SkillCredentialAttributeDefinition.parseMap(
        definition.attributesJson,
      );
    }
    final skillsRepository = this.skillsRepository;
    final credentialDefinitionsRepository =
        skillCredentialDefinitionsRepository;
    if (skillsRepository == null || credentialDefinitionsRepository == null) {
      return const {};
    }
    final skill = await skillsRepository.getSkillById(skillId);
    final credentialDefinitionId = skill?.credentialDefinitionId;
    if (credentialDefinitionId == null) return const {};
    final definition = await credentialDefinitionsRepository.getDefinitionById(
      credentialDefinitionId,
    );
    if (definition == null) return const {};

    return SkillCredentialAttributeDefinition.parseMap(
      definition.attributesJson,
    );
  }
}

// ignore: specify_nonobvious_property_types - Riverpod family type is verbose.
final loadSkillCredentialDefinitionsUsecaseProvider =
    Provider.family<LoadSkillCredentialDefinitionsUsecase, String>((
      ref,
      workspaceId,
    ) {
      final cloud = ref.watch(cloudSkillStoreProvider(workspaceId));

      return LoadSkillCredentialDefinitionsUsecase(
        cloudStore: cloud,
        skillsRepository: cloud == null
            ? ref.watch(skillsRepositoryProvider)
            : null,
        skillCredentialDefinitionsRepository: cloud == null
            ? ref.watch(skillCredentialDefinitionsRepositoryProvider)
            : null,
      );
    });
