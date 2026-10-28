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
import 'package:auravibes_app/widgets/aura_app_bar_with_drawer.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/test_app.dart';

void _noop() {
  return;
}

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });
  testWidgets('compact table retries a failed load', (tester) async {
    var attempts = 0;
    const table = WorkspaceTable(
      id: 'table',
      name: 'Contacts',
      labelColumnId: 'label',
      columns: [WorkspaceColumn(id: 'label', name: 'Name')],
      revision: 1,
      schemaRevision: 1,
    );
    await tester.runAsync(() async {
      await tester.pumpWidget(
        TestableApp(
          child: const WorkspaceTableScreen(
            workspaceId: 'one',
            tableId: 'table',
            onBack: _noop,
            compact: true,
          ),
          overrides: [
            workspaceTableProvider('one', 'table').overrideWith((ref) async {
              if (++attempts == 1) throw StateError('temporary failure');

              return table;
            }),
            workspaceRecordQueryProvider.overrideWith(
              (ref, arguments) async => const WorkspaceRecordPage(
                records: [
                  WorkspaceRecord(
                    id: 'record',
                    tableId: 'table',
                    values: {'label': 'Alice'},
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
    expect(attempts, 1);
    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is AuraButton &&
            widget.identifier == 'workspace_table_retry',
      ),
    );
    final _ = await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.text('Alice'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('compact table shows records without page navigation', (
    tester,
  ) async {
    const table = WorkspaceTable(
      id: 'table',
      name: 'Contacts',
      labelColumnId: 'label',
      columns: [WorkspaceColumn(id: 'label', name: 'Name')],
      revision: 1,
      schemaRevision: 1,
    );
    await tester.runAsync(() async {
      await tester.pumpWidget(
        TestableApp(
          child: const WorkspaceTableScreen(
            workspaceId: 'one',
            tableId: 'table',
            onBack: _noop,
            compact: true,
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
                    values: {'label': 'Alice'},
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
    expect(find.text('Alice'), findsOneWidget);
    expect(find.byType(AuraAppBarWithDrawer), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is AuraIconButton &&
            widget.identifier == 'workspace_table_back',
      ),
      findsNothing,
    );
    expect(find.byType(WorkspaceRecordBrowser), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
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
        WorkspaceColumn(id: 'third', name: 'Third', type: .money),
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
    final grid = tester.widget<DataTable>(find.byType(DataTable));
    expect(grid.horizontalMargin, 0);
    expect(grid.columnSpacing, 0);
    expect(grid.columns, hasLength(3));
    expect(grid.border?.horizontalInside.style, BorderStyle.solid);
    expect(grid.border?.verticalInside.style, BorderStyle.solid);
    final flag = find.byKey(const ValueKey('workspace_cell_row_flag'));
    final third = find.byKey(const ValueKey('workspace_cell_row_third'));
    expect(tester.getRect(cell).right, closeTo(tester.getRect(flag).left, 1));
    final flagRect = tester.getRect(flag);
    await tester.tapAt(.new(flagRect.left + 4, flagRect.center.dy));
    final _ = await tester.pumpAndSettle();
    final flagDecoration =
        tester.widget<Container>(flag).decoration as BoxDecoration?;
    expect(flagDecoration?.border, isNotNull);
    final flagFocus = find
        .ancestor(of: flag, matching: find.byType(Focus))
        .first;
    expect(tester.widget<Focus>(flagFocus).focusNode?.hasFocus, isTrue);
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
    final colors = Theme.of(tester.element(cell)).colorScheme;
    expect(selected?.color, isNot(colors.primaryContainer));
    final cellFocus = find
        .ancestor(of: cell, matching: find.byType(Focus))
        .first;
    final searchInput = find.descendant(
      of: find.byWidgetPredicate(
        (widget) =>
            widget is AuraInput &&
            widget.identifier == 'workspace_record_search',
      ),
      matching: find.byType(EditableText),
    );
    expect(tester.widget<Focus>(cellFocus).focusNode?.hasFocus, isTrue);
    tester.widget<EditableText>(searchInput).focusNode.requestFocus();
    final _ = await tester.pumpAndSettle();
    expect(tester.widget<Focus>(cellFocus).focusNode?.hasFocus, isFalse);
    final focusCleared =
        tester.widget<Container>(cell).decoration as BoxDecoration?;
    expect(focusCleared?.border, isNull);
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
    final editing = tester.widget<Container>(cell).decoration as BoxDecoration?;
    expect(editing?.color, colors.primaryContainer);
    final editor = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const ValueKey('workspace_inline_record_value')),
        matching: find.byType(EditableText),
      ),
    );
    expect(editor.focusNode.hasFocus, isTrue);
    expect(
      editor.controller.selection,
      const TextSelection(baseOffset: 0, extentOffset: 'Value'.length),
    );
    final _ = await tester.sendKeyEvent(.escape);
    final _ = await tester.pumpAndSettle();
    final flagBefore = tester.getSize(flag);
    expect(
      find.descendant(of: flag, matching: find.byType(Checkbox)),
      findsOneWidget,
    );
    expect(find.byType(WorkspaceRecordFields), findsNothing);
    expect(tester.getSize(flag), flagBefore);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 400);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final _ = await tester.pumpAndSettle();
    await tester.dragFrom(const Offset(300, 140), const Offset(-220, 0));
    final _ = await tester.pumpAndSettle();
    await tester.tap(third);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(third);
    final _ = await tester.pumpAndSettle();
    final popup = tester.getRect(
      find.byKey(const ValueKey('workspace_cell_type_popup')),
    );
    expect(popup.width, lessThanOrEqualTo(280));
    expect(popup.height, lessThanOrEqualTo(240));
    expect(popup.left, greaterThanOrEqualTo(0));
    expect(popup.right, lessThanOrEqualTo(400));
    expect(popup.bottom, lessThanOrEqualTo(400));
    await tester.tap(find.byTooltip('Cancel').last);
    final _ = await tester.pumpAndSettle();
  });
  testWidgets('selected cell exposes touch edit and resizable columns', (
    tester,
  ) async {
    const table = WorkspaceTable(
      id: 'source',
      name: 'Source',
      labelColumnId: 'label',
      columns: [
        WorkspaceColumn(id: 'label', name: 'Name'),
        WorkspaceColumn(id: 'notes', name: 'Notes'),
      ],
      revision: 1,
      schemaRevision: 1,
    );
    const record = WorkspaceRecord(
      id: 'row',
      tableId: 'source',
      values: {'label': 'Book', 'notes': 'Read chapter one'},
      revision: 1,
    );
    await tester.runAsync(
      () => tester.pumpWidget(
        TestableApp(
          child: WorkspaceRecordBrowser(
            workspaceId: 'one',
            table: table,
            onRecord: (_) => _noop(),
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

    final cell = find.byKey(const ValueKey('workspace_cell_row_notes'));
    final before = tester.getSize(cell).width;
    final heading = find.byKey(
      const ValueKey('workspace_column_heading_notes'),
    );
    final headingRect = tester.getRect(heading);
    final resize = Offset(headingRect.right - 2, headingRect.center.dy);
    final mouse = await tester.createGesture(kind: .mouse);
    await mouse.addPointer(location: resize);
    await mouse.down(resize);
    await mouse.moveBy(const Offset(48, 0));
    await mouse.up();
    final _ = await tester.pumpAndSettle();
    expect(tester.getSize(cell).width, greaterThan(before));
    expect(
      (await SharedPreferences.getInstance()).getString(
        'workspace_table_column_widths_one_source',
      ),
      contains('"notes":248.0'),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(
      () => tester.pumpWidget(
        TestableApp(
          child: WorkspaceRecordBrowser(
            workspaceId: 'one',
            table: table,
            onRecord: (_) => _noop(),
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
    expect(tester.getSize(cell).width, greaterThan(before));

    await tester.tap(cell);
    final _ = await tester.pumpAndSettle();
    final edit = find.byIcon(Icons.edit_outlined);
    expect(edit, findsOneWidget);
    await tester.tap(edit);
    final _ = await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('workspace_inline_record_value')),
      findsOneWidget,
    );
  });

  testWidgets('arrow keys move cell selection and Enter edits selected cell', (
    tester,
  ) async {
    const table = WorkspaceTable(
      id: 'keyboard-table',
      name: 'Keyboard',
      labelColumnId: 'label',
      columns: [
        WorkspaceColumn(id: 'label', name: 'Name'),
        WorkspaceColumn(id: 'notes', name: 'Notes'),
      ],
      revision: 1,
      schemaRevision: 1,
    );
    const record = WorkspaceRecord(
      id: 'keyboard-row',
      tableId: 'keyboard-table',
      values: {'label': 'Book', 'notes': 'Read chapter one'},
      revision: 1,
    );
    await tester.runAsync(
      () => tester.pumpWidget(
        TestableApp(
          child: WorkspaceRecordBrowser(
            workspaceId: 'one',
            table: table,
            onRecord: (_) => _noop(),
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
    await tester.tap(
      find.byKey(const ValueKey('workspace_cell_keyboard-row_label')),
    );
    final _ = await tester.sendKeyEvent(.arrowRight);
    final _ = await tester.sendKeyEvent(.enter);
    final _ = await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey('workspace_inline_record_value')),
          )
          .controller
          ?.text,
      'Read chapter one',
    );
    await tester.pumpWidget(const SizedBox.shrink());
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

  testWidgets('numeric inline edit rejects invalid text and accepts empty', (
    tester,
  ) async {
    final database = AppDatabase(connection: NativeDatabase.memory());
    addTearDown(database.close);
    final tables = OrganizeWorkspaceTablesUsecase(
      LocalWorkspaceTableRepository(database, 'one'),
    );
    final setup = await tester.runAsync(() async {
      final _ = await database
          .into(database.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              id: const Value('one'),
              name: 'One',
              type: .local,
            ),
          );
      final initial = await tables.create(name: 'Numbers', labelName: 'Name');
      final table = await tables.saveColumn(
        table: initial,
        column: const WorkspaceColumn(id: '', name: 'Count', type: .number),
      );
      final record = await tables.createRecord(
        table: table,
        values: {table.labelColumnId: 'Row', table.columns.last.id: 42},
      );
      await tester.pumpWidget(
        TestableApp(
          child: WorkspaceRecordBrowser(
            workspaceId: 'one',
            table: table,
            onRecord: (_) => fail('Unexpected record navigation'),
          ),
          overrides: [
            appDatabaseProvider.overrideWithValue(database),
            workspaceTableUsecaseProvider('one')
                .overrideWith((ref) async => tables),
            workspaceRecordQueryProvider.overrideWith(
              (ref, arguments) async => WorkspaceRecordPage(
                records: await tables.records(table.id),
                hasMore: false,
              ),
            ),
          ],
          workspaceId: 'one',
        ),
      );

      return (table: table, record: record);
    });
    if (setup == null) throw StateError('Numeric test setup failed');
    final table = setup.table;
    final record = setup.record;
    await _settleDatabase(tester);
    final cell = find.byKey(
      ValueKey('workspace_cell_${record.id}_${table.columns.last.id}'),
    );
    await tester.tap(cell);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(cell);
    await _settleDatabase(tester);
    final inline = find.byKey(const ValueKey('workspace_inline_record_value'));
    expect(inline, findsOneWidget);
    await tester.enterText(inline, 'invalid');
    await tester.runAsync(() => tester.testTextInput.receiveAction(.done));
    await _settleDatabase(tester);
    expect(inline, findsOneWidget);
    expect(
      (await tables.record(table.id, record.id)).values[table.columns.last.id],
      42,
    );
    await tester.enterText(inline, '');
    await tester.runAsync(() => tester.testTextInput.receiveAction(.done));
    await _settleDatabase(tester);
    expect(
      (await tables.record(table.id, record.id)).values[table.columns.last.id],
      isNull,
    );
    await tester.pumpWidget(const SizedBox.shrink());
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
    expect(find.byType(Dialog), findsNothing);
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
    final search = input('workspace_record_search');
    await tester.runAsync(() => tester.tap(search));
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
    final searchInput = find.descendant(
      of: search,
      matching: find.byType(EditableText),
    );
    expect(tester.widget<EditableText>(searchInput).focusNode.hasFocus, isTrue);
    expect(
      (await tables.records(createdTable.id))
          .single
          .values[createdTable.labelColumnId],
      'First book',
    );

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
    final other = find.text('Other book');
    final updated = find.text('Updated book');
    await tester.tap(updated);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(updated);
    await flush();
    await tester.enterText(inline, 'Saved on selection');
    await tester.runAsync(() => tester.tap(other));
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
    expect(find.text('Saved on selection'), findsOneWidget);
    final otherRecord = (await tables.records(current.id))
        .firstWhere((row) => row.values[current.labelColumnId] == 'Other book');
    final otherCell = find.byKey(
      ValueKey('workspace_cell_${otherRecord.id}_${current.labelColumnId}'),
    );
    final decoration =
        tester.widget<Container>(otherCell).decoration as BoxDecoration?;
    expect(decoration?.border, isNotNull);
    final cellFocus = find
        .ancestor(of: otherCell, matching: find.byType(Focus))
        .first;
    expect(tester.widget<Focus>(cellFocus).focusNode?.hasFocus, isTrue);
    await tester.enterText(
      input('workspace_record_search'),
      'Saved on selection',
    );
    await tester.testTextInput.receiveAction(.done);
    await flush();
    for (
      var attempt = 0;
      attempt < 20 && find.text('Saved on selection').evaluate().isEmpty;
      attempt++
    ) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await flush();
    }
    expect(find.text('Saved on selection'), findsWidgets);
    expect(find.text('Other book'), findsNothing);
    await tester.tap(find.byTooltip('Add column').last);
    await flush();
    expect(find.byType(Dialog), findsOneWidget);
    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is AuraDropdownSelector &&
            widget.identifier == 'workspace_column_type',
      ),
    );
    await flush();
    await tester.tap(find.text('Number').last);
    await flush();
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
    await tester.tap(find.byTooltip('Add column').last);
    await flush();
    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is AuraDropdownSelector &&
            widget.identifier == 'workspace_column_type',
      ),
    );
    await flush();
    await tester.tap(find.text('Checkbox').last);
    await flush();
    await tester.enterText(input('workspace_column_name'), 'Flag');
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
    final editedTable = (await tables.list()).single;
    final flagColumn = editedTable.columns.last;
    final editedRecord = (await tables.records(editedTable.id)).firstWhere(
      (record) =>
          record.values[editedTable.labelColumnId] == 'Saved on selection',
    );
    final checkboxCell = find.byKey(
      ValueKey('workspace_cell_${editedRecord.id}_${flagColumn.id}'),
    );
    final checkbox = find.descendant(
      of: checkboxCell,
      matching: find.byType(Checkbox),
    );
    expect(checkbox, findsOneWidget);
    final checkboxTap = find.descendant(
      of: checkboxCell,
      matching: find.byType(InkWell),
    );
    expect(tester.widget<InkWell>(checkboxTap).onTap, isNotNull);
    expect(find.byIcon(Icons.check_box_outlined), findsOneWidget);
    await tester.tap(checkboxTap);
    await flush();
    expect(find.byType(WorkspaceRecordFields), findsNothing);
    final errorMessage = tester
        .widgetList<Tooltip>(
          find.descendant(of: checkboxCell, matching: find.byType(Tooltip)),
        )
        .map((tooltip) => tooltip.message)
        .join(', ');
    expect(
      (await tables.records(editedTable.id))
          .singleWhere((record) => record.id == editedRecord.id)
          .values[flagColumn.id],
      true,
      reason: errorMessage,
    );
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(400, 800);
    addTearDown(tester.view.resetPhysicalSize);
    await flush();
    expect(find.byType(DataTable), findsOneWidget);
    expect(find.text('Saved on selection'), findsWidgets);
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
