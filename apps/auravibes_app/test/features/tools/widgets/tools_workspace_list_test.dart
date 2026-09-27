// ignore_for_file: scoped_providers_should_specify_dependencies
// Required: Widget tests override scoped providers directly.

import 'dart:async';

import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/features/tools/models/tools_group_with_tools.dart';
import 'package:auravibes_app/features/tools/notifiers/grouped_tools_notifier.dart';
import 'package:auravibes_app/features/tools/providers/workspace_tools_notifier.dart';
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
  String id = 'group-1',
  bool isEnabled = true,
  String? mcpServerId,
}) {
  return ToolsGroupWithTools(
    group: .new(
      id: id,
      workspaceId: _workspaceId,
      name: name,
      isEnabled: isEnabled,
      permissions: .ask,
      createdAt: .new(2026),
      updatedAt: .new(2026),
      mcpServerId: mcpServerId,
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
  final deletedGroupIds = <String>[];
  final deleteInvalidations = <bool>[];

  @override
  Future<List<ToolsGroupWithTools>> build(String workspaceId) async => groups;

  @override
  Future<bool> deleteMcpGroup(String groupId, {bool invalidate = true}) async {
    deletedGroupIds.add(groupId);
    deleteInvalidations.add(invalidate);

    return true;
  }
}

class _ErrorNotifier extends GroupedToolsNotifier {
  @override
  Future<List<ToolsGroupWithTools>> build(String workspaceId) async {
    throw Exception('test error');
  }
}

class _WorkspaceToolsDataNotifier extends WorkspaceToolsNotifier {
  new(this.tools);

  final List<WorkspaceToolEntity> tools;
  final removedIds = <String>[];

  @override
  Future<List<WorkspaceToolEntity>> build(String workspaceId) async => tools;

  @override
  Future<bool> removeToolById(String id) async {
    removedIds.add(id);

    return true;
  }
}

class const _ListApp({required final List<Object> overrides})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TestableApp(
    child: AuraThemeScope(
      theme: .light,
      child: Portal(
        child: Theme(
          data: .new(),
          child: const Scaffold(
            body: ToolsWorkspaceListWidget(workspaceId: _workspaceId),
          ),
        ),
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
    final _ = await tester.tap(find.byType(AuraIconButton).last);
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
    final _ = await tester.tap(find.byType(AuraIconButton).last);
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

  testWidgets('sorts tool groups by name and enabled status', (tester) async {
    final groups = [
      _groupWithTools(
        tools: [_tool(id: 'zeta-tool')],
        name: 'Zeta Group',
        id: 'zeta-group',
      ),
      _groupWithTools(
        tools: [
          _tool(id: 'zeta-tool', toolId: 'zeta_tool'),
          _tool(id: 'alpha-tool', toolId: 'alpha_tool', isEnabled: false),
        ],
        name: 'Alpha Group',
        id: 'alpha-group',
        isEnabled: false,
      ),
    ];

    await _pumpListApp(tester, [
      groupedToolsProvider(_workspaceId)
          .overrideWith(() => _DataNotifier(groups)),
    ]);

    expect(
      tester.getTopLeft(find.text('Alpha Group')).dy,
      lessThan(tester.getTopLeft(find.text('Zeta Group')).dy),
    );
    final alphaGroupCard = find.ancestor(
      of: find.text('Alpha Group'),
      matching: find.byType(ToolsGroupCard),
    );
    await tester.tap(
      find.descendant(
        of: alphaGroupCard,
        matching: find.byType(AuraIconButton),
      ),
    );
    final _ = await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('alpha_tool')).dy,
      lessThan(tester.getTopLeft(find.text('zeta_tool')).dy),
    );

    await tester.tap(find.byKey(const ValueKey('tools-sort')));
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('Enabled first').last);
    final _ = await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.text('Zeta Group')).dy,
      lessThan(tester.getTopLeft(find.text('Alpha Group')).dy),
    );
    expect(
      tester.getTopLeft(find.text('zeta_tool')).dy,
      lessThan(tester.getTopLeft(find.text('alpha_tool')).dy),
    );
  });

  testWidgets('selects filtered removable tools and confirms bulk deletion', (
    tester,
  ) async {
    final alpha = _tool(id: 'alpha-id', toolId: 'alpha_tool');
    final zeta = _tool(id: 'zeta-id', toolId: 'zeta_tool');
    final workspaceToolsNotifier = _WorkspaceToolsDataNotifier([alpha, zeta]);
    final groups = [
      _defaultGroup([zeta, alpha]),
    ];

    await _pumpListApp(tester, [
      groupedToolsProvider(_workspaceId)
          .overrideWith(() => _DataNotifier(groups)),
      workspaceToolsProvider(_workspaceId)
          .overrideWith(() => workspaceToolsNotifier),
    ]);

    await tester.enterText(find.byType(AuraInput), 'alpha');
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tools-select-all')));
    final _ = await tester.pumpAndSettle();
    await tester.enterText(find.byType(AuraInput), '');
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.byType(AuraIconButton).last);
    final _ = await tester.pumpAndSettle();

    expect(
      tester
          .widget<AuraCheckbox>(
            find.byKey(const ValueKey('tool-selection-alpha-id')),
          )
          .value,
      isTrue,
    );
    expect(
      tester
          .widget<AuraCheckbox>(
            find.byKey(const ValueKey('tool-selection-zeta-id')),
          )
          .value,
      isFalse,
    );

    await tester.tap(find.byKey(const ValueKey('tools-delete-selected')));
    final _ = await tester.pumpAndSettle();
    expect(find.text('Delete selected tools?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    final _ = await tester.pumpAndSettle();
    expect(workspaceToolsNotifier.removedIds, isEmpty);

    await tester.tap(find.byKey(const ValueKey('tools-delete-selected')));
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    final _ = await tester.pumpAndSettle();

    expect(workspaceToolsNotifier.removedIds, [alpha.id]);
  });

  testWidgets('bulk deletes each MCP group once without early invalidation', (
    tester,
  ) async {
    final groups = [
      _groupWithTools(
        tools: [_tool(id: 'mcp-tool-1')],
        id: 'mcp-group-1',
        mcpServerId: 'mcp-server-1',
      ),
      _groupWithTools(
        tools: [_tool(id: 'mcp-tool-2')],
        id: 'mcp-group-2',
        mcpServerId: 'mcp-server-2',
      ),
    ];
    final groupedToolsNotifier = _DataNotifier(groups);

    await _pumpListApp(tester, [
      groupedToolsProvider(_workspaceId)
          .overrideWith(() => groupedToolsNotifier),
    ]);

    await tester.tap(find.byKey(const ValueKey('tools-select-all')));
    final _ = await tester.pumpAndSettle();

    for (final groupId in ['mcp-group-1', 'mcp-group-2']) {
      expect(
        tester
            .widget<AuraCheckbox>(
              find.byKey(ValueKey('tools-group-selection-$groupId')),
            )
            .value,
        isTrue,
      );
    }

    await tester.tap(find.byKey(const ValueKey('tools-delete-selected')));
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    final _ = await tester.pumpAndSettle();

    expect(groupedToolsNotifier.deletedGroupIds, [
      'mcp-group-1',
      'mcp-group-2',
    ]);
    expect(groupedToolsNotifier.deleteInvalidations, [false, false]);
  });
}
