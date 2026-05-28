// ignore_for_file: no-equal-arguments
// Required: Tests use repeated fixture values to assert equality semantics.
import 'package:auravibes_app/data/database/drift/enums/permission_access.dart';
import 'package:auravibes_app/domain/entities/tools_group_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2025);

  group('ToolsGroupEntity', () {
    final entity = ToolsGroupEntity(
      id: 'group_1',
      workspaceId: 'ws_1',
      name: 'My Tools',
      isEnabled: true,
      permissions: PermissionAccess.ask,
      createdAt: now,
      updatedAt: now,
    );

    test('isMcpGroup true when mcpServerId is set', () {
      final withMcp = ToolsGroupEntity(
        id: 'group_2',
        workspaceId: 'ws_1',
        name: 'MCP Tools',
        isEnabled: true,
        permissions: PermissionAccess.ask,
        createdAt: now,
        updatedAt: now,
        mcpServerId: 'mcp_1',
      );
      expect(withMcp.isMcpGroup, isTrue);
    });

    test('isMcpGroup false when mcpServerId is null', () {
      expect(entity.isMcpGroup, isFalse);
    });

    test('isMcpGroup false when mcpServerId is empty', () {
      final withEmptyMcp = ToolsGroupEntity(
        id: 'group_3',
        workspaceId: 'ws_1',
        name: 'Empty MCP',
        isEnabled: true,
        permissions: PermissionAccess.ask,
        createdAt: now,
        updatedAt: now,
        mcpServerId: '',
      );
      expect(withEmptyMcp.isMcpGroup, isFalse);
    });

    test('permissions enum values', () {
      expect(entity.permissions, PermissionAccess.ask);
      final granted = ToolsGroupEntity(
        id: 'group_4',
        workspaceId: 'ws_1',
        name: 'Granted',
        isEnabled: true,
        permissions: PermissionAccess.granted,
        createdAt: now,
        updatedAt: now,
      );
      expect(granted.permissions, PermissionAccess.granted);
    });
  });

  group('ToolsGroupToCreate', () {
    test('hasValidName true when name is not empty', () {
      const create = ToolsGroupToCreate(name: 'My Group');
      expect(create.hasValidName, isTrue);
      expect(create.isValid, isTrue);
    });

    test('hasValidName false when name is empty', () {
      const create = ToolsGroupToCreate(name: '');
      expect(create.hasValidName, isFalse);
      expect(create.isValid, isFalse);
    });

    test('isEnabled defaults to true', () {
      const create = ToolsGroupToCreate(name: 'Group');
      expect(create.isEnabled, isTrue);
    });

    test('isEnabled can be set false', () {
      const create = ToolsGroupToCreate(name: 'Group', isEnabled: false);
      expect(create.isEnabled, isFalse);
    });

    test('permissions defaults to ask', () {
      const create = ToolsGroupToCreate(name: 'Group');
      expect(create.permissions, PermissionAccess.ask);
    });

    test('permissions can be set to granted', () {
      const create = ToolsGroupToCreate(
        name: 'Group',
        permissions: PermissionAccess.granted,
      );
      expect(create.permissions, PermissionAccess.granted);
    });

    test('mcpServerId is optional', () {
      const create = ToolsGroupToCreate(name: 'Group', mcpServerId: 'mcp_1');
      expect(create.mcpServerId, 'mcp_1');
    });
  });
}
