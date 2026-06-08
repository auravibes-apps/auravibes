// ignore_for_file: format-comment
// Required: Existing comments use generated or domain-specific formatting.
// ignore_for_file: member-ordering
// Required: Existing declaration order groups related UI and model members.
import 'package:freezed_annotation/freezed_annotation.dart';

part 'skill_credential_entity.freezed.dart';

@freezed
abstract class SkillCredentialEntity with _$SkillCredentialEntity {
  const factory SkillCredentialEntity({
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
  const SkillCredentialEntity._();
}

@freezed
abstract class SkillCredentialToCreate with _$SkillCredentialToCreate {
  const factory SkillCredentialToCreate({
    required String credentialDefinitionId,
    required String name,
    required Map<String, String> attributes,
  }) = _SkillCredentialToCreate;
  const SkillCredentialToCreate._();
}

@freezed
abstract class SkillCredentialSecretState with _$SkillCredentialSecretState {
  const factory SkillCredentialSecretState({
    required bool hasValue,
    String? keySuffix,
  }) = _SkillCredentialSecretState;
  const SkillCredentialSecretState._();
}

@freezed
abstract class SkillCredentialForEdit with _$SkillCredentialForEdit {
  const factory SkillCredentialForEdit({
    required String id,
    required String workspaceId,
    required String credentialDefinitionId,
    required String name,
    required Map<String, String> nonSecretAttributes,
    required Map<String, SkillCredentialSecretState> secretAttributes,
    required bool isEnabled,
    String? keySuffix,
  }) = _SkillCredentialForEdit;
  const SkillCredentialForEdit._();
}

@freezed
abstract class SkillCredentialToUpdate with _$SkillCredentialToUpdate {
  // Null means preserve the existing credential name.
  // ignore: unnecessary-nullable
  const factory SkillCredentialToUpdate({
    String? name,
    @Default({}) Map<String, String> nonSecretAttributes,
    @Default({}) Map<String, String> secretAttributes,
    @Default({}) Set<String> clearSecretAttributeNames,
  }) = _SkillCredentialToUpdate;
  const SkillCredentialToUpdate._();
}
