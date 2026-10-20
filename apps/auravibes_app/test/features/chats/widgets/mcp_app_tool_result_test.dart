import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/domain/models/mcp_tool_info.dart';
import 'package:auravibes_app/features/chats/widgets/mcp_app_tool_result.dart';
import 'package:auravibes_app/features/chats/widgets/mcp_app_tool_result_controller.dart';
import 'package:auravibes_app/notifiers/mcp_connection_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/test_app.dart';

const _resourceUri = 'ui://weather/forecast';

void main() {
  test('formats app arguments and caps preview length', () {
    final formatted = formatMcpAppApprovalArguments({'target': 'file.txt'});
    final emoji = String.fromCharCodes([0x1f600]);
    final truncated = formatMcpAppApprovalArguments({'value': emoji * 3000});
    final ellipsis = String.fromCharCode(0x2026);

    expect(formatted, '{\n  "target": "file.txt"\n}');
    expect(truncated.runes.length, 2001);
    expect(truncated.endsWith(ellipsis), isTrue);
  });

  testWidgets(
    'matches declared MCP App result and shows retry fallback on resource error',
    (tester) async {
      final server = McpServerEntity(
        id: 'server-1',
        workspaceId: 'workspace-1',
        name: 'Weather Server',
        url: 'https://mcp.example',
        transport: const McpTransportTypeSSE(),
        authenticationType: const McpAuthenticationTypeNone(),
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      final appTool = McpToolInfo(
        toolName: 'get_forecast',
        description: 'Gets forecast',
        inputSchema: const {},
        metadata: const {
          'ui': {'resourceUri': _resourceUri},
        },
      );
      final connection = McpConnectionState(
        server: server,
        status: McpConnectionStatus.connected,
        tools: [appTool],
      );
      final appToolCall = _toolCall(
        id: 'app-result',
        name: appTool.finalToolName(server),
      );
      final unmatchedToolCall = _toolCall(
        id: 'unmatched-result',
        name: 'browser_search',
      );

      await tester.runAsync(
        () => tester.pumpWidget(
          TestableApp(
            overrides: [
              mcpConnectionProvider.overrideWith(
                () => _TestMcpConnectionNotifier([connection]),
              ),
            ],
            child: Column(
              children: [
                const Text('Forecast result'),
                McpAppToolResult(
                  workspaceId: server.workspaceId,
                  conversationId: 'conversation-1',
                  toolCall: appToolCall,
                  fallbackText: 'Forecast result',
                  controller: McpAppToolResultController(),
                ),
                const Text('Search result'),
                McpAppToolResult(
                  workspaceId: server.workspaceId,
                  conversationId: 'conversation-1',
                  toolCall: unmatchedToolCall,
                  fallbackText: 'Search result',
                  controller: McpAppToolResultController(),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Forecast result'), findsOneWidget);
      expect(find.text('Search result'), findsOneWidget);
      expect(
        find.text(
          'Interactive result unavailable. The text result remains above.',
        ),
        findsOneWidget,
      );
      expect(find.text('Try again'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

MessageToolCallEntity _toolCall({required String id, required String name}) =>
    MessageToolCallEntity(
      id: id,
      name: name,
      argumentsRaw: '{}',
      responseRaw: '{"content":[]}',
      resultStatus: ToolCallResultStatus.success,
    );

class _TestMcpConnectionNotifier(this._connections)
    extends McpConnectionNotifier {
  final List<McpConnectionState> _connections;

  @override
  List<McpConnectionState> build() => _connections;
}
