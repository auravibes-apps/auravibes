import 'package:auravibes_app/data/repositories/agents_repository.dart';
import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/features/agents/providers/agent_repository_providers.dart';
import 'package:auravibes_app/features/agents/usecases/resolve_agent_skills_usecase.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/skills/models/available_skill.dart';
import 'package:riverpod/riverpod.dart';

class ListConversationAgentSkillsUsecase {
  const ListConversationAgentSkillsUsecase(
    this._conversationRepository,
    this._agentsRepository,
    this._resolveAgentSkillsUsecase,
  );

  final ConversationRepository _conversationRepository;
  final AgentsRepository _agentsRepository;
  final ResolveAgentSkillsUsecase _resolveAgentSkillsUsecase;

  Future<List<AvailableSkill>> call({
    required String conversationId,
    required String workspaceId,
  }) async {
    final conversation = await _conversationRepository.getConversationById(
      conversationId,
    );
    final agentId = conversation?.agentId;
    if (agentId == null) return const [];

    final agent = await _agentsRepository.getAgentById(agentId);
    if (agent == null) return const [];

    final resolved = await _resolveAgentSkillsUsecase.call(
      workspaceId: workspaceId,
      refs: agent.skills,
    );

    return resolved.available;
  }
}

final listConversationAgentSkillsUsecaseProvider =
    Provider<ListConversationAgentSkillsUsecase>((ref) {
      return ListConversationAgentSkillsUsecase(
        ref.watch(conversationRepositoryProvider),
        ref.watch(agentsRepositoryProvider),
        ref.watch(resolveAgentSkillsUsecaseProvider),
      );
    });
