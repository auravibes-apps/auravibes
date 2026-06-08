import 'package:auravibes_app/features/skills/providers/conversation_skill_selector_state.dart';
import 'package:auravibes_app/features/skills/usecases/list_available_skills_usecase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'conversation_skill_selector_provider.g.dart';

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
