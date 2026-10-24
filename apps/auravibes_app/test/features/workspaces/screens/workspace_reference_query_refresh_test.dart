import 'dart:async';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/local_workspace_table_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_tables_usecase.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_query_filter.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_record_browser.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_reference_record_dialog.dart';
import 'package:auravibes_app/providers/app_providers.dart';
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
  testWidgets('linked detail saves refresh the mounted bounded grid', (
    tester,
  ) async {
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
      var table = await tables.create(name: 'Items', labelName: 'Title');
      table = await tables.saveColumn(
        table: table,
        column: .new(
          id: '',
          name: 'Related',
          type: .reference,
          targetTableId: table.id,
        ),
      );
      final first = await tables.createRecord(
        table: table,
        values: {table.labelColumnId: 'Before'},
      );
      final _ = await tables.createRecord(
        table: table,
        values: {
          table.labelColumnId: 'Source',
          table.columns.last.id: first.id,
        },
      );
      await tester.pumpWidget(
        TestableApp(
          child: WorkspaceRecordBrowser(
            workspaceId: 'one',
            table: table,
            onRecord: (_) => fail('Unexpected direct record open'),
          ),
          overrides: [appDatabaseProvider.overrideWithValue(database)],
          workspaceId: 'one',
        ),
      );
    });
    Future<void> flush() async {
      await tester.pump();
      await tester.runAsync(() async {
        final _ = await tester.pumpAndSettle();
      });
    }

    await flush();
    expect(find.text('Before'), findsNWidgets(2));
    final link = find.ancestor(
      of: find.text('Before'),
      matching: find.byType(AuraButton),
    );
    await tester.tap(link);
    await flush();
    final input = find.byWidgetPredicate(
      (widget) =>
          widget is AuraInput && widget.identifier == 'workspace_record_value',
    );
    await tester.enterText(input, 'After');
    final save = find.byWidgetPredicate(
      (widget) =>
          widget is AuraButton && widget.identifier == 'workspace_record_save',
    );
    await tester.ensureVisible(save);
    await flush();
    await tester.runAsync(() => tester.tap(save));
    await flush();
    expect(find.text('Before'), findsNothing);
    expect(find.text('After'), findsNWidgets(2));
    await tester.pumpWidget(const SizedBox.shrink());
  });
  for (final reference in [false, true]) {
    testWidgets('dialog retains ${reference ? 'reference' : 'multi'} filter', (
      tester,
    ) async {
      final database = AppDatabase(connection: NativeDatabase.memory());
      addTearDown(database.close);
      final repository = LocalWorkspaceTableRepository(database, 'one');
      var table = const WorkspaceTable(
        id: 'pending',
        name: 'Pending',
        labelColumnId: 'label',
        columns: [],
        revision: 0,
        schemaRevision: 0,
      );
      var targetId = '';
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
        final tables = OrganizeWorkspaceTablesUsecase(repository);
        table = await tables.create(name: 'Items', labelName: 'Title');
        table = await tables.saveColumn(
          table: table,
          column: const WorkspaceColumn(
            id: '',
            name: 'Tags',
            type: .multiSelect,
            options: ['One', 'Two'],
          ),
        );
        table = await tables.saveColumn(
          table: table,
          column: .new(
            id: '',
            name: 'Related',
            type: .reference,
            targetTableId: table.id,
          ),
        );
        final first = await tables.createRecord(
          table: table,
          values: {
            table.labelColumnId: 'Target',
            table.columns[1].id: ['One'],
          },
        );
        targetId = first.id;
        if (reference) {
          final _ = await tables.updateRecord(
            table: table,
            record: first,
            values: {...first.values, table.columns[2].id: first.id},
          );
        }
        final _ = await tables.createRecord(
          table: table,
          values: {
            table.labelColumnId: 'Source',
            table.columns[1].id: ['One'],
            table.columns[2].id: first.id,
          },
        );
        final _ = await tables.createRecord(
          table: table,
          values: {
            table.labelColumnId: 'Excluded',
            table.columns[1].id: ['Two'],
          },
        );
        await tester.pumpWidget(
          TestableApp(
            child: WorkspaceRecordBrowser(
              workspaceId: 'one',
              table: table,
              onRecord: (_) => fail('Unexpected direct record open'),
            ),
            overrides: [appDatabaseProvider.overrideWithValue(database)],
            workspaceId: 'one',
          ),
        );
      });
      Future<void> flush() async {
        await tester.pump();
        await tester.runAsync(() async {
          final _ = await tester.pumpAndSettle();
        });
      }

      Finder button(String id) => find.byWidgetPredicate(
        (widget) => widget is AuraButton && widget.identifier == id,
      );
      final tune = find.byWidgetPredicate(
        (widget) =>
            widget is AuraIconButton &&
            widget.identifier == 'workspace_query_controls',
      );
      await flush();
      await tester.tap(tune);
      await flush();
      await tester.tap(find.byType(AuraDropdownSelector<String>).first);
      await flush();
      await tester.tap(find.text(reference ? 'Related' : 'Tags').first);
      await flush();
      if (reference) {
        await tester.ensureVisible(button('workspace_filter_reference'));
        await flush();
        await tester.tap(button('workspace_filter_reference'));
        await flush();
        await tester.tap(find.text('Target').last);
        await tester.tap(find.text('Done'));
      } else {
        await tester.tap(
          find.byWidgetPredicate(
            (widget) =>
                widget is AuraDropdownSelector<String> &&
                widget.identifier == 'workspace_filter_option',
          ),
        );
        await flush();
        await tester.tap(
          find
              .ancestor(
                of: find.text('One'),
                matching: find.byType(AuraPressable),
              )
              .last,
        );
      }
      await flush();
      await tester.ensureVisible(button('workspace_filter_apply'));
      await flush();
      expect(
        tester.widget<AuraButton>(button('workspace_filter_apply')).disabled,
        isFalse,
      );
      await tester.tap(button('workspace_filter_apply'));
      await flush();
      final query = tester
          .widget<WorkspaceQueryFilter>(find.byType(WorkspaceQueryFilter))
          .query;
      expect(query.value.filterColumnId, table.columns[reference ? 2 : 1].id);
      expect(query.value.filterValue, reference ? targetId : 'One');
      await tester.tap(tune);
      await flush();
      expect(find.text('Excluded'), findsNothing);
      Future<void> open({bool create = false}) async {
        final context = tester.element(find.byType(WorkspaceRecordBrowser));
        await tester.runAsync(() async {
          final record = create
              ? null
              : await repository.record(table.id, targetId);
          unawaited(
            WorkspaceReferenceRecordDialog.open(context, 'one', (
              table: table,
              record: record,
              onSaved: null,
            )),
          );
        });
        await flush();
      }

      Future<void> save() async {
        final save = button('workspace_record_save');
        await tester.ensureVisible(save);
        await flush();
        await tester.runAsync(() => tester.tap(save));
        await flush();
      }

      Finder one() => find.byWidgetPredicate(
        (widget) =>
            widget is AuraCheckboxListTile &&
            widget.semanticLabel == 'Tags: One',
      );
      Future<void> chooseTarget() async {
        await tester.tap(find.text('Choose records').hitTestable().last);
        await flush();
        await tester.tap(find.text('Updated').last);
        await tester.tap(find.text('Done'));
        await flush();
      }

      await open();
      await tester.enterText(
        find.byWidgetPredicate(
          (widget) =>
              widget is AuraInput &&
              widget.identifier == 'workspace_record_value',
        ),
        'Updated',
      );
      if (reference) {
        await tester.tap(find.text('Clear selection').hitTestable().last);
      } else {
        await tester.ensureVisible(one());
        await flush();
        await tester.tap(one());
      }
      await save();
      expect(find.text('Target'), findsNothing);
      expect(find.text('Updated'), findsOneWidget);
      expect(find.text('Excluded'), findsNothing);
      await open();
      if (reference) {
        await chooseTarget();
      } else {
        await tester.ensureVisible(one());
        await flush();
        await tester.tap(one());
      }
      await save();
      expect(find.text('Updated'), findsNWidgets(reference ? 3 : 2));
      expect(find.text('Excluded'), findsNothing);
      await open(create: true);
      await tester.tap(
        find.byWidgetPredicate(
          (widget) =>
              widget is AuraCheckboxListTile && widget.semanticLabel == 'Title',
        ),
      );
      await flush();
      await tester.enterText(
        find.byWidgetPredicate(
          (widget) =>
              widget is AuraInput &&
              widget.identifier == 'workspace_record_value',
        ),
        'New',
      );
      if (reference) {
        await chooseTarget();
      } else {
        await tester.tap(
          find.byWidgetPredicate(
            (widget) =>
                widget is AuraCheckboxListTile &&
                widget.semanticLabel == 'Tags',
          ),
        );
        await flush();
        await tester.tap(one());
      }
      await save();
      expect(find.text('New'), findsOneWidget);
      expect(query.value.filterColumnId, table.columns[reference ? 2 : 1].id);
      expect(query.value.filterValue, reference ? targetId : 'One');
      expect(find.text('Excluded'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
