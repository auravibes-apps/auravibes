// ignore_for_file: member-ordering
// Required: Existing declaration order groups related UI and model members.
import 'package:freezed_annotation/freezed_annotation.dart';

part 'skill_template_tool_entity.freezed.dart';

@freezed
abstract class SkillTemplateToolEntity with _$SkillTemplateToolEntity {
  const factory SkillTemplateToolEntity({
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
  const SkillTemplateToolEntity._();
}

@freezed
abstract class SkillTemplateToolToCreate with _$SkillTemplateToolToCreate {
  const factory SkillTemplateToolToCreate({
    required SkillTemplateToolType templateType,
    required String title,
    required String description,
    required String templateJson,
    required String inputsJson,
    @Default(false) bool requiresCredential,
    @Default(true) bool isEnabled,
  }) = _SkillTemplateToolToCreate;
  const SkillTemplateToolToCreate._();
}

@freezed
abstract class SkillTemplateToolToUpdate with _$SkillTemplateToolToUpdate {
  const factory SkillTemplateToolToUpdate({
    String? title,
    String? description,
    String? templateJson,
    String? inputsJson,
    bool? requiresCredential,
    bool? isEnabled,
  }) = _SkillTemplateToolToUpdate;
  const SkillTemplateToolToUpdate._();
}

enum SkillTemplateToolType { url }
