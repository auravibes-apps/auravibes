// ignore_for_file: implementation_imports
import 'package:auravibes_app/data/repositories/skill_credential_definitions_repository.dart';
import 'package:auravibes_app/domain/entities/skill_credential_definition_entity.dart';
import 'package:auravibes_app/features/skills/providers/cloud_skill_store_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/services/cloud_skill_store.dart';
import 'package:auravibes_app/features/skills/usecases/validate_skill_title_usecase.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:riverpod/src/providers/provider.dart';

class const UpdateSkillCredentialDefinitionUsecase(
  final SkillCredentialDefinitionsRepository?
  _skillCredentialDefinitionsRepository, {
  final CloudSkillStore? cloudStore,
}) {
  Future<SkillCredentialDefinitionEntity> call(
    String definitionId,
    SkillCredentialDefinitionToUpdate definition,
  ) async {
    final existingDefinition =
        await cloudStore?.definition(definitionId) ??
        await _skillCredentialDefinitionsRepository?.getDefinitionById(
          definitionId,
        );
    if (existingDefinition == null) {
      throw StateError('Skill credential definition not found: $definitionId');
    }
    final title = definition.title;
    if (title != null) {
      ValidateSkillTitleUsecase.call(title);
      final slug = generateSkillSlug(title);
      final cloud = cloudStore;
      final repository = _skillCredentialDefinitionsRepository;
      final duplicate = switch ((cloud: cloud, repository: repository)) {
        (cloud: final cloud?, repository: _) =>
          (await cloud.definitions())
              .where((item) => item.slug == slug)
              .firstOrNull,
        (cloud: _, repository: final repository?) =>
          await repository.getDefinitionBySlug(
            existingDefinition.workspaceId,
            slug,
          ),
        _ => throw StateError('Credential definition store is unavailable'),
      };
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
