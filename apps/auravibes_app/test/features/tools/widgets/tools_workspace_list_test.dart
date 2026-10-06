// ignore_for_file: scoped_providers_should_specify_dependencies
// Required: Widget tests override scoped providers directly.

import 'dart:async';

import 'package:auravibes_app/data/database/drift/enums/permission_access.dart';
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/features/tools/models/tools_group_with_tools.dart';
import 'package:auravibes_app/features/tools/notifiers/grouped_tools_notifier.dart';
import 'package:auravibes_app/features/tools/providers/workspace_tools_notifier.dart';
import 'package:auravibes_app/features/tools/widgets/tool_item_row.dart';
import 'package:auravibes_app/features/tools/widgets/tool_permission_selector.dart';
import 'package:auravibes_app/features/tools/widgets/tools_group_card.dart';
import 'package:auravibes_app/features/tools/widgets/tools_workspace_list_widget.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    as sdk_localizations;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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

class _ConnectionSnapshot {
  String name = 'Same service';
  PermissionAccess groupPermission = .granted;
  ToolPermissionMode toolPermission = .alwaysAllow;
  int groupLoads = 0;
  int toolLoads = 0;
  Future<void>? refresh;
}

class _ConnectionToolsNotifier(final _ConnectionSnapshot snapshot)
    extends WorkspaceToolsNotifier {
  @override
  Future<List<WorkspaceToolEntity>> build(String workspaceId) async {
    snapshot.toolLoads++;
    await snapshot.refresh;

    return [
      _tool(toolId: 'read_files')
          .copyWith(permissionMode: snapshot.toolPermission),
    ];
  }
}

class _ConnectionGroupsNotifier(final _ConnectionSnapshot snapshot)
    extends GroupedToolsNotifier {
  @override
  Future<List<ToolsGroupWithTools>> build(String workspaceId) async {
    snapshot.groupLoads++;
    final tools = await ref.watch(workspaceToolsProvider(workspaceId).future);
    final source = _groupWithTools(
      tools: tools,
      name: snapshot.name,
      id: 'group-not-server',
      mcpServerId: 'actual-server',
    );

    return [
      source.copyWith(
        group: source.group?.copyWith(permissions: snapshot.groupPermission),
      ),
      _groupWithTools(
        tools: [_tool(id: 'other', toolId: 'calendar')],
        name: 'Same service',
        id: 'other-group',
        mcpServerId: 'other-server',
      ),
      _defaultGroup([_tool(id: 'native', toolId: 'native_tool')]),
    ];
  }
}

class _RetryNotifier(final bool Function() shouldFail)
    extends GroupedToolsNotifier {
  @override
  Future<List<ToolsGroupWithTools>> build(String workspaceId) async {
    if (shouldFail()) throw Exception('test error');

    return [
      _defaultGroup([_tool()]),
    ];
  }
}

class _WorkspaceToolsDataNotifier extends WorkspaceToolsNotifier {
  new(
    this.tools, {
    this.failRemoval = false,
    Set<String> failedRemovalIds = const {},
    Set<String>? failedIds,
    List<String>? removedIds,
  }) : failedIds = failedIds ?? Set.of(failedRemovalIds),
       removedIds = removedIds ?? [];

  final List<WorkspaceToolEntity> tools;
  final bool failRemoval;
  final Set<String> failedIds;
  final List<String> removedIds;

  @override
  Future<List<WorkspaceToolEntity>> build(String workspaceId) async => tools;

  @override
  Future<bool> removeToolById(String id) async {
    removedIds.add(id);

    return !failRemoval && !failedIds.contains(id);
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
  testWidgets('restores tool query and sort after replacing its list', (
    tester,
  ) async {
    final visible = ValueNotifier(true);
    addTearDown(visible.dispose);
    await tester.runAsync(
      () => tester.pumpWidget(
        TestableApp(
          child: Portal(
            child: Scaffold(
              body: ValueListenableBuilder<bool>(
                valueListenable: visible,
                builder: (_, show, _) => show
                    ? const ToolsWorkspaceListWidget(workspaceId: _workspaceId)
                    : const SizedBox.shrink(),
              ),
            ),
          ),
          overrides: [
            groupedToolsProvider(_workspaceId).overrideWith(
              () => _DataNotifier([
                _groupWithTools(tools: [_tool()], name: 'Files'),
                _groupWithTools(
                  tools: [_tool(id: 'calendar-tool')],
                  name: 'Calendar',
                  id: 'calendar',
                ),
              ]),
            ),
          ],
          workspaceId: _workspaceId,
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), 'Files');
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tools-sort')));
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('Enabled first').last);
    final _ = await tester.pumpAndSettle();
    visible.value = false;
    final _ = await tester.pumpAndSettle();
    visible.value = true;
    final _ = await tester.pumpAndSettle();
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      'Files',
    );
    expect(find.text('Calendar'), findsNothing);
    expect(find.text('Enabled first'), findsOneWidget);
  });

  testWidgets('opens the exact MCP server and refreshes only after Save', (
    tester,
  ) async {
    final snapshot = _ConnectionSnapshot();
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/tools',
          builder: (_, _) => const Scaffold(
            body: ToolsWorkspaceListWidget(workspaceId: _workspaceId),
          ),
        ),
        GoRoute(
          path:
              '/workspaces/:workspaceId/more/service-connections/:connectionId',
          builder: (_, state) =>
              Text('Source ${state.pathParameters['connectionId']}'),
        ),
      ],
      initialLocation: '/tools',
    );
    addTearDown(router.dispose);
    await tester.runAsync(
      () => tester.pumpWidget(
        TestableApp(
          child: Portal(
            child: Builder(
              builder: (context) => MaterialApp.router(
                routerConfig: router,
                locale: context.locale,
                localizationsDelegates: [
                  ...GlobalMaterialLocalizations.delegates,
                  sdk_localizations.GlobalMaterialLocalizations.delegate,
                  ...context.localizationDelegates,
                ],
                supportedLocales: context.supportedLocales,
              ),
            ),
          ),
          overrides: [
            groupedToolsProvider(_workspaceId)
                .overrideWith(() => _ConnectionGroupsNotifier(snapshot)),
            workspaceToolsProvider(_workspaceId)
                .overrideWith(() => _ConnectionToolsNotifier(snapshot)),
          ],
          workspaceId: _workspaceId,
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tools-sort')));
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('Enabled first').last);
    final _ = await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), 'read_files');
    final _ = await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(ToolsGroupCard).first,
        matching: find.byIcon(Icons.keyboard_arrow_down),
      ),
    );
    final _ = await tester.pumpAndSettle();
    expect(
      tester.widget<ToolItemRow>(find.byType(ToolItemRow)).tool.toolId,
      'read_files',
    );
    await tester.tap(
      find.descendant(
        of: find.byType(ToolItemRow),
        matching: find.byIcon(Icons.keyboard_arrow_down),
      ),
    );
    final _ = await tester.pumpAndSettle();
    expect(
      tester
          .widget<ToolPermissionSelector>(find.byType(ToolPermissionSelector))
          .value,
      ToolPermissionMode.alwaysAllow,
    );
    final loadsBeforeBack = (
      groups: snapshot.groupLoads,
      tools: snapshot.toolLoads,
    );
    await tester.tap(
      find.byKey(const ValueKey('tools-open-connection-actual-server')),
    );
    final _ = await tester.pumpAndSettle();
    expect(find.text('Source actual-server'), findsOneWidget);
    router.pop();
    final _ = await tester.pumpAndSettle();
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      'read_files',
    );
    expect(
      tester.widget<ToolItemRow>(find.byType(ToolItemRow)).tool.toolId,
      'read_files',
    );
    expect(
      find.byKey(const ValueKey('tools-open-connection-other-server')),
      findsNothing,
    );
    final loadsAfterBack = (
      groups: snapshot.groupLoads,
      tools: snapshot.toolLoads,
    );
    expect(loadsAfterBack, loadsBeforeBack);
    expect(find.text('Enabled first'), findsOneWidget);
    final refresh = Completer<void>();
    snapshot
      ..name = 'Renamed service'
      ..groupPermission = .ask
      ..toolPermission = .alwaysAsk
      ..refresh = refresh.future;
    await tester.tap(
      find.byKey(const ValueKey('tools-open-connection-actual-server')),
    );
    final _ = await tester.pumpAndSettle();
    router.pop(true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(ToolItemRow), findsOneWidget);
    expect(find.text('Same service'), findsOneWidget);
    refresh.complete();
    final _ = await tester.pumpAndSettle();
    expect(find.text('Renamed service'), findsOneWidget);
    expect(snapshot.groupLoads, greaterThan(loadsBeforeBack.groups));
    expect(snapshot.toolLoads, greaterThan(loadsBeforeBack.tools));
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      'read_files',
    );
    expect(find.text('Enabled first'), findsOneWidget);
    expect(
      tester
          .widget<ToolsGroupCard>(find.byType(ToolsGroupCard))
          .groupWithTools
          .group
          ?.permissions,
      PermissionAccess.ask,
    );
    expect(
      tester
          .widget<ToolPermissionSelector>(find.byType(ToolPermissionSelector))
          .value,
      ToolPermissionMode.alwaysAsk,
    );
  });

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

  testWidgets('aligns disabled select-all with the sort field', (tester) async {
    final groups = <ToolsGroupWithTools>[];

    await _pumpListApp(tester, [
      groupedToolsProvider(_workspaceId)
          .overrideWith(() => _DataNotifier(groups)),
    ]);

    final selectAll = find.byKey(const ValueKey('tools-select-all'));
    expect(tester.widget<AuraButton>(selectAll).disabled, isTrue);
    expect(
      tester.getRect(selectAll).bottom,
      tester.getRect(find.byKey(const ValueKey('tools-sort'))).bottom,
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

  testWidgets('retries a failed tool load without exposing the error', (
    tester,
  ) async {
    var fail = true;
    await _pumpListApp(tester, [
      groupedToolsProvider(_workspaceId)
          .overrideWith(() => _RetryNotifier(() => fail)),
    ]);
    final _ = await tester.pumpAndSettle();

    expect(find.textContaining('test error'), findsNothing);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.byType(ToolsGroupCard), findsNothing);
    fail = false;
    await tester.tap(find.text('Retry'));
    final _ = await tester.pumpAndSettle();

    expect(find.byType(ToolsGroupCard), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
    expect(tester.takeException(), isNull);
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

  testWidgets('shows hidden tool selections in row and confirmation', (
    tester,
  ) async {
    final tools = [
      _tool(id: 'alpha-id', toolId: 'alpha_tool'),
      _tool(id: 'beta-id', toolId: 'beta_tool'),
    ];
    await _pumpListApp(tester, [
      groupedToolsProvider(_workspaceId)
          .overrideWith(() => _DataNotifier([_defaultGroup(tools)])),
    ]);

    await tester.tap(find.byKey(const ValueKey('tools-select-all')));
    final _ = await tester.pumpAndSettle();
    await tester.enterText(find.byType(AuraInput), 'alpha');
    final _ = await tester.pumpAndSettle();
    expect(find.textContaining('2 selected'), findsOneWidget);
    expect(find.textContaining('1 hidden by filters'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('tools-delete-selected')));
    final _ = await tester.pumpAndSettle();
    expect(find.textContaining('2 selected'), findsWidgets);
    expect(find.textContaining('1 hidden by filters'), findsWidgets);
    await tester.tap(find.text('Cancel'));
    final _ = await tester.pumpAndSettle();

    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is AuraIconButton && widget.tooltip == 'Clear selection',
      ),
    );
    final _ = await tester.pumpAndSettle();
    expect(find.textContaining('selected'), findsNothing);
    await tester.enterText(find.byType(AuraInput), '');
    final _ = await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('tools-delete-selected')), findsNothing);
  });

  testWidgets('shows and retries only failed tool removals', (tester) async {
    final tools = [
      _tool(id: 'success', toolId: 'success_tool'),
      _tool(id: 'fail-1', toolId: 'fail_one'),
      _tool(id: 'fail-2', toolId: 'fail_two'),
      _tool(id: 'fail-3', toolId: 'fail_three'),
    ];
    final notifier = _WorkspaceToolsDataNotifier(
      tools,
      failedRemovalIds: const {'fail-1', 'fail-2', 'fail-3'},
    );
    await _pumpListApp(tester, [
      groupedToolsProvider(_workspaceId)
          .overrideWith(() => _DataNotifier([_defaultGroup(tools)])),
      workspaceToolsProvider(_workspaceId).overrideWith(
        () => _WorkspaceToolsDataNotifier(
          tools,
          failRemoval: notifier.failRemoval,
          failedIds: notifier.failedIds,
          removedIds: notifier.removedIds,
        ),
      ),
    ]);

    await tester.tap(find.byKey(const ValueKey('tools-select-all')));
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tools-delete-selected')));
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    final _ = await tester.pumpAndSettle();

    final failureDialog = find.byType(AlertDialog);
    expect(
      find.descendant(
        of: failureDialog,
        matching: find.text('Some items could not be deleted'),
      ),
      findsOneWidget,
    );
    expect(find.text('Retry failed'), findsOneWidget);
    for (final name in ['Fail One', 'Fail Two', 'Fail Three']) {
      expect(
        find.descendant(of: failureDialog, matching: find.text(name)),
        findsOneWidget,
      );
    }
    expect(notifier.removedIds.toSet(), {
      'success',
      'fail-1',
      'fail-2',
      'fail-3',
    });

    final beforeFirstRetry = notifier.removedIds.length;
    notifier.failedIds
      ..clear()
      ..add('fail-2');
    await tester.tap(find.text('Retry failed'));
    final _ = await tester.pumpAndSettle();
    expect(notifier.removedIds.skip(beforeFirstRetry).toSet(), {
      'fail-1',
      'fail-2',
      'fail-3',
    });
    expect(
      find.descendant(of: failureDialog, matching: find.text('Fail Two')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: failureDialog, matching: find.text('Fail One')),
      findsNothing,
    );
    expect(
      find.descendant(of: failureDialog, matching: find.text('Fail Three')),
      findsNothing,
    );

    notifier.failedIds.clear();
    final beforeSecondRetry = notifier.removedIds.length;
    await tester.tap(find.text('Retry failed'));
    final _ = await tester.pumpAndSettle();
    expect(notifier.removedIds.skip(beforeSecondRetry).toList(), ['fail-2']);
    expect(find.byType(AlertDialog), findsNothing);
  });
}
