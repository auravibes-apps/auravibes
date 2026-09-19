import 'package:auravibes_app/domain/entities/agent_entity.dart';
import 'package:auravibes_app/features/agents/usecases/list_conversation_agent_skills_usecase.dart';
import 'package:auravibes_app/features/skills/models/available_skill.dart';
import 'package:auravibes_app/features/skills/usecases/build_loaded_skill_manifests_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/list_available_skills_usecase.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_engine/auravibes_engine.dart' as agent;
import 'package:riverpod/riverpod.dart';

class const BuildSkillContextMessagesService(
  final Future<List<AvailableSkill>> Function({
    required String conversationId,
    required String workspaceId,
    required SkillLoadFilter filter,
  })
  _listAvailableSkillsUsecase,
  final ListConversationAgentSkillsUsecase
  _listConversationAgentSkillsUsecase, [
  final BuildLoadedSkillManifestsUsecase? _buildLoadedSkillManifestsUsecase,
]) {
  static const _builder = agent.BuildSkillContextMessages();
  Future<List<ChatMessage>> call({
    required String conversationId,
    required String workspaceId,
  }) async {
    final context = await _loadContext(conversationId, workspaceId);
    final agentMessages = _builder.compose(
      agentContent: context.selectedAgent?.content,
      conversationSkills: const [],
      skillCatalog: _catalogEntries(context),
      agentSkills: _toAgentSkills(context.agentSkills, context.manifestsBySlug),
    );

    return _toChatMessages(agentMessages);
  }
}

typedef _SkillContextData = ({
  AgentEntity? selectedAgent,
  List<AvailableSkill> catalogSkills,
  List<AvailableSkill> loadedSkills,
  List<AvailableSkill> agentSkills,
  Map<String, SkillManifest> manifestsBySlug,
});

typedef _SkillContextSkills = ({
  List<AvailableSkill> catalogSkills,
  List<AvailableSkill> loadedSkills,
  List<AvailableSkill> agentSkills,
});

extension on BuildSkillContextMessagesService {
  Future<_SkillContextData> _loadContext(
    String conversationId,
    String workspaceId,
  ) async {
    final skills = await _loadSkills(conversationId, workspaceId);
    final selectedAgent = await _selectedAgent(conversationId, workspaceId);
    final manifests = await _manifestsForSkills(
      conversationId,
      workspaceId,
      skills,
    );

    return _contextData(selectedAgent, skills, manifests);
  }

  Future<List<SkillManifest>> _manifestsForSkills(
    String conversationId,
    String workspaceId,
    _SkillContextSkills skills,
  ) => _manifests(conversationId, workspaceId, [
    ...skills.catalogSkills,
    ...skills.agentSkills,
  ]);

  _SkillContextData _contextData(
    AgentEntity? selectedAgent,
    _SkillContextSkills skills,
    List<SkillManifest> manifests,
  ) => (
    selectedAgent: selectedAgent,
    catalogSkills: skills.catalogSkills,
    loadedSkills: skills.loadedSkills,
    agentSkills: skills.agentSkills,
    manifestsBySlug: {
      for (final manifest in manifests) manifest.slug: manifest,
    },
  );

  Future<_SkillContextSkills> _loadSkills(
    String conversationId,
    String workspaceId,
  ) async {
    final catalogSkills = await _catalogSkills(conversationId, workspaceId);
    final loadedSkills = await _loadedSkills(conversationId, workspaceId);
    final agentSkills = await _agentSkills(conversationId, workspaceId);

    return (
      catalogSkills: catalogSkills,
      loadedSkills: loadedSkills,
      agentSkills: agentSkills,
    );
  }

  Future<List<AvailableSkill>> _catalogSkills(
    String conversationId,
    String workspaceId,
  ) => _listAvailableSkillsUsecase(
    conversationId: conversationId,
    workspaceId: workspaceId,
    filter: SkillLoadFilter.catalog,
  );

  Future<List<AvailableSkill>> _loadedSkills(
    String conversationId,
    String workspaceId,
  ) => _listAvailableSkillsUsecase(
    conversationId: conversationId,
    workspaceId: workspaceId,
    filter: SkillLoadFilter.loaded,
  );

  Future<AgentEntity?> _selectedAgent(
    String conversationId,
    String workspaceId,
  ) => _listConversationAgentSkillsUsecase.loadSelectedAgent(
    conversationId: conversationId,
    workspaceId: workspaceId,
  );

  Future<List<AvailableSkill>> _agentSkills(
    String conversationId,
    String workspaceId,
  ) => _listConversationAgentSkillsUsecase.call(
    conversationId: conversationId,
    workspaceId: workspaceId,
  );

  Future<List<SkillManifest>> _manifests(
    String conversationId,
    String workspaceId,
    List<AvailableSkill> agentSkills,
  ) async =>
      await _buildLoadedSkillManifestsUsecase?.call(
        conversationId: conversationId,
        workspaceId: workspaceId,
        extraSkills: agentSkills,
      ) ??
      const <SkillManifest>[];
}

List<ChatMessage> _toChatMessages(List<agent.AgentChatMessage> messages) => [
  for (final message in messages) _toChatMessage(message),
];

List<SkillCatalogEntry> _catalogEntries(_SkillContextData context) =>
    _sortCatalogEntries(_buildCatalogEntries(context));

List<SkillCatalogEntry> _buildCatalogEntries(_SkillContextData context) {
  final activeSlugs = context.loadedSkills.map((skill) => skill.slug).toSet();

  return [
    for (final skill in context.catalogSkills)
      _catalogEntry(skill, context, activeSlugs),
  ].whereType<SkillCatalogEntry>().toList();
}

List<SkillCatalogEntry> _sortCatalogEntries(List<SkillCatalogEntry> entries) =>
    entries..sort((left, right) => left.slug.compareTo(right.slug));

SkillCatalogEntry? _catalogEntry(
  AvailableSkill skill,
  _SkillContextData context,
  Set<String> activeSlugs,
) {
  final manifest = context.manifestsBySlug[skill.slug];
  if (manifest == null) return null;

  return SkillCatalogEntry(
    slug: skill.slug,
    title: skill.title,
    description: skill.description,
    revision: manifest.revision,
    active: activeSlugs.contains(skill.slug),
  );
}

ChatMessage _toChatMessage(agent.AgentChatMessage message) => ChatMessage(
  role: _chatMessageRole(message.role),
  content: message.content,
  metadata: Map<String, Object?>.of(message.metadata),
);

ChatMessageRole _chatMessageRole(agent.AgentChatMessageRole role) =>
    switch (role) {
      agent.AgentChatMessageRole.system => ChatMessageRole.system,
      agent.AgentChatMessageRole.user => ChatMessageRole.user,
      agent.AgentChatMessageRole.model => ChatMessageRole.model,
      agent.AgentChatMessageRole.tool => ChatMessageRole.tool,
    };

List<agent.AgentSkill> _toAgentSkills(
  List<AvailableSkill> skills,
  Map<String, SkillManifest> manifestsBySlug,
) => [
  for (final skill in skills)
    agent.AgentSkill(
      title: skill.title,
      content: skill.content,
      identity: '${skill.source.name}:${skill.id}',
      manifest: manifestsBySlug[skill.slug],
    ),
];

final buildSkillContextMessagesServiceProvider =
    Provider<BuildSkillContextMessagesService>((ref) {
      return BuildSkillContextMessagesService(
        ({required conversationId, required workspaceId, required filter}) =>
            ref
                .watch(listAvailableSkillsUsecaseProvider(workspaceId))
                .call(
                  conversationId: conversationId,
                  workspaceId: workspaceId,
                  filter: filter,
                ),
        ref.watch(listConversationAgentSkillsUsecaseProvider),
        ref.watch(buildLoadedSkillManifestsUsecaseProvider),
      );
    });
