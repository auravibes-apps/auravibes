import 'package:auravibes_app/domain/entities/workspace_tool.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ToolPermissionMode', () {
    test('has alwaysAsk and alwaysAllow', () {
      expect(ToolPermissionMode.alwaysAsk, isNotNull);
      expect(ToolPermissionMode.alwaysAllow, isNotNull);
    });
  });

  final now = DateTime(2025);

  group('WorkspaceToolEntity', () {
    final entity = WorkspaceToolEntity(
      id: 'tool_1',
      workspaceId: 'ws_1',
      toolId: 'calculator',
      isEnabled: true,
      permissionMode: ToolPermissionMode.alwaysAsk,
      createdAt: now,
      updatedAt: now,
    );

    test('isAvailable mirrors isEnabled', () {
      expect(entity.isAvailable, isTrue);
      final disabled = WorkspaceToolEntity(
        id: 'tool_2',
        workspaceId: 'ws_1',
        toolId: 'disabled_tool',
        isEnabled: false,
        permissionMode: ToolPermissionMode.alwaysAsk,
        createdAt: now,
        updatedAt: now,
      );
      expect(disabled.isAvailable, isFalse);
    });

    test('hasConfig true when config is set and not empty', () {
      final withConfig = WorkspaceToolEntity(
        id: 'tool_3',
        workspaceId: 'ws_1',
        toolId: 'config_tool',
        isEnabled: true,
        permissionMode: ToolPermissionMode.alwaysAsk,
        createdAt: now,
        updatedAt: now,
        config: '{"key":"value"}',
      );
      expect(withConfig.hasConfig, isTrue);
      expect(entity.hasConfig, isFalse);
    });

    test('belongsToGroup true when workspaceToolsGroupId is set', () {
      final grouped = WorkspaceToolEntity(
        id: 'tool_4',
        workspaceId: 'ws_1',
        toolId: 'grouped_tool',
        isEnabled: true,
        permissionMode: ToolPermissionMode.alwaysAsk,
        createdAt: now,
        updatedAt: now,
        workspaceToolsGroupId: 'group_1',
      );
      expect(grouped.belongsToGroup, isTrue);
      expect(entity.belongsToGroup, isFalse);
    });

    test('belongsToGroup false when workspaceToolsGroupId is empty', () {
      final emptyGroup = WorkspaceToolEntity(
        id: 'tool_5',
        workspaceId: 'ws_1',
        toolId: 't',
        isEnabled: true,
        permissionMode: ToolPermissionMode.alwaysAsk,
        createdAt: now,
        updatedAt: now,
        workspaceToolsGroupId: '',
      );
      expect(emptyGroup.belongsToGroup, isFalse);
    });

    test('hasDescription true when description is set', () {
      final withDesc = WorkspaceToolEntity(
        id: 'tool_6',
        workspaceId: 'ws_1',
        toolId: 'desc_tool',
        isEnabled: true,
        permissionMode: ToolPermissionMode.alwaysAsk,
        createdAt: now,
        updatedAt: now,
        description: 'A useful tool',
      );
      expect(withDesc.hasDescription, isTrue);
    });

    test('hasInputSchema true when inputSchema is set', () {
      final withSchema = WorkspaceToolEntity(
        id: 'tool_7',
        workspaceId: 'ws_1',
        toolId: 'schema_tool',
        isEnabled: true,
        permissionMode: ToolPermissionMode.alwaysAsk,
        createdAt: now,
        updatedAt: now,
        inputSchema: '{"type":"object"}',
      );
      expect(withSchema.hasInputSchema, isTrue);
      expect(entity.hasInputSchema, isFalse);
    });

    test('buildInType returns null for unknown toolId', () {
      final unknown = WorkspaceToolEntity(
        id: 'tool_x',
        workspaceId: 'ws_1',
        toolId: 'nonexistent_tool',
        isEnabled: true,
        permissionMode: ToolPermissionMode.alwaysAsk,
        createdAt: now,
        updatedAt: now,
      );
      expect(unknown.buildInType, isNull);
    });

    test('nativeType returns null for unknown toolId', () {
      expect(entity.nativeType, isNull);
    });

    test('isNative false when nativeType is null', () {
      expect(entity.isNative, isFalse);
    });
  });

  group('WorkspaceToolToCreate', () {
    test('hasValidToolId true when toolId is not empty', () {
      const create = WorkspaceToolToCreate(toolId: 'test');
      expect(create.hasValidToolId, isTrue);
    });

    test('hasValidToolId false when toolId is empty', () {
      const create = WorkspaceToolToCreate(toolId: '');
      expect(create.hasValidToolId, isFalse);
    });

    test('defaultEnabled returns true when not specified', () {
      const create = WorkspaceToolToCreate(toolId: 'test');
      expect(create.defaultEnabled, isTrue);
    });

    test('defaultEnabled returns isEnabled when specified', () {
      const create = WorkspaceToolToCreate(toolId: 'test', isEnabled: false);
      expect(create.defaultEnabled, isFalse);
    });

    test('hasValidConfig mirrors hasValidToolId', () {
      const create = WorkspaceToolToCreate(toolId: 'test');
      expect(create.hasValidConfig, isTrue);
      const invalid = WorkspaceToolToCreate(toolId: '');
      expect(invalid.hasValidConfig, isFalse);
    });

    test('optional config and description', () {
      const create = WorkspaceToolToCreate(
        toolId: 'test',
        config: '{"enabled":true}',
        description: 'A test tool',
      );
      expect(create.config, '{"enabled":true}');
      expect(create.description, 'A test tool');
    });
  });
}
