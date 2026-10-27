import 'package:auravibes_app/features/workspaces/models/workspace_conversation_context.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/usecases/workspace_conversation_command_usecase.dart';
import 'package:auravibes_engine/auravibes_engine.dart';

/// Explicit user action grants context; imported transcript metadata never
/// does.
class const ManageWorkspaceChatContextUsecase({
  required final String workspaceId,
  required final WorkspaceConversationContextRepository repository,
  required final WorkspaceConversationCommandUsecase commands,
  required final Future<bool> Function(String conversationId) canAccess,
}) {
  Future<WorkspaceConversationContext> read(String conversationId) async {
    await _authorize(conversationId);

    return await repository.read(conversationId);
  }

  Future<Map<String, Object?>?> describe(String conversationId) async {
    final current = await read(conversationId);
    final selection = current.selection;
    if (selection == null) return null;
    if (selection.kind == 'directory') return {'kind': 'directory'};

    final result = await commands.call(
      selection: selection,
      arguments: {
        'action': 'read',
        'id': selection.itemId,
        'tableId': selection.itemId,
      },
    );

    return {...result, 'kind': selection.kind};
  }

  Future<WorkspaceConversationContext> save(
    String conversationId,
    String requestId,
    WorkspaceContextSelection? selection,
  ) async {
    await _authorize(conversationId);
    await _validateSelection(conversationId, selection);
    await _authorize(conversationId);

    return await repository.save(conversationId, requestId, selection);
  }

  Future<void> _validateSelection(
    String conversationId,
    WorkspaceContextSelection? selection,
  ) async {
    if (selection != null) {
      if (selection.conversationId != conversationId ||
          selection.workspaceId != workspaceId) {
        throw const WorkspaceTableException(denied: true);
      }
      if (selection.kind != 'directory') {
        final _ = await commands.call(
          selection: selection,
          arguments: {
            'action': 'read',
            'id': selection.itemId,
            'tableId': selection.itemId,
          },
        );
      }
    }
  }

  Future<void> _authorize(String conversationId) async {
    if (!await canAccess(conversationId)) {
      throw const WorkspaceTableException(denied: true);
    }
  }
}
