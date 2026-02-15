import 'package:auravibes_app/domain/entities/conversation_tool.dart';
import 'package:auravibes_app/domain/entities/workspace_tool.dart';

class ResolvedConversationToolState {
  const ResolvedConversationToolState({
    required this.tool,
    required this.isEnabled,
    required this.permissionMode,
    required this.isWorkspaceEnabled,
  });

  final WorkspaceToolEntity tool;
  final bool isEnabled;
  final ToolPermissionMode permissionMode;
  final bool isWorkspaceEnabled;
}

class ResolveConversationToolStatesUseCase {
  const ResolveConversationToolStatesUseCase({
    required Future<List<WorkspaceToolEntity>> Function(String workspaceId)
    getWorkspaceTools,
    required Future<List<ConversationToolEntity>> Function(
      String conversationId,
    )
    getConversationTools,
  }) : _getWorkspaceTools = getWorkspaceTools,
       _getConversationTools = getConversationTools;

  final Future<List<WorkspaceToolEntity>> Function(String workspaceId)
  _getWorkspaceTools;
  final Future<List<ConversationToolEntity>> Function(String conversationId)
  _getConversationTools;

  Future<List<ResolvedConversationToolState>> call({
    required String workspaceId,
    String? conversationId,
  }) async {
    final workspaceTools = await _getWorkspaceTools(workspaceId);
    final toolStates = workspaceTools
        .map(
          (workspaceTool) => ResolvedConversationToolState(
            tool: workspaceTool,
            isEnabled: workspaceTool.isEnabled,
            permissionMode: workspaceTool.permissionMode,
            isWorkspaceEnabled: workspaceTool.isEnabled,
          ),
        )
        .toList();

    if (conversationId == null || conversationId.isEmpty) {
      return toolStates;
    }

    final conversationTools = await _getConversationTools(conversationId);
    for (final tool in conversationTools) {
      final index = toolStates.indexWhere(
        (state) => state.tool.id == tool.toolId,
      );
      if (index == -1) {
        continue;
      }

      toolStates[index] = ResolvedConversationToolState(
        tool: toolStates[index].tool,
        isEnabled: tool.isEnabled,
        permissionMode: tool.permissionMode,
        isWorkspaceEnabled: toolStates[index].isWorkspaceEnabled,
      );
    }

    return toolStates;
  }
}
