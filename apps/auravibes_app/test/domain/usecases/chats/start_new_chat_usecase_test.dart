import 'package:auravibes_app/domain/entities/conversation.dart';
import 'package:auravibes_app/domain/entities/workspace_tool.dart';
import 'package:auravibes_app/domain/usecases/chats/start_new_chat_usecase.dart';
import 'package:auravibes_app/domain/usecases/tools/conversation/resolve_conversation_tool_states_usecase.dart'
    as tools_usecases;
import 'package:auravibes_app/services/tools/user_tools_entity.dart';
import 'package:flutter_test/flutter_test.dart';

tools_usecases.ResolvedConversationToolState _state({
  required String id,
  required String toolId,
  required ToolPermissionMode currentPermission,
  required ToolPermissionMode workspacePermission,
  required bool enabled,
}) {
  return tools_usecases.ResolvedConversationToolState(
    tool: WorkspaceToolEntity(
      id: id,
      workspaceId: 'w1',
      toolId: toolId,
      isEnabled: true,
      permissionMode: workspacePermission,
      createdAt: DateTime(2025),
      updatedAt: DateTime(2025),
    ),
    isEnabled: enabled,
    permissionMode: currentPermission,
    isWorkspaceEnabled: true,
  );
}

void main() {
  test(
    'builds tool list and permission overrides then returns conversation id',
    () async {
      final usecase = StartNewChatUseCase(
        getConversationTools: (_) async => [
          _state(
            id: 't1',
            toolId: UserToolType.calculator.value,
            currentPermission: ToolPermissionMode.alwaysAllow,
            workspacePermission: ToolPermissionMode.alwaysAsk,
            enabled: true,
          ),
        ],
        addConversation:
            ({
              required workspaceId,
              required modelId,
              required message,
              required toolTypes,
              conversationToolPermissions,
            }) async {
              expect(workspaceId, 'w1');
              expect(modelId, 'model-1');
              expect(message, 'hello');
              expect(toolTypes, [UserToolType.calculator]);
              expect(
                conversationToolPermissions?['t1'],
                ToolPermissionMode.alwaysAllow,
              );
              return ConversationEntity(
                id: 'c123',
                title: 'chat',
                workspaceId: 'w1',
                isPinned: false,
                createdAt: DateTime(2025),
                updatedAt: DateTime(2025),
                modelId: 'model-1',
              );
            },
      );

      final result = await usecase.call(
        workspaceId: 'w1',
        modelId: 'model-1',
        message: 'hello',
      );

      expect(result, 'c123');
    },
  );
}
