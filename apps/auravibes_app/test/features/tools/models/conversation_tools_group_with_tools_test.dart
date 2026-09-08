import 'package:auravibes_app/data/database/drift/enums/permission_access.dart';
import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/features/tools/models/conversation_tools_group_with_tools.dart';
import 'package:auravibes_app/features/tools/notifiers/conversation_tool_state.dart';
import 'package:auravibes_app/notifiers/mcp_connection_status.dart';
import 'package:flutter_test/flutter_test.dart';

ConversationToolState _toolState({
  String id = 't1',
  String toolId = 'calculator',
  bool isEnabled = true,
}) {
  return ConversationToolState(
    tool: .new(
      id: id,
      workspaceId: 'ws1',
      toolId: toolId,
      isEnabled: isEnabled,
      permissionMode: ToolPermissionMode.alwaysAsk,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    ),
    isEnabled: isEnabled,
    permissionMode: .alwaysAsk,
    isWorkspaceEnabled: true,
  );
}

void main() {
  group('ConversationToolsGroupWithTools', () {
    test('enabledToolsCount counts enabled tools', () {
      final group = ConversationToolsGroupWithTools(
        group: null,
        tools: [
          _toolState(),
          _toolState(id: 't2', isEnabled: false),
          _toolState(id: 't3'),
        ],
        defaultGroupType: .builtIn,
      );
      expect(group.enabledToolsCount, 2);
    });

    test('enabledToolsCount is 0 when all disabled', () {
      final group = ConversationToolsGroupWithTools(
        group: null,
        tools: [_toolState(isEnabled: false)],
        defaultGroupType: .builtIn,
      );
      expect(group.enabledToolsCount, 0);
    });

    test('totalToolsCount returns total count', () {
      final group = ConversationToolsGroupWithTools(
        group: null,
        tools: [
          _toolState(),
          _toolState(id: 't2'),
          _toolState(id: 't3'),
        ],
        defaultGroupType: .builtIn,
      );
      expect(group.totalToolsCount, 3);
    });

    test('areAllToolsEnabled returns true when all enabled', () {
      final group = ConversationToolsGroupWithTools(
        group: null,
        tools: [
          _toolState(),
          _toolState(id: 't2'),
        ],
        defaultGroupType: .builtIn,
      );
      expect(group.areAllToolsEnabled, isTrue);
    });

    test('areAllToolsEnabled returns false when some disabled', () {
      final group = ConversationToolsGroupWithTools(
        group: null,
        tools: [
          _toolState(),
          _toolState(id: 't2', isEnabled: false),
        ],
        defaultGroupType: .builtIn,
      );
      expect(group.areAllToolsEnabled, isFalse);
    });

    test('areAllToolsEnabled returns false when empty', () {
      const group = ConversationToolsGroupWithTools(
        group: null,
        tools: [],
        defaultGroupType: .builtIn,
      );
      expect(group.areAllToolsEnabled, isFalse);
    });

    test('areAnyToolsEnabled returns true when some enabled', () {
      final group = ConversationToolsGroupWithTools(
        group: null,
        tools: [
          _toolState(isEnabled: false),
          _toolState(id: 't2'),
        ],
        defaultGroupType: .builtIn,
      );
      expect(group.areAnyToolsEnabled, isTrue);
    });

    test('areAnyToolsEnabled returns false when all disabled', () {
      final group = ConversationToolsGroupWithTools(
        group: null,
        tools: [_toolState(isEnabled: false)],
        defaultGroupType: .builtIn,
      );
      expect(group.areAnyToolsEnabled, isFalse);
    });

    test('assertion fails when both group and defaultGroupType are null', () {
      expect(
        () => ConversationToolsGroupWithTools(group: null, tools: []),
        throwsA(isA<AssertionError>()),
      );
    });

    test('assertion fails when both group and defaultGroupType are set', () {
      expect(
        () => ConversationToolsGroupWithTools(
          group: .new(
            id: 'g1',
            workspaceId: 'ws1',
            name: 'Group',
            isEnabled: true,
            permissions: PermissionAccess.ask,
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026),
          ),
          tools: [],
          defaultGroupType: .builtIn,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('works with MCP connection state', () {
      final server = McpServerEntity(
        id: 'srv1',
        workspaceId: 'ws1',
        name: 'Test',
        url: 'https://example.com',
        transport: const McpTransportTypeSSE(),
        authenticationType: const McpAuthenticationTypeNone(),
        createdAt: .new(2026),
        updatedAt: .new(2026),
      );
      final group = ConversationToolsGroupWithTools(
        group: .new(
          id: 'g1',
          workspaceId: 'ws1',
          name: 'MCP Group',
          isEnabled: true,
          permissions: PermissionAccess.ask,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
          mcpServerId: 'srv1',
        ),
        tools: [],
        mcpConnectionState: .new(
          server: server,
          status: McpConnectionStatus.connected,
        ),
      );
      expect(group.isMcpGroup, isTrue);
      expect(group.isMcpConnected, isTrue);
    });
  });
}
