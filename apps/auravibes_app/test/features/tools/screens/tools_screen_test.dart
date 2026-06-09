// ignore_for_file: prefer-correct-identifier-length
// Required: Existing short identifiers follow callback and pattern APIs.
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/features/tools/models/tools_group_with_tools.dart';
import 'package:auravibes_app/features/tools/notifiers/grouped_tools_notifier.dart';
import 'package:auravibes_app/features/tools/providers/workspace_tools_notifier.dart';
import 'package:auravibes_app/features/tools/screens/tools_screen.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_app.dart';

class _MockWorkspaceToolsNotifier extends WorkspaceToolsNotifier {
  @override
  Future<List<WorkspaceToolEntity>> build(String workspaceId) async => [];
}

class _MockGroupedToolsNotifier extends GroupedToolsNotifier {
  @override
  Future<List<ToolsGroupWithTools>> build(String workspaceId) async => [];
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
          testableApp(
            child: Theme(
              data: ThemeData(extensions: [AuraTheme.light]),
              child: const ToolsScreen(workspaceId: 'test-ws'),
            ),
            overrides: [
              workspaceToolsProvider('test-ws').overrideWith(
                _MockWorkspaceToolsNotifier.new,
              ),
              groupedToolsProvider('test-ws').overrideWith(
                _MockGroupedToolsNotifier.new,
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

    testWidgets('back button pops ToolsScreen route', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          testableApp(
            child: Navigator(
              pages: [
                const MaterialPage<void>(child: Placeholder()),
                MaterialPage<void>(
                  child: Theme(
                    data: ThemeData(extensions: [AuraTheme.light]),
                    child: const ToolsScreen(workspaceId: 'test-ws'),
                  ),
                ),
              ],
              onDidRemovePage: (_) {
                final _ = Object();
              },
            ),
            overrides: [
              workspaceToolsProvider('test-ws').overrideWith(
                _MockWorkspaceToolsNotifier.new,
              ),
              groupedToolsProvider('test-ws').overrideWith(
                _MockGroupedToolsNotifier.new,
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
  });
}
