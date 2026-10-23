import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/local_workspace_folder_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_table_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_folder.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_folders_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_tables_provider.dart';
import 'package:auravibes_app/features/workspaces/screens/workspace_items_screen.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_folders_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_tables_usecase.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_editor.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
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

  for (final key in [
    LocaleKeys.cloud_errors_permission_denied,
    LocaleKeys.cloud_errors_unavailable,
  ]) {
    testWidgets('folder browsing shows $key', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          TestableApp(
            child: const WorkspaceItemsScreen(workspaceId: 'one'),
            overrides: [
              workspaceTablesProvider.overrideWith(
                (ref, arguments) async => [],
              ),
              workspaceFoldersProvider('one', null).overrideWith((ref) async {
                throw CloudAppException(localizationKey: key, context: .state);
              }),
            ],
            workspaceId: 'one',
          ),
        );
      });
      final _ = await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (widget) => widget is TextLocale && widget.data == key,
        ),
        findsOneWidget,
      );
    });
  }

  testWidgets('denied metadata save preserves the editable draft', (
    tester,
  ) async {
    var closed = false;
    await tester.runAsync(() async {
      await tester.pumpWidget(
        TestableApp(
          child: WorkspaceItemEditor(
            workspaceId: 'one',
            name: 'Original',
            parentId: null,
            parentName: null,
            onBack: () => closed = true,
            onSave: (name, parentId) async {
              throw const WorkspaceTableException(denied: true);
            },
          ),
          overrides: [
            workspaceFoldersProvider.overrideWith((ref, arguments) async => []),
          ],
          workspaceId: 'one',
        ),
      );
    });
    final _ = await tester.pumpAndSettle();
    final input = find.byWidgetPredicate(
      (widget) =>
          widget is AuraInput && widget.identifier == 'workspace_item_name',
    );
    await tester.enterText(input, 'Preserved draft');
    final save = find.byWidgetPredicate(
      (widget) =>
          widget is AuraButton && widget.identifier == 'workspace_item_save',
    );
    await tester.tap(save);
    final _ = await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextLocale &&
            widget.data == LocaleKeys.cloud_errors_permission_denied,
      ),
      findsOneWidget,
    );
    expect(tester.widget<AuraInput>(input).controller?.text, 'Preserved draft');
    expect(tester.widget<AuraButton>(save).disabled, isFalse);
    expect(closed, isFalse);
  });

  testWidgets('table controls move and reopen the same records', (
    tester,
  ) async {
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
    final folders = OrganizeWorkspaceFoldersUsecase(
      LocalWorkspaceFolderRepository(database, 'one'),
    );
    final tables = OrganizeWorkspaceTablesUsecase(
      LocalWorkspaceTableRepository(database, 'one'),
    );
    final destination = await folders.create(name: 'Archive');
    final table = await tables.create(
      name: 'Original table',
      labelName: 'Title',
    );
    final record = await tables.createRecord(
      table: table,
      values: {table.labelColumnId: 'Preserved record'},
    );
    await tester.runAsync(() async {
      await tester.pumpWidget(
        TestableApp(
          child: const WorkspaceItemsScreen(workspaceId: 'one'),
          overrides: [
            workspaceTableUsecaseProvider('one')
                .overrideWith((ref) async => tables),
            workspaceFolderUsecaseProvider('one')
                .overrideWith((ref) async => folders),
          ],
          workspaceId: 'one',
        ),
      );
    });
    final _ = await tester.pumpAndSettle();
    final edit = find.byWidgetPredicate(
      (widget) =>
          widget is AuraIconButton &&
          widget.identifier == 'workspace_item_edit_${table.id}',
    );
    await tester.ensureVisible(edit);
    await tester.tap(edit);
    final _ = await tester.pumpAndSettle();
    await tester.enterText(
      find.byWidgetPredicate(
        (widget) =>
            widget is AuraInput && widget.identifier == 'workspace_item_name',
      ),
      'Renamed table',
    );
    await tester.tap(find.text('Archive'));
    final _ = await tester.pumpAndSettle();
    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is AuraButton && widget.identifier == 'workspace_item_save',
      ),
    );
    final _ = await tester.pumpAndSettle();
    expect(await tables.list(), isEmpty);
    final archive = find.text('Archive');
    await tester.ensureVisible(archive);
    await tester.tap(archive);
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('Renamed table'));
    final _ = await tester.pumpAndSettle();
    expect(find.text('Preserved record'), findsOneWidget);
    expect((await tables.list(parentId: destination.id)).single.id, table.id);
    expect((await tables.record(table.id, record.id)).values, {
      table.labelColumnId: 'Preserved record',
    });
  });

  testWidgets('read-only items expose disabled edit controls', (tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        TestableApp(
          child: const WorkspaceItemsScreen(workspaceId: 'one'),
          overrides: [
            workspaceTablesProvider.overrideWith(
              (ref, arguments) async => [
                const WorkspaceTable(
                  id: 'read-only-table',
                  name: 'Readable table',
                  labelColumnId: 'label',
                  columns: [.new(id: 'label', name: 'Title')],
                  revision: 1,
                  schemaRevision: 1,
                  canManage: false,
                ),
              ],
            ),
            workspaceFoldersProvider.overrideWith(
              (ref, arguments) async => [
                const WorkspaceFolder(
                  id: 'read-only',
                  name: 'Readable',
                  revision: 1,
                  canManage: false,
                ),
              ],
            ),
          ],
          workspaceId: 'one',
        ),
      );
    });
    final _ = await tester.pumpAndSettle();
    final button = tester.widget<AuraIconButton>(
      find.byWidgetPredicate(
        (widget) =>
            widget is AuraIconButton &&
            widget.identifier == 'workspace_item_edit_read-only',
      ),
    );
    expect(button.disabled, isTrue);
    final tableButton = tester.widget<AuraIconButton>(
      find.byWidgetPredicate(
        (widget) =>
            widget is AuraIconButton &&
            widget.identifier == 'workspace_item_edit_read-only-table',
      ),
    );
    expect(tableButton.disabled, isTrue);
  });

  testWidgets('folder controls rename and move to another folder', (
    tester,
  ) async {
    final folders = OrganizeWorkspaceFoldersUsecase(_MemoryFolders());
    final original = await folders.create(name: 'Original');
    final destination = await folders.create(name: 'Archive');
    await tester.runAsync(() async {
      await tester.pumpWidget(
        TestableApp(
          child: const WorkspaceItemsScreen(workspaceId: 'one'),
          overrides: [
            workspaceTablesProvider.overrideWith((ref, arguments) async => []),
            workspaceFolderUsecaseProvider('one')
                .overrideWith((ref) async => folders),
          ],
          workspaceId: 'one',
        ),
      );
    });
    final _ = await tester.pumpAndSettle();
    final edit = find.byWidgetPredicate(
      (widget) =>
          widget is AuraIconButton &&
          widget.identifier == 'workspace_item_edit_${original.id}',
    );
    await tester.ensureVisible(edit);
    await tester.tap(edit);
    final _ = await tester.pumpAndSettle();
    await tester.enterText(
      find.byWidgetPredicate(
        (widget) =>
            widget is AuraInput && widget.identifier == 'workspace_item_name',
      ),
      'Renamed',
    );
    await tester.tap(find.text('Archive'));
    final _ = await tester.pumpAndSettle();
    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is AuraButton && widget.identifier == 'workspace_item_save',
      ),
    );
    final _ = await tester.pumpAndSettle();
    expect((await folders.list()).map((item) => item.id), [destination.id]);
    final moved = (await folders.list(parentId: destination.id)).single;
    expect(moved.id, original.id);
    expect(moved.name, 'Renamed');
  });

  testWidgets('empty workspace creates and opens a user-named folder', (
    tester,
  ) async {
    final folders = OrganizeWorkspaceFoldersUsecase(_MemoryFolders());
    await tester.runAsync(() async {
      await tester.pumpWidget(
        TestableApp(
          child: const WorkspaceItemsScreen(workspaceId: 'one'),
          overrides: [
            workspaceTablesProvider.overrideWith((ref, arguments) async => []),
            workspaceFolderUsecaseProvider('one')
                .overrideWith((ref) async => folders),
          ],
          workspaceId: 'one',
        ),
      );
    });
    final _ = await tester.pumpAndSettle();
    expect(
      find.text('No folders yet. Create a folder to get started.'),
      findsOneWidget,
    );
    await tester.enterText(
      find.byWidgetPredicate(
        (widget) =>
            widget is AuraInput && widget.identifier == 'workspace_folder_name',
      ),
      'My documents',
    );
    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is AuraButton &&
            widget.identifier == 'workspace_folder_create',
      ),
    );
    final _ = await tester.pumpAndSettle();
    expect(find.text('My documents'), findsOneWidget);
    await tester.tap(find.text('My documents'));
    final _ = await tester.pumpAndSettle();
    expect(
      find.text('No folders yet. Create a folder to get started.'),
      findsOneWidget,
    );
  });
}

class _MemoryFolders implements WorkspaceFolderRepository {
  final _folders = <WorkspaceFolder>[];

  @override
  Future<List<WorkspaceFolder>> list({String? parentId}) async =>
      _folders.where((folder) => folder.parentId == parentId).toList();

  @override
  Future<WorkspaceFolder> updateMetadata({
    required WorkspaceFolder folder,
    required String name,
    required String? parentId,
  }) async {
    final index = _folders.indexWhere((item) => item.id == folder.id);
    final updated = WorkspaceFolder(
      id: folder.id,
      name: name,
      revision: folder.revision + 1,
      parentId: parentId,
    );
    _folders[index] = updated;

    return updated;
  }

  @override
  Future<WorkspaceFolder> create({
    required String name,
    String? parentId,
  }) async {
    final folder = WorkspaceFolder(
      id: '${_folders.length}',
      name: name,
      revision: 1,
      parentId: parentId,
    );
    _folders.add(folder);

    return folder;
  }
}
