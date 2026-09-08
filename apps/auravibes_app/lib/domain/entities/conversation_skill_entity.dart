import 'package:freezed_annotation/freezed_annotation.dart';

part 'conversation_skill_entity.freezed.dart';

@freezed
abstract class const ConversationSkillEntity._()
    with _$ConversationSkillEntity {
  const factory({
    required String id,
    required String conversationId,
    required bool isLoaded,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? workspaceSkillId,
    String? appSkillIdentifier,
  }) = _ConversationSkillEntity;
  bool get isUserSkill => workspaceSkillId?.isNotEmpty ?? false;

  bool get isAppSkill => appSkillIdentifier?.isNotEmpty ?? false;
}
