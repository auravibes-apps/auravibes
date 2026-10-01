import 'package:auravibes_app/data/repositories/skill_credential_definitions_repository.dart';
import 'package:auravibes_app/domain/models/credential_definition_usage.dart';
import 'package:auravibes_app/features/skills/services/cloud_skill_store.dart';

class const ListCredentialDefinitionUsageUsecase({
  final SkillCredentialDefinitionsRepository? definitionsRepository,
  final CloudSkillStore? cloudStore,
}) {
  Future<CredentialDefinitionUsage> call({
    required String workspaceId,
    required String definitionId,
  }) async {
    await _ensureWorkspace(workspaceId, definitionId);
    final cloud = cloudStore;
    if (cloud != null) return await cloud.definitionUsage(definitionId);
    final repository = definitionsRepository;
    if (repository == null) {
      throw StateError('Credential definition store unavailable');
    }

    return await repository.getUsage(workspaceId, definitionId);
  }

  Future<void> _ensureWorkspace(String workspaceId, String definitionId) async {
    final cloud = cloudStore;
    final definition = cloud == null
        ? await definitionsRepository?.getDefinitionById(definitionId)
        : await cloud.definition(definitionId);
    if (definition == null || definition.workspaceId != workspaceId) {
      throw StateError('Credential definition unavailable in this workspace');
    }
  }
}
