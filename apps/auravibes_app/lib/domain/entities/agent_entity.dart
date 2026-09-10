import 'package:auravibes_app/domain/entities/agent_limits.dart';
import 'package:auravibes_app/domain/entities/agent_visibility.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

export 'agent_limits.dart';
export 'agent_visibility.dart';

part 'agent_entity.freezed.dart';

@immutable
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
  @override
  int get hashCode;

  @override
  String toString();

  @override
  bool operator ==(Object other);
}

extension AgentEntityHelpers on AgentEntity {
  bool get appearsInChatSelector =>
      isEnabled && visibility.appearsInChatSelector;

  bool get appearsInSubAgentList =>
      isEnabled && visibility.appearsInSubAgentList;

  String identity() => id;

  bool hasSkills() => skills.isNotEmpty;

  bool hasDescription() => description.trim().isNotEmpty;
}

@immutable
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

  @override
  int get hashCode;

  bool hasRequiredName() => name.trim().isNotEmpty;

  bool hasRequiredContent() => content.trim().isNotEmpty;

  @override
  String toString();

  @override
  bool operator ==(Object other);
}

@immutable
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

  @override
  int get hashCode;

  bool hasRequiredName() => name.trim().isNotEmpty;

  bool hasRequiredContent() => content.trim().isNotEmpty;

  @override
  String toString();

  @override
  bool operator ==(Object other);
}

@immutable
@freezed
sealed class AgentSkillRef with _$AgentSkillRef {
  const factory user(String skillId) = UserAgentSkillRef;

  const factory app(String identifier) = AppAgentSkillRef;

  @override
  int get hashCode;

  @override
  String toString();

  @override
  bool operator ==(Object other);

  String skillIdentifier() => switch (this) {
    UserAgentSkillRef(:final skillId) => skillId,
    AppAgentSkillRef(:final identifier) => identifier,
  };

  bool isAppSkill() => this is AppAgentSkillRef;
}
