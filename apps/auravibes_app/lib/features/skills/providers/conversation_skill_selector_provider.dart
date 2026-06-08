import 'package:auravibes_app/features/skills/models/available_skill.dart';
import 'package:auravibes_app/features/skills/usecases/list_available_skills_usecase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'conversation_skill_selector_provider.g.dart';

class ConversationSkillSelectorState {
  const ConversationSkillSelectorState({
    required this.loaded,
    required this.loadable,
  });

  final List<AvailableSkill> loaded;
  final List<AvailableSkill> loadable;
}

@riverpod
Future<ConversationSkillSelectorState> conversationSkillSelector(
  Ref ref,
  String workspaceId,
  String conversationId,
) async {
  final usecase = ref.watch(listAvailableSkillsUsecaseProvider);
  final loaded = await usecase.call(
    conversationId: conversationId,
    workspaceId: workspaceId,
    filter: SkillLoadFilter.loaded,
  );
  final loadable = await usecase.call(
    conversationId: conversationId,
    workspaceId: workspaceId,
    filter: SkillLoadFilter.loadable,
  );
  return ConversationSkillSelectorState(loaded: loaded, loadable: loadable);
}
