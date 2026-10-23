import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/local_workspace_table_repository.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_folders_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_tables_provider.dart';
import 'package:auravibes_app/features/workspaces/screens/workspace_items_screen.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_tables_usecase.dart';
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
    await tester.enterText(input('workspace_table_name'), 'Reading');
    await tester.runAsync(() => tester.tap(button('workspace_table_create')));
    await flush();

    expect(find.text('Reading'), findsOneWidget);
    await tester.enterText(input('workspace_label_column'), 'Book');
    await tester.runAsync(() => tester.tap(button('workspace_label_save')));
    await flush();

    await tester.tap(button('workspace_record_create'));
    await flush();
    expect(find.text('Book'), findsOneWidget);
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
  });
}
