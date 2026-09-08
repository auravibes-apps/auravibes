import 'package:freezed_annotation/freezed_annotation.dart';

part 'skill_template_tool_entity.freezed.dart';

@freezed
abstract class const SkillTemplateToolEntity._()
    with _$SkillTemplateToolEntity {
  const factory({
    required String id,
    required String skillId,
    required SkillTemplateToolType templateType,
    required String title,
    required String description,
    required String slug,
    required String templateJson,
    required String inputsJson,
    required bool isEnabled,
    required bool requiresCredential,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _SkillTemplateToolEntity;
}

@freezed
abstract class const SkillTemplateToolToCreate._()
    with _$SkillTemplateToolToCreate {
  const factory({
    required SkillTemplateToolType templateType,
    required String title,
    required String description,
    required String templateJson,
    required String inputsJson,
    @Default(false) bool requiresCredential,
    @Default(true) bool isEnabled,
  }) = _SkillTemplateToolToCreate;
}

@freezed
abstract class const SkillTemplateToolToUpdate._()
    with _$SkillTemplateToolToUpdate {
  const factory({
    String? title,
    String? description,
    String? templateJson,
    String? inputsJson,
    bool? requiresCredential,
    bool? isEnabled,
  }) = _SkillTemplateToolToUpdate;
}

enum SkillTemplateToolType { url }
