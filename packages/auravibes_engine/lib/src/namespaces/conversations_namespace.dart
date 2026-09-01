import 'package:auravibes_engine/src/agent_runtime.dart';
import 'package:auravibes_engine/src/providers/agent_data_provider.dart';

class const ConversationsNamespace({required final AgentDataProvider data}) {
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
