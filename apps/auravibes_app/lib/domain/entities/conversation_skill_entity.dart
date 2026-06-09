// ignore_for_file: format-comment
// Required: Existing comments use generated or domain-specific formatting.
// ignore_for_file: member-ordering
// Required: Existing declaration order groups related UI and model members.
import 'package:freezed_annotation/freezed_annotation.dart';

part 'conversation_skill_entity.freezed.dart';

@freezed
abstract class ConversationSkillEntity with _$ConversationSkillEntity {
  const factory ConversationSkillEntity({
    required String id,
    required String conversationId,
    required bool isLoaded,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? workspaceSkillId,
    String? appSkillIdentifier,
  }) = _ConversationSkillEntity;
  const ConversationSkillEntity._();

  bool get isUserSkill => workspaceSkillId?.isNotEmpty ?? false;

  bool get isAppSkill => appSkillIdentifier?.isNotEmpty ?? false;
}
