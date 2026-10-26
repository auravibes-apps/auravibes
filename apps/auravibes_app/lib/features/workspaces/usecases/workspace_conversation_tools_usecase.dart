import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_command_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_context_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/usecases/workspace_conversation_command_usecase.dart';
import 'package:auravibes_engine/auravibes_engine.dart';

class const WorkspaceConversationToolsUsecase({
  required final ConversationRepository conversations,
  required final LocalWorkspaceContextRepository Function(String workspaceId)
  context,
  required final Future<WorkspaceConversationCommandUsecase> Function(String)
  commands,
  final LocalWorkspaceCommandRepository? receipts,
}) {
  Future<Object?> call({
    required String conversationId,
    required Map<String, dynamic> arguments,
    String? operationId,
  }) async {
    final conversation = await conversations.getConversationById(
      conversationId,
    );
    if (conversation == null) throw const WorkspaceTableException(denied: true);
    final event = await context(conversation.workspaceId)
        .latest(conversation.workspaceId, conversationId);
    final selection = event == null
        ? null
        : WorkspaceContextSelection.decode(
            event.selection,
            conversation.workspaceId,
            conversationId,
          );
    if (selection == null || event == null) {
      throw const WorkspaceTableException(denied: true);
    }
    final created =
        await receipts?.created(
          conversation.workspaceId,
          conversationId,
          event.id,
        ) ??
        [];
    final scope = workspaceCreatedContext(selection, created, arguments);
    final references = WorkspaceReferenceScope(selection, created);
    final command = await commands(conversation.workspaceId);
    if (arguments['action'] == 'read') {
      final result = await command.call(
        selection: scope,
        arguments: arguments,
        references: references,
      );
      final current = await context(conversation.workspaceId)
          .latest(conversation.workspaceId, conversationId);
      if (current?.id != event.id) {
        throw const WorkspaceTableException(denied: true);
      }

      return result;
    }
    final store = receipts;
    if (store == null || operationId == null || operationId.isEmpty) {
      throw const WorkspaceTableException();
    }

    return await store.execute((
      workspaceId: conversation.workspaceId,
      conversationId: conversationId,
      selectionId: event.id,
      requestId: operationId,
      arguments: arguments,
      run: () => command.call(
        selection: scope,
        arguments: arguments,
        references: references,
      ),
      authorizeReplay: command.authorizeReceipt,
    ));
  }
}
