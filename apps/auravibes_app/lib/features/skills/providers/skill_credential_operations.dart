// ignore_for_file: implementation_imports
import 'package:auravibes_app/domain/entities/skill_credential_entity.dart';
import 'package:auravibes_app/features/skills/providers/cloud_skill_store_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:riverpod/src/providers/provider.dart';

class const SkillCredentialOperations({
  required final Future<SkillCredentialEntity> Function(
    String workspaceId,
    SkillCredentialToCreate value,
  )
  create,
  required final Future<SkillCredentialForEdit?> Function(String id) getForEdit,
  required final Future<SkillCredentialEntity> Function(
    String id,
    SkillCredentialToUpdate value,
  )
  update,
  required final Future<void> Function(String id) delete,
});

final ProviderFamily<SkillCredentialOperations, String>
skillCredentialOperationsProvider =
    Provider.family<SkillCredentialOperations, String>((ref, workspaceId) {
      final cloud = ref.watch(cloudSkillStoreProvider(workspaceId));
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
