import 'package:auravibes_app/features/chats/providers/conversation_skill_context_runtime.dart';
import 'package:auravibes_app/features/skills/models/available_skill.dart';

class const ConversationSkillSelectorState({
  required final List<AvailableSkill> loaded,
  required final List<AvailableSkill> loadable,
  final Map<String, ConversationSkillContextStatus> contextStatusBySlug =
      const {},
  final Map<String, ConversationSkillContextFailure> failureBySlug = const {},
});

enum ConversationSkillContextStatus {
  added,
  preparing,
  ready,
  needsContext,
  error,
}
