import 'package:auravibes_app/data/database/drift/enums/permission_access.dart';
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/domain/entities/tools_group_entity.dart';
import 'package:auravibes_app/domain/models/mcp_connection_view_status.dart';
import 'package:auravibes_app/features/tools/models/tools_group_with_tools.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ToolsGroupWithTools', () {
    final tool1 = WorkspaceToolEntity(
      id: 't1',
      workspaceId: 'ws1',
      toolId: 'calculator',
      isEnabled: true,
      permissionMode: ToolPermissionMode.alwaysAsk,
      createdAt: DateTime(2025),
      updatedAt: DateTime(2025),
    );
    final tool2 = WorkspaceToolEntity(
      id: 't2',
      workspaceId: 'ws1',
      toolId: 'readFile',
      isEnabled: false,
      permissionMode: ToolPermissionMode.alwaysAllow,
      createdAt: DateTime(2025),
      updatedAt: DateTime(2025),
    );

    final testGroup = ToolsGroupEntity(
      id: 'g1',
      workspaceId: 'ws1',
      name: 'Test Group',
      isEnabled: true,
      permissions: PermissionAccess.ask,
      createdAt: DateTime(2025),
      updatedAt: DateTime(2025),
    );

    test('enabledToolsCount counts enabled tools', () {
      final grouped = ToolsGroupWithTools(
        group: testGroup,
        tools: [tool1, tool2],
      );
      expect(grouped.enabledToolsCount, 1);
    });

    test('enabledToolsCount is 0 when no tools are enabled', () {
      final tool3 = WorkspaceToolEntity(
        id: 't3',
        workspaceId: 'ws1',
        toolId: 'disabledTool',
        isEnabled: false,
        permissionMode: ToolPermissionMode.alwaysAsk,
        createdAt: DateTime(2025),
        updatedAt: DateTime(2025),
      );
      final grouped = ToolsGroupWithTools(
        group: testGroup,
        tools: [tool3],
      );
      expect(grouped.enabledToolsCount, 0);
    });

    test('totalToolsCount returns total tool count', () {
      final grouped = ToolsGroupWithTools(
        group: testGroup,
        tools: [tool1, tool2],
      );
      expect(grouped.totalToolsCount, 2);
    });

    test('isDefaultGroup is true when group is null', () {
      final grouped = ToolsGroupWithTools(
        group: null,
        tools: [tool1],
        defaultGroupType: DefaultToolGroupType.builtIn,
      );
      expect(grouped.isDefaultGroup, isTrue);
    });

    test('isDefaultGroup is false when group is provided', () {
      final grouped = ToolsGroupWithTools(
        group: testGroup,
        tools: [tool1],
      );
      expect(grouped.isDefaultGroup, isFalse);
    });

    test('isNativeDefaultGroup true for native default', () {
      final grouped = ToolsGroupWithTools(
        group: null,
        tools: [tool1],
        defaultGroupType: DefaultToolGroupType.native,
      );
      expect(grouped.isNativeDefaultGroup, isTrue);
    });

    test('isNativeDefaultGroup false for builtIn default', () {
      final grouped = ToolsGroupWithTools(
        group: null,
        tools: [tool1],
        defaultGroupType: DefaultToolGroupType.builtIn,
      );
      expect(grouped.isNativeDefaultGroup, isFalse);
    });

    test('isMcpGroup returns true for MCP group', () {
      final mcpGroup = ToolsGroupEntity(
        id: 'g2',
        workspaceId: 'ws1',
        name: 'MCP Group',
        isEnabled: true,
        permissions: PermissionAccess.ask,
        mcpServerId: 'server1',
        createdAt: DateTime(2025),
        updatedAt: DateTime(2025),
      );
      final grouped = ToolsGroupWithTools(
        group: mcpGroup,
        tools: [],
      );
      expect(grouped.isMcpGroup, isTrue);
    });

    test('mcpServerId returns group mcpServerId', () {
      final mcpGroup = ToolsGroupEntity(
        id: 'g3',
        workspaceId: 'ws1',
        name: 'MCP Group',
        isEnabled: true,
        permissions: PermissionAccess.ask,
        mcpServerId: 'server_42',
        createdAt: DateTime(2025),
        updatedAt: DateTime(2025),
      );
      final grouped = ToolsGroupWithTools(
        group: mcpGroup,
        tools: [],
      );
      expect(grouped.mcpServerId, 'server_42');
    });

    test('isEnabled returns group.isEnabled', () {
      final disabledGroup = ToolsGroupEntity(
        id: 'g4',
        workspaceId: 'ws1',
        name: 'Disabled',
        isEnabled: false,
        permissions: PermissionAccess.ask,
        createdAt: DateTime(2025),
        updatedAt: DateTime(2025),
      );
      final grouped = ToolsGroupWithTools(
        group: disabledGroup,
        tools: [],
      );
      expect(grouped.isEnabled, isFalse);
    });

    test('isEnabled returns true when group is null', () {
      final grouped = ToolsGroupWithTools(
        group: null,
        tools: [tool1],
        defaultGroupType: DefaultToolGroupType.builtIn,
      );
      expect(grouped.isEnabled, isTrue);
    });

    group('sortPriority', () {
      test('returns 0 for builtIn default group', () {
        final grouped = ToolsGroupWithTools(
          group: null,
          tools: [tool1],
          defaultGroupType: DefaultToolGroupType.builtIn,
        );
        expect(grouped.sortPriority, 0);
      });

      test('returns 1 for native default group', () {
        final grouped = ToolsGroupWithTools(
          group: null,
          tools: [tool1],
          defaultGroupType: DefaultToolGroupType.native,
        );
        expect(grouped.sortPriority, 1);
      });

      test('returns 0 for null defaultGroupType (builtIn default)', () {
        final grouped = ToolsGroupWithTools(
          group: null,
          tools: [tool1],
          defaultGroupType: DefaultToolGroupType.builtIn,
        );
        expect(grouped.sortPriority, 0);
      });

      test('returns 5 for connected normal group', () {
        final grouped = ToolsGroupWithTools(
          group: testGroup,
          tools: [tool1],
        );
        expect(grouped.sortPriority, 5);
      });
    });

    group('localizedDisplayNameKey', () {
      test('returns null for non-default group', () {
        final grouped = ToolsGroupWithTools(
          group: testGroup,
          tools: [tool1],
        );
        expect(grouped.localizedDisplayNameKey, isNull);
      });

      test('returns different keys for different default types', () {
        final builtInGroup = ToolsGroupWithTools(
          group: null,
          tools: [tool1],
          defaultGroupType: DefaultToolGroupType.builtIn,
        );
        final nativeGroup = ToolsGroupWithTools(
          group: null,
          tools: [tool1],
          defaultGroupType: DefaultToolGroupType.native,
        );
        expect(builtInGroup.localizedDisplayNameKey, isNotNull);
        expect(nativeGroup.localizedDisplayNameKey, isNotNull);
        expect(
          builtInGroup.localizedDisplayNameKey,
          isNot(nativeGroup.localizedDisplayNameKey),
        );
      });
    });
  });
}
