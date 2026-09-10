import 'package:auravibes_app/domain/entities/agent_entity.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/features/agents/agent_adapters/agent_repository.dart';
import 'package:auravibes_app/features/agents/providers/agent_repository_providers.dart';
import 'package:auravibes_app/features/agents/usecases/resolve_agent_skills_usecase.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/services/cloud_chat_gateway.dart';
import 'package:auravibes_app/features/skills/models/available_skill.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:riverpod/riverpod.dart';

typedef LoadAgentConversation = Future<ConversationEntity?> Function(
  String id,
  String workspaceId,
);

typedef ResolveAgentSkills = Future<ResolvedAgentSkills> Function({
  required String workspaceId,
  required List<AgentSkillRef> refs,
});

class const ListConversationAgentSkillsUsecase(
  final LoadAgentConversation _loadConversation,
  final AgentRepository Function(String workspaceId)
  _agentRepositoryForWorkspace,
  final ResolveAgentSkills _resolveAgentSkillsUsecase,
) {
  Future<List<AvailableSkill>> call({
    required String conversationId,
    required String workspaceId,
  }) async {
    final context = await loadSelectedAgent(
      conversationId: conversationId,
      workspaceId: workspaceId,
    );

    return context == null
        ? const []
        : (await _resolveAgentSkillsUsecase(
            workspaceId: workspaceId,
            refs: context.skills,
          )).available;
  }

  Future<AgentEntity?> loadSelectedAgent({
    required String conversationId,
    required String workspaceId,
  }) async {
    final conversation = await _loadConversation(conversationId, workspaceId);
    if (!_isConversationForWorkspace(conversation, workspaceId)) return null;

    return _loadVisibleAgent(workspaceId, conversation!);
  }

  bool _isConversationForWorkspace(
    ConversationEntity? conversation,
    String workspaceId,
  ) => conversation != null && conversation.workspaceId == workspaceId;

  Future<AgentEntity?> _loadVisibleAgent(
    String workspaceId,
    ConversationEntity conversation,
  ) async {
    final agentId = conversation.agentId;
    if (agentId == null) return null;

    final agent = await _agentRepositoryForWorkspace(workspaceId)
        .getAgentById(agentId);
    if (agent == null || !_isAvailableAgent(agent, workspaceId)) return null;

    return _isVisibleInConversation(conversation, agent) ? agent : null;
  }

  bool _isAvailableAgent(AgentEntity agent, String workspaceId) =>
      agent.workspaceId == workspaceId && agent.isEnabled;

  bool _isVisibleInConversation(
    ConversationEntity conversation,
    AgentEntity agent,
  ) {
    return conversation.parentConversationId != null
        ? agent.appearsInSubAgentList
        : agent.appearsInChatSelector;
  }
}

final listConversationAgentSkillsUsecaseProvider =
    Provider<ListConversationAgentSkillsUsecase>((ref) {
      return ListConversationAgentSkillsUsecase(
        (conversationId, workspaceId) async {
          final session = ref
              .read(workspaceSessionForRouteProvider(workspaceId))
              .requireValue;
          if (session.cloud == null) {
            return await ref
                .read(conversationRepositoryProvider)
                .getConversationById(conversationId);
          }
          final cloud = await ref.read(
            cloudWorkspaceStateGatewayProvider(session).future,
          );
          if (cloud == null) return null;
          final conversation = await CloudChatGateway(cloud)
              .getConversation(conversationId);

          return ConversationEntity(
            id: conversation.id,
            title: conversation.title,
            workspaceId: session.workspace.localWorkspaceId,
            isPinned: conversation.isPinned,
            createdAt: conversation.createdAt,
            updatedAt: conversation.updatedAt,
            revision: conversation.revision,
            modelId: conversation.modelId,
            agentId: conversation.agentId,
            parentConversationId: conversation.parentConversationId,
          );
        },
        (workspaceId) => ref.read(agentRepositoryProvider(workspaceId)),
        ({required workspaceId, required refs}) => ref
            .read(resolveAgentSkillsUsecaseProvider(workspaceId))
            .call(workspaceId: workspaceId, refs: refs),
      );
    });
