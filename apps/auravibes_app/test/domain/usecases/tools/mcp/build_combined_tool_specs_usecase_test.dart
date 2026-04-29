import 'package:auravibes_app/data/database/drift/enums/permission_access.dart';
import 'package:auravibes_app/domain/entities/tool_spec.dart';
import 'package:auravibes_app/domain/entities/tools_group.dart';
import 'package:auravibes_app/domain/entities/workspace_tool.dart';
import 'package:auravibes_app/domain/usecases/tools/mcp/build_combined_tool_specs_usecase.dart';
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

  test('includes built-in tool specs for calculator tool', () async {
    final usecase = BuildCombinedToolSpecsUseCase(
      getToolsGroupById: (_) async => null,
      getMcpToolSpec: ({required mcpServerId, required toolName}) => null,
    );

    final result = await usecase.call([
      _tool(id: 't1', toolId: 'calculator'),
    ]);

    expect(result, hasLength(1));
    expect(result.single.name, startsWith('built_in_'));
  });

  test('skips built-in tool when tool type is unknown', () async {
    final usecase = BuildCombinedToolSpecsUseCase(
      getToolsGroupById: (_) async => null,
      getMcpToolSpec: ({required mcpServerId, required toolName}) => null,
    );

    final result = await usecase.call([
      _tool(id: 't1', toolId: 'nonexistent_builtin'),
    ]);

    expect(result, isEmpty);
  });

  test('includes native tool specs for url tool', () async {
    final usecase = BuildCombinedToolSpecsUseCase(
      getToolsGroupById: (_) async => null,
      getMcpToolSpec: ({required mcpServerId, required toolName}) => null,
    );

    final result = await usecase.call([
      _tool(id: 't2', toolId: 'url'),
    ]);

    expect(result, hasLength(1));
    expect(result.single.name, startsWith('native_'));
  });

  test('skips tool not belonging to a group', () async {
    final usecase = BuildCombinedToolSpecsUseCase(
      getToolsGroupById: (_) async => null,
      getMcpToolSpec: ({required mcpServerId, required toolName}) => null,
    );

    final result = await usecase.call([
      _tool(id: 't1', toolId: 'some_tool'),
    ]);

    expect(result, isEmpty);
  });

  test('skips tool when group returns null', () async {
    final usecase = BuildCombinedToolSpecsUseCase(
      getToolsGroupById: (_) async => null,
      getMcpToolSpec: ({required mcpServerId, required toolName}) => null,
    );

    final result = await usecase.call([
      _tool(id: 't1', toolId: 'some_tool', groupId: 'g1'),
    ]);

    expect(result, isEmpty);
  });

  test('skips tool when group has null mcpServerId', () async {
    final usecase = BuildCombinedToolSpecsUseCase(
      getToolsGroupById: (groupId) async => ToolsGroupEntity(
        id: groupId,
        workspaceId: 'w1',
        name: 'group',
        isEnabled: true,
        permissions: PermissionAccess.ask,
        createdAt: DateTime(2025),
        updatedAt: DateTime(2025),
      ),
      getMcpToolSpec: ({required mcpServerId, required toolName}) => null,
    );

    final result = await usecase.call([
      _tool(id: 't1', toolId: 'some_tool', groupId: 'g1'),
    ]);

    expect(result, isEmpty);
  });

  test('skips tool when getMcpToolSpec returns null', () async {
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
      getMcpToolSpec: ({required mcpServerId, required toolName}) => null,
    );

    final result = await usecase.call([
      _tool(id: 't1', toolId: 'some_tool', groupId: 'g1'),
    ]);

    expect(result, isEmpty);
  });

  test('returns empty for empty enabled tools list', () async {
    final usecase = BuildCombinedToolSpecsUseCase(
      getToolsGroupById: (_) async => null,
      getMcpToolSpec: ({required mcpServerId, required toolName}) => null,
    );

    final result = await usecase.call([]);

    expect(result, isEmpty);
  });

  test('mixes built-in, native, and mcp tools', () async {
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
        return const ToolSpec(
          name: 'mcp_tool',
          description: 'desc',
          inputJsonSchema: {},
        );
      },
    );

    final result = await usecase.call([
      _tool(id: 't1', toolId: 'calculator'),
      _tool(id: 't2', toolId: 'url'),
      _tool(id: 't3', toolId: 'remote_tool', groupId: 'g1'),
    ]);

    expect(result, hasLength(3));
    expect(result[0].name, startsWith('built_in_'));
    expect(result[1].name, startsWith('native_'));
    expect(result[2].name, 'mcp_tool');
  });
}
