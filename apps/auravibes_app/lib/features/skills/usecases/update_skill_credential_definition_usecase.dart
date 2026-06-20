import 'package:auravibes_app/data/repositories/skill_credential_definitions_repository.dart';
import 'package:auravibes_app/domain/entities/skill_credential_definition_entity.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/usecases/generate_skill_slug_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/validate_skill_title_usecase.dart';
import 'package:riverpod/riverpod.dart';

class UpdateSkillCredentialDefinitionUsecase {
  const UpdateSkillCredentialDefinitionUsecase(
    this._skillCredentialDefinitionsRepository,
  );

  final SkillCredentialDefinitionsRepository
  _skillCredentialDefinitionsRepository;

  Future<SkillCredentialDefinitionEntity> call(
    String definitionId,
    SkillCredentialDefinitionToUpdate definition,
  ) async {
    final existingDefinition = await _skillCredentialDefinitionsRepository
        .getDefinitionById(definitionId);
    if (existingDefinition == null) {
      throw StateError('Skill credential definition not found: $definitionId');
    }
    final title = definition.title;
    if (title != null) {
      validateSkillTitle(title);
      final slug = generateSkillSlug(title);
      final duplicate = await _skillCredentialDefinitionsRepository
          .getDefinitionBySlug(existingDefinition.workspaceId, slug);
      if (duplicate != null && duplicate.id != definitionId) {
        throw const SkillTitleValidationException(
          'A credential definition with this title already exists',
        );
      }
    }
    final attributesJson = definition.attributesJson;
    if (attributesJson != null) {
      final _ = SkillCredentialAttributeDefinition.parseMap(attributesJson);
    }

    return _skillCredentialDefinitionsRepository.updateDefinition(
      definitionId,
      definition,
    );
  }
}

final updateSkillCredentialDefinitionUsecaseProvider =
    Provider<UpdateSkillCredentialDefinitionUsecase>((ref) {
      return UpdateSkillCredentialDefinitionUsecase(
        ref.watch(skillCredentialDefinitionsRepositoryProvider),
      );
    });
