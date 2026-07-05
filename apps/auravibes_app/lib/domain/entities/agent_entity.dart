import 'package:freezed_annotation/freezed_annotation.dart';

part 'agent_entity.freezed.dart';

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
  }) = _AgentEntity;
  const AgentEntity._();
}

@freezed
abstract class AgentToCreate with _$AgentToCreate {
  const factory AgentToCreate({
    required String name,
    required String content,
    @Default([]) List<AgentSkillRef> skills,
  }) = _AgentToCreate;
  const AgentToCreate._();

  bool get isValid => name.trim().isNotEmpty && content.trim().isNotEmpty;
}

@freezed
abstract class AgentToUpdate with _$AgentToUpdate {
  const factory AgentToUpdate({
    String? name,
    String? content,
    List<AgentSkillRef>? skills,
  }) = _AgentToUpdate;
  const AgentToUpdate._();

  bool get isValid {
    final name = this.name;
    if (name != null && name.trim().isEmpty) return false;

    final content = this.content;
    if (content != null && content.trim().isEmpty) return false;

    return name != null || content != null || skills != null;
  }
}

@freezed
sealed class AgentSkillRef with _$AgentSkillRef {
  const factory AgentSkillRef.user(String skillId) = UserAgentSkillRef;

  const factory AgentSkillRef.app(String identifier) = AppAgentSkillRef;
}
