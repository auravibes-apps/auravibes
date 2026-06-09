import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/domain/repositories/skill_credentials_repository.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:riverpod/riverpod.dart';

class CheckSkillCredentialReadinessUsecase {
  const CheckSkillCredentialReadinessUsecase(this._skillCredentialsRepository);

  final SkillCredentialsRepository _skillCredentialsRepository;

  Future<bool> call({
    required String workspaceId,
    required SkillEntity skill,
  }) async {
    final credentialDefinitionId = skill.credentialDefinitionId;
    if (credentialDefinitionId == null || credentialDefinitionId.isEmpty) {
      return true;
    }
    if (skill.isCredentialOptional) return true;

    final credentials = await _skillCredentialsRepository
        .getCredentialsForDefinition(
          workspaceId: workspaceId,
          credentialDefinitionId: credentialDefinitionId,
        );
    return credentials.isNotEmpty;
  }
}

final checkSkillCredentialReadinessUsecaseProvider =
    Provider<CheckSkillCredentialReadinessUsecase>((ref) {
      return CheckSkillCredentialReadinessUsecase(
        ref.watch(skillCredentialsRepositoryProvider),
      );
    });
