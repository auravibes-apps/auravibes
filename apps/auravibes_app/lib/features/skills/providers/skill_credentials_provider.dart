import 'package:auravibes_app/domain/entities/skill_credential_entity.dart';
import 'package:auravibes_app/features/skills/providers/cloud_skill_store_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'skill_credentials_provider.g.dart';

@riverpod
Future<List<SkillCredentialEntity>> skillCredentialsForDefinition(
  Ref ref,
  String workspaceId,
  String credentialDefinitionId,
) {
  final cloud = ref.watch(cloudSkillStoreProvider(workspaceId));
  if (cloud != null) return cloud.credentials(credentialDefinitionId);

  return ref
      .watch(skillCredentialsRepositoryProvider)
      .getCredentialsForDefinition(
        workspaceId: workspaceId,
        credentialDefinitionId: credentialDefinitionId,
      );
}
