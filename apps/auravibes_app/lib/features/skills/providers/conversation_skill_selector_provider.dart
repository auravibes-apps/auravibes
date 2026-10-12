import 'package:auravibes_app/domain/repositories/recent_skill_usage_repository.dart';
import 'package:auravibes_app/features/chats/providers/conversation_skill_context_runtime.dart';
import 'package:auravibes_app/features/skills/models/available_skill.dart';
import 'package:auravibes_app/features/skills/providers/conversation_skill_selector_state.dart';
import 'package:auravibes_app/features/skills/providers/recent_skill_usage_repository_provider.dart';
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
  RecentSkillUsageRepository recentSkillUsageRepository,
  String workspaceId,
  String conversationId,
  ConversationSkillContextSnapshot? snapshot,
});

typedef _SkillSelectorStateRequest = ({
  List<AvailableSkill> loaded,
  List<AvailableSkill> loadable,
  List<AvailableSkill> recentSkills,
  Map<String, String> revisions,
  ConversationSkillContextSnapshot? snapshot,
});

typedef _RecentSkillReadRequest = ({
  RecentSkillUsageRepository repository,
  String workspaceId,
  List<AvailableSkill> loaded,
  List<AvailableSkill> loadable,
});

typedef _SkillContextState = ({
  ConversationSkillContextStatus status,
  ConversationSkillContextFailure? failure,
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
  recentSkillUsageRepository: ref.watch(recentSkillUsageRepositoryProvider),
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
  final stateRequest = await _selectorStateRequest(dependencies, skills);

  return _selectorState(stateRequest);
}

Future<_SkillSelectorStateRequest> _selectorStateRequest(
  _SkillSelectorDependencies dependencies,
  ({List<AvailableSkill> loaded, List<AvailableSkill> loadable}) skills,
) async {
  final loaded = skills.loaded;
  final recentSkills = await _readRecentSkills((
    repository: dependencies.recentSkillUsageRepository,
    workspaceId: dependencies.workspaceId,
    loaded: loaded,
    loadable: skills.loadable,
  ));
  final revisions = await _currentSkillRevisions(dependencies, loaded);

  return (
    loaded: loaded,
    loadable: skills.loadable,
    recentSkills: recentSkills,
    revisions: revisions,
    snapshot: dependencies.snapshot,
  );
}

Future<List<AvailableSkill>> _readRecentSkills(
  _RecentSkillReadRequest request,
) async {
  try {
    final recentSlugs = await request.repository.readRecentSkillSlugs(
      request.workspaceId,
    );

    return _skillsInRecentOrder(recentSlugs, _skillIndex(request));
  } on Object {
    return const [];
  }
}

Map<String, AvailableSkill> _skillIndex(_RecentSkillReadRequest request) => {
  for (final skill in request.loadable) skill.slug: skill,
  for (final skill in request.loaded) skill.slug: skill,
};

List<AvailableSkill> _skillsInRecentOrder(
  List<String> recentSlugs,
  Map<String, AvailableSkill> skillsBySlug,
) => recentSlugs
    .toSet()
    .map((slug) => skillsBySlug[slug])
    .whereType<AvailableSkill>()
    .toList();

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
) {
  final contextBySlug = _contextBySlug(request);

  return ConversationSkillSelectorState(
    loaded: request.loaded,
    loadable: request.loadable,
    recentSkills: request.recentSkills,
    contextStatusBySlug: _contextStatuses(contextBySlug),
    failureBySlug: _contextFailures(contextBySlug),
  );
}

Map<String, _SkillContextState> _contextBySlug(
  _SkillSelectorStateRequest request,
) => {
  for (final skill in request.loaded)
    skill.slug: _skillContextState(
      skill,
      request.snapshot,
      request.revisions[skill.slug],
    ),
};

Map<String, ConversationSkillContextStatus> _contextStatuses(
  Map<String, _SkillContextState> contextBySlug,
) => {for (final entry in contextBySlug.entries) entry.key: entry.value.status};

Map<String, ConversationSkillContextFailure> _contextFailures(
  Map<String, _SkillContextState> contextBySlug,
) {
  final failures = <String, ConversationSkillContextFailure>{};
  for (final entry in contextBySlug.entries) {
    final failure = entry.value.failure;
    if (failure != null) failures[entry.key] = failure;
  }

  return failures;
}

_SkillContextState _skillContextState(
  AvailableSkill skill,
  ConversationSkillContextSnapshot? snapshot,
  String? revision,
) {
  final failure = _contextFailure(skill, snapshot, revision);

  return (
    failure: failure,
    status: _contextStatus(skill, snapshot, revision, failure),
  );
}

ConversationSkillContextStatus _contextStatus(
  AvailableSkill skill,
  ConversationSkillContextSnapshot? snapshot,
  String? currentRevision,
  ConversationSkillContextFailure? failure,
) {
  if (failure != null) {
    return .error;
  }
  if (snapshot == null) return .added;

  return switch (snapshot.phase) {
    .preparing => .preparing,
    .needsContext => .needsContext,
    .error => .error,
    .ready =>
      currentRevision == null
          ? .error
          : _readyStatus(skill, snapshot, currentRevision),
  };
}

ConversationSkillContextFailure? _contextFailure(
  AvailableSkill skill,
  ConversationSkillContextSnapshot? snapshot,
  String? currentRevision,
) {
  if (skill.credentialReadiness == .missing) {
    return .missingCredentials;
  }
  if (skill.credentialReadiness == .unknown) {
    return .preparationFailed;
  }
  if (currentRevision == null) return .unavailableMetadata;
  if (snapshot == null) return null;
  if (snapshot.phase == .error) {
    return snapshot.failure ?? .preparationFailed;
  }
  if (snapshot.phase == .ready && !snapshot.canActivate) {
    return .preparationFailed;
  }

  return null;
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
