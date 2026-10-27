import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/local_workspace_table_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_record_query.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_folders_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_record_query_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_references_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_tables_provider.dart';
import 'package:auravibes_app/features/workspaces/screens/workspace_items_screen.dart';
import 'package:auravibes_app/features/workspaces/screens/workspace_table_screen.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_tables_usecase.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_record_browser.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_record_fields.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_reference_label.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
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
  testWidgets('read-only table opens records without exposing edit controls', (
    tester,
  ) async {
    const table = WorkspaceTable(
      id: 'table',
      name: 'Shared',
      labelColumnId: 'label',
      columns: [WorkspaceColumn(id: 'label', name: 'Title')],
      revision: 1,
      schemaRevision: 1,
      canManage: false,
      canEditRecords: false,
      supportsSharing: true,
    );
    await tester.runAsync(() async {
      await tester.pumpWidget(
        TestableApp(
          child: WorkspaceTableScreen(
            workspaceId: 'one',
            tableId: 'table',
            onBack: () => fail('Unexpected back navigation'),
          ),
          overrides: [
            workspaceTableProvider(
              'one',
              'table',
            ).overrideWith((ref) async => table),
            workspaceRecordQueryProvider.overrideWith(
              (ref, arguments) async => const WorkspaceRecordPage(
                records: [
                  WorkspaceRecord(
                    id: 'record',
                    tableId: 'table',
                    values: {'label': 'Readable'},
                    revision: 1,
                  ),
                ],
                hasMore: false,
              ),
            ),
          ],
          workspaceId: 'one',
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    final _ = await tester.pumpAndSettle();
    Finder button(String id) => find.byWidgetPredicate(
      (widget) => widget is AuraButton && widget.identifier == id,
    );
    for (final id in [
      'workspace_table_back',
      'workspace_records_previous',
      'workspace_records_next',
    ]) {
      expect(
        find.byWidgetPredicate(
          (widget) => widget is AuraIconButton && widget.identifier == id,
        ),
        findsOneWidget,
      );
    }
    final overflow = find.byWidgetPredicate(
      (widget) =>
          widget is AuraPopupMenuButton &&
          widget.identifier == 'workspace_table_overflow',
    );
    await tester.tap(overflow);
    final _ = await tester.pumpAndSettle();
    expect(find.text('Export CSV'), findsOneWidget);
    expect(find.text('Revision history'), findsOneWidget);
    expect(find.text('Import CSV'), findsNothing);
    expect(find.text('Move to Trash'), findsNothing);
    expect(find.text('Settings'), findsNothing);
    await tester.tap(overflow);
    final _ = await tester.pumpAndSettle();
    expect(button('workspace_label_save'), findsNothing);
    expect(button('workspace_record_create'), findsNothing);
    await tester.tap(find.text('Readable'));
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Show more').last);
    final _ = await tester.pumpAndSettle();
    expect(find.text('Readable'), findsOneWidget);
    expect(button('workspace_record_save'), findsNothing);
    final recordMenu = find.byWidgetPredicate(
      (widget) =>
          widget is AuraPopupMenuButton &&
          widget.identifier == 'workspace_record_overflow',
    );
    expect(recordMenu, findsOneWidget);
    await tester.tap(recordMenu);
    final _ = await tester.pumpAndSettle();
    expect(find.text('Revision history'), findsOneWidget);
    expect(find.text('Move to Trash'), findsNothing);
  });
  testWidgets('selecting a cell does not open the record editor', (
    tester,
  ) async {
    const table = WorkspaceTable(
      id: 'source',
      name: 'Source',
      labelColumnId: 'label',
      columns: [
        WorkspaceColumn(id: 'label', name: 'Title'),
        WorkspaceColumn(id: 'flag', name: 'Flag', type: .checkbox),
        WorkspaceColumn(id: 'third', name: 'Third'),
      ],
      revision: 1,
      schemaRevision: 1,
    );
    const record = WorkspaceRecord(
      id: 'row',
      tableId: 'source',
      values: {'label': 'Value', 'flag': true},
      revision: 1,
    );
    await tester.runAsync(
      () => tester.pumpWidget(
        TestableApp(
          child: WorkspaceRecordBrowser(
            workspaceId: 'one',
            table: table,
            onRecord: (_) => fail('Selection must stay in the table'),
          ),
          overrides: [
            workspaceRecordQueryProvider.overrideWith(
              (ref, arguments) async =>
                  const WorkspaceRecordPage(records: [record], hasMore: false),
            ),
          ],
          workspaceId: 'one',
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();
    final cell = find.byKey(const ValueKey('workspace_cell_row_label'));
    expect(cell, findsOneWidget);
    expect(tester.getTopLeft(find.byType(DataTable)).dx, lessThan(40));
    final mouse = await tester.createGesture(kind: .mouse);
    await mouse.addPointer();
    await mouse.moveTo(tester.getCenter(cell));
    final _ = await tester.pumpAndSettle();
    expect(
      tester.widget<DataTable>(find.byType(DataTable)).rows.first.color,
      isNotNull,
    );
    await mouse.moveTo(const Offset(799, 10));
    final _ = await tester.pumpAndSettle();
    await tester.tap(cell);
    await tester.pump(const Duration(milliseconds: 400));
    final _ = await tester.pumpAndSettle();
    final selected =
        tester.widget<Container>(cell).decoration as BoxDecoration?;
    expect(selected?.border, isNotNull);
    final textStyle = tester.widget<DefaultTextStyle>(
      find.descendant(of: cell, matching: find.byType(DefaultTextStyle)).first,
    );
    expect(textStyle.style.color, isNotNull);
    await tester.tap(find.text('Search records'));
    final _ = await tester.pumpAndSettle();
    final cleared = tester.widget<Container>(cell).decoration as BoxDecoration?;
    expect(cleared?.border, isNull);
    final before = tester.getSize(cell);
    await tester.tap(cell);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(cell);
    final _ = await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('workspace_inline_record_value')),
      findsOneWidget,
    );
    expect(tester.getSize(cell), before);
    final _ = await tester.sendKeyEvent(.escape);
    final _ = await tester.pumpAndSettle();
    final flag = find.byKey(const ValueKey('workspace_cell_row_flag'));
    final flagBefore = tester.getSize(flag);
    await tester.tap(flag);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(flag);
    final _ = await tester.pumpAndSettle();
    expect(find.byType(WorkspaceRecordFields), findsOneWidget);
    expect(tester.getSize(flag), flagBefore);
    expect(
      tester.getTopLeft(find.byType(WorkspaceRecordFields)).dy,
      closeTo(tester.getBottomLeft(flag).dy, 1),
    );
    await tester.tap(find.byTooltip('Cancel').last);
    final _ = await tester.pumpAndSettle();
    expect(find.byType(WorkspaceRecordFields), findsNothing);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 400);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final _ = await tester.pumpAndSettle();
    await tester.dragFrom(const Offset(300, 140), const Offset(-220, 0));
    final _ = await tester.pumpAndSettle();
    await tester.tap(flag);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(flag);
    final _ = await tester.pumpAndSettle();
    final popup = tester.getRect(
      find.byKey(const ValueKey('workspace_cell_type_popup')),
    );
    expect(popup.left, greaterThanOrEqualTo(0));
    expect(popup.right, lessThanOrEqualTo(400));
    expect(popup.bottom, lessThanOrEqualTo(400));
    await tester.tap(find.byTooltip('Cancel').last);
    final _ = await tester.pumpAndSettle();
    final left = tester.getTopLeft(flag).dx;
    await tester.dragFrom(const Offset(300, 140), .new(-left - 60, 0));
    final _ = await tester.pumpAndSettle();
    expect(tester.getTopLeft(flag).dx, lessThan(0));
    final partiallyVisible = Offset(10, tester.getCenter(flag).dy);
    await tester.tapAt(partiallyVisible);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tapAt(partiallyVisible);
    final _ = await tester.pumpAndSettle();
    final clamped = tester.getRect(
      find.byKey(const ValueKey('workspace_cell_type_popup')),
    );
    expect(clamped.left, greaterThanOrEqualTo(0));
    expect(clamped.right, lessThanOrEqualTo(400));
    await tester.tap(find.byTooltip('Cancel').last);
    final _ = await tester.pumpAndSettle();
  });
  testWidgets('restricted reference cells hide stored IDs at both widths', (
    tester,
  ) async {
    const table = WorkspaceTable(
      id: 'source',
      name: 'Source',
      labelColumnId: 'label',
      columns: [
        WorkspaceColumn(id: 'label', name: 'Title'),
        WorkspaceColumn(
          id: 'link',
          name: 'Related',
          type: .reference,
          targetTableId: 'target',
        ),
      ],
      revision: 1,
      schemaRevision: 1,
    );
    const record = WorkspaceRecord(
      id: 'source-record',
      tableId: 'source',
      values: {'label': 'Readable source', 'link': 'secret-record-id'},
      revision: 1,
      restrictedReferenceColumns: ['link'],
    );
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.runAsync(
      () => tester.pumpWidget(
        TestableApp(
          child: WorkspaceRecordBrowser(
            workspaceId: 'one',
            table: table,
            onRecord: (_) => fail('Unexpected row navigation'),
          ),
          overrides: [
            workspaceRecordQueryProvider.overrideWith(
              (ref, arguments) async =>
                  const WorkspaceRecordPage(records: [record], hasMore: false),
            ),
          ],
          workspaceId: 'one',
        ),
      ),
    );
    for (final width in [1200.0, 400.0]) {
      tester.view.physicalSize = .new(width, 900);
      final _ = await tester.pumpAndSettle();
      expect(find.text('Readable source'), findsOneWidget);
      expect(
        find.text('Linked records are unavailable with your current access.'),
        findsOneWidget,
      );
      expect(find.textContaining('secret-record-id'), findsNothing);
    }
  });
  testWidgets(
    'reference cells show authorized labels instead of IDs at both widths',
    (tester) async {
      const table = WorkspaceTable(
        id: 'source',
        name: 'Source',
        labelColumnId: 'label',
        columns: [
          WorkspaceColumn(id: 'label', name: 'Title'),
          WorkspaceColumn(
            id: 'link',
            name: 'Related',
            type: .reference,
            targetTableId: 'target',
          ),
        ],
        revision: 1,
        schemaRevision: 1,
        canManage: false,
        canEditRecords: false,
      );
      const record = WorkspaceRecord(
        id: 'source-record',
        tableId: 'source',
        values: {'label': 'Readable source', 'link': 'target-record-id'},
        revision: 1,
      );
      const target = WorkspaceTable(
        id: 'target',
        name: 'Targets',
        labelColumnId: 'label',
        columns: [WorkspaceColumn(id: 'label', name: 'Title')],
        revision: 1,
        schemaRevision: 1,
        canManage: false,
        canEditRecords: false,
      );
      const targetRecord = WorkspaceRecord(
        id: 'target-record-id',
        tableId: 'target',
        values: {'label': 'Friendly target'},
        revision: 1,
      );
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.runAsync(
        () => tester.pumpWidget(
          TestableApp(
            child: WorkspaceRecordBrowser(
              workspaceId: 'one',
              table: table,
              onRecord: (_) => fail('Unexpected row navigation'),
            ),
            overrides: [
              workspaceRecordQueryProvider.overrideWith(
                (ref, arguments) async => const WorkspaceRecordPage(
                  records: [record],
                  hasMore: false,
                ),
              ),
              workspaceTableProvider(
                'one',
                'target',
              ).overrideWith((ref) async => target),
              workspaceReferencedRecordProvider(
                'one',
                'target',
                'target-record-id',
              ).overrideWith((ref) async => targetRecord),
            ],
            workspaceId: 'one',
          ),
        ),
      );
      for (final width in [1200.0, 400.0]) {
        tester.view.physicalSize = .new(width, 900);
        final _ = await tester.pumpAndSettle();
        expect(find.text('Friendly target'), findsOneWidget);
        expect(find.textContaining('target-record-id'), findsNothing);
      }
    },
  );
  testWidgets(
    'saving a target refreshes a continuously mounted reference label',
    (tester) async {
      final database = AppDatabase(connection: NativeDatabase.memory());
      addTearDown(database.close);
      await tester.runAsync(() async {
        final _ = await database
            .into(database.workspaces)
            .insert(
              WorkspacesCompanion.insert(
                id: const .new('one'),
                name: 'One',
                type: .local,
              ),
            );
        final tables = OrganizeWorkspaceTablesUsecase(
          LocalWorkspaceTableRepository(database, 'one'),
        );
        final table = await tables.create(name: 'Targets', labelName: 'Title');
        final schema = await tables.saveColumn(
          table: table,
          column: .new(
            id: '',
            name: 'Related',
            type: .reference,
            targetTableId: table.id,
          ),
        );
        final target = await tables.createRecord(
          table: schema,
          values: {schema.labelColumnId: 'Old target'},
        );
        final _ = await tables.createRecord(
          table: schema,
          values: {
            schema.labelColumnId: 'Source',
            schema.columns.last.id: target.id,
          },
        );
        await tester.pumpWidget(
          TestableApp(
            child: Column(
              children: [
                Expanded(
                  child: WorkspaceTableScreen(
                    workspaceId: 'one',
                    tableId: schema.id,
                    onBack: () => fail('Unexpected table back'),
                  ),
                ),
                SizedBox(
                  height: 60,
                  child: WorkspaceReferenceLabel(
                    workspaceId: 'one',
                    targetTableId: schema.id,
                    recordId: target.id,
                    key: const ValueKey('stable_reference'),
                  ),
                ),
              ],
            ),
            overrides: [
              appDatabaseProvider.overrideWithValue(database),
              workspaceTableUsecaseProvider('one')
                  .overrideWith((ref) async => tables),
            ],
            workspaceId: 'one',
          ),
        );
      });
      await _settleDatabase(tester);
      await tester.tap(find.text('Old target').first);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('Old target').first);
      await _settleDatabase(tester);
      await tester.enterText(
        find.byKey(const ValueKey('workspace_inline_record_value')),
        'Updated target',
      );
      await tester.runAsync(() => tester.testTextInput.receiveAction(.done));
      await _settleDatabase(tester);
      for (
        var attempt = 0;
        attempt < 20 &&
            find
                .descendant(
                  of: find.byKey(const ValueKey('stable_reference')),
                  matching: find.text('Updated target'),
                )
                .evaluate()
                .isEmpty;
        attempt++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await _settleDatabase(tester);
      }
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('stable_reference')),
          matching: find.text('Updated target'),
        ),
        findsOneWidget,
      );
    },
  );
  testWidgets('record grid preserves money precision and selected timezone', (
    tester,
  ) async {
    const table = WorkspaceTable(
      id: 'values',
      name: 'Values',
      labelColumnId: 'label',
      columns: [
        WorkspaceColumn(id: 'label', name: 'Title'),
        WorkspaceColumn(id: 'money', name: 'Amount', type: .money),
        WorkspaceColumn(
          id: 'instant',
          name: 'Time',
          type: .timestamp,
          timeZone: 'America/New_York',
        ),
      ],
      revision: 1,
      schemaRevision: 1,
    );
    const record = WorkspaceRecord(
      id: 'value',
      tableId: 'values',
      values: {
        'label': 'Entry',
        'money': {
          'amount': '9007199254740993.010000000000000001',
          'currency': 'USD',
        },
        'instant': '2026-03-08T07:00:00Z',
      },
      revision: 1,
    );
    await tester.runAsync(
      () => tester.pumpWidget(
        TestableApp(
          child: WorkspaceRecordBrowser(
            workspaceId: 'one',
            table: table,
            onRecord: (_) => fail('Unexpected record navigation'),
          ),
          overrides: [
            workspaceRecordQueryProvider.overrideWith(
              (ref, arguments) async =>
                  const WorkspaceRecordPage(records: [record], hasMore: false),
            ),
          ],
          workspaceId: 'one',
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();
    expect(
      find.text('USD 9007199254740993.010000000000000001'),
      findsOneWidget,
    );
    expect(find.textContaining('2026-03-08T03:00:00'), findsOneWidget);
  });

  testWidgets('ordinary controls create tables and edit columns and records', (
    tester,
  ) async {
    final database = AppDatabase(connection: NativeDatabase.memory());
    addTearDown(database.close);
    final tables = OrganizeWorkspaceTablesUsecase(
      LocalWorkspaceTableRepository(database, 'one'),
    );
    await tester.runAsync(() async {
      final _ = await database
          .into(database.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              id: const Value('one'),
              name: 'One',
              type: .local,
            ),
          );
      await tester.pumpWidget(
        TestableApp(
          child: const WorkspaceItemsScreen(workspaceId: 'one'),
          overrides: [
            appDatabaseProvider.overrideWithValue(database),
            workspaceTableUsecaseProvider('one')
                .overrideWith((ref) async => tables),
            workspaceFoldersProvider(
              'one',
              null,
            ).overrideWith((ref) async => []),
          ],
          workspaceId: 'one',
        ),
      );
    });
    Future<void> flush() async {
      for (var index = 0; index < 5; index++) {
        await tester.pump();
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        });
      }
      if (find
          .byKey(const ValueKey('workspace_inline_record_value'))
          .evaluate()
          .isNotEmpty) {
        await tester.pump(const Duration(milliseconds: 100));
      } else {
        final _ = await tester.pumpAndSettle();
      }
    }

    await flush();
    Finder input(String id) => find.byWidgetPredicate(
      (widget) => widget is AuraInput && widget.identifier == id,
    );
    Finder button(String id) => find.byWidgetPredicate(
      (widget) => widget is AuraButton && widget.identifier == id,
    );
    await tester.tap(find.byKey(const ValueKey('directory_create')));
    await flush();
    await tester.tap(find.text('Table'));
    await flush();
    await tester.enterText(input('workspace_table_name'), 'Reading');
    await tester.runAsync(() => tester.tap(button('workspace_table_create')));
    await flush();

    expect(find.text('Reading'), findsOneWidget);
    await tester.tap(find.byType(AuraPopupMenuButton).last);
    await flush();
    await tester.tap(find.text('Table settings'));
    await flush();
    await tester.enterText(input('workspace_label_column'), 'Book');
    await tester.runAsync(() => tester.tap(button('workspace_label_save')));
    await flush();

    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is AuraIconButton &&
            widget.identifier == 'workspace_table_back',
      ),
    );
    await flush();
    await tester.tap(find.byTooltip('Add record').last);
    await flush();
    final createdTable = (await tables.list()).single;
    var emptyRecords = await tables.records(createdTable.id);
    for (var attempt = 0; attempt < 20 && emptyRecords.isEmpty; attempt++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await flush();
      emptyRecords = await tables.records(createdTable.id);
    }
    expect(emptyRecords, hasLength(1));
    expect(emptyRecords.single.values[createdTable.labelColumnId], isNull);
    final emptyCell = find.byKey(
      ValueKey(
        'workspace_cell_${emptyRecords.single.id}_'
        '${createdTable.labelColumnId}',
      ),
    );
    await tester.tap(emptyCell);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(emptyCell);
    await flush();
    final inline = find.byKey(const ValueKey('workspace_inline_record_value'));
    await tester.enterText(inline, 'First book');
    await flush();
    expect(tester.widget<PopScope>(find.byType(PopScope).last).canPop, isFalse);
    expect(inline, findsOneWidget);
    expect(find.text('First book'), findsOneWidget);
    await tester.runAsync(() => tester.testTextInput.receiveAction(.done));
    await flush();
    for (
      var attempt = 0;
      attempt < 20 && inline.evaluate().isNotEmpty;
      attempt++
    ) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await flush();
    }
    expect(inline, findsNothing);

    final first = find.text('First book');
    await tester.tap(first);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(first);
    await flush();
    await tester.enterText(
      find.byKey(const ValueKey('workspace_inline_record_value')),
      'Updated book',
    );
    await tester.runAsync(() => tester.testTextInput.receiveAction(.done));
    await flush();
    for (
      var attempt = 0;
      attempt < 20 &&
          find
              .byKey(const ValueKey('workspace_inline_record_value'))
              .evaluate()
              .isNotEmpty;
      attempt++
    ) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await flush();
    }
    expect(
      find.byKey(const ValueKey('workspace_inline_record_value')),
      findsNothing,
    );
    expect(find.text('Updated book'), findsOneWidget);
    expect(find.text('First book'), findsNothing);
    final current = (await tables.list()).single;
    final _ = await tables.createRecord(
      table: current,
      values: {current.labelColumnId: 'Other book'},
    );
    await tester.tap(find.byIcon(Icons.refresh));
    await flush();
    expect(find.byType(DataTable), findsOneWidget);
    expect(find.text('Other book'), findsOneWidget);
    await tester.enterText(input('workspace_record_search'), 'Updated');
    await tester.testTextInput.receiveAction(.done);
    await flush();
    for (
      var attempt = 0;
      attempt < 20 && find.text('Updated book').evaluate().isEmpty;
      attempt++
    ) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await flush();
    }
    expect(find.text('Updated book'), findsOneWidget);
    expect(find.text('Other book'), findsNothing);
    await tester.tap(find.byTooltip('Add column').last);
    await flush();
    await tester.tap(find.text('Number').last);
    await flush();
    expect(find.byType(Dialog), findsOneWidget);
    await tester.enterText(input('workspace_column_name'), 'Pages');
    await tester.runAsync(
      () => tester.tap(button('workspace_column_create_confirm')),
    );
    await flush();
    for (
      var attempt = 0;
      attempt < 20 && find.byType(Dialog).evaluate().isNotEmpty;
      attempt++
    ) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await flush();
    }
    expect(find.byType(Dialog), findsNothing);
    expect(
      (await tables.list()).single.columns.last.type,
      WorkspaceColumnType.number,
    );
    expect(find.text('Pages'), findsOneWidget);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(400, 800);
    addTearDown(tester.view.resetPhysicalSize);
    await flush();
    expect(find.byType(DataTable), findsOneWidget);
    expect(find.text('Updated book'), findsOneWidget);
  });
}

Future<void> _settleDatabase(WidgetTester tester) async {
  for (var index = 0; index < 5; index++) {
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
  }
  if (find
      .byKey(const ValueKey('workspace_inline_record_value'))
      .evaluate()
      .isNotEmpty) {
    await tester.pump(const Duration(milliseconds: 100));
  } else {
    final _ = await tester.pumpAndSettle();
  }
}
