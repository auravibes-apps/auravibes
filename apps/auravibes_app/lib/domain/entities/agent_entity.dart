import 'package:auravibes_app/domain/entities/agent_limits.dart';
import 'package:auravibes_app/domain/entities/agent_visibility.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

export 'agent_limits.dart';
export 'agent_visibility.dart';

part 'agent_entity.freezed.dart';

@freezed
abstract class const AgentEntity._() with _$AgentEntity {
  const factory({
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
  bool get appearsInChatSelector =>
      isEnabled && visibility.appearsInChatSelector;

  bool get appearsInSubAgentList =>
      isEnabled && visibility.appearsInSubAgentList;
}

@freezed
abstract class const AgentToCreate._() with _$AgentToCreate {
  const factory({
    required String name,
    required String description,
    required String content,
    @Default(true) bool isEnabled,
    @Default(AgentVisibility.both) AgentVisibility visibility,
    @Default([]) List<AgentSkillRef> skills,
  }) = _AgentToCreate;
  bool get isValid {
    final normalizedDescription = description.trim();

    return name.trim().isNotEmpty &&
        normalizedDescription.isNotEmpty &&
        normalizedDescription.length <= AgentLimits.descriptionMaxLength &&
        content.trim().isNotEmpty;
  }
}

@freezed
abstract class const AgentToUpdate._() with _$AgentToUpdate {
  const factory({
    required String name,
    required String description,
    required String content,
    @Default(true) bool isEnabled,
    @Default(AgentVisibility.both) AgentVisibility visibility,
    @Default([]) List<AgentSkillRef> skills,
  }) = _AgentToUpdate;
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
  const factory user(String skillId) = UserAgentSkillRef;

  const factory app(String identifier) = AppAgentSkillRef;
}
