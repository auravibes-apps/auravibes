import 'package:auravibes_app/features/skills/models/available_skill.dart';

class ConversationSkillSelectorState {
  const ConversationSkillSelectorState({
    required this.loaded,
    required this.loadable,
  });

  final List<AvailableSkill> loaded;
  final List<AvailableSkill> loadable;
}
