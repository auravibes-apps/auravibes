import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/local_workspace_folder_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_table_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_view_repository.dart';
import 'package:auravibes_app/features/workspaces/screens/workspace_items_screen.dart';
import 'package:auravibes_app/features/workspaces/screens/workspace_view_screen.dart';
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
  for (final width in [400.0, 1200.0]) {
    testWidgets('Directory creates and reopens a View at $width', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = .new(width, 900);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final database = AppDatabase(connection: NativeDatabase.memory());
      addTearDown(database.close);
      String? folderId;
      String? savedViewId;
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
        ).create(name: 'Reports');
        folderId = folder.id;
        final table = await LocalWorkspaceTableRepository(
          database,
          'one',
        ).create(name: 'Contacts', labelName: 'Name', parentId: folder.id);
        final _ = await LocalWorkspaceTableRepository(
          database,
          'one',
        ).createRecord(table: table, values: {table.labelColumnId: 'Ada'});
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
      await tester.tap(find.text('Reports'));
      await flush();
      await tester.tap(find.byKey(const ValueKey('directory_create')));
      await flush();
      expect(find.text('View'), findsOneWidget);
      await tester.tap(find.text('View'));
      await flush();
      final name = find.byWidgetPredicate(
        (widget) =>
            widget is AuraInput && widget.identifier == 'workspace_view_name',
      );
      await tester.enterText(name, 'A report');
      await tester.tap(find.text('Reports').last);
      await flush();
      await tester.tap(find.text('Contacts').last);
      await flush();
      final create = find.byWidgetPredicate(
        (widget) =>
            widget is AuraButton &&
            widget.identifier == 'workspace_view_create',
      );
      await tester.ensureVisible(create);
      await flush();
      await tester.runAsync(() => tester.tap(create));
      await flush();
      expect(find.byType(WorkspaceViewScreen), findsOneWidget);
      expect(find.text('Ada'), findsWidgets);
      final back = find.byWidgetPredicate(
        (widget) =>
            widget is AuraIconButton &&
            widget.identifier == 'workspace_view_back',
      );
      await tester.tap(back);
      await flush();
      expect(find.text('A report'), findsOneWidget);
      expect(find.text('Reports'), findsOneWidget);
      await tester.tap(find.text('A report'));
      await flush();
      expect(find.byType(WorkspaceViewScreen), findsOneWidget);
      expect(find.text('Ada'), findsWidgets);
      await tester.runAsync(() async {
        final views = await LocalWorkspaceViewRepository(
          database,
          'one',
        ).list(parentId: folderId);
        savedViewId = views.single.id;
        expect(views.single.name, 'A report');
        expect(views.single.parentId, folderId);
      });
      await tester.tap(back);
      await flush();
      final menu = find.byWidgetPredicate(
        (widget) =>
            widget is AuraPopupMenuButton &&
            widget.identifier == 'workspace_item_edit_$savedViewId',
      );
      await tester.tap(menu);
      await flush();
      await tester.tap(find.text('Rename or move'));
      await flush();
      final itemName = find.byWidgetPredicate(
        (widget) =>
            widget is AuraInput && widget.identifier == 'workspace_item_name',
      );
      expect(itemName, findsOneWidget);
      await tester.enterText(itemName, 'Renamed report');
      await tester.tap(find.text('Workspace root'));
      await flush();
      final save = find.byWidgetPredicate(
        (widget) =>
            widget is AuraButton && widget.identifier == 'workspace_item_save',
      );
      await tester.ensureVisible(save);
      await flush();
      await tester.runAsync(() => tester.tap(save));
      await flush();
      expect(find.text('Renamed report'), findsNothing);
      final _ = await tester.binding.handlePopRoute();
      await flush();
      expect(find.text('Renamed report'), findsOneWidget);
      await tester.tap(find.text('Renamed report'));
      await flush();
      expect(find.text('Ada'), findsWidgets);
      await tester.runAsync(() async {
        final moved = await LocalWorkspaceViewRepository(
          database,
          'one',
        ).read(_required(savedViewId));
        expect(moved.name, 'Renamed report');
        expect(moved.parentId, isNull);
        expect(moved.revision, 2);
      });
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}

String _required(String? value) {
  if (value == null) throw StateError('Missing fixture ID');

  return value;
}
