import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/local_workspace_table_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_record_query.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_folders_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_record_query_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_tables_provider.dart';
import 'package:auravibes_app/features/workspaces/screens/workspace_items_screen.dart';
import 'package:auravibes_app/features/workspaces/screens/workspace_table_screen.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_tables_usecase.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_record_browser.dart';
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
    expect(button('workspace_label_save'), findsNothing);
    expect(button('workspace_record_create'), findsNothing);
    await tester.tap(find.text('Readable'));
    final _ = await tester.pumpAndSettle();
    expect(find.text('Readable'), findsOneWidget);
    expect(button('workspace_record_save'), findsNothing);
  });
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
      final _ = await tester.pumpAndSettle();
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
            widget.identifier == 'workspace_record_create',
      ),
    );
    await flush();
    expect(find.text('Book'), findsOneWidget);
    await tester.tap(find.text('Book'));
    await flush();
    await tester.enterText(input('workspace_record_value'), 'First book');
    await tester.runAsync(() => tester.tap(button('workspace_record_save')));
    await flush();

    await tester.tap(find.text('First book'));
    await flush();
    await tester.enterText(input('workspace_record_value'), 'Updated book');
    await tester.runAsync(() => tester.tap(button('workspace_record_save')));
    await flush();

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
    expect(find.text('Updated book'), findsOneWidget);
    expect(find.text('Other book'), findsNothing);
    await tester.tap(find.text('Updated book'));
    await flush();
    await tester.tap(find.text('Reading'));
    await flush();
    expect(find.text('Other book'), findsNothing);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(400, 800);
    addTearDown(tester.view.resetPhysicalSize);
    await flush();
    expect(find.byType(DataTable), findsNothing);
    expect(find.text('Updated book'), findsOneWidget);
  });
}
