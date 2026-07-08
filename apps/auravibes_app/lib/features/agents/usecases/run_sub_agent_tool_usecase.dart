import 'package:auravibes_app/data/repositories/agents_repository.dart';
import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/domain/entities/agent_entity.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_engine/auravibes_engine.dart' as agent;
import 'package:collection/collection.dart';

class AppSubAgentCatalog implements agent.SubAgentCatalog {
  const AppSubAgentCatalog(this._agentsRepository);

  final AgentsRepository _agentsRepository;

  @override
  Future<agent.SubAgentCatalogEntry?> getSubAgent(String agentId) async {
    final subAgent = await _agentsRepository.getAgentById(agentId);
    if (subAgent == null || !subAgent.appearsInSubAgentList) return null;

    return agent.SubAgentCatalogEntry(
      id: subAgent.id,
      workspaceId: subAgent.workspaceId,
      name: subAgent.name,
      description: subAgent.description,
      types: _agentTypes(subAgent.visibility),
    );
  }

  @override
  Future<List<agent.SubAgentCatalogEntry>> listSubAgents(
    String workspaceId,
  ) async {
    final agents = await _agentsRepository.getAgentsByWorkspace(workspaceId);

    return [
      for (final subAgent in agents)
        if (subAgent.isEnabled)
          agent.SubAgentCatalogEntry(
            id: subAgent.id,
            workspaceId: subAgent.workspaceId,
            name: subAgent.name,
            description: subAgent.description,
            types: _agentTypes(subAgent.visibility),
          ),
    ];
  }

  List<String> _agentTypes(AgentVisibility visibility) {
    return switch (visibility) {
      AgentVisibility.chatSelector => const ['main'],
      AgentVisibility.subAgentList => const ['sub_agent'],
      AgentVisibility.both => const ['main', 'sub_agent'],
    };
  }
}

class AppSubAgentConversationStore implements agent.SubAgentConversationStore {
  const AppSubAgentConversationStore(this._conversationRepository);

  final ConversationRepository _conversationRepository;

  @override
  Future<agent.SubAgentConversationRecord> createChildConversation({
    required String parentConversationId,
    required String workspaceId,
    required String? modelId,
    required String? agentId,
    required String title,
  }) async {
    final conversation = await _conversationRepository.createConversation(
      ConversationToCreate(
        title: title,
        workspaceId: workspaceId,
        modelId: modelId,
        agentId: agentId,
        parentConversationId: parentConversationId,
      ),
    );

    return _toRecord(conversation);
  }

  @override
  Future<agent.SubAgentConversationRecord?> getConversation(
    String conversationId,
  ) async {
    final conversation = await _conversationRepository.getConversationById(
      conversationId,
    );
    if (conversation == null) return null;

    return _toRecord(conversation);
  }

  agent.SubAgentConversationRecord _toRecord(ConversationEntity conversation) {
    return agent.SubAgentConversationRecord(
      id: conversation.id,
      workspaceId: conversation.workspaceId,
      modelId: conversation.modelId,
      parentConversationId: conversation.parentConversationId,
    );
  }
}

class AppSubAgentMessageStore implements agent.SubAgentMessageStore {
  const AppSubAgentMessageStore(this._messageRepository);

  final MessageRepository _messageRepository;

  @override
  Future<agent.SubAgentMessageRecord> createUserPrompt({
    required String conversationId,
    required String prompt,
  }) async {
    final message = await _messageRepository.createMessage(
      MessageToCreate(
        conversationId: conversationId,
        content: prompt,
        messageType: MessageType.text,
        isUser: true,
        status: MessageStatus.sent,
      ),
    );

    return agent.SubAgentMessageRecord(id: message.id);
  }

  @override
  Future<String> latestAssistantContent(String conversationId) async {
    final messages = await _messageRepository
        .getLatestAssistantMessagesByConversations([conversationId]);
    final message = messages.firstOrNull;
    if (message != null) return message.content;

    return '';
  }
}
