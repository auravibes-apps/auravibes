import 'package:auravibes_app/domain/entities/mcp_server.dart';
import 'package:auravibes_app/features/chats/providers/messages_providers.dart';
import 'package:auravibes_app/features/chats/widgets/mcp_connecting_indicator.dart';
import 'package:auravibes_app/notifiers/mcp_connection_notifier.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

McpServerEntity _mcpServer({
  String id = 'server-1',
  String name = 'Test Server',
}) {
  return McpServerEntity(
    id: id,
    workspaceId: 'ws1',
    name: name,
    url: 'http://localhost',
    transport: const McpTransportTypeStreamableHttp(),
    authenticationType: const McpAuthenticationType.none(),
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
}

void main() {
  testWidgets('renders SizedBox.shrink when no pending connections', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pendingMcpConnectionsProvider.overrideWithValue(const []),
          mcpConnectionProvider.overrideWithValue(const []),
        ],
        child: MaterialApp(
          theme: ThemeData(extensions: [AuraTheme.light]),
          home: const Scaffold(body: McpConnectingIndicator()),
        ),
      ),
    );

    expect(find.byType(SizedBox), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('renders progress indicator when pending connections exist', (
    tester,
  ) async {
    const pendingIds = ['server-1'];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pendingMcpConnectionsProvider.overrideWithValue(pendingIds),
          mcpConnectionProvider.overrideWithValue([
            McpConnectionState(
              server: _mcpServer(),
              status: McpConnectionStatus.connecting,
            ),
          ]),
        ],
        child: MaterialApp(
          theme: ThemeData(extensions: [AuraTheme.light]),
          home: const Scaffold(body: McpConnectingIndicator()),
        ),
      ),
    );

    expect(find.byType(AuraContainer), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
