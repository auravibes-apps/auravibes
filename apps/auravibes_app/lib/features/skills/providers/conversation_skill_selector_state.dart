import 'package:auravibes_app/features/skills/models/available_skill.dart';

class const ConversationSkillSelectorState({
  required final List<AvailableSkill> loaded,
  required final List<AvailableSkill> loadable,
  final Map<String, ConversationSkillContextStatus> contextStatusBySlug =
      const {},
});

enum ConversationSkillContextStatus { added, ready, needsContext, error }
