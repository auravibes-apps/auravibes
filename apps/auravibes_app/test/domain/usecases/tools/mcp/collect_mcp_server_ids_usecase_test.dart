import 'package:auravibes_app/data/database/drift/enums/permission_access.dart';
import 'package:auravibes_app/domain/entities/tools_group.dart';
import 'package:auravibes_app/domain/entities/workspace_tool.dart';
import 'package:auravibes_app/domain/usecases/tools/mcp/collect_mcp_server_ids_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

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

ToolsGroupEntity _group(String id, String mcpServerId) => ToolsGroupEntity(
  id: id,
  workspaceId: 'w1',
  name: 'grp',
  isEnabled: true,
  permissions: PermissionAccess.ask,
  createdAt: DateTime(2025),
  updatedAt: DateTime(2025),
  mcpServerId: mcpServerId,
);

void main() {
  test(
    'collects unique mcp server ids for grouped non built-in tools',
    () async {
      final usecase = CollectMcpServerIdsUseCase(
        getToolsGroupById: (groupId) async => _group(groupId, 'mcp-1'),
      );

      final ids = await usecase.call([
        _tool(id: '1', toolId: 'custom_a', groupId: 'g1'),
        _tool(id: '2', toolId: 'custom_b', groupId: 'g1'),
        _tool(id: '3', toolId: 'calculator'),
      ]);

      expect(ids, ['mcp-1']);
    },
  );
}
