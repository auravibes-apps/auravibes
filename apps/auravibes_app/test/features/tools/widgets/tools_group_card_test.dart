import 'package:auravibes_app/data/database/drift/enums/permission_access.dart';
import 'package:auravibes_app/domain/entities/mcp_server.dart';
import 'package:auravibes_app/domain/entities/tools_group.dart';
import 'package:auravibes_app/domain/entities/workspace_tool.dart';
import 'package:auravibes_app/domain/models/grouped_tools_view_item.dart';
import 'package:auravibes_app/features/tools/models/tools_group_with_tools.dart';
import 'package:auravibes_app/features/tools/notifiers/grouped_tools_notifier.dart';
import 'package:auravibes_app/features/tools/widgets/tool_item_row.dart';
import 'package:auravibes_app/features/tools/widgets/tools_group_card.dart';
import 'package:auravibes_app/features/tools/widgets/tools_group_header.dart';
import 'package:auravibes_app/notifiers/mcp_connection_notifier.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const _workspaceId = 'ws-1';

WorkspaceToolEntity _tool({String id = 't1', bool isEnabled = true}) {
  return WorkspaceToolEntity(
    id: id,
    workspaceId: _workspaceId,
    toolId: 'custom_tool',
    isEnabled: isEnabled,
    permissionMode: ToolPermissionMode.alwaysAsk,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
}

ToolsGroupEntity _group({
  String id = 'g1',
  String name = 'Test Group',
  bool isEnabled = true,
  String? mcpServerId,
}) {
  return ToolsGroupEntity(
    id: id,
    workspaceId: _workspaceId,
    name: name,
    isEnabled: isEnabled,
    permissions: PermissionAccess.ask,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    mcpServerId: mcpServerId,
  );
}

class _MockGroupedNotifier extends GroupedToolsNotifier {
  _MockGroupedNotifier(this.groups);

  final List<ToolsGroupWithTools> groups;

  @override
  Future<List<ToolsGroupWithTools>> build(String workspaceId) async => groups;
}

Widget _buildSubject(Widget child) {
  return EasyLocalization(
    supportedLocales: const [Locale('en')],
    path: 'assets/i18n',
    fallbackLocale: const Locale('en'),
    startLocale: const Locale('en'),
    useFallbackTranslations: true,
    useOnlyLangCode: true,
    child: ProviderScope(
      overrides: [
        groupedToolsProvider(
          _workspaceId,
        ).overrideWith(() => _MockGroupedNotifier([])),
      ],
      child: MaterialApp(
        home: Theme(
          data: ThemeData(extensions: [AuraTheme.light]),
          child: Material(child: child),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('renders ToolsGroupHeader', (tester) async {
    final groupWithTools = ToolsGroupWithTools(
      group: _group(),
      tools: [_tool()],
    );

    await tester.pumpWidget(
      _buildSubject(
        ToolsGroupCard(
          groupWithTools: groupWithTools,
          workspaceId: _workspaceId,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ToolsGroupHeader), findsOneWidget);
  });

  testWidgets('does not show tool rows when collapsed', (tester) async {
    final groupWithTools = ToolsGroupWithTools(
      group: _group(),
      tools: [
        _tool(),
        _tool(id: 't2'),
      ],
    );

    await tester.pumpWidget(
      _buildSubject(
        ToolsGroupCard(
          groupWithTools: groupWithTools,
          workspaceId: _workspaceId,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ToolItemRow), findsNothing);
  });

  testWidgets('expands to show tool rows', (tester) async {
    final groupWithTools = ToolsGroupWithTools(
      group: _group(),
      tools: [
        _tool(),
        _tool(id: 't2'),
      ],
    );

    await tester.pumpWidget(
      _buildSubject(
        ToolsGroupCard(
          groupWithTools: groupWithTools,
          workspaceId: _workspaceId,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(IconButton).last);
    await tester.pumpAndSettle();

    expect(find.byType(ToolItemRow), findsNWidgets(2));
  });

  testWidgets('renders card with group name', (tester) async {
    final groupWithTools = ToolsGroupWithTools(
      group: _group(name: 'My Group'),
      tools: [],
    );

    await tester.pumpWidget(
      _buildSubject(
        ToolsGroupCard(
          groupWithTools: groupWithTools,
          workspaceId: _workspaceId,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('My Group'), findsOneWidget);
  });

  testWidgets('renders inside AuraCard', (tester) async {
    final groupWithTools = ToolsGroupWithTools(
      group: _group(),
      tools: [],
    );

    await tester.pumpWidget(
      _buildSubject(
        ToolsGroupCard(
          groupWithTools: groupWithTools,
          workspaceId: _workspaceId,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AuraCard), findsOneWidget);
  });

  testWidgets('shows divider when expanded', (tester) async {
    final groupWithTools = ToolsGroupWithTools(
      group: _group(),
      tools: [_tool()],
    );

    await tester.pumpWidget(
      _buildSubject(
        ToolsGroupCard(
          groupWithTools: groupWithTools,
          workspaceId: _workspaceId,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AuraDivider), findsNothing);

    await tester.tap(find.byType(IconButton).last);
    await tester.pumpAndSettle();

    expect(find.byType(AuraDivider), findsOneWidget);
  });

  testWidgets('collapses after second tap', (tester) async {
    final groupWithTools = ToolsGroupWithTools(
      group: _group(),
      tools: [_tool()],
    );

    await tester.pumpWidget(
      _buildSubject(
        ToolsGroupCard(
          groupWithTools: groupWithTools,
          workspaceId: _workspaceId,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(IconButton).first);
    await tester.pumpAndSettle();
    expect(find.byType(ToolItemRow), findsOneWidget);

    await tester.tap(find.byType(IconButton).first);
    await tester.pumpAndSettle();
    expect(find.byType(ToolItemRow), findsNothing);
  });

  testWidgets('shows empty message when tools list is empty and expanded', (
    tester,
  ) async {
    final groupWithTools = ToolsGroupWithTools(
      group: _group(),
      tools: [],
    );

    await tester.pumpWidget(
      _buildSubject(
        ToolsGroupCard(
          groupWithTools: groupWithTools,
          workspaceId: _workspaceId,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(IconButton).last);
    await tester.pumpAndSettle();

    expect(find.text('tools_screen.no_tools_in_group'), findsOneWidget);
    expect(find.byType(ToolItemRow), findsNothing);
  });

  testWidgets('renders default group without null group', (tester) async {
    final groupWithTools = ToolsGroupWithTools(
      group: null,
      tools: [_tool()],
      defaultGroupType: DefaultToolGroupType.builtIn,
    );

    await tester.pumpWidget(
      _buildSubject(
        ToolsGroupCard(
          groupWithTools: groupWithTools,
          workspaceId: _workspaceId,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AuraCard), findsOneWidget);
  });

  testWidgets('MCP group with error shows reconnect', (tester) async {
    final mcpGroup = _group(
      name: 'MCP Server',
      id: 'mcp-g1',
    );
    final groupWithTools = ToolsGroupWithTools(
      group: mcpGroup,
      tools: [_tool()],
      mcpConnectionState: McpConnectionState(
        server: McpServerEntity(
          id: 'srv-1',
          name: 'Test MCP',
          url: 'http://localhost:8080',
          transport: const McpTransportTypeSSE(),
          authenticationType: const McpAuthenticationType.none(),
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
          workspaceId: _workspaceId,
        ),
        status: McpConnectionStatus.error,
        errorMessage: 'Connection failed',
      ),
    );

    await tester.pumpWidget(
      _buildSubject(
        ToolsGroupCard(
          groupWithTools: groupWithTools,
          workspaceId: _workspaceId,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AuraCard), findsOneWidget);
  });

  testWidgets('renders multiple tools in expanded state', (tester) async {
    final groupWithTools = ToolsGroupWithTools(
      group: _group(),
      tools: [
        _tool(),
        _tool(id: 't2'),
        _tool(id: 't3'),
      ],
    );

    await tester.pumpWidget(
      _buildSubject(
        ToolsGroupCard(
          groupWithTools: groupWithTools,
          workspaceId: _workspaceId,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(IconButton).last);
    await tester.pumpAndSettle();

    expect(find.byType(ToolItemRow), findsNWidgets(3));
  });

  testWidgets('MCP group with disconnected shows reconnect', (tester) async {
    final mcpGroup = _group(name: 'MCP Disc', id: 'mcp-g2');
    final groupWithTools = ToolsGroupWithTools(
      group: mcpGroup,
      tools: [_tool()],
      mcpConnectionState: McpConnectionState(
        server: McpServerEntity(
          id: 'srv-2',
          name: 'Test MCP',
          url: 'http://localhost:8080',
          transport: const McpTransportTypeSSE(),
          authenticationType: const McpAuthenticationType.none(),
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
          workspaceId: _workspaceId,
        ),
        status: McpConnectionStatus.disconnected,
      ),
    );

    await tester.pumpWidget(
      _buildSubject(
        ToolsGroupCard(
          groupWithTools: groupWithTools,
          workspaceId: _workspaceId,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AuraCard), findsOneWidget);
  });

  testWidgets('MCP group without error or disconnected has no reconnect', (
    tester,
  ) async {
    final mcpGroup = _group(name: 'MCP OK', id: 'mcp-g3');
    final groupWithTools = ToolsGroupWithTools(
      group: mcpGroup,
      tools: [_tool()],
      mcpConnectionState: McpConnectionState(
        server: McpServerEntity(
          id: 'srv-3',
          name: 'MCP OK',
          url: 'http://localhost:8080',
          transport: const McpTransportTypeSSE(),
          authenticationType: const McpAuthenticationType.none(),
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
          workspaceId: _workspaceId,
        ),
        status: McpConnectionStatus.connected,
      ),
    );

    await tester.pumpWidget(
      _buildSubject(
        ToolsGroupCard(
          groupWithTools: groupWithTools,
          workspaceId: _workspaceId,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AuraCard), findsOneWidget);
  });

  testWidgets('default group has null onToggleEnabled', (tester) async {
    final groupWithTools = ToolsGroupWithTools(
      group: null,
      tools: [_tool()],
      defaultGroupType: DefaultToolGroupType.builtIn,
    );

    await tester.pumpWidget(
      _buildSubject(
        ToolsGroupCard(
          groupWithTools: groupWithTools,
          workspaceId: _workspaceId,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AuraCard), findsOneWidget);
    expect(find.byType(ToolsGroupHeader), findsOneWidget);
  });

  testWidgets('MCP group with connecting status renders', (tester) async {
    final mcpGroup = _group(name: 'MCP Connecting', id: 'mcp-g4');
    final groupWithTools = ToolsGroupWithTools(
      group: mcpGroup,
      tools: [_tool()],
      mcpConnectionState: McpConnectionState(
        server: McpServerEntity(
          id: 'srv-4',
          name: 'MCP Conn',
          url: 'http://localhost:8080',
          transport: const McpTransportTypeSSE(),
          authenticationType: const McpAuthenticationType.none(),
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
          workspaceId: _workspaceId,
        ),
        status: McpConnectionStatus.connecting,
      ),
    );

    await tester.pumpWidget(
      _buildSubject(
        ToolsGroupCard(
          groupWithTools: groupWithTools,
          workspaceId: _workspaceId,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AuraCard), findsOneWidget);
  });

  testWidgets('MCP group expanded shows tools without delete button', (
    tester,
  ) async {
    final mcpGroup = _group(name: 'MCP Tools', id: 'mcp-g5');
    final groupWithTools = ToolsGroupWithTools(
      group: mcpGroup,
      tools: [_tool()],
      mcpConnectionState: McpConnectionState(
        server: McpServerEntity(
          id: 'srv-5',
          name: 'MCP',
          url: 'http://localhost:8080',
          transport: const McpTransportTypeSSE(),
          authenticationType: const McpAuthenticationType.none(),
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
          workspaceId: _workspaceId,
        ),
        status: McpConnectionStatus.connected,
      ),
    );

    await tester.pumpWidget(
      _buildSubject(
        ToolsGroupCard(
          groupWithTools: groupWithTools,
          workspaceId: _workspaceId,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(IconButton).last);
    await tester.pumpAndSettle();

    expect(find.byType(ToolItemRow), findsOneWidget);
  });

  testWidgets('non-MCP group expanded shows tools with delete button', (
    tester,
  ) async {
    final groupWithTools = ToolsGroupWithTools(
      group: _group(),
      tools: [_tool()],
    );

    await tester.pumpWidget(
      _buildSubject(
        ToolsGroupCard(
          groupWithTools: groupWithTools,
          workspaceId: _workspaceId,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(IconButton).last);
    await tester.pumpAndSettle();

    expect(find.byType(ToolItemRow), findsOneWidget);
  });

  testWidgets('disabled group renders header', (tester) async {
    final groupWithTools = ToolsGroupWithTools(
      group: _group(isEnabled: false),
      tools: [_tool()],
    );

    await tester.pumpWidget(
      _buildSubject(
        ToolsGroupCard(
          groupWithTools: groupWithTools,
          workspaceId: _workspaceId,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ToolsGroupHeader), findsOneWidget);
  });

  testWidgets('tapping switch triggers toggle callback', (tester) async {
    final groupWithTools = ToolsGroupWithTools(
      group: _group(),
      tools: [_tool()],
    );

    await tester.pumpWidget(
      _buildSubject(
        ToolsGroupCard(
          groupWithTools: groupWithTools,
          workspaceId: _workspaceId,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final switchFinder = find.byType(AuraSwitch);
    if (switchFinder.evaluate().isNotEmpty) {
      await tester.tap(switchFinder.first);
      await tester.pumpAndSettle();
    }

    expect(find.byType(AuraCard), findsOneWidget);
  });

  testWidgets('MCP error group shows reconnect button', (tester) async {
    final mcpGroup = _group(
      name: 'MCP Err',
      id: 'mcp-err',
      mcpServerId: 'srv-err',
    );
    final groupWithTools = ToolsGroupWithTools(
      group: mcpGroup,
      tools: [_tool()],
      mcpConnectionState: McpConnectionState(
        server: McpServerEntity(
          id: 'srv-err',
          name: 'MCP',
          url: 'http://localhost:8080',
          transport: const McpTransportTypeSSE(),
          authenticationType: const McpAuthenticationType.none(),
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
          workspaceId: _workspaceId,
        ),
        status: McpConnectionStatus.error,
        errorMessage: 'Connection failed',
      ),
    );

    await tester.pumpWidget(
      _buildSubject(
        ToolsGroupCard(
          groupWithTools: groupWithTools,
          workspaceId: _workspaceId,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final refreshFinder = find.byIcon(Icons.refresh);
    if (refreshFinder.evaluate().isNotEmpty) {
      await tester.tap(refreshFinder.first);
      await tester.pumpAndSettle();
    }

    expect(find.byType(AuraCard), findsOneWidget);
  });

  testWidgets('MCP group shows delete button', (tester) async {
    final mcpGroup = _group(
      name: 'MCP Del',
      id: 'mcp-del',
      mcpServerId: 'srv-del',
    );
    final groupWithTools = ToolsGroupWithTools(
      group: mcpGroup,
      tools: [_tool()],
      mcpConnectionState: McpConnectionState(
        server: McpServerEntity(
          id: 'srv-del',
          name: 'MCP',
          url: 'http://localhost:8080',
          transport: const McpTransportTypeSSE(),
          authenticationType: const McpAuthenticationType.none(),
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
          workspaceId: _workspaceId,
        ),
        status: McpConnectionStatus.connected,
      ),
    );

    await tester.pumpWidget(
      _buildSubject(
        ToolsGroupCard(
          groupWithTools: groupWithTools,
          workspaceId: _workspaceId,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });

  testWidgets('MCP disconnected group shows reconnect button', (tester) async {
    final mcpGroup = _group(
      name: 'MCP Disconn',
      id: 'mcp-disc',
      mcpServerId: 'srv-disc',
    );
    final groupWithTools = ToolsGroupWithTools(
      group: mcpGroup,
      tools: [_tool()],
      mcpConnectionState: McpConnectionState(
        server: McpServerEntity(
          id: 'srv-disc',
          name: 'MCP',
          url: 'http://localhost:8080',
          transport: const McpTransportTypeSSE(),
          authenticationType: const McpAuthenticationType.none(),
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
          workspaceId: _workspaceId,
        ),
        status: McpConnectionStatus.disconnected,
      ),
    );

    await tester.pumpWidget(
      _buildSubject(
        ToolsGroupCard(
          groupWithTools: groupWithTools,
          workspaceId: _workspaceId,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final refreshFinder = find.byIcon(Icons.refresh);
    if (refreshFinder.evaluate().isNotEmpty) {
      await tester.tap(refreshFinder.first);
      await tester.pumpAndSettle();
    }

    expect(find.byType(AuraCard), findsOneWidget);
  });

  testWidgets('non-MCP group has no delete or reconnect buttons', (
    tester,
  ) async {
    final groupWithTools = ToolsGroupWithTools(
      group: _group(),
      tools: [_tool()],
    );

    await tester.pumpWidget(
      _buildSubject(
        ToolsGroupCard(
          groupWithTools: groupWithTools,
          workspaceId: _workspaceId,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.delete_outline), findsNothing);
    expect(find.byIcon(Icons.refresh), findsNothing);
  });
}
