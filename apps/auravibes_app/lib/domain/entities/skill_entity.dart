// ignore_for_file: format-comment
// Required: Existing comments use generated or domain-specific formatting.
// ignore_for_file: member-ordering
// Required: Existing declaration order groups related UI and model members.
import 'package:freezed_annotation/freezed_annotation.dart';

part 'skill_entity.freezed.dart';

enum SkillSource { user, app }

enum SkillKind { template, native }

@freezed
abstract class SkillEntity with _$SkillEntity {
  const factory SkillEntity({
    required String id,
    required String workspaceId,
    required SkillSource source,
    required SkillKind kind,
    required String title,
    required String slug,
    required String description,
    required String content,
    required bool isEnabled,
    required bool isCredentialOptional,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? credentialDefinitionId,
  }) = _SkillEntity;
  const SkillEntity._();
}

@freezed
abstract class SkillToCreate with _$SkillToCreate {
  const factory SkillToCreate({
    required SkillKind kind,
    required String title,
    required String description,
    required String content,
    String? credentialDefinitionId,
    @Default(false) bool isCredentialOptional,
    @Default(true) bool isEnabled,
  }) = _SkillToCreate;
  const SkillToCreate._();
}

@freezed
abstract class SkillToUpdate with _$SkillToUpdate {
  const factory SkillToUpdate({
    String? title,
    String? description,
    String? content,
    String? credentialDefinitionId,
    @Default(false) bool clearCredentialDefinition,
    bool? isCredentialOptional,
    bool? isEnabled,
  }) = _SkillToUpdate;
  const SkillToUpdate._();
}
