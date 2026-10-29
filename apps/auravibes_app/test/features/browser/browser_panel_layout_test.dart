import 'dart:async';

import 'package:auravibes_app/features/browser/models/browser_session_state.dart';
import 'package:auravibes_app/features/browser/models/sidebar_tool_result_tab.dart';
import 'package:auravibes_app/features/browser/providers/browser_session_notifier.dart';
import 'package:auravibes_app/features/browser/providers/browser_session_providers.dart';
import 'package:auravibes_app/features/browser/providers/sidebar_workspace_tab_count.dart';
import 'package:auravibes_app/features/browser/screens/browser_panel.dart';
import 'package:auravibes_app/features/chats/widgets/responsive_conversation_layout.dart';
import 'package:auravibes_app/features/workflows/models/workflow_definition.dart';
import 'package:auravibes_app/features/workflows/providers/workflow_providers.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/notifiers/workspace_open_view_notifier.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_tables_provider.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_app.dart';
import 'helpers/fake_browser_web_view_service.dart';

void main() {
  testWidgets('suspended sessions do not build webviews until resumed', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final runtime = FakeBrowserWebViewService();
    await tester.runAsync(() async {
      await tester.pumpWidget(
        TestableApp(
          child: const _SidebarHarness(),
          overrides: [
            browserSessionProvider(
              'workspace',
              'conversation',
            ).overrideWith(_SuspendedBrowserSessionNotifier.new),
            browserWebViewServiceProvider.overrideWithValue(runtime.service),
          ],
        ),
      );
    });
    await tester.pump();
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('open-sidebar')));
    await tester.pump();
    final _ = await tester.pumpAndSettle();

    expect(runtime.buildViewCount, 0);
    expect(
      find.text(
        'Browser suspended to free memory. Resume to reload these tabs.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Resume browser'));
    await tester.pump();
    final _ = await tester.pumpAndSettle();

    expect(runtime.buildViewCount, greaterThan(0));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('opens first browser tab only after the user requests it', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final runtime = FakeBrowserWebViewService();
    await tester.runAsync(() async {
      await tester.pumpWidget(
        TestableApp(
          child: const _SidebarHarness(),
          overrides: [
            browserSessionProvider(
              'workspace',
              'conversation',
            ).overrideWith(_TestBrowserSessionNotifier.new),
            browserWebViewServiceProvider.overrideWithValue(runtime.service),
          ],
        ),
      );
    });
    await tester.pump();
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('open-sidebar')));
    await tester.pump();
    final _ = await tester.pumpAndSettle();

    expect(runtime.buildViewCount, 0);
    expect(
      find.bySemanticsIdentifier('browser_new_tab_button'),
      findsOneWidget,
    );
    expect(find.bySemanticsIdentifier('browser_address_input'), findsNothing);

    await tester.tap(find.bySemanticsIdentifier('browser_new_tab_button'));
    await tester.pump();
    expect(
      find.bySemanticsIdentifier('sidebar_open_directory'),
      findsOneWidget,
    );
    expect(find.bySemanticsIdentifier('sidebar_open_browser'), findsOneWidget);
    await tester.tap(find.bySemanticsIdentifier('sidebar_open_browser'));
    await tester.pump();
    final _ = await tester.pumpAndSettle();

    expect(find.bySemanticsIdentifier('browser_address_input'), findsOneWidget);
    expect(runtime.buildViewCount, greaterThan(0));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('table tabs show authorized names after loading', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final runtime = FakeBrowserWebViewService();
    final table = Completer<WorkspaceTable>();
    await tester.runAsync(() async {
      await tester.pumpWidget(
        TestableApp(
          child: const _SidebarHarness(),
          overrides: [
            browserSessionProvider(
              'workspace',
              'conversation',
            ).overrideWith(_TestBrowserSessionNotifier.new),
            browserWebViewServiceProvider.overrideWithValue(runtime.service),
            workspaceTableProvider(
              'workspace',
              'first',
            ).overrideWith((ref) => table.future),
          ],
        ),
      );
    });
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('open-sidebar')));
    final _ = await tester.pumpAndSettle();
    final ref = ProviderScope.containerOf(
      tester.element(find.byType(BrowserPanel)),
    );
    ref
        .read(workspaceOpenViewProvider('workspace', 'conversation').notifier)
        .openItem('first', 'table');
    await tester.pump();
    await tester.pump();
    expect(find.bySemanticsIdentifier('sidebar_open_directory'), findsNothing);
    expect(find.bySemanticsIdentifier('sidebar_open_browser'), findsNothing);
    final chip = find.bySemanticsIdentifier('sidebar_workspace_table:first');
    expect(
      find.descendant(of: chip, matching: find.text('Table')),
      findsOneWidget,
    );
    table.complete(
      const WorkspaceTable(
        id: 'first',
        name: 'Projects',
        labelColumnId: 'label',
        columns: [],
        revision: 1,
        schemaRevision: 1,
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(
      find.descendant(of: chip, matching: find.text('Projects')),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    final _ = await tester.pumpAndSettle();
  });

  testWidgets('workflow tabs show read-only state and close cleanly', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final runtime = FakeBrowserWebViewService();
    final now = DateTime.utc(2026, 10, 29);
    final workflow = WorkspaceWorkflow.create(
      id: 'flow',
      workspaceId: 'workspace',
      name: 'Shared workflow',
      description: 'Read-only item',
      revision: 2,
      createdAt: now,
      updatedAt: now,
      canManage: false,
    );
    await tester.runAsync(() async {
      await tester.pumpWidget(
        TestableApp(
          child: const _SidebarHarness(),
          overrides: [
            browserSessionProvider(
              'workspace',
              'conversation',
            ).overrideWith(_TestBrowserSessionNotifier.new),
            browserWebViewServiceProvider.overrideWithValue(runtime.service),
            workflowProvider(
              'workspace',
              'flow',
            ).overrideWith((ref) async => workflow),
            workflowsProvider('workspace')
                .overrideWith((ref) => Stream.value([workflow])),
          ],
        ),
      );
    });
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('open-sidebar')));
    final _ = await tester.pumpAndSettle();
    final ref = ProviderScope.containerOf(
      tester.element(find.byType(BrowserPanel)),
    );
    ref
        .read(workspaceOpenViewProvider('workspace', 'conversation').notifier)
        .openItem('flow', 'workflow');
    final _ = await tester.pumpAndSettle();

    final chip = find.bySemanticsIdentifier('sidebar_workspace_workflow:flow');
    expect(chip, findsOneWidget);
    expect(
      find.descendant(of: chip, matching: find.text('Shared workflow')),
      findsOneWidget,
    );
    expect(
      find.text(
        'Read only: only workspace owners and admins can edit this workflow.',
      ),
      findsOneWidget,
    );
    expect(find.text('Add step'), findsNothing);
    final metadataFields = tester.widgetList<TextField>(find.byType(TextField));
    expect(metadataFields, hasLength(2));
    expect(metadataFields.every((field) => field.readOnly), isTrue);

    tester.view.physicalSize = const Size(466, 678);
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(1280, 800);
    await tester.pumpAndSettle();

    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is AuraIconButton &&
            widget.identifier == 'sidebar_close_workspace_workflow:flow',
      ),
    );
    final _ = await tester.pumpAndSettle();
    expect(chip, findsNothing);
    expect(find.text('Sidebar closed'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('workflow tab close confirms unsaved metadata edits', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final runtime = FakeBrowserWebViewService();
    final now = DateTime.utc(2026, 10, 29);
    final workflow = WorkspaceWorkflow.create(
      id: 'flow',
      workspaceId: 'workspace',
      name: 'Editable workflow',
      description: 'Draft',
      createdAt: now,
      updatedAt: now,
    );
    await tester.runAsync(() async {
      await tester.pumpWidget(
        TestableApp(
          child: const _SidebarHarness(),
          overrides: [
            browserSessionProvider(
              'workspace',
              'conversation',
            ).overrideWith(_TestBrowserSessionNotifier.new),
            browserWebViewServiceProvider.overrideWithValue(runtime.service),
            workflowProvider(
              'workspace',
              'flow',
            ).overrideWith((ref) async => workflow),
            workflowsProvider('workspace')
                .overrideWith((ref) => Stream.value([workflow])),
          ],
        ),
      );
    });
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('open-sidebar')));
    final _ = await tester.pumpAndSettle();
    final ref = ProviderScope.containerOf(
      tester.element(find.byType(BrowserPanel)),
    );
    ref
        .read(workspaceOpenViewProvider('workspace', 'conversation').notifier)
        .openItem('flow', 'workflow');
    final _ = await tester.pumpAndSettle();

    final chip = find.bySemanticsIdentifier('sidebar_workspace_workflow:flow');
    final close = find.byWidgetPredicate(
      (widget) =>
          widget is AuraIconButton &&
          widget.identifier == 'sidebar_close_workspace_workflow:flow',
    );
    await tester.enterText(find.byType(TextField).first, 'Unsaved workflow');
    await tester.pump();
    await tester.tap(close);
    final _ = await tester.pumpAndSettle();

    expect(find.text('Keep editing'), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    final _ = await tester.pumpAndSettle();
    expect(chip, findsOneWidget);

    await tester.tap(close);
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('Discard changes'));
    final _ = await tester.pumpAndSettle();
    expect(chip, findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('workspace requests open separate tabs and can be closed', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final runtime = FakeBrowserWebViewService();
    await tester.runAsync(() async {
      await tester.pumpWidget(
        TestableApp(
          child: const _SidebarHarness(),
          overrides: [
            browserSessionProvider(
              'workspace',
              'conversation',
            ).overrideWith(_TestBrowserSessionNotifier.new),
            browserWebViewServiceProvider.overrideWithValue(runtime.service),
          ],
        ),
      );
    });
    final _ = await tester.pumpAndSettle();
    final _ = await tester.tap(find.byKey(const ValueKey('open-sidebar')));
    final _ = await tester.pumpAndSettle();
    final ref = ProviderScope.containerOf(
      tester.element(find.byType(BrowserPanel)),
    );
    final notifier = ref.read(
      workspaceOpenViewProvider('workspace', 'conversation').notifier,
    );
    void openFile(String id) => notifier.openItem(id, 'file');
    openFile('first');
    await tester.pump();
    await tester.pump();
    expect(find.text('AI context'), findsNothing);
    expect(find.text('Share with AI'), findsNothing);
    expect(find.text('Inspect shared context'), findsNothing);
    openFile('second');
    await tester.pump();
    await tester.pump();
    expect(
      find.bySemanticsIdentifier('sidebar_workspace_file:first'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsIdentifier('sidebar_workspace_file:second'),
      findsOneWidget,
    );
    final count = ref.read(
      sidebarWorkspaceTabCountProvider((
        workspaceId: 'workspace',
        conversationId: 'conversation',
      )),
    );
    await tester.pump();
    expect(count.value, 2);
    await tester.ensureVisible(
      find.bySemanticsIdentifier('sidebar_workspace_file:second'),
    );
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is AuraIconButton &&
            widget.identifier == 'sidebar_close_workspace_file:second',
      ),
    );
    await tester.pump();
    expect(
      find.bySemanticsIdentifier('sidebar_workspace_file:first'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsIdentifier('sidebar_workspace_file:second'),
      findsNothing,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is AuraTile &&
            widget.identifier == 'sidebar_workspace_file:first' &&
            widget.variant == AuraTileVariant.selected,
      ),
      findsOneWidget,
    );
    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is AuraIconButton &&
            widget.identifier == 'sidebar_close_workspace_file:first',
      ),
    );
    await tester.pump();
    expect(find.text('Sidebar closed'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

class const _SidebarHarness() extends StatefulWidget {
  @override
  State<_SidebarHarness> createState() => _SidebarHarnessState();
}

class _SidebarHarnessState extends State<_SidebarHarness> {
  var _sidePanelVisible = false;
  var _sidePanelMounted = false;
  var _sidePanelWidthPercent = 0.4;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        TextButton(
          key: const ValueKey('open-sidebar'),
          onPressed: _openSidebar,
          child: const Text('Open sidebar'),
        ),
        if (!_sidePanelVisible) const Text('Sidebar closed'),
        Expanded(
          child: ResponsiveConversationLayout(
            mainContent: ListView(children: const [Text('chat message')]),
            sidePanel: .new(
              visible: _sidePanelVisible,
              mounted: _sidePanelMounted,
              widthPercent: _sidePanelWidthPercent,
              onWidthChanged: (value) =>
                  setState(() => _sidePanelWidthPercent = value),
              onClose: () => setState(() => _sidePanelVisible = false),
              builder: () => BrowserPanel(
                workspaceId: 'workspace',
                conversationId: 'conversation',
                toolResultTabs: const <SidebarToolResultTab>[],
                selectedToolResultTabId: null,
                onSelectToolResultTab: (_) {
                  expect(true, isTrue);
                },
                onCloseToolResultTab: (id) => expect(id, isNotEmpty),
                onCloseSidebar: () => setState(() => _sidePanelVisible = false),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  void _openSidebar() {
    setState(() {
      _sidePanelMounted = true;
      _sidePanelVisible = true;
    });
  }
}

class _TestBrowserSessionNotifier extends BrowserSessionNotifier {
  @override
  Future<BrowserSessionState> build(
    String workspaceId,
    String conversationId,
  ) async => const BrowserSessionState(tabs: [], activeTabId: '');
}

class _SuspendedBrowserSessionNotifier extends BrowserSessionNotifier {
  @override
  Future<BrowserSessionState> build(
    String workspaceId,
    String conversationId,
  ) async => const BrowserSessionState(
    tabs: [BrowserTab(id: 'tab-1', url: 'https://example.com')],
    activeTabId: 'tab-1',
    isSuspended: true,
  );
}
