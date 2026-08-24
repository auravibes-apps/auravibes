import 'package:freezed_annotation/freezed_annotation.dart';

part 'agent_entity.freezed.dart';

abstract final class AgentLimits {
  static const descriptionMaxLength = 512;
}

enum AgentVisibility { chatSelector, subAgentList, both }

extension AgentVisibilityX on AgentVisibility {
  bool get appearsInChatSelector {
    return this == AgentVisibility.chatSelector || this == AgentVisibility.both;
  }

  bool get appearsInSubAgentList {
    return this == AgentVisibility.subAgentList || this == AgentVisibility.both;
  }
}

@freezed
abstract class AgentEntity with _$AgentEntity {
  const factory AgentEntity({
    required String id,
    required String workspaceId,
    required String name,
    required String content,
    required List<AgentSkillRef> skills,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default('') String description,
    @Default(true) bool isEnabled,
    @Default(AgentVisibility.both) AgentVisibility visibility,
  }) = _AgentEntity;
  const AgentEntity._();

  bool get appearsInChatSelector =>
      isEnabled && visibility.appearsInChatSelector;

  bool get appearsInSubAgentList =>
      isEnabled && visibility.appearsInSubAgentList;
}

@freezed
abstract class AgentToCreate with _$AgentToCreate {
  const factory AgentToCreate({
    required String name,
    required String description,
    required String content,
    @Default(true) bool isEnabled,
    @Default(AgentVisibility.both) AgentVisibility visibility,
    @Default([]) List<AgentSkillRef> skills,
  }) = _AgentToCreate;
  const AgentToCreate._();

  bool get isValid {
    final normalizedDescription = description.trim();

    return name.trim().isNotEmpty &&
        normalizedDescription.isNotEmpty &&
        normalizedDescription.length <= AgentLimits.descriptionMaxLength &&
        content.trim().isNotEmpty;
  }
}

@freezed
abstract class AgentToUpdate with _$AgentToUpdate {
  const factory AgentToUpdate({
    required String name,
    required String description,
    required String content,
    @Default(true) bool isEnabled,
    @Default(AgentVisibility.both) AgentVisibility visibility,
    @Default([]) List<AgentSkillRef> skills,
  }) = _AgentToUpdate;
  const AgentToUpdate._();

  bool get isValid {
    final normalizedDescription = description.trim();

    return name.trim().isNotEmpty &&
        normalizedDescription.isNotEmpty &&
        normalizedDescription.length <= AgentLimits.descriptionMaxLength &&
        content.trim().isNotEmpty;
  }
}

@freezed
sealed class AgentSkillRef with _$AgentSkillRef {
  const factory AgentSkillRef.user(String skillId) = UserAgentSkillRef;

  const factory AgentSkillRef.app(String identifier) = AppAgentSkillRef;
}
