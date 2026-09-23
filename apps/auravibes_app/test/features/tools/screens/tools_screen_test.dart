import 'dart:async';

import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/features/tools/models/tools_group_with_tools.dart';
import 'package:auravibes_app/features/tools/notifiers/grouped_tools_notifier.dart';
import 'package:auravibes_app/features/tools/providers/workspace_tools_notifier.dart';
import 'package:auravibes_app/features/tools/screens/tools_screen.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod/riverpod.dart';

import '../../../helpers/test_app.dart';

class _MockWorkspaceToolsNotifier extends WorkspaceToolsNotifier {
  @override
  Future<List<WorkspaceToolEntity>> build(String workspaceId) async => [];
}

class _ResetWorkspaceToolsNotifier extends WorkspaceToolsNotifier {
  new(this._onReset);

  final void Function() _onReset;

  @override
  Future<List<WorkspaceToolEntity>> build(String workspaceId) async => [];

  @override
  Future<void> resetToolPermissions() async {
    _onReset();
  }
}

class _MockGroupedToolsNotifier extends GroupedToolsNotifier {
  @override
  Future<List<ToolsGroupWithTools>> build(String workspaceId) async => [];
}

class _ReconnectAllNotifier extends GroupedToolsNotifier {
  new(this._groups);

  final Completer<List<String>> _reconnectResult = .new();
  final List<ToolsGroupWithTools> _groups;
  int _reconnectCalls = 0;

  @override
  Future<List<ToolsGroupWithTools>> build(String workspaceId) async => _groups;

  @override
  Future<List<String>> reconnectFailedMcps() {
    _reconnectCalls++;

    return _reconnectResult.future;
  }
}

ToolsGroupWithTools _failedMcpGroup({bool isEnabled = true}) {
  final server = McpServerEntity(
    id: 'failed-server',
    workspaceId: 'test-ws',
    name: 'Failed MCP',
    url: 'http://localhost:8080',
    transport: const McpTransportTypeSSE(),
    authenticationType: const McpAuthenticationType.none(),
    createdAt: .new(2026),
    updatedAt: .new(2026),
  );

  return ToolsGroupWithTools(
    group: .new(
      id: 'failed-group',
      workspaceId: 'test-ws',
      name: 'Failed MCP',
      isEnabled: isEnabled,
      permissions: .ask,
      createdAt: .new(2026),
      updatedAt: .new(2026),
      mcpServerId: server.id,
    ),
    tools: const [],
    mcpConnectionState: .new(server: server, status: .error),
  );
}

void main() {
  test('constructor sets workspaceId', () {
    const screen = ToolsScreen(workspaceId: 'test-ws');
    expect(screen.workspaceId, 'test-ws');
  });

  test('constructor accepts different workspaceIds', () {
    const screen = ToolsScreen(workspaceId: 'other-id');
    expect(screen.workspaceId, 'other-id');
  });

  group('render', () {
    testWidgets('renders ToolsScreen', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          TestableApp(
            child: Theme(
              data: .new(extensions: [AuraTheme.light]),
              child: const ToolsScreen(workspaceId: 'test-ws'),
            ),
            overrides: [
              workspaceToolsProvider('test-ws')
                  .overrideWith(_MockWorkspaceToolsNotifier.new),
              groupedToolsProvider('test-ws')
                  .overrideWith(_MockGroupedToolsNotifier.new),
              workspaceSessionForRouteProvider('test-ws').overrideWithValue(
                const AsyncData(
                  WorkspaceSession(
                    LocalWorkspaceRef(localWorkspaceId: 'test-ws'),
                  ),
                ),
              ),
            ],
          ),
        );
      });
      await tester.pump();
      await tester.pump();
      expect(find.byType(ToolsScreen), findsOneWidget);
      expect(find.byType(AuraScreen), findsOneWidget);
    });

    testWidgets('confirms before resetting workspace tool permissions', (
      tester,
    ) async {
      var resetCalls = 0;
      final notifier = _ResetWorkspaceToolsNotifier(() => resetCalls++);
      await tester.runAsync(() async {
        await tester.pumpWidget(
          TestableApp(
            child: Theme(
              data: .new(extensions: [AuraTheme.light]),
              child: const ToolsScreen(workspaceId: 'test-ws'),
            ),
            overrides: [
              workspaceToolsProvider('test-ws').overrideWith(() => notifier),
              groupedToolsProvider('test-ws')
                  .overrideWith(_MockGroupedToolsNotifier.new),
              workspaceSessionForRouteProvider('test-ws').overrideWithValue(
                const AsyncData(
                  WorkspaceSession(
                    LocalWorkspaceRef(localWorkspaceId: 'test-ws'),
                  ),
                ),
              ),
            ],
          ),
        );
      });
      await tester.pump();
      await tester.pump();

      await tester.tap(find.byIcon(Icons.restore));
      await tester.pump();

      expect(find.text('Reset Workspace Tool Permissions'), findsOneWidget);
      expect(
        find.text(
          'This will enable all tools in this workspace and set their '
          'permissions to Always Ask. Continue?',
        ),
        findsOneWidget,
      );
      expect(resetCalls, 0);

      await tester.tap(find.text('Cancel'));
      final _ = await tester.pumpAndSettle();
      expect(resetCalls, 0);

      await tester.tap(find.byIcon(Icons.restore));
      await tester.pump();
      await tester.tap(find.text('Confirm'));
      final _ = await tester.pumpAndSettle();

      expect(resetCalls, 1);
    });

    testWidgets('back button pops ToolsScreen route', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          TestableApp(
            child: Navigator(
              pages: [
                const MaterialPage<void>(child: Placeholder()),
                MaterialPage<void>(
                  child: Theme(
                    data: .new(extensions: [AuraTheme.light]),
                    child: const ToolsScreen(workspaceId: 'test-ws'),
                  ),
                ),
              ],
              onDidRemovePage: (_) {
                final _ = Object();
              },
            ),
            overrides: [
              workspaceToolsProvider('test-ws')
                  .overrideWith(_MockWorkspaceToolsNotifier.new),
              groupedToolsProvider('test-ws')
                  .overrideWith(_MockGroupedToolsNotifier.new),
              workspaceSessionForRouteProvider('test-ws').overrideWithValue(
                const AsyncData(
                  WorkspaceSession(
                    LocalWorkspaceRef(localWorkspaceId: 'test-ws'),
                  ),
                ),
              ),
            ],
          ),
        );
      });
      await tester.pump();
      await tester.pump();
      final backButton = find.byIcon(Icons.arrow_back);
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      final _ = await tester.pumpAndSettle();
      expect(find.byType(ToolsScreen), findsNothing);
    });

    testWidgets(
      'reconnect action disables while running and reports partial failures',
      (tester) async {
        final reconnectNotifier = _ReconnectAllNotifier([_failedMcpGroup()]);
        await tester.runAsync(() async {
          await tester.pumpWidget(
            TestableApp(
              child: Theme(
                data: .new(extensions: [AuraTheme.light]),
                child: const ToolsScreen(workspaceId: 'test-ws'),
              ),
              overrides: [
                workspaceToolsProvider('test-ws')
                    .overrideWith(_MockWorkspaceToolsNotifier.new),
                groupedToolsProvider('test-ws')
                    .overrideWith(() => reconnectNotifier),
                workspaceSessionForRouteProvider('test-ws').overrideWithValue(
                  const AsyncData(
                    WorkspaceSession(
                      LocalWorkspaceRef(localWorkspaceId: 'test-ws'),
                    ),
                  ),
                ),
              ],
            ),
          );
        });
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        final reconnectButton = find.byType(AuraButton);
        expect(find.text('Reconnect all failed MCPs'), findsOneWidget);
        expect(reconnectButton, findsOneWidget);

        await tester.tap(reconnectButton);
        await tester.pump();

        expect(reconnectNotifier._reconnectCalls, 1);
        expect(tester.widget<AuraButton>(reconnectButton).isLoading, isTrue);
        expect(tester.widget<AuraButton>(reconnectButton).disabled, isTrue);

        reconnectNotifier._reconnectResult.complete(['failed-server']);
        await tester.pump();

        expect(find.text('Could not reconnect 1 MCP group.'), findsOneWidget);
      },
    );

    testWidgets('does not offer bulk reconnect for disabled MCP groups', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          TestableApp(
            child: Theme(
              data: .new(extensions: [AuraTheme.light]),
              child: const ToolsScreen(workspaceId: 'test-ws'),
            ),
            overrides: [
              workspaceToolsProvider('test-ws')
                  .overrideWith(_MockWorkspaceToolsNotifier.new),
              groupedToolsProvider('test-ws').overrideWith(
                () =>
                    _ReconnectAllNotifier([_failedMcpGroup(isEnabled: false)]),
              ),
              workspaceSessionForRouteProvider('test-ws').overrideWithValue(
                const AsyncData(
                  WorkspaceSession(
                    LocalWorkspaceRef(localWorkspaceId: 'test-ws'),
                  ),
                ),
              ),
            ],
          ),
        );
      });
      await tester.pump();
      await tester.pump();

      expect(find.text('Reconnect all failed MCPs'), findsNothing);
    });
  });
}
