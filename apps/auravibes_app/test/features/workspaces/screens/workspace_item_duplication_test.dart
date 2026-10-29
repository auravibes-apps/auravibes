import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/local_workspace_table_repository.dart';
import 'package:auravibes_app/features/workspaces/screens/workspace_items_screen.dart';
import 'package:auravibes_app/features/workspaces/screens/workspace_table_screen.dart';
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
  for (final layout in [
    (width: 400.0, height: 900.0, scale: 1.0, keyboard: false),
    (width: 400.0, height: 900.0, scale: 2.0, keyboard: false),
    (width: 1200.0, height: 900.0, scale: 1.0, keyboard: false),
    (width: 1200.0, height: 900.0, scale: 2.0, keyboard: false),
    (width: 400.0, height: 450.0, scale: 2.0, keyboard: true),
  ]) {
    final width = layout.width;
    final scale = layout.scale;
    testWidgets(
      'Directory duplicate defaults to schema only at $width/$scale/${layout.height}',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = .new(width, layout.height);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetViewInsets);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final database = AppDatabase(connection: NativeDatabase.memory());
        addTearDown(database.close);
        String? sourceId;
        final tables = LocalWorkspaceTableRepository(database, 'one');
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
          final table = await tables.create(
            name: 'Original',
            labelName: 'Title',
          );
          sourceId = table.id;
          final _ = await tables.createRecord(
            table: table,
            values: {table.labelColumnId: 'Private original record'},
          );
          await tester.pumpWidget(
            TestableApp(
              child: const WorkspaceItemsScreen(workspaceId: 'one'),
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
        await tester.tap(
          find.byWidgetPredicate(
            (widget) =>
                widget is AuraPopupMenuButton &&
                widget.identifier == 'workspace_item_edit_$sourceId',
          ),
        );
        await flush();
        await tester.tap(find.text('Duplicate'));
        await flush();
        expect(
          tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
          false,
        );
        final name = find.byWidgetPredicate(
          (widget) =>
              widget is AuraInput &&
              widget.identifier == 'workspace_duplicate_name',
        );
        await tester.enterText(name, 'Copied table');
        if (layout.keyboard) {
          tester.view.viewInsets = const FakeViewPadding(bottom: 180);
          await flush();
        }
        final save = find.byWidgetPredicate(
          (widget) =>
              widget is AuraButton &&
              widget.identifier == 'workspace_duplicate_submit',
        );
        await tester.ensureVisible(save);
        await tester.runAsync(() => tester.tap(save));
        await flush();
        expect(find.byType(WorkspaceTableScreen), findsOneWidget);
        expect(find.text('Copied table'), findsWidgets);
        expect(find.text('Private original record'), findsNothing);
        expect(tester.takeException(), isNull);
        final all = await tables.list();
        final copied = all.singleWhere((table) => table.name == 'Copied table');
        expect(await tables.records(copied.id), isEmpty);
      },
    );
  }
}
