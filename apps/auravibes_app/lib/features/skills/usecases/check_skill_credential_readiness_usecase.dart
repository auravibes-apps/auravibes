import 'package:auravibes_app/data/repositories/skill_credentials_repository.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/features/skills/providers/cloud_skill_store_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/services/cloud_skill_store.dart';
import 'package:riverpod/riverpod.dart';

class CheckSkillCredentialReadinessUsecase {
  const CheckSkillCredentialReadinessUsecase(
    this._skillCredentialsRepository, {
    this.cloudStore,
  });

  final SkillCredentialsRepository? _skillCredentialsRepository;
  final CloudSkillStore? cloudStore;

  Future<bool> call({
    required String workspaceId,
    required SkillEntity skill,
  }) async {
    final credentialDefinitionId = skill.credentialDefinitionId;
    if (credentialDefinitionId == null || credentialDefinitionId.isEmpty) {
      return true;
    }
    if (skill.isCredentialOptional) return true;
    final cloud = cloudStore;
    if (cloud != null) return cloud.credentialReady(skill);

    final repository = _skillCredentialsRepository;
    if (repository == null) {
      throw StateError('Skill credentials repository is unavailable');
    }
    final credentials = await repository.getCredentialsForDefinition(
      workspaceId: workspaceId,
      credentialDefinitionId: credentialDefinitionId,
    );

    return credentials.isNotEmpty;
  }
}

final checkSkillCredentialReadinessUsecaseProvider =
    Provider<CheckSkillCredentialReadinessUsecase>(
      (ref) {
        final cloud = ref.watch(cloudSkillStoreProvider);

        return CheckSkillCredentialReadinessUsecase(
          cloud == null ? ref.watch(skillCredentialsRepositoryProvider) : null,
          cloudStore: cloud,
        );
      },
      dependencies: [cloudSkillStoreProvider],
    );
