// ignore_for_file: avoid-returning-widgets
// Required: Widget tests use helpers that build widgets under test.
// ignore_for_file: no-equal-arguments
// Required: Tests use repeated fixture values to assert equality semantics.
// ignore_for_file: no-empty-block
// Required: Tests use intentional no-op callbacks and fake hooks.
// ignore_for_file: prefer-correct-identifier-length
// Required: Existing short identifiers follow callback and pattern APIs.
// ignore_for_file: prefer-static-class
// Required: Tests keep fixture helpers and fakes top-level.
import 'package:auravibes_app/data/database/drift/enums/permission_access.dart';
import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/domain/entities/tools_group_entity.dart';
import 'package:auravibes_app/domain/models/mcp_connection_view_status.dart';
import 'package:auravibes_app/features/tools/models/tools_group_with_tools.dart';
import 'package:auravibes_app/features/tools/widgets/tools_group_header.dart';
import 'package:auravibes_app/notifiers/mcp_connection_status.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

ToolsGroupEntity _group({String id = 'g1', String name = 'Test Group'}) {
  return ToolsGroupEntity(
    id: id,
    workspaceId: _workspaceId,
    name: name,
    isEnabled: true,
    permissions: PermissionAccess.ask,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
}

McpServerEntity _mcpServer({String id = 'mcp-1'}) {
  return McpServerEntity(
    id: id,
    workspaceId: _workspaceId,
    name: 'Test MCP',
    url: 'http://test.com',
    transport: const McpTransportTypeStreamableHttp(),
    authenticationType: const McpAuthenticationType.none(),
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
}

Widget _buildSubject(Widget child) {
  return EasyLocalization(
    child: MaterialApp(
      home: Theme(
        data: ThemeData(extensions: [AuraTheme.light]),
        child: Material(child: child),
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

void main() {
  testWidgets('renders group name for named group', (tester) async {
    final groupWithTools = ToolsGroupWithTools(
      group: _group(name: 'My MCP Server'),
      tools: [_tool()],
    );

    await tester.pumpWidget(
      _buildSubject(
        ToolsGroupHeader(
          groupWithTools: groupWithTools,
          isExpanded: false,
          onToggleExpand: () {},
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();

    expect(find.text('My MCP Server'), findsOneWidget);
  });

  testWidgets('shows toggle for non-default group', (tester) async {
    final groupWithTools = ToolsGroupWithTools(
      group: _group(),
      tools: [_tool()],
    );

    await tester.pumpWidget(
      _buildSubject(
        ToolsGroupHeader(
          groupWithTools: groupWithTools,
          isExpanded: false,
          onToggleExpand: () {},
          onToggleEnabled: (_) {},
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();

    expect(find.byType(AuraSwitch), findsOneWidget);
  });

  testWidgets('hides toggle for default group', (tester) async {
    final groupWithTools = ToolsGroupWithTools(
      group: null,
      tools: [_tool()],
      defaultGroupType: DefaultToolGroupType.builtIn,
    );

    await tester.pumpWidget(
      _buildSubject(
        ToolsGroupHeader(
          groupWithTools: groupWithTools,
          isExpanded: false,
          onToggleExpand: () {},
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();

    expect(find.byType(AuraSwitch), findsNothing);
  });

  testWidgets('renders expand chevron', (tester) async {
    final groupWithTools = ToolsGroupWithTools(
      group: _group(),
      tools: [_tool()],
    );

    await tester.pumpWidget(
      _buildSubject(
        ToolsGroupHeader(
          groupWithTools: groupWithTools,
          isExpanded: false,
          onToggleExpand: () {},
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();

    expect(
      find.widgetWithIcon(IconButton, Icons.keyboard_arrow_down),
      findsOneWidget,
    );
  });

  testWidgets('shows delete button for MCP group when onDelete provided', (
    tester,
  ) async {
    final mcpGroup = ToolsGroupEntity(
      id: 'g-mcp',
      workspaceId: _workspaceId,
      name: 'MCP Group',
      isEnabled: true,
      permissions: PermissionAccess.ask,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      mcpServerId: 'mcp-1',
    );
    final groupWithTools = ToolsGroupWithTools(
      group: mcpGroup,
      tools: [_tool()],
    );

    await tester.pumpWidget(
      _buildSubject(
        ToolsGroupHeader(
          groupWithTools: groupWithTools,
          isExpanded: false,
          onToggleExpand: () {},
          onDelete: () {},
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();

    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });

  testWidgets('hides delete button for non-MCP group', (tester) async {
    final groupWithTools = ToolsGroupWithTools(
      group: _group(),
      tools: [_tool()],
    );

    await tester.pumpWidget(
      _buildSubject(
        ToolsGroupHeader(
          groupWithTools: groupWithTools,
          isExpanded: false,
          onToggleExpand: () {},
          onDelete: () {},
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();

    expect(find.byIcon(Icons.delete_outline), findsNothing);
  });

  testWidgets('shows MCP connecting spinner', (tester) async {
    final mcpGroup = ToolsGroupEntity(
      id: 'g-mcp',
      workspaceId: _workspaceId,
      name: 'MCP',
      isEnabled: true,
      permissions: PermissionAccess.ask,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      mcpServerId: 'mcp-1',
    );
    final groupWithTools = ToolsGroupWithTools(
      group: mcpGroup,
      tools: [_tool()],
      mcpConnectionState: McpConnectionState(
        server: _mcpServer(),
        status: McpConnectionStatus.connecting,
      ),
    );

    await tester.pumpWidget(
      _buildSubject(
        ToolsGroupHeader(
          groupWithTools: groupWithTools,
          isExpanded: false,
          onToggleExpand: () {},
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(AuraSpinner), findsOneWidget);
  });

  testWidgets('shows MCP connected badge', (tester) async {
    final mcpGroup = ToolsGroupEntity(
      id: 'g-mcp',
      workspaceId: _workspaceId,
      name: 'MCP',
      isEnabled: true,
      permissions: PermissionAccess.ask,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      mcpServerId: 'mcp-1',
    );
    final groupWithTools = ToolsGroupWithTools(
      group: mcpGroup,
      tools: [_tool()],
      mcpConnectionState: McpConnectionState(
        server: _mcpServer(),
        status: McpConnectionStatus.connected,
      ),
    );

    await tester.pumpWidget(
      _buildSubject(
        ToolsGroupHeader(
          groupWithTools: groupWithTools,
          isExpanded: false,
          onToggleExpand: () {},
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();

    expect(find.byType(AuraBadge), findsOneWidget);
  });

  testWidgets('shows MCP error badge', (tester) async {
    final mcpGroup = ToolsGroupEntity(
      id: 'g-mcp',
      workspaceId: _workspaceId,
      name: 'MCP',
      isEnabled: true,
      permissions: PermissionAccess.ask,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      mcpServerId: 'mcp-1',
    );
    final groupWithTools = ToolsGroupWithTools(
      group: mcpGroup,
      tools: [_tool()],
      mcpConnectionState: McpConnectionState(
        server: _mcpServer(),
        status: McpConnectionStatus.error,
        errorMessage: 'Connection failed',
      ),
    );

    await tester.pumpWidget(
      _buildSubject(
        ToolsGroupHeader(
          groupWithTools: groupWithTools,
          isExpanded: false,
          onToggleExpand: () {},
          onViewError: () {},
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();

    expect(find.byType(AuraBadge), findsOneWidget);
  });

  testWidgets('shows MCP disconnected badge', (tester) async {
    final mcpGroup = ToolsGroupEntity(
      id: 'g-mcp',
      workspaceId: _workspaceId,
      name: 'MCP',
      isEnabled: true,
      permissions: PermissionAccess.ask,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      mcpServerId: 'mcp-1',
    );
    final groupWithTools = ToolsGroupWithTools(
      group: mcpGroup,
      tools: [_tool()],
      mcpConnectionState: McpConnectionState(
        server: _mcpServer(),
        status: McpConnectionStatus.disconnected,
      ),
    );

    await tester.pumpWidget(
      _buildSubject(
        ToolsGroupHeader(
          groupWithTools: groupWithTools,
          isExpanded: false,
          onToggleExpand: () {},
          onReconnect: () {},
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();

    expect(find.byType(AuraBadge), findsOneWidget);
  });

  testWidgets('renders extension icon for MCP group', (tester) async {
    final mcpGroup = ToolsGroupEntity(
      id: 'g-mcp',
      workspaceId: _workspaceId,
      name: 'MCP',
      isEnabled: true,
      permissions: PermissionAccess.ask,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      mcpServerId: 'mcp-1',
    );
    final groupWithTools = ToolsGroupWithTools(
      group: mcpGroup,
      tools: [_tool()],
    );

    await tester.pumpWidget(
      _buildSubject(
        ToolsGroupHeader(
          groupWithTools: groupWithTools,
          isExpanded: false,
          onToggleExpand: () {},
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();

    expect(find.byIcon(Icons.extension), findsOneWidget);
  });

  testWidgets('renders build_circle icon for default group', (tester) async {
    final groupWithTools = ToolsGroupWithTools(
      group: _group(),
      tools: [_tool()],
    );

    await tester.pumpWidget(
      _buildSubject(
        ToolsGroupHeader(
          groupWithTools: groupWithTools,
          isExpanded: false,
          onToggleExpand: () {},
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();

    expect(find.byIcon(Icons.build_circle_outlined), findsOneWidget);
  });

  testWidgets('does not show MCP badge for non-MCP group', (tester) async {
    final groupWithTools = ToolsGroupWithTools(
      group: _group(),
      tools: [_tool()],
    );

    await tester.pumpWidget(
      _buildSubject(
        ToolsGroupHeader(
          groupWithTools: groupWithTools,
          isExpanded: false,
          onToggleExpand: () {},
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();

    expect(find.byType(AuraBadge), findsNothing);
    expect(find.byType(AuraSpinner), findsNothing);
  });
}
