import 'package:auravibes_app/domain/repositories/skill_credential_definitions_repository.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:riverpod/riverpod.dart';

class DeleteSkillCredentialDefinitionUsecase {
  const DeleteSkillCredentialDefinitionUsecase(
    this._skillCredentialDefinitionsRepository,
  );

  final SkillCredentialDefinitionsRepository
  _skillCredentialDefinitionsRepository;

  Future<bool> call(String definitionId) {
    return _skillCredentialDefinitionsRepository.deleteDefinition(definitionId);
  }
}

final deleteSkillCredentialDefinitionUsecaseProvider =
    Provider<DeleteSkillCredentialDefinitionUsecase>((ref) {
      return DeleteSkillCredentialDefinitionUsecase(
        ref.watch(skillCredentialDefinitionsRepositoryProvider),
      );
    });
