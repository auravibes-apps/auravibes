import 'package:auravibes_app/features/skills/models/available_skill.dart';
import 'package:auravibes_app/features/skills/providers/conversation_skill_selector_state.dart';
import 'package:auravibes_app/features/skills/usecases/list_available_skills_usecase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'conversation_skill_selector_provider.g.dart';

typedef _SkillLoadRequest = ({
  ListAvailableSkillsUsecase usecase,
  String workspaceId,
  String conversationId,
  SkillLoadFilter filter,
});

typedef _SkillSelectorLoadRequest = ({
  ListAvailableSkillsUsecase usecase,
  String workspaceId,
  String conversationId,
});

Future<List<AvailableSkill>> _loadSkills(_SkillLoadRequest request) =>
    request.usecase.call(
      conversationId: request.conversationId,
      workspaceId: request.workspaceId,
      filter: request.filter,
    );

Future<List<AvailableSkill>> _loadSkillsForFilter(
  _SkillSelectorLoadRequest request,
  SkillLoadFilter filter,
) => _loadSkills((
  usecase: request.usecase,
  workspaceId: request.workspaceId,
  conversationId: request.conversationId,
  filter: filter,
));

@riverpod
Future<ConversationSkillSelectorState> conversationSkillSelector(
  Ref ref,
  String workspaceId,
  String conversationId,
) async {
  final skills = await _loadSelectorSkills((
    usecase: ref.watch(listAvailableSkillsUsecaseProvider(workspaceId)),
    workspaceId: workspaceId,
    conversationId: conversationId,
  ));

  return ConversationSkillSelectorState(
    loaded: skills.loaded,
    loadable: skills.loadable,
  );
}

Future<({List<AvailableSkill> loaded, List<AvailableSkill> loadable})>
_loadSelectorSkills(_SkillSelectorLoadRequest request) async {
  final loaded = await _loadSkillsForFilter(request, .loaded);
  final loadable = await _loadSkillsForFilter(request, .loadable);

  return (loaded: loaded, loadable: loadable);
}
