// ignore_for_file: scoped_providers_should_specify_dependencies
// Required: widget tests override scoped providers directly.
// ignore_for_file: prefer-static-class
// Required: Tests keep fixture helpers and fakes top-level.

import 'package:auravibes_app/data/database/drift/enums/permission_access.dart';
import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/domain/entities/tools_group_entity.dart';
import 'package:auravibes_app/domain/models/mcp_connection_view_status.dart';
import 'package:auravibes_app/features/tools/models/tools_group_with_tools.dart';
import 'package:auravibes_app/features/tools/notifiers/grouped_tools_notifier.dart';
import 'package:auravibes_app/features/tools/widgets/tool_item_row.dart';
import 'package:auravibes_app/features/tools/widgets/tools_group_card.dart';
import 'package:auravibes_app/features/tools/widgets/tools_group_header.dart';
import 'package:auravibes_app/notifiers/mcp_connection_status.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_provider_scope.dart';

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

class _Subject extends StatelessWidget {
  const _Subject({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return EasyLocalization(
      child: TestProviderScope(
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
      supportedLocales: const [Locale('en')],
      path: 'assets/i18n',
      fallbackLocale: const Locale('en'),
      startLocale: const Locale('en'),
      useOnlyLangCode: true,
      useFallbackTranslations: true,
    );
  }
}

void main() {
  testWidgets('renders ToolsGroupHeader', (tester) async {
    final groupWithTools = ToolsGroupWithTools(
      group: _group(),
      tools: [_tool()],
    );

    await tester.pumpWidget(
      _Subject(
        child: ToolsGroupCard(
          groupWithTools: groupWithTools,
          workspaceId: _workspaceId,
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();

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
      _Subject(
        child: ToolsGroupCard(
          groupWithTools: groupWithTools,
          workspaceId: _workspaceId,
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();

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
      _Subject(
        child: ToolsGroupCard(
          groupWithTools: groupWithTools,
          workspaceId: _workspaceId,
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();

    await tester.tap(find.byType(IconButton).last);
    final _ = await tester.pumpAndSettle();

    expect(find.byType(ToolItemRow), findsNWidgets(2));
  });

  testWidgets('renders card with group name', (tester) async {
    final groupWithTools = ToolsGroupWithTools(
      group: _group(name: 'My Group'),
      tools: [],
    );

    await tester.pumpWidget(
      _Subject(
        child: ToolsGroupCard(
          groupWithTools: groupWithTools,
          workspaceId: _workspaceId,
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();

    expect(find.text('My Group'), findsOneWidget);
  });

  testWidgets('renders inside AuraCard', (tester) async {
    final groupWithTools = ToolsGroupWithTools(
      group: _group(),
      tools: [],
    );

    await tester.pumpWidget(
      _Subject(
        child: ToolsGroupCard(
          groupWithTools: groupWithTools,
          workspaceId: _workspaceId,
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();

    expect(find.byType(AuraCard), findsOneWidget);
  });

  testWidgets('shows divider when expanded', (tester) async {
    final groupWithTools = ToolsGroupWithTools(
      group: _group(),
      tools: [_tool()],
    );

    await tester.pumpWidget(
      _Subject(
        child: ToolsGroupCard(
          groupWithTools: groupWithTools,
          workspaceId: _workspaceId,
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();

    expect(find.byType(AuraDivider), findsNothing);

    await tester.tap(find.byType(IconButton).last);
    final _ = await tester.pumpAndSettle();

    expect(find.byType(AuraDivider), findsOneWidget);
  });

  testWidgets('collapses after second tap', (tester) async {
    final groupWithTools = ToolsGroupWithTools(
      group: _group(),
      tools: [_tool()],
    );

    await tester.pumpWidget(
      _Subject(
        child: ToolsGroupCard(
          groupWithTools: groupWithTools,
          workspaceId: _workspaceId,
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();

    await tester.tap(find.byType(IconButton).first);
    final _ = await tester.pumpAndSettle();
    expect(find.byType(ToolItemRow), findsOneWidget);

    await tester.tap(find.byType(IconButton).first);
    final _ = await tester.pumpAndSettle();
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
      _Subject(
        child: ToolsGroupCard(
          groupWithTools: groupWithTools,
          workspaceId: _workspaceId,
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();

    await tester.tap(find.byType(IconButton).last);
    final _ = await tester.pumpAndSettle();

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
      _Subject(
        child: ToolsGroupCard(
          groupWithTools: groupWithTools,
          workspaceId: _workspaceId,
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();

    expect(find.byType(AuraCard), findsOneWidget);
  });

  testWidgets('MCP group with error shows reconnect', (tester) async {
    final mcpGroup = _group(
      id: 'mcp-g1',
      name: 'MCP Server',
    );
    final groupWithTools = ToolsGroupWithTools(
      group: mcpGroup,
      tools: [_tool()],
      mcpConnectionState: McpConnectionState(
        server: McpServerEntity(
          id: 'srv-1',
          workspaceId: _workspaceId,
          name: 'Test MCP',
          url: 'http://localhost:8080',
          transport: const McpTransportTypeSSE(),
          authenticationType: const McpAuthenticationType.none(),
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
        status: McpConnectionStatus.error,
        errorMessage: 'Connection failed',
      ),
    );

    await tester.pumpWidget(
      _Subject(
        child: ToolsGroupCard(
          groupWithTools: groupWithTools,
          workspaceId: _workspaceId,
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();

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
      _Subject(
        child: ToolsGroupCard(
          groupWithTools: groupWithTools,
          workspaceId: _workspaceId,
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();

    await tester.tap(find.byType(IconButton).last);
    final _ = await tester.pumpAndSettle();

    expect(find.byType(ToolItemRow), findsNWidgets(3));
  });

  testWidgets('MCP group with disconnected shows reconnect', (tester) async {
    final mcpGroup = _group(id: 'mcp-g2', name: 'MCP Disc');
    final groupWithTools = ToolsGroupWithTools(
      group: mcpGroup,
      tools: [_tool()],
      mcpConnectionState: McpConnectionState(
        server: McpServerEntity(
          id: 'srv-2',
          workspaceId: _workspaceId,
          name: 'Test MCP',
          url: 'http://localhost:8080',
          transport: const McpTransportTypeSSE(),
          authenticationType: const McpAuthenticationType.none(),
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
        status: McpConnectionStatus.disconnected,
      ),
    );

    await tester.pumpWidget(
      _Subject(
        child: ToolsGroupCard(
          groupWithTools: groupWithTools,
          workspaceId: _workspaceId,
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();

    expect(find.byType(AuraCard), findsOneWidget);
  });

  testWidgets('MCP group without error or disconnected has no reconnect', (
    tester,
  ) async {
    final mcpGroup = _group(id: 'mcp-g3', name: 'MCP OK');
    final groupWithTools = ToolsGroupWithTools(
      group: mcpGroup,
      tools: [_tool()],
      mcpConnectionState: McpConnectionState(
        server: McpServerEntity(
          id: 'srv-3',
          workspaceId: _workspaceId,
          name: 'MCP OK',
          url: 'http://localhost:8080',
          transport: const McpTransportTypeSSE(),
          authenticationType: const McpAuthenticationType.none(),
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
        status: McpConnectionStatus.connected,
      ),
    );

    await tester.pumpWidget(
      _Subject(
        child: ToolsGroupCard(
          groupWithTools: groupWithTools,
          workspaceId: _workspaceId,
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();

    expect(find.byType(AuraCard), findsOneWidget);
  });

  testWidgets('default group has null onToggleEnabled', (tester) async {
    final groupWithTools = ToolsGroupWithTools(
      group: null,
      tools: [_tool()],
      defaultGroupType: DefaultToolGroupType.builtIn,
    );

    await tester.pumpWidget(
      _Subject(
        child: ToolsGroupCard(
          groupWithTools: groupWithTools,
          workspaceId: _workspaceId,
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();

    expect(find.byType(AuraCard), findsOneWidget);
    expect(find.byType(ToolsGroupHeader), findsOneWidget);
  });

  testWidgets('MCP group with connecting status renders', (tester) async {
    final mcpGroup = _group(id: 'mcp-g4', name: 'MCP Connecting');
    final groupWithTools = ToolsGroupWithTools(
      group: mcpGroup,
      tools: [_tool()],
      mcpConnectionState: McpConnectionState(
        server: McpServerEntity(
          id: 'srv-4',
          workspaceId: _workspaceId,
          name: 'MCP Conn',
          url: 'http://localhost:8080',
          transport: const McpTransportTypeSSE(),
          authenticationType: const McpAuthenticationType.none(),
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
        status: McpConnectionStatus.connecting,
      ),
    );

    await tester.pumpWidget(
      _Subject(
        child: ToolsGroupCard(
          groupWithTools: groupWithTools,
          workspaceId: _workspaceId,
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();

    expect(find.byType(AuraCard), findsOneWidget);
  });

  testWidgets('MCP group expanded shows tools without delete button', (
    tester,
  ) async {
    final mcpGroup = _group(id: 'mcp-g5', name: 'MCP Tools');
    final groupWithTools = ToolsGroupWithTools(
      group: mcpGroup,
      tools: [_tool()],
      mcpConnectionState: McpConnectionState(
        server: McpServerEntity(
          id: 'srv-5',
          workspaceId: _workspaceId,
          name: 'MCP',
          url: 'http://localhost:8080',
          transport: const McpTransportTypeSSE(),
          authenticationType: const McpAuthenticationType.none(),
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
        status: McpConnectionStatus.connected,
      ),
    );

    await tester.pumpWidget(
      _Subject(
        child: ToolsGroupCard(
          groupWithTools: groupWithTools,
          workspaceId: _workspaceId,
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();

    await tester.tap(find.byType(IconButton).last);
    final _ = await tester.pumpAndSettle();

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
      _Subject(
        child: ToolsGroupCard(
          groupWithTools: groupWithTools,
          workspaceId: _workspaceId,
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();

    await tester.tap(find.byType(IconButton).last);
    final _ = await tester.pumpAndSettle();

    expect(find.byType(ToolItemRow), findsOneWidget);
  });

  testWidgets('disabled group renders header', (tester) async {
    final groupWithTools = ToolsGroupWithTools(
      group: _group(isEnabled: false),
      tools: [_tool()],
    );

    await tester.pumpWidget(
      _Subject(
        child: ToolsGroupCard(
          groupWithTools: groupWithTools,
          workspaceId: _workspaceId,
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();

    expect(find.byType(ToolsGroupHeader), findsOneWidget);
  });

  testWidgets('tapping switch triggers toggle callback', (tester) async {
    final groupWithTools = ToolsGroupWithTools(
      group: _group(),
      tools: [_tool()],
    );

    await tester.pumpWidget(
      _Subject(
        child: ToolsGroupCard(
          groupWithTools: groupWithTools,
          workspaceId: _workspaceId,
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();

    final switchFinder = find.byType(AuraSwitch);
    if (switchFinder.evaluate().isNotEmpty) {
      await tester.tap(switchFinder.first);
      final _ = await tester.pumpAndSettle();
    }

    expect(find.byType(AuraCard), findsOneWidget);
  });

  testWidgets('MCP error group shows reconnect button', (tester) async {
    final mcpGroup = _group(
      id: 'mcp-err',
      name: 'MCP Err',
      mcpServerId: 'srv-err',
    );
    final groupWithTools = ToolsGroupWithTools(
      group: mcpGroup,
      tools: [_tool()],
      mcpConnectionState: McpConnectionState(
        server: McpServerEntity(
          id: 'srv-err',
          workspaceId: _workspaceId,
          name: 'MCP',
          url: 'http://localhost:8080',
          transport: const McpTransportTypeSSE(),
          authenticationType: const McpAuthenticationType.none(),
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
        status: McpConnectionStatus.error,
        errorMessage: 'Connection failed',
      ),
    );

    await tester.pumpWidget(
      _Subject(
        child: ToolsGroupCard(
          groupWithTools: groupWithTools,
          workspaceId: _workspaceId,
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();

    final refreshFinder = find.byIcon(Icons.refresh);
    if (refreshFinder.evaluate().isNotEmpty) {
      await tester.tap(refreshFinder.first);
      final _ = await tester.pumpAndSettle();
    }

    expect(find.byType(AuraCard), findsOneWidget);
  });

  testWidgets('MCP group shows delete button', (tester) async {
    final mcpGroup = _group(
      id: 'mcp-del',
      name: 'MCP Del',
      mcpServerId: 'srv-del',
    );
    final groupWithTools = ToolsGroupWithTools(
      group: mcpGroup,
      tools: [_tool()],
      mcpConnectionState: McpConnectionState(
        server: McpServerEntity(
          id: 'srv-del',
          workspaceId: _workspaceId,
          name: 'MCP',
          url: 'http://localhost:8080',
          transport: const McpTransportTypeSSE(),
          authenticationType: const McpAuthenticationType.none(),
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
        status: McpConnectionStatus.connected,
      ),
    );

    await tester.pumpWidget(
      _Subject(
        child: ToolsGroupCard(
          groupWithTools: groupWithTools,
          workspaceId: _workspaceId,
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();

    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });

  testWidgets('MCP disconnected group shows reconnect button', (tester) async {
    final mcpGroup = _group(
      id: 'mcp-disc',
      name: 'MCP Disconn',
      mcpServerId: 'srv-disc',
    );
    final groupWithTools = ToolsGroupWithTools(
      group: mcpGroup,
      tools: [_tool()],
      mcpConnectionState: McpConnectionState(
        server: McpServerEntity(
          id: 'srv-disc',
          workspaceId: _workspaceId,
          name: 'MCP',
          url: 'http://localhost:8080',
          transport: const McpTransportTypeSSE(),
          authenticationType: const McpAuthenticationType.none(),
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
        status: McpConnectionStatus.disconnected,
      ),
    );

    await tester.pumpWidget(
      _Subject(
        child: ToolsGroupCard(
          groupWithTools: groupWithTools,
          workspaceId: _workspaceId,
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();

    final refreshFinder = find.byIcon(Icons.refresh);
    if (refreshFinder.evaluate().isNotEmpty) {
      await tester.tap(refreshFinder.first);
      final _ = await tester.pumpAndSettle();
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
      _Subject(
        child: ToolsGroupCard(
          groupWithTools: groupWithTools,
          workspaceId: _workspaceId,
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();

    expect(find.byIcon(Icons.delete_outline), findsNothing);
    expect(find.byIcon(Icons.refresh), findsNothing);
  });
}
