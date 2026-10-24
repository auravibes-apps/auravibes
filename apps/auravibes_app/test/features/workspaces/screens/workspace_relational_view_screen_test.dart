import 'package:auravibes_app/features/workspaces/models/workspace_record_query.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_view.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_views_provider.dart';
import 'package:auravibes_app/features/workspaces/screens/workspace_view_screen.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/test_app.dart';

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });
  for (final width in [400.0, 1200.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('saved result pages and full summaries at $width/$scale', (
        tester,
      ) async {
        tester.view.physicalSize = .new(width, 1100);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final first = _data('First', hasMore: true);
        final second = _data('Second', offset: 1);
        await tester.runAsync(() async {
          await tester.pumpWidget(
            TestableApp(
              child: MediaQuery(
                data: .new(textScaler: .linear(scale)),
                child: Scaffold(
                  body: WorkspaceViewScreen(
                    workspaceId: 'one',
                    viewId: 'view',
                    onBack: () => fail('Unexpected Back'),
                  ),
                ),
              ),
              overrides: [
                workspaceViewDataProvider(
                  'one',
                  'view',
                ).overrideWith((ref) async => first),
                workspaceViewDataProvider(
                  'one',
                  'view',
                  offset: 1,
                ).overrideWith((ref) async => second),
              ],
              workspaceId: 'one',
            ),
          );
          await Future<void>.delayed(const Duration(milliseconds: 20));
        });
        final _ = await tester.pumpAndSettle();
        expect(find.text('First'), findsOneWidget);
        await tester.tap(find.text('Summary of all filtered records'));
        final _ = await tester.pumpAndSettle();
        expect(find.text('Records: 103'), findsOneWidget);
        expect(find.text('Sum: 0.000000000000000000001'), findsOneWidget);
        await tester.tap(_button('workspace_view_next'));
        final _ = await tester.pumpAndSettle();
        expect(find.text('Second'), findsOneWidget);
        expect(find.text('First'), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
  testWidgets(
    'approved chart omits missing values instead of substituting zero',
    (tester) async {
      final data = _data('Chart', chart: true);
      await tester.runAsync(() async {
        await tester.pumpWidget(
          TestableApp(
            child: Scaffold(
              body: WorkspaceViewScreen(
                workspaceId: 'one',
                viewId: 'view',
                onBack: () => fail('Unexpected Back'),
              ),
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
        await Future<void>.delayed(const Duration(milliseconds: 20));
      });
      final _ = await tester.pumpAndSettle();
      final chart = tester.widget<AuraChart>(find.byType(AuraChart));
      expect(chart.labels, ['Chart', 'Zero']);
      expect(chart.series.single.values, [2, 0]);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('details select an intended record within the current page', (
    tester,
  ) async {
    final data = _data('First detail', detail: true);
    await tester.runAsync(() async {
      await tester.pumpWidget(
        TestableApp(
          child: Scaffold(
            body: WorkspaceViewScreen(
              workspaceId: 'one',
              viewId: 'view',
              onBack: () => fail('Unexpected Back'),
            ),
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
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    final _ = await tester.pumpAndSettle();
    expect(find.text('2'), findsOneWidget);
    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is AuraDropdownSelector<String> &&
            widget.identifier == 'workspace_view_detail_record',
      ),
    );
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('Second detail').last);
    final _ = await tester.pumpAndSettle();
    expect(find.text('99'), findsOneWidget);
    expect(find.text('2'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('repair state exposes no stale record or aggregate count', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        TestableApp(
          child: Scaffold(
            body: WorkspaceViewScreen(
              workspaceId: 'one',
              viewId: 'view',
              onBack: () => fail('Unexpected Back'),
            ),
          ),
          overrides: [
            workspaceViewDataProvider(
              'one',
              'view',
            ).overrideWith((ref) async => _data('Stale', repair: true)),
          ],
          workspaceId: 'one',
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    final _ = await tester.pumpAndSettle();
    expect(find.text('Stale'), findsNothing);
    expect(find.text('Summary of all filtered records'), findsNothing);
    expect(_button('workspace_view_next'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'existing literal chart remains renderable without numeric bindings',
    (tester) async {
      final base = _data('Static');
      final view = base.view.edited(
        name: base.view.name,
        definition: .fromJson({
          'version': 1,
          'components': [
            {
              'id': 'root',
              'component': 'Chart',
              'labels': ['Fixed'],
              'series': [
                {
                  'label': 'Fixed',
                  'values': [5],
                },
              ],
            },
          ],
        }),
        bindings: {'title': 'label'},
        columnTypes: {'label': 'text'},
      );
      final data = WorkspaceViewData(
        view: view,
        table: base.table,
        records: base.records,
        needsRepair: false,
      );
      await tester.runAsync(() async {
        await tester.pumpWidget(
          TestableApp(
            child: Scaffold(
              body: WorkspaceViewScreen(
                workspaceId: 'one',
                viewId: 'view',
                onBack: () => fail('Unexpected Back'),
              ),
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
        await Future<void>.delayed(const Duration(milliseconds: 20));
      });
      final _ = await tester.pumpAndSettle();
      expect(
        tester.widget<AuraChart>(find.byType(AuraChart)).series.single.values,
        [5],
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('oversized exact money is never converted to chart geometry', (
    tester,
  ) async {
    final amount = '1${List.filled(400, '0').join()}';
    expect(double.parse(amount).isInfinite, isTrue);
    const table = WorkspaceTable(
      id: 'money',
      name: 'Amounts',
      labelColumnId: 'label',
      columns: [
        WorkspaceColumn(id: 'label', name: 'Title'),
        WorkspaceColumn(id: 'cost', name: 'Cost', type: .money),
      ],
      revision: 1,
      schemaRevision: 1,
      canManage: false,
    );
    final data = WorkspaceViewData(
      view: .new(
        id: 'view',
        name: 'Amounts',
        tableId: 'money',
        bindings: {'title': 'label', 'cost': 'cost'},
        columnTypes: {'label': 'text', 'cost': 'money'},
        definition: .fromJson({
          'version': 1,
          'components': [
            {
              'id': 'root',
              'component': 'Chart',
              'labels': {'path': '/chartLabels'},
              'series': {'path': '/chartSeries'},
            },
          ],
        }),
        revision: 1,
        summaryColumnIds: ['cost'],
      ),
      table: table,
      records: [
        WorkspaceRecord(
          id: 'one',
          tableId: 'money',
          values: {
            'label': 'Exact amount',
            'cost': {'amount': amount, 'currency': 'USD'},
          },
          revision: 1,
        ),
      ],
      needsRepair: false,
      summary: {
        'count': 1,
        'columns': {
          'cost': {
            'present': 1,
            'currencies': {
              'USD': {'sum': amount},
            },
          },
        },
      },
    );
    await tester.runAsync(() async {
      await tester.pumpWidget(
        TestableApp(
          child: Scaffold(
            body: WorkspaceViewScreen(
              workspaceId: 'one',
              viewId: 'view',
              onBack: () => fail('Unexpected Back'),
            ),
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
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    final _ = await tester.pumpAndSettle();
    expect(find.byType(AuraChart), findsNothing);
    expect(find.text('No numeric values on this page.'), findsOneWidget);
    await tester.tap(find.text('Summary of all filtered records'));
    final _ = await tester.pumpAndSettle();
    expect(find.text('Sum: $amount'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

Finder _button(String identifier) => find.byWidgetPredicate(
  (widget) => widget is AuraButton && widget.identifier == identifier,
);
WorkspaceViewData _data(
  String label, {
  int offset = 0,
  bool hasMore = false,
  bool chart = false,
  bool detail = false,
  bool repair = false,
}) => WorkspaceViewData(
  view: .new(
    id: 'view',
    name: 'Summary',
    tableId: 'table',
    bindings: {'title': 'label', 'quantity': 'quantity'},
    columnTypes: {'label': 'text', 'quantity': 'number'},
    definition: .fromJson({
      'version': 1,
      'components': [
        if (detail) ...[
          {
            'id': 'root',
            'component': 'Column',
            'children': ['detail_quantity'],
          },
          {
            'id': 'detail_quantity',
            'component': 'Text',
            'text': {'path': '/quantity'},
          },
        ] else if (chart)
          {
            'id': 'root',
            'component': 'Chart',
            'variant': 'bar',
            'labels': {'path': '/chartLabels'},
            'series': {'path': '/chartSeries'},
          }
        else
          {
            'id': 'root',
            'component': 'Table',
            'columns': {'path': '/columns'},
            'rows': {'path': '/rows'},
          },
      ],
    }),
    revision: 1,
    query: const WorkspaceRecordQuery(limit: 1),
  ),
  table: const WorkspaceTable(
    id: 'table',
    name: 'Items',
    labelColumnId: 'label',
    columns: [
      WorkspaceColumn(id: 'label', name: 'Title'),
      WorkspaceColumn(id: 'quantity', name: 'Quantity', type: .number),
    ],
    revision: 1,
    schemaRevision: 1,
    canManage: false,
  ),
  records: [
    WorkspaceRecord(
      id: label,
      tableId: 'table',
      values: {'label': label, 'quantity': 2},
      revision: 1,
    ),
    if (detail)
      const WorkspaceRecord(
        id: 'second-detail',
        tableId: 'table',
        values: {'label': 'Second detail', 'quantity': 99},
        revision: 1,
      ),
    if (chart)
      const WorkspaceRecord(
        id: 'zero',
        tableId: 'table',
        values: {'label': 'Zero', 'quantity': 0},
        revision: 1,
      ),
    if (chart)
      const WorkspaceRecord(
        id: 'missing',
        tableId: 'table',
        values: {'label': 'Missing'},
        revision: 1,
      ),
  ],
  needsRepair: repair,
  hasMore: hasMore,
  offset: offset,
  summary: const {
    'count': 103,
    'columns': {
      'quantity': {'present': 2, 'sum': '0.000000000000000000001'},
    },
  },
);
