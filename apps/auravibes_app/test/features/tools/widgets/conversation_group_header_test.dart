import 'package:auravibes_app/data/database/drift/enums/permission_access.dart';
import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/domain/entities/tools_group_entity.dart';
import 'package:auravibes_app/features/tools/models/conversation_tools_group_with_tools.dart';
import 'package:auravibes_app/features/tools/notifiers/conversation_tool_state.dart';
import 'package:auravibes_app/features/tools/widgets/conversation_group_header.dart';
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

ConversationToolState _toolState({
  String id = 't1',
  bool isEnabled = true,
}) {
  return ConversationToolState(
    tool: _tool(id: id),
    isEnabled: isEnabled,
    permissionMode: ToolPermissionMode.alwaysAsk,
    isWorkspaceEnabled: true,
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
    supportedLocales: const [Locale('en')],
    path: 'assets/i18n',
    fallbackLocale: const Locale('en'),
    startLocale: const Locale('en'),
    useFallbackTranslations: true,
    useOnlyLangCode: true,
    child: MaterialApp(
      home: Theme(
        data: ThemeData(extensions: [AuraTheme.light]),
        child: Material(child: child),
      ),
    ),
  );
}

void main() {
  testWidgets('renders group name for named group', (tester) async {
    final groupWithTools = ConversationToolsGroupWithTools(
      group: _group(name: 'My MCP Group'),
      tools: [_toolState()],
    );

    await tester.pumpWidget(
      _buildSubject(
        ConversationGroupHeader(
          groupWithTools: groupWithTools,
          isExpanded: false,
          onToggleExpand: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('My MCP Group'), findsOneWidget);
  });

  testWidgets('shows toggle when onToggleAllTools provided', (tester) async {
    final groupWithTools = ConversationToolsGroupWithTools(
      group: _group(),
      tools: [_toolState()],
    );

    await tester.pumpWidget(
      _buildSubject(
        ConversationGroupHeader(
          groupWithTools: groupWithTools,
          isExpanded: false,
          onToggleExpand: () {},
          onToggleAllTools: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AuraSwitch), findsOneWidget);
  });

  testWidgets('hides toggle when onToggleAllTools is null', (tester) async {
    final groupWithTools = ConversationToolsGroupWithTools(
      group: _group(),
      tools: [_toolState()],
    );

    await tester.pumpWidget(
      _buildSubject(
        ConversationGroupHeader(
          groupWithTools: groupWithTools,
          isExpanded: false,
          onToggleExpand: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AuraSwitch), findsNothing);
  });

  testWidgets('renders expand chevron', (tester) async {
    final groupWithTools = ConversationToolsGroupWithTools(
      group: _group(),
      tools: [_toolState()],
    );

    await tester.pumpWidget(
      _buildSubject(
        ConversationGroupHeader(
          groupWithTools: groupWithTools,
          isExpanded: false,
          onToggleExpand: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.widgetWithIcon(IconButton, Icons.keyboard_arrow_down),
      findsOneWidget,
    );
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
    final groupWithTools = ConversationToolsGroupWithTools(
      group: mcpGroup,
      tools: [_toolState()],
      mcpConnectionState: McpConnectionState(
        server: _mcpServer(),
        status: McpConnectionStatus.connecting,
      ),
    );

    await tester.pumpWidget(
      _buildSubject(
        ConversationGroupHeader(
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
    final groupWithTools = ConversationToolsGroupWithTools(
      group: mcpGroup,
      tools: [_toolState()],
      mcpConnectionState: McpConnectionState(
        server: _mcpServer(),
        status: McpConnectionStatus.connected,
      ),
    );

    await tester.pumpWidget(
      _buildSubject(
        ConversationGroupHeader(
          groupWithTools: groupWithTools,
          isExpanded: false,
          onToggleExpand: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AuraBadge), findsOneWidget);
  });

  testWidgets('shows MCP disconnected badge with reconnect', (tester) async {
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
    final groupWithTools = ConversationToolsGroupWithTools(
      group: mcpGroup,
      tools: [_toolState()],
      mcpConnectionState: McpConnectionState(
        server: _mcpServer(),
        status: McpConnectionStatus.disconnected,
      ),
    );

    await tester.pumpWidget(
      _buildSubject(
        ConversationGroupHeader(
          groupWithTools: groupWithTools,
          isExpanded: false,
          onToggleExpand: () {},
          onReconnect: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

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
    final groupWithTools = ConversationToolsGroupWithTools(
      group: mcpGroup,
      tools: [_toolState()],
      mcpConnectionState: McpConnectionState(
        server: _mcpServer(),
        status: McpConnectionStatus.error,
        errorMessage: 'Connection failed',
      ),
    );

    await tester.pumpWidget(
      _buildSubject(
        ConversationGroupHeader(
          groupWithTools: groupWithTools,
          isExpanded: false,
          onToggleExpand: () {},
          onViewError: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

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
    final groupWithTools = ConversationToolsGroupWithTools(
      group: mcpGroup,
      tools: [_toolState()],
    );

    await tester.pumpWidget(
      _buildSubject(
        ConversationGroupHeader(
          groupWithTools: groupWithTools,
          isExpanded: false,
          onToggleExpand: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.extension), findsOneWidget);
  });

  testWidgets('renders build_circle icon for default group', (tester) async {
    final groupWithTools = ConversationToolsGroupWithTools(
      group: _group(),
      tools: [_toolState()],
    );

    await tester.pumpWidget(
      _buildSubject(
        ConversationGroupHeader(
          groupWithTools: groupWithTools,
          isExpanded: false,
          onToggleExpand: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.build_circle_outlined), findsOneWidget);
  });

  testWidgets('tool count renders text', (tester) async {
    final groupWithTools = ConversationToolsGroupWithTools(
      group: _group(),
      tools: [
        _toolState(),
        _toolState(id: 't2', isEnabled: false),
        _toolState(id: 't3'),
      ],
    );

    await tester.pumpWidget(
      _buildSubject(
        ConversationGroupHeader(
          groupWithTools: groupWithTools,
          isExpanded: false,
          onToggleExpand: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AuraText), findsWidgets);
  });
}
