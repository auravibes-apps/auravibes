import 'package:auravibes_app/domain/entities/skill_credential_definition_entity.dart';
import 'package:auravibes_app/features/skills/providers/cloud_skill_store_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/services/cloud_skill_store.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'skill_credential_definitions_provider.g.dart';

@riverpod
Future<List<SkillCredentialDefinitionEntity>> skillCredentialDefinitions(
  Ref ref,
  String workspaceId,
) async {
  final cloud = await _cloudSkillStore(ref, workspaceId);
  if (cloud != null) return await cloud.definitions();

  return await ref
      .watch(skillCredentialDefinitionsRepositoryProvider)
      .getDefinitions(workspaceId);
}

Future<CloudSkillStore?> _cloudSkillStore(Ref ref, String workspaceId) async {
  final store = await cloudWorkspaceResourceStoreForWorkspace(ref, workspaceId);
  if (store == null) return null;

  return CloudSkillStore(store, workspaceId);
}

@riverpod
// ignore: prefer-static-class (required framework top-level declaration)
Future<SkillCredentialDefinitionEntity?> skillCredentialDefinition(
  Ref ref,
  String workspaceId,
  String definitionId,
) {
  final cloud = ref.watch(cloudSkillStoreProvider(workspaceId));
  if (cloud != null) return cloud.definition(definitionId);

  return ref
      .watch(skillCredentialDefinitionsRepositoryProvider)
      .getDefinitionById(definitionId);
}
