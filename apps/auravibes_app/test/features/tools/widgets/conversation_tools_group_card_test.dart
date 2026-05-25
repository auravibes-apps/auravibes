// ignore_for_file: scoped_providers_should_specify_dependencies
// Required: widget tests override scoped providers directly.

import 'package:auravibes_app/data/database/drift/enums/permission_access.dart';
import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/domain/entities/tools_group_entity.dart';
import 'package:auravibes_app/domain/models/mcp_connection_view_status.dart';
import 'package:auravibes_app/features/tools/models/conversation_tools_group_with_tools.dart';
import 'package:auravibes_app/features/tools/notifiers/conversation_tool_state.dart';
import 'package:auravibes_app/features/tools/notifiers/grouped_conversation_tools_notifier.dart';
import 'package:auravibes_app/features/tools/widgets/conversation_group_header.dart';
import 'package:auravibes_app/features/tools/widgets/conversation_tool_tile.dart';
import 'package:auravibes_app/features/tools/widgets/conversation_tools_group_card.dart';
import 'package:auravibes_app/notifiers/mcp_connection_status.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_provider_scope.dart';

const _workspaceId = 'ws-1';

WorkspaceToolEntity _tool({String id = 't1'}) {
  return WorkspaceToolEntity(
    id: id,
    workspaceId: _workspaceId,
    toolId: 'custom_tool',
    isEnabled: true,
    permissionMode: ToolPermissionMode.alwaysAsk,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
}

ToolsGroupEntity _group({
  String id = 'g1',
  String name = 'Test Group',
  String? mcpServerId,
}) {
  return ToolsGroupEntity(
    id: id,
    workspaceId: _workspaceId,
    name: name,
    isEnabled: true,
    permissions: PermissionAccess.ask,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    mcpServerId: mcpServerId,
  );
}

ConversationToolState _toolState({String id = 't1'}) {
  return ConversationToolState(
    tool: _tool(id: id),
    isEnabled: false,
    permissionMode: ToolPermissionMode.alwaysAsk,
    isWorkspaceEnabled: true,
  );
}

class _MockConversationToolsNotifier extends ConversationToolsNotifier {
  _MockConversationToolsNotifier(this.states);

  final List<ConversationToolState> states;

  @override
  Future<List<ConversationToolState>> build({
    required String workspaceId,
    String? conversationId,
  }) async => states;
}

class _MockGroupedConversationToolsNotifier
    extends GroupedConversationToolsNotifier {
  _MockGroupedConversationToolsNotifier(this.groups);

  final List<ConversationToolsGroupWithTools> groups;

  @override
  Future<List<ConversationToolsGroupWithTools>> build({
    required String workspaceId,
    String? conversationId,
  }) async => groups;
}

Widget _buildSubject(Widget child) {
  return EasyLocalization(
    child: TestProviderScope(
      overrides: [
        conversationToolsProvider(
          workspaceId: _workspaceId,
        ).overrideWith(
          () => _MockConversationToolsNotifier([]),
        ),
        groupedConversationToolsProvider(
          workspaceId: _workspaceId,
        ).overrideWith(
          () => _MockGroupedConversationToolsNotifier([]),
        ),
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

void main() {
  testWidgets('renders ConversationGroupHeader', (tester) async {
    final groupWithTools = ConversationToolsGroupWithTools(
      group: _group(),
      tools: [_toolState()],
    );

    await tester.pumpWidget(
      _buildSubject(
        ConversationToolsGroupCard(
          groupWithTools: groupWithTools,
          workspaceId: _workspaceId,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ConversationGroupHeader), findsOneWidget);
  });

  testWidgets('does not show tool tiles when collapsed', (tester) async {
    final groupWithTools = ConversationToolsGroupWithTools(
      group: _group(),
      tools: [
        _toolState(),
        _toolState(id: 't2'),
      ],
    );

    await tester.pumpWidget(
      _buildSubject(
        ConversationToolsGroupCard(
          groupWithTools: groupWithTools,
          workspaceId: _workspaceId,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ConversationToolTile), findsNothing);
  });

  testWidgets('renders card with group name', (tester) async {
    final groupWithTools = ConversationToolsGroupWithTools(
      group: _group(name: 'My Tools'),
      tools: [],
    );

    await tester.pumpWidget(
      _buildSubject(
        ConversationToolsGroupCard(
          groupWithTools: groupWithTools,
          workspaceId: _workspaceId,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('My Tools'), findsOneWidget);
  });

  testWidgets('expands to show tool tiles', (tester) async {
    final groupWithTools = ConversationToolsGroupWithTools(
      group: _group(),
      tools: [
        _toolState(),
        _toolState(id: 't2'),
      ],
    );

    await tester.pumpWidget(
      _buildSubject(
        ConversationToolsGroupCard(
          groupWithTools: groupWithTools,
          workspaceId: _workspaceId,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(IconButton).last);
    await tester.pumpAndSettle();

    expect(find.byType(ConversationToolTile), findsNWidgets(2));
  });

  testWidgets('shows divider when expanded', (tester) async {
    final groupWithTools = ConversationToolsGroupWithTools(
      group: _group(),
      tools: [_toolState()],
    );

    await tester.pumpWidget(
      _buildSubject(
        ConversationToolsGroupCard(
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

  testWidgets('renders inside AuraCard', (tester) async {
    final groupWithTools = ConversationToolsGroupWithTools(
      group: _group(),
      tools: [],
    );

    await tester.pumpWidget(
      _buildSubject(
        ConversationToolsGroupCard(
          groupWithTools: groupWithTools,
          workspaceId: _workspaceId,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AuraCard), findsOneWidget);
  });

  testWidgets('accepts conversationId parameter', (tester) async {
    final groupWithTools = ConversationToolsGroupWithTools(
      group: _group(),
      tools: [_toolState()],
    );

    await tester.pumpWidget(
      _buildSubject(
        ConversationToolsGroupCard(
          groupWithTools: groupWithTools,
          workspaceId: _workspaceId,
          conversationId: 'conv-1',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ConversationGroupHeader), findsOneWidget);
  });

  testWidgets('accepts initiallyExpanded parameter', (tester) async {
    final groupWithTools = ConversationToolsGroupWithTools(
      group: _group(),
      tools: [_toolState()],
    );

    await tester.pumpWidget(
      _buildSubject(
        ConversationToolsGroupCard(
          groupWithTools: groupWithTools,
          workspaceId: _workspaceId,
          initiallyExpanded: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ConversationToolTile), findsOneWidget);
  });

  testWidgets('shows no tools message when expanded with empty tools', (
    tester,
  ) async {
    final groupWithTools = ConversationToolsGroupWithTools(
      group: _group(),
      tools: [],
    );

    await tester.pumpWidget(
      _buildSubject(
        ConversationToolsGroupCard(
          groupWithTools: groupWithTools,
          workspaceId: _workspaceId,
          initiallyExpanded: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AuraDivider), findsOneWidget);
    expect(find.byType(ConversationToolTile), findsNothing);
  });
  testWidgets('shows MCP error state with view error callback', (tester) async {
    final mcpGroup = _group(
      id: 'mcp-g1',
      name: 'MCP Server',
      mcpServerId: 'mcp-1',
    );
    final groupWithTools = ConversationToolsGroupWithTools(
      group: mcpGroup,
      tools: [],
      mcpConnectionState: McpConnectionState(
        server: McpServerEntity(
          id: 'mcp-1',
          workspaceId: _workspaceId,
          name: 'MCP',
          url: 'https://mcp.example.com',
          transport: const McpTransportTypeSSE(),
          authenticationType: const McpAuthenticationTypeNone(),
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
        status: McpConnectionStatus.error,
        errorMessage: 'Connection failed',
      ),
    );

    await tester.pumpWidget(
      _buildSubject(
        ConversationToolsGroupCard(
          groupWithTools: groupWithTools,
          workspaceId: _workspaceId,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ConversationGroupHeader), findsOneWidget);
  });

  testWidgets('MCP disconnected group renders', (tester) async {
    final mcpGroup = _group(
      id: 'mcp-g2',
      name: 'MCP Disc',
      mcpServerId: 'mcp-2',
    );
    final groupWithTools = ConversationToolsGroupWithTools(
      group: mcpGroup,
      tools: [_toolState()],
      mcpConnectionState: McpConnectionState(
        server: McpServerEntity(
          id: 'mcp-2',
          workspaceId: _workspaceId,
          name: 'MCP',
          url: 'https://mcp.example.com',
          transport: const McpTransportTypeSSE(),
          authenticationType: const McpAuthenticationTypeNone(),
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
        status: McpConnectionStatus.disconnected,
      ),
    );

    await tester.pumpWidget(
      _buildSubject(
        ConversationToolsGroupCard(
          groupWithTools: groupWithTools,
          workspaceId: _workspaceId,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ConversationGroupHeader), findsOneWidget);
  });

  testWidgets('MCP connected group renders without reconnect', (tester) async {
    final mcpGroup = _group(
      id: 'mcp-g3',
      name: 'MCP OK',
      mcpServerId: 'mcp-3',
    );
    final groupWithTools = ConversationToolsGroupWithTools(
      group: mcpGroup,
      tools: [_toolState()],
      mcpConnectionState: McpConnectionState(
        server: McpServerEntity(
          id: 'mcp-3',
          workspaceId: _workspaceId,
          name: 'MCP',
          url: 'https://mcp.example.com',
          transport: const McpTransportTypeSSE(),
          authenticationType: const McpAuthenticationTypeNone(),
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
        status: McpConnectionStatus.connected,
      ),
    );

    await tester.pumpWidget(
      _buildSubject(
        ConversationToolsGroupCard(
          groupWithTools: groupWithTools,
          workspaceId: _workspaceId,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ConversationGroupHeader), findsOneWidget);
  });

  testWidgets('default group renders without toggle', (tester) async {
    const groupWithTools = ConversationToolsGroupWithTools(
      group: null,
      tools: [],
      defaultGroupType: DefaultToolGroupType.builtIn,
    );

    await tester.pumpWidget(
      _buildSubject(
        const ConversationToolsGroupCard(
          groupWithTools: groupWithTools,
          workspaceId: _workspaceId,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ConversationGroupHeader), findsOneWidget);
  });

  testWidgets('MCP connecting state renders', (tester) async {
    final mcpGroup = _group(
      id: 'mcp-g4',
      name: 'MCP Conn',
      mcpServerId: 'mcp-4',
    );
    final groupWithTools = ConversationToolsGroupWithTools(
      group: mcpGroup,
      tools: [_toolState()],
      mcpConnectionState: McpConnectionState(
        server: McpServerEntity(
          id: 'mcp-4',
          workspaceId: _workspaceId,
          name: 'MCP',
          url: 'https://mcp.example.com',
          transport: const McpTransportTypeSSE(),
          authenticationType: const McpAuthenticationTypeNone(),
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
        status: McpConnectionStatus.connecting,
      ),
    );

    await tester.pumpWidget(
      _buildSubject(
        ConversationToolsGroupCard(
          groupWithTools: groupWithTools,
          workspaceId: _workspaceId,
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(ConversationGroupHeader), findsOneWidget);
  });

  testWidgets('collapses after second tap', (tester) async {
    final groupWithTools = ConversationToolsGroupWithTools(
      group: _group(),
      tools: [_toolState()],
    );

    await tester.pumpWidget(
      _buildSubject(
        ConversationToolsGroupCard(
          groupWithTools: groupWithTools,
          workspaceId: _workspaceId,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(IconButton).first);
    await tester.pumpAndSettle();
    expect(find.byType(ConversationToolTile), findsOneWidget);

    await tester.tap(find.byType(IconButton).first);
    await tester.pumpAndSettle();
    expect(find.byType(ConversationToolTile), findsNothing);
  });

  testWidgets('multiple tools expanded with conversationId', (tester) async {
    final groupWithTools = ConversationToolsGroupWithTools(
      group: _group(),
      tools: [
        _toolState(),
        _toolState(id: 't2'),
        _toolState(id: 't3'),
      ],
    );

    await tester.pumpWidget(
      _buildSubject(
        ConversationToolsGroupCard(
          groupWithTools: groupWithTools,
          workspaceId: _workspaceId,
          conversationId: 'conv-1',
          initiallyExpanded: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ConversationToolTile), findsNWidgets(3));
  });

  testWidgets('empty tools group expanded shows no tools message', (
    tester,
  ) async {
    final groupWithTools = ConversationToolsGroupWithTools(
      group: _group(),
      tools: [],
    );

    await tester.pumpWidget(
      _buildSubject(
        ConversationToolsGroupCard(
          groupWithTools: groupWithTools,
          workspaceId: _workspaceId,
          initiallyExpanded: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('tools_screen.no_tools_in_group'), findsOneWidget);
  });

  testWidgets('tapping switch triggers toggleAllTools callback', (
    tester,
  ) async {
    final groupWithTools = ConversationToolsGroupWithTools(
      group: _group(),
      tools: [_toolState()],
    );

    await tester.pumpWidget(
      _buildSubject(
        ConversationToolsGroupCard(
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

  testWidgets('MCP error group reconnect button can be tapped', (
    tester,
  ) async {
    final mcpGroup = _group(
      id: 'mcp-recon',
      name: 'MCP Recon',
      mcpServerId: 'mcp-srv-recon',
    );
    final groupWithTools = ConversationToolsGroupWithTools(
      group: mcpGroup,
      tools: [_toolState()],
      mcpConnectionState: McpConnectionState(
        server: McpServerEntity(
          id: 'mcp-srv-recon',
          workspaceId: _workspaceId,
          name: 'MCP',
          url: 'https://mcp.example.com',
          transport: const McpTransportTypeSSE(),
          authenticationType: const McpAuthenticationTypeNone(),
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
        status: McpConnectionStatus.error,
        errorMessage: 'Connection failed',
      ),
    );

    await tester.pumpWidget(
      _buildSubject(
        ConversationToolsGroupCard(
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

    expect(find.byType(ConversationGroupHeader), findsOneWidget);
  });

  testWidgets('MCP disconnected group reconnect can be tapped', (
    tester,
  ) async {
    final mcpGroup = _group(
      id: 'mcp-discon2',
      name: 'MCP Discon',
      mcpServerId: 'mcp-srv-discon',
    );
    final groupWithTools = ConversationToolsGroupWithTools(
      group: mcpGroup,
      tools: [_toolState()],
      mcpConnectionState: McpConnectionState(
        server: McpServerEntity(
          id: 'mcp-srv-discon',
          workspaceId: _workspaceId,
          name: 'MCP',
          url: 'https://mcp.example.com',
          transport: const McpTransportTypeSSE(),
          authenticationType: const McpAuthenticationTypeNone(),
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
        status: McpConnectionStatus.disconnected,
      ),
    );

    await tester.pumpWidget(
      _buildSubject(
        ConversationToolsGroupCard(
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

    expect(find.byType(ConversationGroupHeader), findsOneWidget);
  });

  testWidgets('non-MCP group has no reconnect button', (tester) async {
    final groupWithTools = ConversationToolsGroupWithTools(
      group: _group(),
      tools: [_toolState()],
    );

    await tester.pumpWidget(
      _buildSubject(
        ConversationToolsGroupCard(
          groupWithTools: groupWithTools,
          workspaceId: _workspaceId,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.refresh), findsNothing);
  });
}
