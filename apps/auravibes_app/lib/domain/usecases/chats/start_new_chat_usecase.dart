import 'package:auravibes_app/domain/entities/conversation.dart';
import 'package:auravibes_app/domain/entities/workspace_tool.dart';
import 'package:auravibes_app/domain/usecases/tools/conversation/resolve_conversation_tool_states_usecase.dart'
    as tools_usecases;
import 'package:auravibes_app/services/tools/user_tools_entity.dart';

class StartNewChatUseCase {
  const StartNewChatUseCase({
    required Future<List<tools_usecases.ResolvedConversationToolState>>
    Function(String)
    getConversationTools,
    required Future<ConversationEntity> Function({
      required String workspaceId,
      required String modelId,
      required String message,
      required List<UserToolType> toolTypes,
      Map<String, ToolPermissionMode>? conversationToolPermissions,
    })
    addConversation,
  }) : _getConversationTools = getConversationTools,
       _addConversation = addConversation;

  final Future<List<tools_usecases.ResolvedConversationToolState>> Function(
    String,
  )
  _getConversationTools;
  final Future<ConversationEntity> Function({
    required String workspaceId,
    required String modelId,
    required String message,
    required List<UserToolType> toolTypes,
    Map<String, ToolPermissionMode>? conversationToolPermissions,
  })
  _addConversation;

  Future<String> call({
    required String workspaceId,
    required String modelId,
    required String message,
  }) async {
    final toolsList = await _getConversationTools(workspaceId);

    final enabledToolStates = toolsList
        .where((tool) => tool.isEnabled)
        .toList();
    final tools = enabledToolStates
        .map((tool) => tool.tool.buildInType)
        .whereType<UserToolType>()
        .toList();

    final conversationToolPermissions = <String, ToolPermissionMode>{};
    for (final toolState in enabledToolStates) {
      if (toolState.permissionMode == toolState.tool.permissionMode) {
        continue;
      }
      conversationToolPermissions[toolState.tool.id] = toolState.permissionMode;
    }

    final createdConversation = await _addConversation(
      workspaceId: workspaceId,
      modelId: modelId,
      message: message,
      toolTypes: tools,
      conversationToolPermissions: conversationToolPermissions.isEmpty
          ? null
          : conversationToolPermissions,
    );

    return createdConversation.id;
  }
}
