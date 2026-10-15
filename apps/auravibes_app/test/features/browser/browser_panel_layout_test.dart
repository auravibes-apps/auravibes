import 'package:auravibes_app/features/browser/models/browser_session_state.dart';
import 'package:auravibes_app/features/browser/models/sidebar_tool_result_tab.dart';
import 'package:auravibes_app/features/browser/providers/browser_session_notifier.dart';
import 'package:auravibes_app/features/browser/providers/browser_session_providers.dart';
import 'package:auravibes_app/features/browser/screens/browser_panel.dart';
import 'package:auravibes_app/features/chats/widgets/responsive_conversation_layout.dart';
import 'package:flutter_test/flutter_test.dart';
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
    final _ = await tester.pumpAndSettle();

    expect(find.bySemanticsIdentifier('browser_address_input'), findsOneWidget);
    expect(runtime.buildViewCount, greaterThan(0));
    expect(tester.takeException(), isNull);
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
                onSelectToolResultTab: (id) => expect(id, isNotNull),
                onCloseToolResultTab: (id) => expect(id, isNotEmpty),
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
