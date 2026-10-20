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
  final currentWorkspace = workspaces
      .where((workspace) => workspace.id == currentWorkspaceId)
      .firstOrNull;
  final entries = <QuickSwitcherEntry>[
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

  final availabilityLoads = workspaces
      .map(
        (workspace) => _capture(
          ref.watch(workspaceAvailabilityProvider(workspace.id).future),
        ),
      )
      .toList();
  final availability = await Future.wait(availabilityLoads);
  var hasUnavailableResults = false;

  for (var index = 0; index < workspaces.length; index++) {
    final workspace = workspaces[index];
    final workspaceAvailability = availability[index];
    if (workspaceAvailability.hasError) {
      hasUnavailableResults = true;
      continue;
    }
    if (workspaceAvailability.value is! WorkspaceAvailable) continue;

    entries.add(_workspaceEntry(workspace));
    final conversationsLoad = _capture(
      ref.watch(
        conversationsStreamProvider(
          workspaceId: workspace.id,
          pagination: (limit: _recentConversationLimit, offset: 0),
        ).future,
      ),
    );
    final agentsLoad = _capture(ref.watch(agentsProvider(workspace.id).future));
    final skillsLoad = _capture(
      ref.watch(workspaceSkillsProvider(workspace.id).future),
    );
    final conversations = await conversationsLoad;
    final agents = await agentsLoad;
    final skills = await skillsLoad;

    hasUnavailableResults |=
        conversations.hasError || agents.hasError || skills.hasError;
    if (conversations.value case final conversationList?) {
      entries.addAll(
        conversationList.map(
          (conversation) => _conversationEntry(conversation, workspace),
        ),
      );
    }
    if (agents.value case final agentList?) {
      entries.addAll(agentList.map((agent) => _agentEntry(agent, workspace)));
    }
    if (skills.value case final skillList?) {
      entries.addAll(skillList.map((skill) => _skillEntry(skill, workspace)));
    }
  }

  return QuickSwitcherEntries(
    entries: entries,
    hasUnavailableResults: hasUnavailableResults,
  );
}

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
