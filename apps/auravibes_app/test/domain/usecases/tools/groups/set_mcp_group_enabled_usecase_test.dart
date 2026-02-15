import 'package:auravibes_app/data/database/drift/enums/permission_access.dart';
import 'package:auravibes_app/domain/entities/tools_group.dart';
import 'package:auravibes_app/domain/models/grouped_tools_view_item.dart';
import 'package:auravibes_app/domain/usecases/tools/groups/set_mcp_group_enabled_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

ToolsGroupEntity _mcpGroup(String id, String serverId) => ToolsGroupEntity(
  id: id,
  workspaceId: 'w1',
  name: 'group',
  isEnabled: true,
  permissions: PermissionAccess.ask,
  createdAt: DateTime(2025),
  updatedAt: DateTime(2025),
  mcpServerId: serverId,
);

void main() {
  test('disconnects mcp server when group is disabled', () async {
    var disconnected = '';
    final usecase = SetMcpGroupEnabledUseCase(
      setToolsGroupEnabled: (_, {required isEnabled}) async {
        expect(isEnabled, isFalse);
      },
    );

    await usecase.call(
      groupId: 'g1',
      isEnabled: false,
      groups: [
        GroupedToolsViewItem(group: _mcpGroup('g1', 'mcp-1'), tools: const []),
      ],
      disconnectMcpServer: (id) => disconnected = id,
      reconnectMcpServer: (_) async {},
    );

    expect(disconnected, 'mcp-1');
  });
}
