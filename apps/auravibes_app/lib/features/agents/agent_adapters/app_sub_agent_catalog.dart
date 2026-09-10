// App adapters for the engine sub-agent storage contracts.
import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/domain/entities/agent_entity.dart';
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
  Future<List<agent.SubAgentCatalogEntry>> listSubAgents(
    String workspaceId,
  ) async {
    final agents = await _agentsRepository.getAgentsByWorkspace(workspaceId);

    return [
      for (final subAgent in agents)
        if (subAgent.isEnabled) _toCatalogEntry(subAgent),
    ];
  }

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

class AppSubAgentConversationStore(
  final ConversationRepository _conversationRepository,
) implements agent.SubAgentConversationStore {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #createChildConversation) {
      return _createChildConversationFromInvocation(invocation);
    }

    return super.noSuchMethod(invocation);
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

  Future<agent.SubAgentConversationRecord>
  _createChildConversationFromInvocation(Invocation invocation) =>
      _createChildConversation(
        _conversationRepository,
        _createChildConversationRequest(invocation.namedArguments),
      );

  Future<agent.SubAgentConversationRecord> _createChildConversation(
    ConversationRepository repository,
    ({
      String parentConversationId,
      String workspaceId,
      String? modelId,
      String? agentId,
      String title,
    })
    request,
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

({
  String parentConversationId,
  String workspaceId,
  String? modelId,
  String? agentId,
  String title,
})
_createChildConversationRequest(Map<Symbol, dynamic> arguments) => (
  parentConversationId: arguments[#parentConversationId] as String,
  workspaceId: arguments[#workspaceId] as String,
  modelId: arguments[#modelId] as String?,
  agentId: arguments[#agentId] as String?,
  title: arguments[#title] as String,
);

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
