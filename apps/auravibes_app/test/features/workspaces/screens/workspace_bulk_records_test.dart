import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/local_workspace_table_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_record_change.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_record_query.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_record_batch_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_record_query_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_tables_provider.dart';
import 'package:auravibes_app/features/workspaces/screens/workspace_table_screen.dart';
import 'package:auravibes_app/features/workspaces/usecases/edit_workspace_records_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_tables_usecase.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_record_browser.dart';
import 'package:auravibes_ui/ui.dart';
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
  testWidgets('bulk editor swaps selected unique values in persisted records', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final database = AppDatabase(connection: NativeDatabase.memory());
    addTearDown(database.close);
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
    var table = await tables.create(name: 'Items', labelName: 'Title');
    table = await tables.saveColumn(
      table: table,
      column: .new(id: table.labelColumnId, name: 'Title', isUnique: true),
    );
    final first = await tables.createRecord(
      table: table,
      values: {table.labelColumnId: 'A'},
    );
    final second = await tables.createRecord(
      table: table,
      values: {table.labelColumnId: 'B'},
    );
    await tester.runAsync(
      () => tester.pumpWidget(
        TestableApp(
          child: WorkspaceTableScreen(
            workspaceId: 'one',
            tableId: table.id,
            onBack: () => fail('Unexpected back'),
          ),
          overrides: [
            workspaceTableProvider(
              'one',
              table.id,
            ).overrideWith((ref) async => table),
            workspaceTableUsecaseProvider('one')
                .overrideWith((ref) async => tables),
            workspaceRecordBatchUsecaseProvider('one').overrideWith(
              (ref) async => EditWorkspaceRecordsUsecase(
                LocalWorkspaceRecordBatchRepository(database, 'one'),
              ),
            ),
            workspaceRecordQueryProvider.overrideWith(
              (ref, args) async => WorkspaceRecordPage(
                records: await tables.records(table.id),
                hasMore: false,
              ),
            ),
          ],
          workspaceId: 'one',
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();
    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is AuraPopupMenuButton &&
            widget.identifier == 'workspace_table_overflow',
      ),
    );
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('Select records'));
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox).first);
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox).last);
    final _ = await tester.pumpAndSettle();
    await tester.tap(_button('workspace_records_bulk_edit'));
    final _ = await tester.pumpAndSettle();
    for (final change in [
      (id: first.id, value: 'B'),
      (id: second.id, value: 'A'),
    ]) {
      final row = find.byKey(ValueKey('workspace_bulk_record_${change.id}'));
      await tester.ensureVisible(row);
      await tester.tap(
        find.descendant(of: row, matching: find.byType(ListTile)).first,
      );
      final _ = await tester.pumpAndSettle();
      final input = find.descendant(of: row, matching: find.byType(AuraInput));
      await tester.ensureVisible(input);
      await tester.enterText(input, change.value);
      await tester.tap(
        find.descendant(of: row, matching: find.byType(ListTile)).first,
      );
      final _ = await tester.pumpAndSettle();
    }
    await tester.tap(_button('workspace_bulk_save'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const ValueKey('workspace_bulk_approve')));
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    final _ = await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(
      (await tables.record(table.id, first.id)).values[table.labelColumnId],
      'B',
    );
    expect(
      (await tables.record(table.id, second.id)).values[table.labelColumnId],
      'A',
    );
    expect(_button('workspace_records_bulk_edit'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  for (final size in [
    (width: 400.0, height: 900.0),
    (width: 1200.0, height: 900.0),
    (width: 400.0, height: 450.0),
  ]) {
    final width = size.width;
    testWidgets(
      'frozen selection survives search and failed bulk save at $width/${size.height}',
      (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = .new(width, size.height);
        if (size.height == 450) {
          tester.view.viewInsets = const FakeViewPadding(bottom: 180);
          addTearDown(tester.view.resetViewInsets);
        }
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repository = _Batch();
        await tester.runAsync(
          () => tester.pumpWidget(
            TestableApp(
              child: WorkspaceRecordBrowser(
                workspaceId: 'one',
                table: _table,
                onRecord: (_) => fail('Selection opened editor'),
              ),
              overrides: [
                workspaceRecordBatchUsecaseProvider('one').overrideWith(
                  (ref) async => EditWorkspaceRecordsUsecase(repository),
                ),
                workspaceRecordQueryProvider.overrideWith(
                  (ref, args) async => WorkspaceRecordPage(
                    records: args.$3.search.isEmpty
                        ? [_record('one', 'First'), _record('two', 'Second')]
                        : [_record('other', 'Different')],
                    hasMore: false,
                  ),
                ),
              ],
              workspaceId: 'one',
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('First'));
        await tester.longPress(find.text('First'));
        final _ = await tester.pumpAndSettle();
        if (size.height == 450) {
          expect(tester.takeException(), isNull);
          tester.view.resetViewInsets();
          tester.view.physicalSize = .new(width, 900);
          final _ = await tester.pumpAndSettle();
        }
        final search = find.byWidgetPredicate(
          (widget) =>
              widget is AuraInput &&
              widget.identifier == 'workspace_record_search',
        );
        await tester.enterText(search, 'Different');
        await tester.testTextInput.receiveAction(.done);
        final _ = await tester.pumpAndSettle();
        await tester.tap(_button('workspace_records_bulk_edit'));
        final _ = await tester.pumpAndSettle();
        expect(find.text('First'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(Dialog),
            matching: find.text('Different'),
          ),
          findsNothing,
        );
        await tester.tap(_button('workspace_bulk_save'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(
          find.byKey(const ValueKey('workspace_bulk_approve')),
          findsOneWidget,
        );
        await tester.tap(find.text('Cancel').last);
        final _ = await tester.pumpAndSettle();
        expect(repository.applied, isNull);
        await tester.tap(_button('workspace_bulk_save'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.byKey(const ValueKey('workspace_bulk_approve')));
        final _ = await tester.pumpAndSettle();
        expect(repository.applied?.map((change) => change.record.id), ['one']);
        expect(find.text('First'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

Finder _button(String id) => find.byWidgetPredicate(
  (widget) => widget is AuraButton && widget.identifier == id,
);
const _table = WorkspaceTable(
  id: 'table',
  name: 'Items',
  labelColumnId: 'label',
  columns: [WorkspaceColumn(id: 'label', name: 'Title')],
  revision: 1,
  schemaRevision: 1,
);
WorkspaceRecord _record(String id, String label) => WorkspaceRecord(
  id: id,
  tableId: 'table',
  values: {'label': label},
  revision: 1,
);

class _Batch implements WorkspaceRecordBatchRepository {
  List<WorkspaceRecordChange>? applied;
  @override
  Future<void> apply(
    List<WorkspaceRecordChange> changes, {
    required String requestId,
  }) async {
    applied = changes;
    throw const WorkspaceTableException(conflict: true);
  }
}
