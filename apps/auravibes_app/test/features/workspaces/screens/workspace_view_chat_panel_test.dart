import 'package:auravibes_app/features/browser/models/browser_session_state.dart';
import 'package:auravibes_app/features/browser/providers/browser_session_notifier.dart';
import 'package:auravibes_app/features/browser/providers/browser_session_providers.dart';
import 'package:auravibes_app/features/browser/screens/browser_panel.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_view.dart';
import 'package:auravibes_app/features/workspaces/notifiers/workspace_open_view_notifier.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_views_provider.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_view_chat_layout.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/test_app.dart';
import '../../browser/helpers/fake_browser_web_view_service.dart';

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });
  testWidgets(
    'saved View uses one responsive chat panel and preserves draft on return',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final data = _data();
      await tester.runAsync(() async {
        await tester.pumpWidget(
          TestableApp(
            child: const _Harness(),
            overrides: [
              browserSessionProvider(
                'one',
                'chat',
              ).overrideWith(_BrowserSession.new),
              browserWebViewServiceProvider.overrideWithValue(
                FakeBrowserWebViewService().service,
              ),
              workspaceViewDataProvider(
                'one',
                'view',
              ).overrideWith((ref) async => data),
            ],
            workspaceId: 'one',
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));
      });
      final _ = await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Keep my chat draft');
      await tester.tap(find.text('Open view'));
      final _ = await tester.pumpAndSettle();
      expect(find.text('Saved surface'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      tester.view.physicalSize = const Size(400, 900);
      final _ = await tester.pumpAndSettle();
      expect(find.text('Saved surface'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      await tester.tap(
        find.byWidgetPredicate(
          (widget) =>
              widget is AuraIconButton &&
              widget.identifier == 'sidebar_close_workspace_view:view',
        ),
      );
      final _ = await tester.pumpAndSettle();
      expect(find.text('Saved surface'), findsNothing);
      await tester.tap(find.text('Close panel'));
      final _ = await tester.pumpAndSettle();
      expect(find.text('Keep my chat draft'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}

WorkspaceViewData _data() => .new(
  view: .new(
    id: 'view',
    name: 'Overview',
    tableId: 'table',
    bindings: const {'title': 'label'},
    columnTypes: const {'label': 'text'},
    definition: .fromJson({
      'version': 1,
      'components': [
        {'id': 'root', 'component': 'Text', 'text': 'Saved surface'},
      ],
    }),
    revision: 1,
  ),
  table: const WorkspaceTable(
    id: 'table',
    name: 'Items',
    labelColumnId: 'label',
    columns: [WorkspaceColumn(id: 'label', name: 'Title')],
    revision: 1,
    schemaRevision: 1,
    canManage: false,
  ),
  records: const [
    WorkspaceRecord(
      id: 'record',
      tableId: 'table',
      values: {'label': 'Value'},
      revision: 1,
    ),
  ],
  needsRepair: false,
);

class const _Harness() extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController();

    return Scaffold(
      body: Column(
        children: [
          AuraButton(
            onPressed: () => ref
                .read(workspaceOpenViewProvider('one', 'chat').notifier)
                .open('view'),
            child: const Text('Open view'),
          ),
          TextButton(
            onPressed: () => ref
                .read(workspaceOpenViewProvider('one', 'chat').notifier)
                .close(),
            child: const Text('Close panel'),
          ),
          Expanded(
            child: WorkspaceViewChatLayout(
              workspaceId: 'one',
              conversationId: 'chat',
              mainContent: TextField(controller: controller),
              fallbackSidePanel: .new(
                visible: false,
                mounted: false,
                widthPercent: 0.4,
                onWidthChanged: (_) => fail('No browser resize expected'),
                onClose: () {
                  return;
                },
                builder: () => BrowserPanel(
                  workspaceId: 'one',
                  conversationId: 'chat',
                  toolResultTabs: const [],
                  selectedToolResultTabId: null,
                  onSelectToolResultTab: (_) {
                    return;
                  },
                  onCloseToolResultTab: (_) {
                    return;
                  },
                  onCloseSidebar: () {
                    return;
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrowserSession extends BrowserSessionNotifier {
  @override
  Future<BrowserSessionState> build(
    String workspaceId,
    String conversationId,
  ) async => BrowserSessionState.initial();
}
