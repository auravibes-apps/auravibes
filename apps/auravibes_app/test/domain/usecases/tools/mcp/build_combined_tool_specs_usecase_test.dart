// Required: Existing test and UI helpers keep compact return flow.
import 'package:auravibes_app/data/database/drift/enums/permission_access.dart';
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/domain/entities/tools_group_entity.dart';
import 'package:auravibes_app/domain/usecases/tools/mcp/build_combined_tool_specs_use_case.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool_type.dart';
import 'package:auravibes_engine/auravibes_engine.dart'
    show
        AgentResolvedToolName,
        ToolSpec,
        buildToolCatalog,
        stableToolNameSuffix;
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

        return ToolSpec(
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
    expect(result.single.spec.name, 'mcp_custom_tool');
    expect(result.single.target.tableId, 't1');
    expect(result.single.target.mcpServerId, 'mcp-1');
  });

  test('includes built-in tool specs for calculator tool', () async {
    final usecase = BuildCombinedToolSpecsUseCase(
      getToolsGroupById: (_) async => null,
      getMcpToolSpec: ({required mcpServerId, required toolName}) => null,
    );

    final result = await usecase.call([_tool(id: 't1', toolId: 'calculator')]);

    expect(result, hasLength(1));
    expect(result.single.spec.name, 'calculator');
    expect(result.single.target.tableId, 't1');
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

    final result = await usecase.call([_tool(id: 't2', toolId: 'url')]);

    expect(result, hasLength(1));
    expect(result.single.spec.name, 'url');
    expect(result.single.target.tableId, 't2');
  });

  test('keeps grouped tools as MCP beside local tools', () async {
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
      getMcpToolSpec: ({required mcpServerId, required toolName}) => ToolSpec(
        name: AgentResolvedToolName.mcp(
          tableId: 'mcp-row',
          toolIdentifier: toolName,
          mcpServerId: mcpServerId,
          mcpSlug: 'mcp-slug',
        ).fullName,
        description: toolName,
        inputJsonSchema: const {},
      ),
    );

    final result = await usecase.call([
      _tool(id: 'local-calculator', toolId: 'calculator'),
      _tool(id: 'mcp-calculator', toolId: 'calculator', groupId: 'g1'),
      _tool(id: 'local-url', toolId: 'url'),
      _tool(id: 'mcp-url', toolId: 'url', groupId: 'g1'),
    ]);

    expect(result, hasLength(4));
    expect(result.firstOrNull?.target.isBuiltIn, isTrue);
    expect(result[1].target.isMcp, isTrue);
    expect(result[2].target.isNative, isTrue);
    expect(result[3].target.isMcp, isTrue);
    expect(
      result
          .where((candidate) => candidate.target.isMcp)
          .map((candidate) => candidate.target.mcpServerId),
      ['mcp-1', 'mcp-1'],
    );

    final catalog = buildToolCatalog(result);
    final mcpCalculatorSuffix = stableToolNameSuffix(
      'mcp:mcp-1:mcp-calculator:calculator',
    );
    expect(catalog.specs.map((spec) => spec.name), [
      'calculator_${stableToolNameSuffix('user:local-calculator')}',
      'mcp_calculator_$mcpCalculatorSuffix',
      'url',
      'mcp_url_${stableToolNameSuffix('mcp:mcp-1:mcp-url:url')}',
    ]);
  });

  test('skips tool not belonging to a group', () async {
    final usecase = BuildCombinedToolSpecsUseCase(
      getToolsGroupById: (_) async => null,
      getMcpToolSpec: ({required mcpServerId, required toolName}) => null,
    );

    final result = await usecase.call([_tool(id: 't1', toolId: 'some_tool')]);

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

  test('binds duplicate built-in and MCP specs to distinct targets', () async {
    final groups = {
      'github-group': 'github-server',
      'linear-group': 'linear-server',
    };
    final usecase = BuildCombinedToolSpecsUseCase(
      getToolsGroupById: (groupId) async => ToolsGroupEntity(
        id: groupId,
        workspaceId: 'w1',
        name: groupId,
        isEnabled: true,
        permissions: PermissionAccess.ask,
        createdAt: DateTime(2025),
        updatedAt: DateTime(2025),
        mcpServerId: groups[groupId],
      ),
      getMcpToolSpec: ({required mcpServerId, required toolName}) => ToolSpec(
        name: AgentResolvedToolName.mcp(
          tableId: mcpServerId,
          toolIdentifier: toolName,
          mcpServerId: mcpServerId,
          mcpSlug: '$mcpServerId-slug',
        ).fullName,
        description: toolName,
        inputJsonSchema: const {},
      ),
    );

    final result = await usecase.call([
      _tool(id: 'calculator-row-1', toolId: 'calculator'),
      _tool(id: 'calculator-row-2', toolId: 'calculator'),
      _tool(id: 'github-search-row', toolId: 'search', groupId: 'github-group'),
      _tool(id: 'linear-search-row', toolId: 'search', groupId: 'linear-group'),
    ]);

    expect(result, hasLength(4));
    expect(result.map((value) => value.target.tableId).toSet(), hasLength(4));
    expect(
      result.where((value) => value.target.toolIdentifier == 'calculator'),
      hasLength(2),
    );
    expect(result.map((value) => value.spec.name), [
      'calculator',
      'calculator',
      'mcp_search',
      'mcp_search',
    ]);
    expect(
      result.map((value) => value.target),
      everyElement(isA<ResolvedTool>()),
    );
    expect(
      result
          .where((value) => value.target.isMcp)
          .map((value) => value.target.mcpServerId),
      ['github-server', 'linear-server'],
    );

    final catalog = buildToolCatalog(result);
    const githubSourceId = 'mcp:github-server:github-search-row:search';
    const linearSourceId = 'mcp:linear-server:linear-search-row:search';
    final githubSuffix = stableToolNameSuffix(githubSourceId);
    final linearSuffix = stableToolNameSuffix(linearSourceId);
    expect(catalog.specs.map((value) => value.name), [
      'calculator_${stableToolNameSuffix('user:calculator-row-1')}',
      'calculator_${stableToolNameSuffix('user:calculator-row-2')}',
      'mcp_search_$githubSuffix',
      'mcp_search_$linearSuffix',
    ]);
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
        return ToolSpec(
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
    expect(result.firstOrNull?.spec.name, 'calculator');
    expect(result[1].spec.name, 'url');
    expect(result[2].spec.name, 'mcp_remote_tool');
  });
}
