import 'package:auravibes_app/domain/entities/skill_credential_definition_entity.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'skill_credential_definitions_provider.g.dart';

@riverpod
Future<List<SkillCredentialDefinitionEntity>> skillCredentialDefinitions(
  Ref ref,
  String workspaceId,
) {
  return ref
      .watch(skillCredentialDefinitionsRepositoryProvider)
      .getDefinitions(workspaceId);
}

@riverpod
Future<SkillCredentialDefinitionEntity?> skillCredentialDefinition(
  Ref ref,
  String definitionId,
) {
  return ref
      .watch(skillCredentialDefinitionsRepositoryProvider)
      .getDefinitionById(definitionId);
}
