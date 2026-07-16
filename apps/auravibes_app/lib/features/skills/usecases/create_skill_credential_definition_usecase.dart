import 'package:auravibes_app/data/repositories/skill_credential_definitions_repository.dart';
import 'package:auravibes_app/domain/entities/skill_credential_definition_entity.dart';
import 'package:auravibes_app/features/skills/providers/cloud_skill_store_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/services/cloud_skill_store.dart';
import 'package:auravibes_app/features/skills/usecases/validate_skill_title_usecase.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:riverpod/riverpod.dart';

class CreateSkillCredentialDefinitionUsecase {
  const CreateSkillCredentialDefinitionUsecase(
    this._skillCredentialDefinitionsRepository, {
    this.cloudStore,
  });

  final SkillCredentialDefinitionsRepository?
  _skillCredentialDefinitionsRepository;
  final CloudSkillStore? cloudStore;

  Future<SkillCredentialDefinitionEntity> call(
    String workspaceId,
    SkillCredentialDefinitionToCreate definition,
  ) async {
    validateSkillTitle(definition.title);
    final _ = SkillCredentialAttributeDefinition.parseMap(
      definition.attributesJson,
    );
    final slug = generateSkillSlug(definition.title);
    final cloud = cloudStore;
    final repository = _skillCredentialDefinitionsRepository;
    final existing = switch ((cloud: cloud, repository: repository)) {
      (cloud: final cloud?, repository: _) =>
        (await cloud.definitions())
            .where((item) => item.slug == slug)
            .firstOrNull,
      (cloud: _, repository: final repository?) =>
        await repository.getDefinitionBySlug(
          workspaceId,
          slug,
        ),
      _ => throw StateError('Credential definition store is unavailable'),
    };
    if (existing != null) {
      throw const SkillTitleValidationException(
        'A credential definition with this title already exists',
      );
    }

    if (cloud != null) return cloud.createDefinition(definition);
    if (repository == null) {
      throw StateError('Credential definition store is unavailable');
    }

    return repository.createDefinition(workspaceId, definition);
  }
}

final createSkillCredentialDefinitionUsecaseProvider =
    Provider<CreateSkillCredentialDefinitionUsecase>((ref) {
      final cloud = ref.watch(cloudSkillStoreProvider);

      return CreateSkillCredentialDefinitionUsecase(
        cloud == null
            ? ref.watch(skillCredentialDefinitionsRepositoryProvider)
            : null,
        cloudStore: cloud,
      );
    });
