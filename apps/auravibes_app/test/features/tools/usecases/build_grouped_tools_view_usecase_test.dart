import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/domain/entities/tools_group_entity.dart';
import 'package:auravibes_app/domain/models/mcp_connection_view_status.dart';
import 'package:auravibes_app/features/tools/usecases/build_grouped_tools_view_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

WorkspaceToolEntity _tool(String id, {String? groupId}) => WorkspaceToolEntity(
  id: id,
  workspaceId: 'w1',
  toolId: 'custom_tool',
  isEnabled: true,
  permissionMode: .alwaysAsk,
  createdAt: .new(2025),
  updatedAt: .new(2025),
  workspaceToolsGroupId: groupId,
);

ToolsGroupEntity _group(String id, String serverId) => ToolsGroupEntity(
  id: id,
  workspaceId: 'w1',
  name: 'MCP',
  isEnabled: true,
  permissions: .ask,
  createdAt: .new(2025),
  updatedAt: .new(2025),
  mcpServerId: serverId,
);

McpConnectionView _connection(String serverId) =>
    McpConnectionView(serverId: serverId, status: .connected);

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
    expect(result.firstOrNull?.group, isNull);
    expect(result.last.group?.id, 'g1');
    expect(result.last.mcpConnection, isNotNull);
  });
}
