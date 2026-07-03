import 'package:freezed_annotation/freezed_annotation.dart';

export 'package:auravibes_skills/auravibes_skills.dart'
    show SkillCredentialAttributeDefinition;

part 'skill_credential_definition_entity.freezed.dart';

@freezed
abstract class SkillCredentialDefinitionEntity
    with _$SkillCredentialDefinitionEntity {
  const factory SkillCredentialDefinitionEntity({
    required String id,
    required String workspaceId,
    required String title,
    required String slug,
    required String attributesJson,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _SkillCredentialDefinitionEntity;
  const SkillCredentialDefinitionEntity._();
}

@freezed
abstract class SkillCredentialDefinitionToCreate
    with _$SkillCredentialDefinitionToCreate {
  const factory SkillCredentialDefinitionToCreate({
    required String title,
    required String attributesJson,
  }) = _SkillCredentialDefinitionToCreate;
  const SkillCredentialDefinitionToCreate._();
}

@freezed
abstract class SkillCredentialDefinitionToUpdate
    with _$SkillCredentialDefinitionToUpdate {
  const factory SkillCredentialDefinitionToUpdate({
    String? title,
    String? attributesJson,
  }) = _SkillCredentialDefinitionToUpdate;
  const SkillCredentialDefinitionToUpdate._();
}
