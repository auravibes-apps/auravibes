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
import 'package:riverpod_annotation/experimental/scope.dart';

typedef LoadAgentConversation = Future<ConversationEntity?> Function(String id);

class ListConversationAgentSkillsUsecase {
  const ListConversationAgentSkillsUsecase(
    this._loadConversation,
    this._agentRepository,
    this._resolveAgentSkillsUsecase,
  );

  final LoadAgentConversation _loadConversation;
  final AgentRepository _agentRepository;
  final ResolveAgentSkillsUsecase _resolveAgentSkillsUsecase;

  Future<List<AvailableSkill>> call({
    required String conversationId,
    required String workspaceId,
  }) async {
    final context = await loadSelectedAgent(
      conversationId: conversationId,
      workspaceId: workspaceId,
    );
    if (context == null) return const [];

    final resolved = await _resolveAgentSkillsUsecase.call(
      workspaceId: workspaceId,
      refs: context.skills,
    );

    return resolved.available;
  }

  Future<AgentEntity?> loadSelectedAgent({
    required String conversationId,
    required String workspaceId,
  }) async {
    final conversation = await _loadConversation(conversationId);
    if (conversation?.workspaceId != workspaceId) return null;

    final agentId = conversation?.agentId;
    if (agentId == null) return null;

    final agent = await _agentRepository.getAgentById(agentId);
    if (agent == null || agent.workspaceId != workspaceId) return null;
    if (!agent.isEnabled) return null;

    final isSubAgentConversation = conversation?.parentConversationId != null;
    if (isSubAgentConversation) {
      if (!agent.appearsInSubAgentList) return null;
    } else if (!agent.appearsInChatSelector) {
      return null;
    }

    return agent;
  }
}

@Dependencies([
  workspaceSession,
  cloudWorkspaceStateGateway,
])
final listConversationAgentSkillsUsecaseProvider =
    Provider<ListConversationAgentSkillsUsecase>(
      (ref) {
        final session = ref.watch(workspaceSessionProvider);
        final gateway = ref.watch(cloudWorkspaceStateGatewayProvider.future);

        return ListConversationAgentSkillsUsecase(
          session.cloud == null
              ? ref.watch(conversationRepositoryProvider).getConversationById
              : (conversationId) async {
                  final cloud = await gateway;
                  if (cloud == null) return null;
                  final conversation =
                      await CloudChatGateway(
                        cloud,
                      ).getConversation(
                        conversationId,
                      );

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

          ref.watch(agentRepositoryProvider),
          ref.watch(resolveAgentSkillsUsecaseProvider),
        );
      },
      dependencies: [
        workspaceSessionProvider,
        cloudWorkspaceStateGatewayProvider,
        agentRepositoryProvider,
        resolveAgentSkillsUsecaseProvider,
      ],
    );
