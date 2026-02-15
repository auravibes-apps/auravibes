import 'package:auravibes_app/domain/entities/conversation_tool.dart';
import 'package:auravibes_app/domain/entities/workspace_tool.dart';
import 'package:auravibes_app/domain/usecases/tools/conversation/resolve_conversation_tool_states_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

WorkspaceToolEntity _workspaceTool({
  required String id,
  required bool enabled,
}) => WorkspaceToolEntity(
  id: id,
  workspaceId: 'w1',
  toolId: 'calculator',
  isEnabled: enabled,
  permissionMode: ToolPermissionMode.alwaysAsk,
  createdAt: DateTime(2025),
  updatedAt: DateTime(2025),
);

ConversationToolEntity _conversationTool({required String toolId}) =>
    ConversationToolEntity(
      conversationId: 'c1',
      toolId: toolId,
      isEnabled: false,
      permissionMode: ToolPermissionMode.alwaysAllow,
      createdAt: DateTime(2025),
      updatedAt: DateTime(2025),
    );

void main() {
  test('returns workspace defaults when conversation id is null', () async {
    final usecase = ResolveConversationToolStatesUseCase(
      getWorkspaceTools: (_) async => [_workspaceTool(id: 't1', enabled: true)],
      getConversationTools: (_) async => [_conversationTool(toolId: 't1')],
    );

    final result = await usecase.call(workspaceId: 'w1');

    expect(result.single.tool.id, 't1');
    expect(result.single.isEnabled, isTrue);
    expect(result.single.permissionMode, ToolPermissionMode.alwaysAsk);
  });

  test('applies conversation overrides by tool id', () async {
    final usecase = ResolveConversationToolStatesUseCase(
      getWorkspaceTools: (_) async => [_workspaceTool(id: 't1', enabled: true)],
      getConversationTools: (_) async => [_conversationTool(toolId: 't1')],
    );

    final result = await usecase.call(workspaceId: 'w1', conversationId: 'c1');

    expect(result.single.isEnabled, isFalse);
    expect(result.single.permissionMode, ToolPermissionMode.alwaysAllow);
    expect(result.single.isWorkspaceEnabled, isTrue);
  });
}
