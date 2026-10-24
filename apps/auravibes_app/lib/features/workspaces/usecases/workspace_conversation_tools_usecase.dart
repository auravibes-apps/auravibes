import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/usecases/workspace_conversation_command_usecase.dart';
import 'package:auravibes_engine/auravibes_engine.dart';

class const WorkspaceConversationToolsUsecase({
  required final ConversationRepository conversations,
  required final MessageRepository messages,
  required final Future<WorkspaceConversationCommandUsecase> Function(String)
  commands,
}) {
  Future<Object?> call({
    required String conversationId,
    required Map<String, dynamic> arguments,
  }) async {
    final conversation = await conversations.getConversationById(
      conversationId,
    );
    if (conversation == null) throw const WorkspaceTableException(denied: true);
    final selection = await _selection(
      conversation.workspaceId,
      conversationId,
    );
    if (selection == null) throw const WorkspaceTableException(denied: true);
    return (await commands(conversation.workspaceId))
        .call(selection: selection, arguments: arguments);
  }

  Future<WorkspaceContextSelection?> _selection(
    String workspaceId,
    String conversationId,
  ) async {
    final users = await messages.getUserMessages(conversationId);
    users.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    for (final message in users) {
      final data = message.metadata?.modelMetadata;
      if (message.conversationId != conversationId ||
          data == null ||
          !data.containsKey(workspaceContextMetadataKey))
        continue;
      return WorkspaceContextSelection.decode(
        data[workspaceContextMetadataKey],
        workspaceId,
        conversationId,
      );
    }
    return null;
  }
}
