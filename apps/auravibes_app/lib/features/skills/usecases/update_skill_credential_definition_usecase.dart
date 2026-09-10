import 'package:auravibes_app/data/repositories/skill_credential_definitions_repository.dart';
import 'package:auravibes_app/domain/entities/skill_credential_definition_entity.dart';
import 'package:auravibes_app/features/skills/providers/cloud_skill_store_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/services/cloud_skill_store.dart';
import 'package:auravibes_app/features/skills/usecases/validate_skill_title_usecase.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:riverpod/misc.dart';
import 'package:riverpod/riverpod.dart';

class const UpdateSkillCredentialDefinitionUsecase(
  final SkillCredentialDefinitionsRepository?
  _skillCredentialDefinitionsRepository, {
  final CloudSkillStore? cloudStore,
}) {
  Future<SkillCredentialDefinitionEntity> call(
    String definitionId,
    SkillCredentialDefinitionToUpdate definition,
  ) async {
    final existingDefinition = await _requiredDefinition(definitionId);
    final title = definition.title;
    await _validateTitle(existingDefinition, definitionId, title);
    _validateAttributes(definition.attributesJson);

    return await _updateDefinition(definitionId, definition);
  }

  Future<SkillCredentialDefinitionEntity> _requiredDefinition(
    String definitionId,
  ) async {
    final definition = await _existingDefinition(definitionId);
    if (definition == null) {
      throw StateError('Skill credential definition not found: $definitionId');
    }

    return definition;
  }

  void _validateAttributes(String? attributesJson) {
    if (attributesJson == null) return;

    final _ = SkillCredentialAttributeDefinition.parseMap(attributesJson);
  }

  Future<SkillCredentialDefinitionEntity?> _existingDefinition(
    String definitionId,
  ) {
    return cloudStore?.definition(definitionId) ??
        _skillCredentialDefinitionsRepository?.getDefinitionById(definitionId);
  }

  Future<void> _validateTitle(
    SkillCredentialDefinitionEntity existingDefinition,
    String definitionId,
    String? title,
  ) async {
    if (title == null) return;

    ValidateSkillTitleUsecase.call(title);
    final duplicate = await _duplicateTitle(existingDefinition, title);
    if (duplicate != null && duplicate.id != definitionId) {
      throw const SkillTitleValidationException(
        'A credential definition with this title already exists',
      );
    }
  }

  Future<SkillCredentialDefinitionEntity?> _duplicateTitle(
    SkillCredentialDefinitionEntity existingDefinition,
    String title,
  ) {
    final slug = generateSkillSlug(title);
    final cloud = cloudStore;
    if (cloud != null) return _cloudDuplicateTitle(cloud, slug);
    final repository = _skillCredentialDefinitionsRepository;
    if (repository == null) {
      throw StateError('Credential definition store is unavailable');
    }

    return repository.getDefinitionBySlug(existingDefinition.workspaceId, slug);
  }

  Future<SkillCredentialDefinitionEntity?> _cloudDuplicateTitle(
    CloudSkillStore cloud,
    String slug,
  ) => cloud.definitions().then(
    (definitions) => definitions.where((item) => item.slug == slug).firstOrNull,
  );

  Future<SkillCredentialDefinitionEntity> _updateDefinition(
    String definitionId,
    SkillCredentialDefinitionToUpdate definition,
  ) async {
    final cloud = cloudStore;
    if (cloud != null) {
      return await cloud.updateDefinition(definitionId, definition);
    }
    final repository = _skillCredentialDefinitionsRepository;
    if (repository == null) {
      throw StateError('Credential definition store is unavailable');
    }

    return await repository.updateDefinition(definitionId, definition);
  }
}

final ProviderFamily<UpdateSkillCredentialDefinitionUsecase, String>
updateSkillCredentialDefinitionUsecaseProvider =
    Provider.family<UpdateSkillCredentialDefinitionUsecase, String>((
      ref,
      workspaceId,
    ) {
      final cloud = ref.watch(cloudSkillStoreProvider(workspaceId));

      return UpdateSkillCredentialDefinitionUsecase(
        cloud == null
            ? ref.watch(skillCredentialDefinitionsRepositoryProvider)
            : null,
        cloudStore: cloud,
      );
    });
