import 'package:auravibes_agent/src/agent_runtime.dart';
import 'package:auravibes_agent/src/providers/agent_data_provider.dart';

class ConversationsNamespace {
  const ConversationsNamespace({required this.data});

  final AgentDataProvider data;

  Future<List<AgentConversationMessage>> getMessages({
    required String conversationId,
  }) {
    return data.getMessages(conversationId);
  }

  Future<AgentCreatedMessage> create({
    required String conversationId,
    required String content,
  }) {
    return data.createQueuedUserMessage(
      conversationId: conversationId,
      content: content,
    );
  }
}
