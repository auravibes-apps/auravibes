import 'package:auravibes_app/domain/entities/agent_entity.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/features/agents/providers/agent_repository_providers.dart';
import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/features/quick_switcher/models/quick_switcher_entry.dart';
import 'package:auravibes_app/features/skills/models/workspace_skill.dart';
import 'package:auravibes_app/features/skills/providers/workspace_skills_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'quick_switcher_entries_provider.g.dart';

const _recentConversationLimit = 10;

@riverpod
Future<QuickSwitcherEntries> quickSwitcherEntries(
  Ref ref,
  String currentWorkspaceId,
) async {
  final workspaces = await ref.watch(allWorkspacesProvider.future);
  final currentWorkspace = _currentWorkspace(workspaces, currentWorkspaceId);
  final results = await _loadWorkspaceResults(ref, workspaces);

  return _quickSwitcherEntries(currentWorkspaceId, currentWorkspace, results);
}

WorkspaceEntity? _currentWorkspace(
  List<WorkspaceEntity> workspaces,
  String workspaceId,
) => workspaces.where((workspace) => workspace.id == workspaceId).firstOrNull;

Future<List<_WorkspaceResult>> _loadWorkspaceResults(
  Ref ref,
  List<WorkspaceEntity> workspaces,
) => Future.wait(
  workspaces.map((workspace) => _workspaceResult(ref, workspace)),
);

QuickSwitcherEntries _quickSwitcherEntries(
  String workspaceId,
  WorkspaceEntity? currentWorkspace,
  List<_WorkspaceResult> results,
) => QuickSwitcherEntries(
  entries: _quickSwitcherEntryList(workspaceId, currentWorkspace, results),
  hasUnavailableResults: results.any(_hasUnavailableResults),
);

List<QuickSwitcherEntry> _quickSwitcherEntryList(
  String workspaceId,
  WorkspaceEntity? currentWorkspace,
  List<_WorkspaceResult> results,
) =>
    _actionEntries(workspaceId, currentWorkspace)
      ..addAll(results.expand((result) => result.entries));

List<QuickSwitcherEntry> _actionEntries(
  String currentWorkspaceId,
  WorkspaceEntity? currentWorkspace,
) => [
  QuickSwitcherEntry(
    type: .newConversation,
    workspaceId: currentWorkspaceId,
    workspaceName: currentWorkspace?.name ?? '',
    title: '',
    titleKey: LocaleKeys.quick_switcher_new_conversation,
  ),
  QuickSwitcherEntry(
    type: .settings,
    workspaceId: currentWorkspaceId,
    workspaceName: currentWorkspace?.name ?? '',
    title: '',
    titleKey: LocaleKeys.quick_switcher_settings,
  ),
];

Future<_WorkspaceResult> _workspaceResult(
  Ref ref,
  WorkspaceEntity workspace,
) async {
  final availability = await _capture(
    ref.watch(workspaceAvailabilityProvider(workspace.id).future),
  );

  return await _workspaceResultForAvailability(
    ref,
    workspace,
    availability.hasError,
    availability.value is WorkspaceAvailable,
  );
}

Future<_WorkspaceResult> _workspaceResultForAvailability(
  Ref ref,
  WorkspaceEntity workspace,
  bool hasError,
  bool isAvailable,
) async {
  if (hasError) {
    return (entries: const <QuickSwitcherEntry>[], hasUnavailableResults: true);
  }
  if (!isAvailable) {
    return (
      entries: const <QuickSwitcherEntry>[],
      hasUnavailableResults: false,
    );
  }

  final data = await _loadWorkspaceData(ref, workspace);

  return (
    entries: _workspaceEntries(workspace, data),
    hasUnavailableResults: _hasUnavailableWorkspaceData(data),
  );
}

Future<_WorkspaceData> _loadWorkspaceData(
  Ref ref,
  WorkspaceEntity workspace,
) async {
  final conversations = _loadConversations(ref, workspace);
  final agents = _loadAgents(ref, workspace);
  final skills = _loadSkills(ref, workspace);

  return (
    conversations: await conversations,
    agents: await agents,
    skills: await skills,
  );
}

Future<_Captured<List<ConversationEntity>>> _loadConversations(
  Ref ref,
  WorkspaceEntity workspace,
) {
  final provider = conversationsStreamProvider(
    workspaceId: workspace.id,
    pagination: (limit: _recentConversationLimit, offset: 0),
  );

  return _capture(ref.watch(provider.future));
}

Future<_Captured<List<AgentEntity>>> _loadAgents(
  Ref ref,
  WorkspaceEntity workspace,
) => _capture(ref.watch(agentsProvider(workspace.id).future));

Future<_Captured<List<WorkspaceSkill>>> _loadSkills(
  Ref ref,
  WorkspaceEntity workspace,
) => _capture(ref.watch(workspaceSkillsProvider(workspace.id).future));

List<QuickSwitcherEntry> _workspaceEntries(
  WorkspaceEntity workspace,
  _WorkspaceData data,
) => [
  _workspaceEntry(workspace),
  ..._entriesFor(
    data.conversations.value,
    (value) => _conversationEntry(value, workspace),
  ),
  ..._entriesFor(data.agents.value, (value) => _agentEntry(value, workspace)),
  ..._entriesFor(data.skills.value, (value) => _skillEntry(value, workspace)),
];

Iterable<QuickSwitcherEntry> _entriesFor<T>(
  Iterable<T>? values,
  QuickSwitcherEntry Function(T) toEntry,
) => values?.map(toEntry) ?? const [];

bool _hasUnavailableResults(_WorkspaceResult result) =>
    result.hasUnavailableResults;

bool _hasUnavailableWorkspaceData(_WorkspaceData data) =>
    data.conversations.hasError || data.agents.hasError || data.skills.hasError;

typedef _WorkspaceResult = ({
  List<QuickSwitcherEntry> entries,
  bool hasUnavailableResults,
});

typedef _WorkspaceData = ({
  _Captured<List<ConversationEntity>> conversations,
  _Captured<List<AgentEntity>> agents,
  _Captured<List<WorkspaceSkill>> skills,
});
QuickSwitcherEntry _workspaceEntry(WorkspaceEntity workspace) =>
    QuickSwitcherEntry(
      type: .workspace,
      workspaceId: workspace.id,
      workspaceName: workspace.name,
      title: workspace.name,
      id: workspace.id,
    );

QuickSwitcherEntry _conversationEntry(
  ConversationEntity conversation,
  WorkspaceEntity workspace,
) => QuickSwitcherEntry(
  type: .conversation,
  workspaceId: workspace.id,
  workspaceName: workspace.name,
  title: conversation.title,
  id: conversation.id,
);

QuickSwitcherEntry _agentEntry(AgentEntity agent, WorkspaceEntity workspace) =>
    QuickSwitcherEntry(
      type: .agent,
      workspaceId: workspace.id,
      workspaceName: workspace.name,
      title: agent.name,
      id: agent.id,
      searchTerms: agent.description,
    );

QuickSwitcherEntry _skillEntry(
  WorkspaceSkill skill,
  WorkspaceEntity workspace,
) => QuickSwitcherEntry(
  type: .skill,
  workspaceId: workspace.id,
  workspaceName: workspace.name,
  title: skill.title,
  id: skill.id,
  titleKey: skill.titleKey,
  searchTerms: skill.description,
);

typedef _Captured<T> = ({T? value, bool hasError});

Future<_Captured<T>> _capture<T>(Future<T> future) async {
  try {
    return (value: await future, hasError: false);
  } on Object {
    return (value: null, hasError: true);
  }
}
