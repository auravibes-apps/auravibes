import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_view.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_views_provider.dart';
import 'package:auravibes_app/features/workspaces/screens/workspace_view_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/test_app.dart';

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });
  testWidgets('hidden views stop refresh and resume on activation', (
    tester,
  ) async {
    final active = ValueNotifier(true);
    addTearDown(active.dispose);
    var reads = 0;
    await tester.runAsync(() async {
      await tester.pumpWidget(
        TestableApp(
          workspaceId: 'one',
          child: ValueListenableBuilder<bool>(
            valueListenable: active,
            builder: (context, value, child) => TickerMode(
              enabled: value,
              child: WorkspaceViewScreen(
                workspaceId: 'one',
                viewId: 'view',
                onBack: () {},
              ),
            ),
          ),
          overrides: [
            workspaceViewDataProvider('one', 'view').overrideWith((ref) async {
              reads++;
              throw StateError('test');
            }),
          ],
        ),
      );
    });
    await tester.pump();
    await tester.pump();
    expect(reads, 1);
    active.value = false;
    await tester.pump();
    await tester.pump(const Duration(seconds: 11));
    expect(reads, 1);
    active.value = true;
    await tester.pump();
    await tester.pump();
    final readsBeforeRefresh = reads;
    await tester.pump(const Duration(seconds: 11));
    await tester.pump();
    expect(reads, readsBeforeRefresh + 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('hidden view preserves interactive form draft', (tester) async {
    final active = ValueNotifier(true);
    addTearDown(active.dispose);
    final connector = connectorDefinitions.firstWhere(
      (item) => item.identifier == 'synthetic',
    );
    final tool = connector.tools.firstWhere((item) => item.slug == 'search');
    final data = WorkspaceViewData(
      view: WorkspaceView(
        id: 'view',
        name: 'Form',
        tableId: 'table',
        bindings: const {},
        columnTypes: const {},
        definition: .fromJson({
          'version': 1,
          'components': [
            {
              'id': 'root',
              'component': 'Column',
              'children': ['query'],
            },
            {
              'id': 'query',
              'component': 'TextField',
              'label': 'Query',
              'value': {'path': '/answers/query'},
            },
          ],
        }, requiresUserAction: true),
        action: .fromJson({
          'version': 1,
          'type': 'connectorWrite',
          'toolId': connectorToolId(connector, tool),
          'revision': connectorToolRevision(connector, tool),
          'connectionId': 'service:synthetic-submit',
          'inputs': {'query': '/answers/query'},
        }),
        revision: 1,
      ),
      table: const WorkspaceTable(
        id: 'table',
        name: 'Items',
        labelColumnId: 'label',
        columns: [],
        revision: 1,
        schemaRevision: 1,
        canManage: false,
      ),
      records: const [
        WorkspaceRecord(id: 'row', tableId: 'table', values: {}, revision: 1),
      ],
      needsRepair: false,
    );
    await tester.runAsync(() async {
      await tester.pumpWidget(
        TestableApp(
          workspaceId: 'one',
          child: ValueListenableBuilder<bool>(
            valueListenable: active,
            builder: (context, value, child) => TickerMode(
              enabled: value,
              child: WorkspaceViewScreen(
                workspaceId: 'one',
                viewId: 'view',
                onBack: () {},
              ),
            ),
          ),
          overrides: [
            workspaceViewDataProvider('one', 'view').overrideWith(
              (ref) async => WorkspaceViewData(
                view: data.view,
                table: data.table,
                records: data.records,
                needsRepair: data.needsRepair,
              ),
            ),
          ],
        ),
      );
    });
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), 'draft stays');
    active.value = false;
    await tester.pump();
    await tester.pump(const Duration(seconds: 11));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(WorkspaceViewScreen)),
    );
    container.invalidate(workspaceViewDataProvider('one', 'view'));
    active.value = true;
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(find.text('draft stays'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  for (final width in [400.0, 1200.0]) {
    testWidgets(
      'saved view displays approved surface and returns at width $width',
      (tester) async {
        tester.view.physicalSize = .new(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var returned = false;
        final data = WorkspaceViewData(
          view: .new(
            id: 'view',
            name: 'Overview',
            tableId: 'table',
            bindings: {'title': 'label'},
            columnTypes: {'label': 'text'},
            definition: .fromJson({
              'version': 1,
              'components': [
                {
                  'id': 'root',
                  'component': 'Table',
                  'columns': {'path': '/columns'},
                  'rows': {'path': '/rows'},
                },
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
          records: [
            const WorkspaceRecord(
              id: 'record',
              tableId: 'table',
              values: {'label': 'Visible owned record'},
              revision: 1,
            ),
          ],
          needsRepair: false,
        );
        await tester.runAsync(() async {
          await tester.pumpWidget(
            TestableApp(
              child: WorkspaceViewScreen(
                workspaceId: 'one',
                viewId: 'view',
                onBack: () => returned = true,
              ),
              overrides: [
                workspaceViewDataProvider(
                  'one',
                  'view',
                ).overrideWith((ref) async => data),
              ],
              workspaceId: 'one',
            ),
          );
          await Future<void>.delayed(const Duration(milliseconds: 30));
        });
        final _ = await tester.pumpAndSettle();
        expect(find.text('Visible owned record'), findsOneWidget);
        expect(find.byType(PopupMenuButton<String>), findsNothing);
        await tester.tap(find.byIcon(Icons.arrow_back));
        expect(returned, isTrue);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
