import 'package:auravibes_app/data/database/drift/enums/permission_access.dart';
import 'package:auravibes_app/domain/entities/tools_group.dart';
import 'package:auravibes_app/domain/entities/workspace_tool.dart';
import 'package:auravibes_app/domain/usecases/tools/mcp/build_combined_tool_specs_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:langchain/langchain.dart';

WorkspaceToolEntity _tool({
  required String id,
  required String toolId,
  String? groupId,
}) => WorkspaceToolEntity(
  id: id,
  workspaceId: 'w1',
  toolId: toolId,
  isEnabled: true,
  permissionMode: ToolPermissionMode.alwaysAsk,
  createdAt: DateTime(2025),
  updatedAt: DateTime(2025),
  workspaceToolsGroupId: groupId,
);

void main() {
  test('includes mcp tool specs for grouped custom tools', () async {
    final usecase = BuildCombinedToolSpecsUseCase(
      getToolsGroupById: (groupId) async => ToolsGroupEntity(
        id: groupId,
        workspaceId: 'w1',
        name: 'group',
        isEnabled: true,
        permissions: PermissionAccess.ask,
        createdAt: DateTime(2025),
        updatedAt: DateTime(2025),
        mcpServerId: 'mcp-1',
      ),
      getMcpToolSpec: ({required mcpServerId, required toolName}) {
        expect(mcpServerId, 'mcp-1');
        expect(toolName, 'custom_tool');
        return const ToolSpec(
          name: 'mcp_tool',
          description: 'desc',
          inputJsonSchema: {},
        );
      },
    );

    final result = await usecase.call([
      _tool(id: 't1', toolId: 'custom_tool', groupId: 'g1'),
    ]);

    expect(result, hasLength(1));
    expect(result.single.name, 'mcp_tool');
  });
}
