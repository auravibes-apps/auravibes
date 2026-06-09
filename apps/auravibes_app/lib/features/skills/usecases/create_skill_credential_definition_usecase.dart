import 'package:auravibes_app/domain/entities/skill_credential_definition_entity.dart';
import 'package:auravibes_app/domain/repositories/skill_credential_definitions_repository.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/usecases/generate_skill_slug_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/validate_skill_title_usecase.dart';
import 'package:riverpod/riverpod.dart';

class CreateSkillCredentialDefinitionUsecase {
  const CreateSkillCredentialDefinitionUsecase(
    this._skillCredentialDefinitionsRepository, {
    required this.generateSkillSlugUsecase,
    required this.validateSkillTitleUsecase,
  });

  final SkillCredentialDefinitionsRepository
  _skillCredentialDefinitionsRepository;
  final GenerateSkillSlugUsecase generateSkillSlugUsecase;
  final ValidateSkillTitleUsecase validateSkillTitleUsecase;

  Future<SkillCredentialDefinitionEntity> call(
    String workspaceId,
    SkillCredentialDefinitionToCreate definition,
  ) async {
    validateSkillTitleUsecase.call(definition.title);
    SkillCredentialAttributeDefinition.parseMap(definition.attributesJson);
    final slug = generateSkillSlugUsecase.call(definition.title);
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
        generateSkillSlugUsecase: ref.watch(generateSkillSlugUsecaseProvider),
        validateSkillTitleUsecase: ref.watch(validateSkillTitleUsecaseProvider),
      );
    });
