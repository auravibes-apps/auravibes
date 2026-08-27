import 'package:auravibes_app/features/agents/usecases/list_conversation_agent_skills_usecase.dart';
import 'package:auravibes_app/features/skills/models/available_skill.dart';
import 'package:auravibes_app/features/skills/usecases/build_loaded_skill_manifests_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/list_available_skills_usecase.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_engine/auravibes_engine.dart' as agent;
import 'package:riverpod/riverpod.dart';

class BuildSkillContextMessagesService {
  static const _builder = agent.BuildSkillContextMessages();
  const BuildSkillContextMessagesService(
    this._listAvailableSkillsUsecase,
    this._listConversationAgentSkillsUsecase, [
    this._buildLoadedSkillManifestsUsecase,
  ]);

  final Future<List<AvailableSkill>> Function({
    required String conversationId,
    required String workspaceId,
    required SkillLoadFilter filter,
  })
  _listAvailableSkillsUsecase;
  final ListConversationAgentSkillsUsecase _listConversationAgentSkillsUsecase;
  final BuildLoadedSkillManifestsUsecase? _buildLoadedSkillManifestsUsecase;

  Future<List<ChatMessage>> call({
    required String conversationId,
    required String workspaceId,
  }) async {
    final loadedSkills = await _listAvailableSkillsUsecase(
      conversationId: conversationId,
      workspaceId: workspaceId,
      filter: SkillLoadFilter.loaded,
    );
    final selectedAgent = await _listConversationAgentSkillsUsecase
        .loadSelectedAgent(
          conversationId: conversationId,
          workspaceId: workspaceId,
        );
    final agentSkills = await _listConversationAgentSkillsUsecase.call(
      conversationId: conversationId,
      workspaceId: workspaceId,
    );
    final manifests =
        await _buildLoadedSkillManifestsUsecase?.call(
          conversationId: conversationId,
          workspaceId: workspaceId,
          extraSkills: agentSkills,
        ) ??
        const <SkillManifest>[];
    final manifestsBySlug = {
      for (final manifest in manifests) manifest.slug: manifest,
    };
    final agentMessages = _builder.compose(
      agentContent: selectedAgent?.content,
      conversationSkills: [
        for (final skill in loadedSkills)
          agent.AgentSkill(
            title: skill.title,
            content: skill.content,
            identity: '${skill.source.name}:${skill.id}',
            manifest: manifestsBySlug[skill.slug],
          ),
      ],
      agentSkills: [
        for (final skill in agentSkills)
          agent.AgentSkill(
            title: skill.title,
            content: skill.content,
            identity: '${skill.source.name}:${skill.id}',
            manifest: manifestsBySlug[skill.slug],
          ),
      ],
    );

    return [
      for (final message in agentMessages)
        ChatMessage(
          role: switch (message.role) {
            agent.AgentChatMessageRole.system => ChatMessageRole.system,
            agent.AgentChatMessageRole.user => ChatMessageRole.user,
            agent.AgentChatMessageRole.model => ChatMessageRole.model,
            agent.AgentChatMessageRole.tool => ChatMessageRole.tool,
          },
          content: message.content,
          metadata: Map<String, Object?>.of(message.metadata),
        ),
    ];
  }
}

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
