import 'package:freezed_annotation/freezed_annotation.dart';

part 'skill_credential_definition_entity.freezed.dart';

@freezed
abstract class const SkillCredentialDefinitionEntity._()
    with _$SkillCredentialDefinitionEntity {
  const factory({
    required String id,
    required String workspaceId,
    required String title,
    required String slug,
    required String attributesJson,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _SkillCredentialDefinitionEntity;
}

@freezed
abstract class const SkillCredentialDefinitionToCreate._()
    with _$SkillCredentialDefinitionToCreate {
  const factory({required String title, required String attributesJson}) =
      _SkillCredentialDefinitionToCreate;
}

@freezed
abstract class const SkillCredentialDefinitionToUpdate._()
    with _$SkillCredentialDefinitionToUpdate {
  const factory({String? title, String? attributesJson}) =
      _SkillCredentialDefinitionToUpdate;
}
