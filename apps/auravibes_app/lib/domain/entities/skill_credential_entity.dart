import 'package:freezed_annotation/freezed_annotation.dart';

part 'skill_credential_entity.freezed.dart';

@freezed
abstract class const SkillCredentialEntity._() with _$SkillCredentialEntity {
  const factory({
    required String id,
    required String workspaceId,
    required String credentialDefinitionId,
    required String name,
    required Map<String, String> attributes,
    required bool isEnabled,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? keySuffix,
  }) = _SkillCredentialEntity;
}

@freezed
abstract class const SkillCredentialToCreate._()
    with _$SkillCredentialToCreate {
  const factory({
    required String credentialDefinitionId,
    required String name,
    required Map<String, String> attributes,
  }) = _SkillCredentialToCreate;
}

@freezed
abstract class const SkillCredentialSecretState._()
    with _$SkillCredentialSecretState {
  const factory({required bool hasValue, String? keySuffix}) =
      _SkillCredentialSecretState;
}

@freezed
abstract class const SkillCredentialForEdit._() with _$SkillCredentialForEdit {
  const factory({
    required String id,
    required String workspaceId,
    required String credentialDefinitionId,
    required String name,
    required Map<String, String> nonSecretAttributes,
    required Map<String, SkillCredentialSecretState> secretAttributes,
    required bool isEnabled,
    String? keySuffix,
  }) = _SkillCredentialForEdit;
}

@freezed
abstract class const SkillCredentialToUpdate._()
    with _$SkillCredentialToUpdate {
  // Null means preserve the existing credential name.
  // ignore: unnecessary-nullable
  const factory({
    String? name,
    @Default({}) Map<String, String> nonSecretAttributes,
    @Default({}) Map<String, String> secretAttributes,
    @Default({}) Set<String> clearSecretAttributeNames,
  }) = _SkillCredentialToUpdate;
}
