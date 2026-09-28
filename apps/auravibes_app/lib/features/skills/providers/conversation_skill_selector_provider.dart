import 'package:auravibes_app/features/chats/providers/conversation_skill_context_runtime.dart';
import 'package:auravibes_app/features/skills/models/available_skill.dart';
import 'package:auravibes_app/features/skills/providers/conversation_skill_selector_state.dart';
import 'package:auravibes_app/features/skills/usecases/build_loaded_skill_manifests_usecase.dart';
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

typedef _SkillSelectorDependencies = ({
  BuildLoadedSkillManifestsUsecase buildManifests,
  ListAvailableSkillsUsecase listSkills,
  String workspaceId,
  String conversationId,
  ConversationSkillContextSnapshot? snapshot,
});

typedef _SkillSelectorStateRequest = ({
  List<AvailableSkill> loaded,
  List<AvailableSkill> loadable,
  Map<String, String> revisions,
  ConversationSkillContextSnapshot? snapshot,
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
) => _buildSelectorState((
  buildManifests: ref.watch(buildLoadedSkillManifestsUsecaseProvider),
  listSkills: ref.watch(listAvailableSkillsUsecaseProvider(workspaceId)),
  workspaceId: workspaceId,
  conversationId: conversationId,
  snapshot: ref.watch(conversationSkillContextRuntimeProvider)[conversationId],
));

Future<ConversationSkillSelectorState> _buildSelectorState(
  _SkillSelectorDependencies dependencies,
) async {
  final skills = await _loadSelectorSkills((
    usecase: dependencies.listSkills,
    workspaceId: dependencies.workspaceId,
    conversationId: dependencies.conversationId,
  ));
  final loaded = skills.loaded;
  final revisions = await _currentSkillRevisions(dependencies, loaded);

  return _selectorState((
    loaded: loaded,
    loadable: skills.loadable,
    revisions: revisions,
    snapshot: dependencies.snapshot,
  ));
}

Future<Map<String, String>> _currentSkillRevisions(
  _SkillSelectorDependencies dependencies,
  List<AvailableSkill> loadedSkills,
) async {
  if (loadedSkills.isEmpty) return const {};

  final revisions = <String, String>{};
  try {
    for (final manifest in await dependencies.buildManifests.call(
      conversationId: dependencies.conversationId,
      workspaceId: dependencies.workspaceId,
    )) {
      revisions[manifest.slug] = manifest.revision;
    }
  } on Exception {
    // Selection remains visible when current manifests cannot be prepared.
  }

  return revisions;
}

ConversationSkillSelectorState _selectorState(
  _SkillSelectorStateRequest request,
) => ConversationSkillSelectorState(
  loaded: request.loaded,
  loadable: request.loadable,
  contextStatusBySlug: {
    for (final skill in request.loaded)
      skill.slug: _contextStatus(
        skill,
        request.snapshot,
        request.revisions[skill.slug],
      ),
  },
);

ConversationSkillContextStatus _contextStatus(
  AvailableSkill skill,
  ConversationSkillContextSnapshot? snapshot,
  String? currentRevision,
) {
  if (skill.credentialReadiness == .missing || currentRevision == null) {
    return .error;
  }
  if (snapshot == null) return .added;

  return switch (snapshot.phase) {
    .preparing || .needsContext => .needsContext,
    .error => .error,
    .ready => _readyStatus(skill, snapshot, currentRevision),
  };
}

ConversationSkillContextStatus _readyStatus(
  AvailableSkill skill,
  ConversationSkillContextSnapshot snapshot,
  String currentRevision,
) {
  if (!snapshot.canActivate) return .error;

  final preparedRevision = snapshot.selectedRevisions[skill.slug];
  if (preparedRevision == null) return .added;

  return preparedRevision == currentRevision ? .ready : .needsContext;
}

Future<({List<AvailableSkill> loaded, List<AvailableSkill> loadable})>
_loadSelectorSkills(_SkillSelectorLoadRequest request) async {
  final loaded = await _loadSkillsForFilter(request, .loaded);
  final selectable = await _loadSkillsForFilter(request, .selector);
  final loadedIds = loaded.map((skill) => skill.id).toSet();
  final loadable = _excludeLoadedSkills(selectable, loadedIds);

  return (loaded: loaded, loadable: loadable);
}

List<AvailableSkill> _excludeLoadedSkills(
  List<AvailableSkill> selectable,
  Set<String> loadedIds,
) => selectable.where((skill) => !loadedIds.contains(skill.id)).toList();
