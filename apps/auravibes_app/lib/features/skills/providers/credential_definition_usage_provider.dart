import 'package:auravibes_app/domain/models/credential_definition_usage.dart';
import 'package:auravibes_app/features/skills/providers/cloud_skill_store_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/usecases/list_credential_definition_usage_usecase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'credential_definition_usage_provider.g.dart';

@riverpod
Future<CredentialDefinitionUsage> credentialDefinitionUsage(
  Ref ref,
  String workspaceId,
  String definitionId,
) {
  final cloud = ref.watch(cloudSkillStoreProvider(workspaceId));

  return ListCredentialDefinitionUsageUsecase(
    definitionsRepository: cloud == null
        ? ref.watch(skillCredentialDefinitionsRepositoryProvider)
        : null,
    cloudStore: cloud,
  ).call(workspaceId: workspaceId, definitionId: definitionId);
}
