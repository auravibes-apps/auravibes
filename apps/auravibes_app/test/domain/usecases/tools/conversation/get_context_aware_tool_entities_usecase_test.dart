import 'package:auravibes_app/domain/entities/workspace_tool.dart';
import 'package:auravibes_app/domain/usecases/tools/conversation/get_context_aware_tool_entities_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

WorkspaceToolEntity _tool(String id) => WorkspaceToolEntity(
  id: id,
  workspaceId: 'w1',
  toolId: 'calculator',
  isEnabled: true,
  permissionMode: ToolPermissionMode.alwaysAsk,
  createdAt: DateTime(2025),
  updatedAt: DateTime(2025),
);

void main() {
  test('delegates to getAvailableToolEntities callback', () async {
    final usecase = GetContextAwareToolEntitiesUseCase(
      getAvailableToolEntities: (conversationId, workspaceId) async {
        expect(conversationId, 'c1');
        expect(workspaceId, 'w1');
        return [_tool('t1')];
      },
    );

    final result = await usecase.call(conversationId: 'c1', workspaceId: 'w1');
    expect(result.map((e) => e.id), ['t1']);
  });
}
