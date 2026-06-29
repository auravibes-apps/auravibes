import 'package:auravibes_app/data/repositories/skill_credential_definitions_repository.dart';
import 'package:auravibes_app/domain/entities/skill_credential_definition_entity.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/usecases/validate_skill_title_usecase.dart';
import 'package:auravibes_app/utils/generate_skill_slug.dart';
import 'package:riverpod/riverpod.dart';

class CreateSkillCredentialDefinitionUsecase {
  const CreateSkillCredentialDefinitionUsecase(
    this._skillCredentialDefinitionsRepository,
  );

  final SkillCredentialDefinitionsRepository
  _skillCredentialDefinitionsRepository;

  Future<SkillCredentialDefinitionEntity> call(
    String workspaceId,
    SkillCredentialDefinitionToCreate definition,
  ) async {
    validateSkillTitle(definition.title);
    final _ = SkillCredentialAttributeDefinition.parseMap(
      definition.attributesJson,
    );
    final slug = generateSkillSlug(definition.title);
    final existing = await _skillCredentialDefinitionsRepository
        .getDefinitionBySlug(workspaceId, slug);
    if (existing != null) {
      throw const SkillTitleValidationException(
        'A credential definition with this title already exists',
      );
    }

    return _skillCredentialDefinitionsRepository.createDefinition(
      workspaceId,
      definition,
    );
  }
}

final createSkillCredentialDefinitionUsecaseProvider =
    Provider<CreateSkillCredentialDefinitionUsecase>((ref) {
      return CreateSkillCredentialDefinitionUsecase(
        ref.watch(skillCredentialDefinitionsRepositoryProvider),
      );
    });
