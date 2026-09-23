// ignore_for_file: scoped_providers_should_specify_dependencies
// Required: Widget tests override scoped providers directly.

import 'dart:async';

import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/features/tools/models/tools_group_with_tools.dart';
import 'package:auravibes_app/features/tools/notifiers/grouped_tools_notifier.dart';
import 'package:auravibes_app/features/tools/widgets/tool_item_row.dart';
import 'package:auravibes_app/features/tools/widgets/tools_group_card.dart';
import 'package:auravibes_app/features/tools/widgets/tools_workspace_list_widget.dart';
import 'package:auravibes_app/widgets/app_error_widget.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/test_app.dart';

const _workspaceId = 'ws-1';

WorkspaceToolEntity _tool({
  String id = 't1',
  String toolId = 'custom_tool',
  String? description,
  bool isEnabled = true,
}) {
  return WorkspaceToolEntity(
    id: id,
    workspaceId: _workspaceId,
    toolId: toolId,
    isEnabled: isEnabled,
    permissionMode: .alwaysAsk,
    createdAt: .new(2026),
    updatedAt: .new(2026),
    description: description,
  );
}

ToolsGroupWithTools _defaultGroup(List<WorkspaceToolEntity> tools) {
  return ToolsGroupWithTools(
    group: null,
    tools: tools,
    defaultGroupType: .builtIn,
  );
}

ToolsGroupWithTools _groupWithTools({
  required List<WorkspaceToolEntity> tools,
  String name = 'Test Group',
  bool isEnabled = true,
}) {
  return ToolsGroupWithTools(
    group: .new(
      id: 'group-1',
      workspaceId: _workspaceId,
      name: name,
      isEnabled: isEnabled,
      permissions: .ask,
      createdAt: .new(2026),
      updatedAt: .new(2026),
    ),
    tools: tools,
  );
}

class _LoadingNotifier extends GroupedToolsNotifier {
  final _completer = Completer<List<ToolsGroupWithTools>>();

  @override
  Future<List<ToolsGroupWithTools>> build(String workspaceId) =>
      _completer.future;
}

class _DataNotifier(final List<ToolsGroupWithTools> groups)
    extends GroupedToolsNotifier {
  @override
  Future<List<ToolsGroupWithTools>> build(String workspaceId) async => groups;
}

class _ErrorNotifier extends GroupedToolsNotifier {
  @override
  Future<List<ToolsGroupWithTools>> build(String workspaceId) async {
    throw Exception('test error');
  }
}

class const _ListApp({required final List<Object> overrides})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TestableApp(
    child: Theme(
      data: .new(extensions: [AuraTheme.light]),
      child: const Scaffold(
        body: ToolsWorkspaceListWidget(workspaceId: _workspaceId),
      ),
    ),
    overrides: overrides,
    workspaceId: _workspaceId,
  );
}

Future<void> _pumpListApp(WidgetTester tester, List<Object> overrides) async {
  await tester.runAsync(() async {
    await tester.pumpWidget(_ListApp(overrides: overrides));
  });
  await tester.pump();
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('shows loading spinner while loading', (tester) async {
    await _pumpListApp(tester, [
      groupedToolsProvider(_workspaceId).overrideWith(_LoadingNotifier.new),
    ]);

    expect(find.byType(AuraSpinner), findsOneWidget);
  });

  testWidgets('shows group cards when data loaded', (tester) async {
    final groups = [
      _defaultGroup([_tool(), _tool(id: 't2')]),
      _defaultGroup([_tool(id: 't3')]),
    ];

    await _pumpListApp(tester, [
      groupedToolsProvider(_workspaceId)
          .overrideWith(() => _DataNotifier(groups)),
    ]);

    expect(find.byType(ToolsGroupCard), findsNWidgets(2));
  });

  testWidgets('sorts tool groups by name or enabled status', (tester) async {
    final groups = [
      _groupWithTools(name: 'A Disabled', isEnabled: false, tools: []),
      _groupWithTools(name: 'Z Enabled', tools: []),
    ];
    await _pumpListApp(tester, [
      groupedToolsProvider(_workspaceId)
          .overrideWith(() => _DataNotifier(groups)),
    ]);
    final cards = find.byType(ToolsGroupCard);
    expect(
      tester.widget<ToolsGroupCard>(cards.first).groupWithTools.group?.name,
      'A Disabled',
    );

    await tester.tap(find.byKey(const ValueKey('tools-sort')));
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('Enabled').last);
    final _ = await tester.pumpAndSettle();
    expect(
      tester.widget<ToolsGroupCard>(cards.first).groupWithTools.group?.name,
      'Z Enabled',
    );
  });

  testWidgets('sorts tools within a group by enabled status', (tester) async {
    await _pumpListApp(tester, [
      groupedToolsProvider(_workspaceId).overrideWith(
        () => _DataNotifier([
          _groupWithTools(
            name: 'Tools',
            tools: [
              _tool(id: 'a', toolId: 'alpha', isEnabled: false),
              _tool(id: 'z', toolId: 'zeta'),
            ],
          ),
        ]),
      ),
    ]);
    final _ = await tester.tap(find.byType(IconButton).last);
    final _ = await tester.pumpAndSettle();
    expect(
      tester.widget<ToolItemRow>(find.byType(ToolItemRow).first).tool.toolId,
      'alpha',
    );
    await tester.tap(find.byKey(const ValueKey('tools-sort')));
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('Enabled').last);
    final _ = await tester.pumpAndSettle();
    expect(
      tester.widget<ToolItemRow>(find.byType(ToolItemRow).first).tool.toolId,
      'zeta',
    );
  });

  testWidgets('filters tools by name or description', (tester) async {
    final groups = [
      _defaultGroup([
        _tool(toolId: 'search_files', description: 'Reads local files'),
        _tool(id: 't2', toolId: 'calendar', description: 'Plans events'),
      ]),
    ];

    await _pumpListApp(tester, [
      groupedToolsProvider(_workspaceId)
          .overrideWith(() => _DataNotifier(groups)),
    ]);

    await tester.enterText(find.byType(AuraInput), 'local files');
    await tester.pump();
    final _ = await tester.tap(find.byType(IconButton).last);
    final _ = await tester.pumpAndSettle();

    expect(find.byType(ToolItemRow), findsOneWidget);
    expect(find.text('calendar'), findsNothing);
  });

  testWidgets('group matches show all tools with original enablement', (
    tester,
  ) async {
    final groups = [
      _groupWithTools(
        tools: [
          _tool(id: 'enabled', toolId: 'alpha'),
          _tool(id: 'disabled', toolId: 'beta', isEnabled: false),
        ],
        name: 'Remote Files',
      ),
    ];

    await _pumpListApp(tester, [
      groupedToolsProvider(_workspaceId)
          .overrideWith(() => _DataNotifier(groups)),
    ]);

    await tester.enterText(find.byType(AuraInput), 'remote');
    await tester.pump();
    final _ = await tester.tap(find.byType(IconButton).last);
    final _ = await tester.pumpAndSettle();

    final rows = tester.widgetList<ToolItemRow>(find.byType(ToolItemRow));
    expect(rows, hasLength(2));
    expect(rows.map((row) => row.tool.isEnabled), [true, false]);
  });

  testWidgets('shows no-results state when no tools match', (tester) async {
    final groups = [
      _defaultGroup([_tool()]),
    ];

    await _pumpListApp(tester, [
      groupedToolsProvider(_workspaceId)
          .overrideWith(() => _DataNotifier(groups)),
    ]);

    await tester.enterText(find.byType(AuraInput), 'not-found');
    await tester.pump();

    expect(find.byIcon(Icons.search_off), findsOneWidget);
    expect(find.byType(ToolsGroupCard), findsNothing);
  });

  testWidgets('shows error widget on error', (tester) async {
    await _pumpListApp(tester, [
      groupedToolsProvider(_workspaceId).overrideWith(_ErrorNotifier.new),
    ]);
    final _ = await tester.pumpAndSettle();

    expect(find.byType(AppErrorWidget), findsOneWidget);
  });
}
