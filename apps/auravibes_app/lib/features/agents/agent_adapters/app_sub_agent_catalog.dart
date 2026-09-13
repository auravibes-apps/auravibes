// App adapters for the engine sub-agent storage contracts.
import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/domain/entities/agent_entity.dart';
import 'package:auravibes_app/domain/entities/agent_list_query.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/features/agents/agent_adapters/agent_repository.dart';
import 'package:auravibes_engine/auravibes_engine.dart' as agent;
import 'package:collection/collection.dart';

class const AppSubAgentCatalog(final AgentRepository _agentsRepository)
    implements agent.SubAgentCatalog {
  @override
  Future<agent.SubAgentCatalogEntry?> getSubAgent(String agentId) async {
    final subAgent = await _agentsRepository.getAgentById(agentId);
    if (subAgent == null || !subAgent.appearsInSubAgentList) return null;

    return _toCatalogEntry(subAgent);
  }

  @override
  Future<agent.SubAgentCatalogPage> listSubAgents(
    agent.SubAgentCatalogQuery query,
  ) async {
    final page = await _agentsRepository.listAgents(_agentListQuery(query));

    return agent.SubAgentCatalogPage(
      agents: [
        for (final item in page.agents)
          _toCatalogListEntry(item, query.workspaceId),
      ],
      nextCursor: page.nextCursor,
    );
  }

  agent.SubAgentCatalogEntry _toCatalogListEntry(
    AgentListItem item,
    String workspaceId,
  ) => agent.SubAgentCatalogEntry(
    id: item.id,
    workspaceId: workspaceId,
    name: item.name,
    description: item.description,
    types: _agentTypes(item.visibility),
  );

  agent.SubAgentCatalogEntry _toCatalogEntry(AgentEntity subAgent) {
    return agent.SubAgentCatalogEntry(
      id: subAgent.id,
      workspaceId: subAgent.workspaceId,
      name: subAgent.name,
      description: subAgent.description,
      types: _agentTypes(subAgent.visibility),
    );
  }

  List<String> _agentTypes(AgentVisibility visibility) {
    return switch (visibility) {
      .chatSelector => const ['main'],
      .subAgentList => const ['sub_agent'],
      .both => const ['main', 'sub_agent'],
    };
  }
}

AgentListQuery _agentListQuery(agent.SubAgentCatalogQuery query) => .new(
  workspaceId: query.workspaceId,
  search: query.query,
  type: switch (query.type) {
    'main' => .chatSelector,
    'sub_agent' => .subAgentList,
    _ => null,
  },
  status: .enabled,
  limit: query.limit,
  cursor: query.cursor,
);

class AppSubAgentConversationStore(
  final ConversationRepository _conversationRepository,
) implements agent.SubAgentConversationStore {
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

  @override
  Future<agent.SubAgentConversationRecord> createChildConversation(
    agent.SubAgentChildConversationRequest request,
  ) => _createChildConversation(_conversationRepository, request);

  Future<agent.SubAgentConversationRecord> _createChildConversation(
    ConversationRepository repository,
    agent.SubAgentChildConversationRequest request,
  ) async {
    final conversation = await repository.createConversation(
      .new(
        title: request.title,
        workspaceId: request.workspaceId,
        modelId: request.modelId,
        agentId: request.agentId,
        parentConversationId: request.parentConversationId,
      ),
    );

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

class const AppSubAgentMessageStore(final MessageRepository _messageRepository)
    implements agent.SubAgentMessageStore {
  @override
  Future<agent.SubAgentMessageRecord> createUserPrompt({
    required String conversationId,
    required String prompt,
  }) async {
    final message = await _messageRepository.createMessage(
      .new(
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
