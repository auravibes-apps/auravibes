import 'package:freezed_annotation/freezed_annotation.dart';

part 'skill_entity.freezed.dart';

@freezed
abstract class const SkillEntity._() with _$SkillEntity {
  const factory({
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
}

@freezed
abstract class const SkillToCreate._() with _$SkillToCreate {
  const factory({
    required SkillKind kind,
    required String title,
    required String description,
    required String content,
    String? credentialDefinitionId,
    @Default(false) bool isCredentialOptional,
    @Default(true) bool isEnabled,
  }) = _SkillToCreate;
}

@freezed
abstract class const SkillToUpdate._() with _$SkillToUpdate {
  const factory({
    String? title,
    String? description,
    String? content,
    String? credentialDefinitionId,
    @Default(false) bool clearCredentialDefinition,
    bool? isCredentialOptional,
    bool? isEnabled,
  }) = _SkillToUpdate;
}

enum SkillSource { user, app }

enum SkillKind { template, native }
