import 'package:auravibes_app/data/repositories/skill_credential_definitions_repository.dart';
import 'package:auravibes_app/domain/entities/skill_credential_definition_entity.dart';
import 'package:auravibes_app/features/skills/providers/cloud_skill_store_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/services/cloud_skill_store.dart';
import 'package:auravibes_app/features/skills/usecases/create_skill_credential_definition_usecase.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:riverpod/misc.dart';
import 'package:riverpod/riverpod.dart';

class const DuplicateCredentialDefinitionUsecase(
  final SkillCredentialDefinitionsRepository?
  _skillCredentialDefinitionsRepository, {
  required final CreateSkillCredentialDefinitionUsecase
  createSkillCredentialDefinitionUsecase,
  final CloudSkillStore? cloudStore,
}) {
  Future<SkillCredentialDefinitionEntity> call(String definitionId) async {
    final definition = await _requiredDefinition(definitionId);
    final title = await _copyTitle(definition);

    return await createSkillCredentialDefinitionUsecase.call(
      definition.workspaceId,
      .new(title: title, attributesJson: definition.attributesJson),
    );
  }
}

extension on DuplicateCredentialDefinitionUsecase {
  Future<SkillCredentialDefinitionEntity> _requiredDefinition(
    String definitionId,
  ) async {
    final cloud = cloudStore;
    final definition = cloud != null
        ? await cloud.definition(definitionId)
        : await _skillCredentialDefinitionsRepository?.getDefinitionById(
            definitionId,
          );
    if (definition == null) {
      throw StateError('Skill credential definition not found: $definitionId');
    }

    return definition;
  }

  Future<String> _copyTitle(SkillCredentialDefinitionEntity definition) async {
    for (var suffix = 1; ; suffix++) {
      final title = suffix == 1
          ? '${definition.title} Copy'
          : '${definition.title} Copy $suffix';
      if (!await _slugExists(
        definition.workspaceId,
        generateSkillSlug(title),
      )) {
        return title;
      }
    }
  }

  Future<bool> _slugExists(String workspaceId, String slug) async {
    final cloud = cloudStore;
    if (cloud != null) {
      return (await cloud.definitions()).any((item) => item.slug == slug);
    }
    final repository = _skillCredentialDefinitionsRepository;
    if (repository == null) {
      throw StateError('Credential definition store is unavailable');
    }

    return await repository.getDefinitionBySlug(workspaceId, slug) != null;
  }
}

final ProviderFamily<DuplicateCredentialDefinitionUsecase, String>
duplicateCredentialDefinitionUsecaseProvider =
    Provider.family<DuplicateCredentialDefinitionUsecase, String>((
      ref,
      workspaceId,
    ) {
      final cloud = ref.watch(cloudSkillStoreProvider(workspaceId));

      return DuplicateCredentialDefinitionUsecase(
        cloud == null
            ? ref.watch(skillCredentialDefinitionsRepositoryProvider)
            : null,
        createSkillCredentialDefinitionUsecase: ref.watch(
          createSkillCredentialDefinitionUsecaseProvider(workspaceId),
        ),
        cloudStore: cloud,
      );
    });
