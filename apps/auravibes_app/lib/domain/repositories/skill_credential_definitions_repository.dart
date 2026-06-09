import 'package:auravibes_app/domain/entities/skill_credential_definition_entity.dart';

abstract class SkillCredentialDefinitionsRepository {
  Future<List<SkillCredentialDefinitionEntity>> getDefinitions(
    String workspaceId,
  );

  Stream<List<SkillCredentialDefinitionEntity>> watchDefinitions(
    String workspaceId,
  );

  Future<SkillCredentialDefinitionEntity?> getDefinitionById(
    String definitionId,
  );

  Future<SkillCredentialDefinitionEntity?> getDefinitionBySlug(
    String workspaceId,
    String slug,
  );

  Future<SkillCredentialDefinitionEntity> createDefinition(
    String workspaceId,
    SkillCredentialDefinitionToCreate definition,
  );

  Future<SkillCredentialDefinitionEntity> updateDefinition(
    String definitionId,
    SkillCredentialDefinitionToUpdate definition,
  );

  Future<bool> deleteDefinition(String definitionId);
}
