import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/local_workspace_folder_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_table_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_folders_provider.dart';
import 'package:auravibes_app/features/workspaces/screens/workspace_items_screen.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_csv_dialog.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_failure.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:drift/native.dart';
import 'package:easy_localization/easy_localization.dart';
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
  for (final width in [400.0, 1200.0]) {
    testWidgets('Directory recovery and record/CSV menus work at $width', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = .new(width, 900);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final database = AppDatabase(connection: NativeDatabase.memory());
      addTearDown(database.close);
      String? folderId;
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
        final folder = await LocalWorkspaceFolderRepository(
          database,
          'one',
        ).create(name: 'Recover folder');
        folderId = folder.id;
        final tables = LocalWorkspaceTableRepository(database, 'one');
        final table = await tables.create(
          name: 'Records',
          labelName: 'Name',
          parentId: folder.id,
        );
        final _ = await tables.createRecord(
          table: table,
          values: {table.labelColumnId: 'Recover record'},
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

      Future<void> settleUntil(bool Function() ready) async {
        for (var attempt = 0; attempt < 50 && !ready(); attempt++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)),
          );
          await flush();
        }
        expect(
          ready(),
          isTrue,
          reason: tester
              .widgetList<Text>(find.byType(Text))
              .map((text) => text.data)
              .join(' | '),
        );
      }

      Finder menu(String id) => find.byWidgetPredicate(
        (widget) => widget is AuraPopupMenuButton && widget.identifier == id,
      );
      Finder button(String id) => find.byWidgetPredicate(
        (widget) => widget is AuraButton && widget.identifier == id,
      );
      await flush();
      await tester.tap(menu('workspace_item_edit_$folderId'));
      await flush();
      await tester.runAsync(() async {
        final folders = LocalWorkspaceFolderRepository(database, 'one');
        final folder = (await folders.list()).single;
        final _ = await folders.updateMetadata(
          folder: folder,
          name: folder.name,
          parentId: null,
        );
      });
      await tester.tap(find.text('Move to Trash'));
      await settleUntil(
        () => find.byType(WorkspaceItemFailure).evaluate().isNotEmpty,
      );
      expect(
        tester
            .widget<WorkspaceItemFailure>(find.byType(WorkspaceItemFailure))
            .error,
        isA<WorkspaceTableException>().having(
          (error) => error.conflict,
          'conflict',
          isTrue,
        ),
      );
      await tester.tap(find.text('Close'));
      await flush();
      await tester.tap(menu('workspace_directory_more'));
      await flush();
      await tester.tap(find.text('Reload'));
      await settleUntil(
        () =>
            ProviderScope.containerOf(
                  tester.element(find.byType(WorkspaceItemsScreen)),
                )
                .read(workspaceFoldersProvider('one', null))
                .value
                ?.single
                .revision ==
            2,
      );
      await flush();
      await tester.tap(menu('workspace_item_edit_$folderId'));
      await flush();
      await tester.tap(find.text('Move to Trash'));
      await flush();
      await settleUntil(
        () => button('workspace_trash_cancel').evaluate().isNotEmpty,
      );
      await tester.tap(button('workspace_trash_cancel'));
      await flush();
      expect(find.text('Recover folder'), findsOneWidget);
      await tester.tap(menu('workspace_item_edit_$folderId'));
      await flush();
      await tester.tap(find.text('Move to Trash'));
      await flush();
      await settleUntil(
        () => button('workspace_trash_confirm').evaluate().isNotEmpty,
      );
      await tester.runAsync(
        () => tester.tap(button('workspace_trash_confirm')),
      );
      await flush();
      await settleUntil(() => find.text('Recover folder').evaluate().isEmpty);
      expect(find.text('Recover folder'), findsNothing);
      await tester.tap(menu('workspace_directory_more'));
      await flush();
      await tester.tap(find.text('Trash'));
      await flush();
      await settleUntil(
        () => find
            .byWidgetPredicate(
              (widget) =>
                  widget is AuraPopupMenuButton &&
                  (widget.identifier?.startsWith('workspace_trash_menu_') ??
                      false),
            )
            .evaluate()
            .isNotEmpty,
      );
      await tester.tap(
        find.byWidgetPredicate(
          (widget) =>
              widget is AuraPopupMenuButton &&
              (widget.identifier?.startsWith('workspace_trash_menu_') ?? false),
        ),
      );
      await flush();
      await tester.tap(find.text('Restore'));
      await tester.pump();
      await tester.runAsync(
        () => tester.tap(button('workspace_history_confirm')),
      );
      await flush();
      await tester.tap(
        find.byWidgetPredicate(
          (widget) =>
              widget is AuraIconButton &&
              widget.identifier == 'workspace_trash_close',
        ),
      );
      await flush();
      expect(find.text('Recover folder'), findsOneWidget);
      await tester.tap(find.text('Recover folder'));
      await flush();
      await tester.tap(find.text('Records'));
      await flush();
      for (final importing in [true, false]) {
        await tester.tap(menu('workspace_table_overflow'));
        await flush();
        await tester.tap(find.text(importing ? 'Import CSV' : 'Export CSV'));
        await flush();
        expect(
          tester
              .widget<WorkspaceCsvDialog>(find.byType(WorkspaceCsvDialog))
              .importing,
          importing,
        );
        await settleUntil(
          () => !tester
              .widget<AuraButton>(button('workspace_csv_continue'))
              .disabled,
        );
        await tester.tap(find.text('Close'));
        await flush();
      }
      await tester.tap(find.text('Recover record'));
      await tester.pump(const Duration(milliseconds: 400));
      await flush();
      await tester.tap(find.byIcon(Icons.more_horiz));
      await tester.pump(const Duration(milliseconds: 400));
      await flush();
      final field = find.byWidgetPredicate(
        (widget) =>
            widget is AuraInput &&
            widget.identifier == 'workspace_record_value',
      );
      await settleUntil(() => field.evaluate().isNotEmpty);
      await tester.enterText(field, 'Uncommitted edit');
      await tester.tap(menu('workspace_record_overflow'));
      await flush();
      await tester.tap(find.text('Move to Trash'));
      await settleUntil(
        () => button('workspace_trash_cancel').evaluate().isNotEmpty,
      );
      await tester.tap(button('workspace_trash_cancel'));
      await flush();
      expect(find.text('Uncommitted edit'), findsOneWidget);

      await tester.tap(menu('workspace_record_overflow'));
      await flush();
      await tester.tap(find.text('Move to Trash'));
      await flush();
      await settleUntil(
        () => button('workspace_trash_confirm').evaluate().isNotEmpty,
      );
      await tester.runAsync(
        () => tester.tap(button('workspace_trash_confirm')),
      );
      await flush();
      await settleUntil(() => find.text('Recover record').evaluate().isEmpty);
      expect(find.text('Recover record'), findsNothing);
      await tester.tap(menu('workspace_table_overflow'));
      await flush();
      await tester.tap(find.text('Move to Trash'));
      await settleUntil(
        () => button('workspace_trash_confirm').evaluate().isNotEmpty,
      );
      await tester.runAsync(
        () => tester.tap(button('workspace_trash_confirm')),
      );
      await settleUntil(
        () => menu('workspace_directory_more').evaluate().isNotEmpty,
      );
      expect(find.text('Records'), findsNothing);

      expect(tester.takeException(), isNull);
    });
  }
}
