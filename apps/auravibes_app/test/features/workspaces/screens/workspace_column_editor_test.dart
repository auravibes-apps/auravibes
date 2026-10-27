import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/local_workspace_table_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_record_query.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_record_query_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_tables_provider.dart';
import 'package:auravibes_app/features/workspaces/screens/workspace_table_screen.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_tables_usecase.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_column_editor.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/test_app.dart';

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });
  testWidgets(
    'preview rejects duplicate values and offers a separate replacement',
    (tester) async {
      final database = AppDatabase(connection: NativeDatabase.memory());
      addTearDown(database.close);
      final tables = OrganizeWorkspaceTablesUsecase(
        LocalWorkspaceTableRepository(database, 'one'),
      );
      var saved = false;
      final table = await tester.runAsync(() async {
        final _ = await database
            .into(database.workspaces)
            .insert(
              WorkspacesCompanion.insert(
                id: const Value('one'),
                name: 'One',
                type: .local,
              ),
            );
        var table = await tables.create(name: 'Items', labelName: 'Title');
        table = await tables.saveColumn(
          table: table,
          column: const WorkspaceColumn(id: '', name: 'Value'),
        );
        for (final label in ['First', 'Second']) {
          final _ = await tables.createRecord(
            table: table,
            values: {
              table.labelColumnId: label,
              table.columns.last.id: 'Duplicate',
            },
          );
        }
        await tester.pumpWidget(
          TestableApp(
            child: WorkspaceColumnEditor(
              workspaceId: 'one',
              table: table,
              column: table.columns.last,
              onBack: () => saved = true,
            ),
            overrides: [
              workspaceTableUsecaseProvider('one')
                  .overrideWith((ref) async => tables),
            ],
            workspaceId: 'one',
          ),
        );

        return table;
      });
      if (table == null) fail('Missing prepared table');
      await _flush(tester);
      await tester.tap(find.text('Unique values'));
      await _flush(tester);
      final save = find.byWidgetPredicate(
        (widget) =>
            widget is AuraButton &&
            widget.identifier == 'workspace_column_save',
      );
      await tester.runAsync(() => tester.tap(save));
      await _flush(tester);
      expect(saved, false);
      expect(find.textContaining('First ('), findsOneWidget);
      expect(find.textContaining('Second ('), findsOneWidget);
      await tester.ensureVisible(
        find.text('Create a separate replacement column'),
      );
      await tester.tap(find.text('Create a separate replacement column'));
      await _flush(tester);
      await tester.ensureVisible(save);
      await tester.runAsync(() => tester.tap(save));
      await _flush(tester);
      expect(saved, true);
      await tester.runAsync(() async {
        final current = await tables.table(table.id);
        expect(current.columns.length, 3);
        expect(
          (await tables.records(table.id)).first.values[table.columns.last.id],
          'Duplicate',
        );
      });
    },
  );
  testWidgets(
    'ordinary controls add a number column and retain zero in a record',
    (tester) async {
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
        final table = await tables.create(name: 'My list', labelName: 'Title');
        await tester.pumpWidget(
          TestableApp(
            child: WorkspaceTableScreen(
              workspaceId: 'one',
              tableId: table.id,
              onBack: () => fail('Unexpected table exit'),
            ),
            overrides: [
              appDatabaseProvider.overrideWithValue(database),
              workspaceRecordQueryProvider.overrideWith(
                (ref, arguments) async =>
                    const WorkspaceRecordPage(records: [], hasMore: false),
              ),
              workspaceTableUsecaseProvider('one')
                  .overrideWith((ref) async => tables),
            ],
            workspaceId: 'one',
          ),
        );
      });
      Future<void> flush() async {
        await tester.pump();
        await tester.runAsync(() async {
          final _ = await database.customSelect('SELECT 1').get();
        });
        await tester.runAsync(() async {
          final _ = await tester.pumpAndSettle();
        });
      }

      Finder button(String id) => find.byWidgetPredicate(
        (widget) => switch (widget) {
          final AuraButton button => button.identifier == id,
          final AuraIconButton button => button.identifier == id,
          _ => false,
        },
      );
      Finder input(String id) => find.byWidgetPredicate(
        (widget) => widget is AuraInput && widget.identifier == id,
      );
      await flush();
      await tester.tap(
        find.byWidgetPredicate(
          (widget) =>
              widget is AuraPopupMenuButton &&
              widget.identifier == 'workspace_table_overflow',
        ),
      );
      await flush();
      await tester.tap(find.text('Table settings'));
      await flush();
      await tester.tap(button('workspace_column_create'));
      await flush();
      await tester.enterText(input('workspace_column_name'), 'Count');
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
      expect(find.text('Required'), findsNothing);
      await tester.tap(find.byType(AuraCheckboxListTile).last);
      await flush();
      await tester.enterText(input('workspace_column_default'), '2.5');
      await tester.runAsync(() => tester.tap(button('workspace_column_save')));
      await flush();
      expect(find.text('Count'), findsOneWidget);
      await tester.tap(button('workspace_record_create'));
      await flush();
      final number = find.byWidgetPredicate(
        (widget) => widget is AuraInput && widget.keyboardType?.index == 2,
      );
      expect(tester.widget<AuraInput>(number).controller?.text, '2.5');
      await tester.enterText(number, 'bad');
      await tester.runAsync(() => tester.tap(button('workspace_record_save')));
      await flush();
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is TextLocale &&
              widget.data == LocaleKeys.workspace_items_invalid_table,
        ),
        findsOneWidget,
      );
      expect(find.text('bad'), findsOneWidget);
      await tester.enterText(number, '0');
      await tester.runAsync(() => tester.tap(button('workspace_record_save')));
      await flush();
      await tester.runAsync(() async {
        final table = (await tables.list()).single;
        expect(table.columns.last.isRequired, false);
        expect(table.columns.last.defaultValue, 2.5);
        final record = (await tables.records(table.id)).single;
        expect(record.values[table.columns.last.id], 0);
        expect(record.values.containsKey(table.columns.last.id), true);
      });
    },
  );
}

Future<void> _flush(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
  }
  final _ = await tester.pumpAndSettle();
}
