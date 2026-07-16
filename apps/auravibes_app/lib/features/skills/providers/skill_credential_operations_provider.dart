import 'package:auravibes_app/domain/entities/skill_credential_entity.dart';
import 'package:auravibes_app/features/skills/providers/cloud_skill_store_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:riverpod/riverpod.dart';

class SkillCredentialOperations {
  const SkillCredentialOperations({
    required this.create,
    required this.getForEdit,
    required this.update,
    required this.delete,
  });

  final Future<SkillCredentialEntity> Function(
    String workspaceId,
    SkillCredentialToCreate value,
  )
  create;
  final Future<SkillCredentialForEdit?> Function(String id) getForEdit;
  final Future<SkillCredentialEntity> Function(
    String id,
    SkillCredentialToUpdate value,
  )
  update;
  final Future<void> Function(String id) delete;
}

final skillCredentialOperationsProvider = Provider<SkillCredentialOperations>((
  ref,
) {
  final cloud = ref.watch(cloudSkillStoreProvider);
  if (cloud != null) {
    return SkillCredentialOperations(
      create: (_, value) => cloud.createCredential(value),
      getForEdit: cloud.credentialForEdit,
      update: cloud.updateCredential,
      delete: cloud.deleteCredential,
    );
  }
  final local = ref.watch(skillCredentialsRepositoryProvider);

  return SkillCredentialOperations(
    create: local.createCredential,
    getForEdit: local.getCredentialForEdit,
    update: local.updateCredential,
    delete: local.deleteCredential,
  );
});
