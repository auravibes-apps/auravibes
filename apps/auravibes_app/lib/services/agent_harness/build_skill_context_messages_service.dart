import 'package:auravibes_agent/auravibes_agent.dart' as agent;
import 'package:auravibes_app/data/repositories/agents_repository.dart';
import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/domain/entities/agent_entity.dart';
import 'package:auravibes_app/features/agents/providers/agent_repository_providers.dart';
import 'package:auravibes_app/features/agents/usecases/list_conversation_agent_skills_usecase.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/skills/usecases/list_available_skills_usecase.dart';
import 'package:auravibes_app/services/chatbot_service/chat_result.dart';
import 'package:riverpod/riverpod.dart';

class BuildSkillContextMessagesService {
  const BuildSkillContextMessagesService(
    this._listAvailableSkillsUsecase,
    this._conversationRepository,
    this._agentsRepository,
    this._listConversationAgentSkillsUsecase,
  );

  static const _builder = agent.BuildSkillContextMessages();

  final ListAvailableSkillsUsecase _listAvailableSkillsUsecase;
  final ConversationRepository _conversationRepository;
  final AgentsRepository _agentsRepository;
  final ListConversationAgentSkillsUsecase _listConversationAgentSkillsUsecase;

  Future<List<ChatMessage>> call({
    required String conversationId,
    required String workspaceId,
  }) async {
    final loadedSkills = await _listAvailableSkillsUsecase.call(
      conversationId: conversationId,
      workspaceId: workspaceId,
      filter: SkillLoadFilter.loaded,
    );
    final selectedAgent = await _selectedAgent(conversationId);
    final agentSkills = await _listConversationAgentSkillsUsecase.call(
      conversationId: conversationId,
      workspaceId: workspaceId,
    );
    final skillKeys = <String>{};
    final runtimeSkills = [...loadedSkills, ...agentSkills]
        .where((skill) => skillKeys.add('${skill.source.name}:${skill.id}'))
        .toList();

    final agentMessages = _builder.call([
      for (final skill in runtimeSkills)
        agent.AgentSkill(title: skill.title, content: skill.content),
    ]);

    return [
      if (selectedAgent != null) ChatMessage.system(selectedAgent.content),
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

  Future<AgentEntity?> _selectedAgent(String conversationId) async {
    final conversation = await _conversationRepository.getConversationById(
      conversationId,
    );
    final agentId = conversation?.agentId;
    if (agentId == null) return null;

    return _agentsRepository.getAgentById(agentId);
  }
}

final buildSkillContextMessagesServiceProvider =
    Provider<BuildSkillContextMessagesService>((ref) {
      return BuildSkillContextMessagesService(
        ref.watch(listAvailableSkillsUsecaseProvider),
        ref.watch(conversationRepositoryProvider),
        ref.watch(agentsRepositoryProvider),
        ref.watch(listConversationAgentSkillsUsecaseProvider),
      );
    });
