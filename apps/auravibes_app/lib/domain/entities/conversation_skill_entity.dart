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
