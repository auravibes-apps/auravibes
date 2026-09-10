import 'package:auravibes_app/data/repositories/skill_credential_definitions_repository.dart';
import 'package:auravibes_app/domain/entities/skill_credential_definition_entity.dart';
import 'package:auravibes_app/features/skills/providers/cloud_skill_store_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/services/cloud_skill_store.dart';
import 'package:auravibes_app/features/skills/usecases/validate_skill_title_usecase.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:riverpod/misc.dart';
import 'package:riverpod/riverpod.dart';

class const CreateSkillCredentialDefinitionUsecase(
  final SkillCredentialDefinitionsRepository?
  _skillCredentialDefinitionsRepository, {
  final CloudSkillStore? cloudStore,
}) {
  Future<SkillCredentialDefinitionEntity> call(
    String workspaceId,
    SkillCredentialDefinitionToCreate definition,
  ) async {
    await _validateNewDefinition(workspaceId, definition);

    return _createDefinition(workspaceId, definition);
  }

  Future<void> _validateNewDefinition(
    String workspaceId,
    SkillCredentialDefinitionToCreate definition,
  ) async {
    _validateDefinition(definition);
    await _ensureTitleAvailable(
      workspaceId,
      generateSkillSlug(definition.title),
    );
  }

  Future<void> _ensureTitleAvailable(String workspaceId, String slug) async {
    final existing = await _existingDefinition(workspaceId, slug);
    if (existing != null) _throwDuplicateDefinition();
  }

  void _validateDefinition(SkillCredentialDefinitionToCreate definition) {
    ValidateSkillTitleUsecase.call(definition.title);
    final _ = SkillCredentialAttributeDefinition.parseMap(
      definition.attributesJson,
    );
  }

  Future<SkillCredentialDefinitionEntity?> _existingDefinition(
    String workspaceId,
    String slug,
  ) async {
    final cloud = cloudStore;
    if (cloud != null) return _cloudDefinition(cloud, slug);
    final repository = _skillCredentialDefinitionsRepository;
    if (repository != null) {
      return repository.getDefinitionBySlug(workspaceId, slug);
    }
    throw StateError('Credential definition store is unavailable');
  }

  Future<SkillCredentialDefinitionEntity?> _cloudDefinition(
    CloudSkillStore cloud,
    String slug,
  ) async => (await cloud.definitions())
      .where((item) => item.slug == slug)
      .firstOrNull;

  Never _throwDuplicateDefinition() {
    throw const SkillTitleValidationException(
      'A credential definition with this title already exists',
    );
  }

  Future<SkillCredentialDefinitionEntity> _createDefinition(
    String workspaceId,
    SkillCredentialDefinitionToCreate definition,
  ) async {
    final cloud = cloudStore;
    if (cloud != null) return await cloud.createDefinition(definition);
    final repository = _skillCredentialDefinitionsRepository;
    if (repository == null) {
      throw StateError('Credential definition store is unavailable');
    }

    return await repository.createDefinition(workspaceId, definition);
  }
}

final ProviderFamily<CreateSkillCredentialDefinitionUsecase, String>
createSkillCredentialDefinitionUsecaseProvider =
    Provider.family<CreateSkillCredentialDefinitionUsecase, String>((
      ref,
      workspaceId,
    ) {
      final cloud = ref.watch(cloudSkillStoreProvider(workspaceId));

      return CreateSkillCredentialDefinitionUsecase(
        cloud == null
            ? ref.watch(skillCredentialDefinitionsRepositoryProvider)
            : null,
        cloudStore: cloud,
      );
    });
