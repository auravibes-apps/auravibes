import 'package:auravibes_app/data/database/drift/enums/permission_access.dart';
import 'package:auravibes_app/domain/entities/tools_group.dart';
import 'package:auravibes_app/domain/entities/workspace_tool.dart';
import 'package:auravibes_app/domain/models/grouped_tools_view_item.dart';
import 'package:auravibes_app/domain/usecases/tools/groups/build_grouped_tools_view_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

WorkspaceToolEntity _tool(String id, {String? groupId}) => WorkspaceToolEntity(
  id: id,
  workspaceId: 'w1',
  toolId: 'custom_tool',
  isEnabled: true,
  permissionMode: ToolPermissionMode.alwaysAsk,
  createdAt: DateTime(2025),
  updatedAt: DateTime(2025),
  workspaceToolsGroupId: groupId,
);

ToolsGroupEntity _group(String id, String serverId) => ToolsGroupEntity(
  id: id,
  workspaceId: 'w1',
  name: 'MCP',
  isEnabled: true,
  permissions: PermissionAccess.ask,
  createdAt: DateTime(2025),
  updatedAt: DateTime(2025),
  mcpServerId: serverId,
);

McpConnectionView _connection(String serverId) => McpConnectionView(
  serverId: serverId,
  status: McpConnectionViewStatus.connected,
);

void main() {
  test('builds default and mcp groups with connection state', () {
    const usecase = BuildGroupedToolsViewUseCase();

    final result = usecase.call(
      workspaceTools: [
        _tool('default-tool'),
        _tool('group-tool', groupId: 'g1'),
      ],
      groups: [_group('g1', 'mcp-1')],
      mcpConnections: [_connection('mcp-1')],
    );

    expect(result.length, 2);
    expect(result.first.group, isNull);
    expect(result.last.group?.id, 'g1');
    expect(result.last.mcpConnection, isNotNull);
  });
}
