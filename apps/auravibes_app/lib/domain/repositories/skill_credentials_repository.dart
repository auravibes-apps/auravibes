import 'package:auravibes_app/domain/entities/skill_credential_entity.dart';

abstract class SkillCredentialsRepository {
  Future<List<SkillCredentialEntity>> getCredentialsForDefinition({
    required String workspaceId,
    required String credentialDefinitionId,
  });

  Stream<List<SkillCredentialEntity>> watchCredentialsForWorkspace(
    String workspaceId,
  );

  Future<SkillCredentialEntity?> getCredentialById(String credentialId);

  Future<SkillCredentialForEdit?> getCredentialForEdit(String credentialId);

  Future<SkillCredentialEntity> createCredential(
    String workspaceId,
    SkillCredentialToCreate credential,
  );

  Future<SkillCredentialEntity> updateCredential(
    String credentialId,
    SkillCredentialToUpdate credential,
  );

  Future<void> deleteCredential(String credentialId);
}
