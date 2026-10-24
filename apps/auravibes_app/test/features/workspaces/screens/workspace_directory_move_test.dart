import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/local_workspace_folder_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_table_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_view_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/screens/workspace_items_screen.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_failure.dart';
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
  for (final scenario in [
    (width: 400.0, stale: false),
    (width: 1200.0, stale: false),
    (width: 400.0, stale: true),
  ]) {
    final width = scenario.width;
    testWidgets(
      'mixed selection at $width preserves failures: ${scenario.stale}',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = .new(width, 900);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final database = AppDatabase(connection: NativeDatabase.memory());
        addTearDown(database.close);
        String? destinationId;
        String? tableId;
        String? viewId;
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
          final folders = LocalWorkspaceFolderRepository(database, 'one');
          destinationId = (await folders.create(name: 'Destination')).id;
          final _ = await folders.create(name: 'Source folder');
          final table = await LocalWorkspaceTableRepository(
            database,
            'one',
          ).create(name: 'Items', labelName: 'Title');
          tableId = table.id;
          final view = await LocalWorkspaceViewRepository(database, 'one').save(
            .create(
              name: 'Overview',
              table: table,
              columnIds: [table.labelColumnId],
            ),
            requestId: 'view',
          );
          viewId = view.id;
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
        await tester.longPress(find.text('Source folder'));
        await flush();
        await tester.tap(find.text('Items'));
        await tester.tap(find.text('Overview'));
        await flush();
        final move = find.byWidgetPredicate(
          (widget) =>
              widget is AuraButton && widget.identifier == 'directory_move',
        );
        expect(move, findsOneWidget);
        if (scenario.stale) {
          await tester.runAsync(() async {
            final tables = LocalWorkspaceTableRepository(database, 'one');
            final current = await tables.table(_required(tableId));
            final _ = await tables.updateMetadata(
              table: current,
              name: current.name,
              parentId: null,
            );
          });
        }
        await tester.tap(move);
        await flush();
        expect(find.text('Source folder').hitTestable(), findsNothing);
        await tester.tap(find.text('Destination').last);
        await flush();
        final submit = find.byWidgetPredicate(
          (widget) =>
              widget is AuraButton &&
              widget.identifier == 'directory_move_submit',
        );
        await tester.ensureVisible(submit);
        await flush();
        await tester.runAsync(() => tester.tap(submit));
        await flush();
        if (scenario.stale) {
          final failure = tester
              .widgetList<WorkspaceItemFailure>(
                find.byType(WorkspaceItemFailure),
              )
              .single
              .error;
          expect(
            failure,
            isA<WorkspaceTableException>().having(
              (error) => error.conflict,
              'conflict',
              true,
            ),
          );
          expect(submit, findsOneWidget);
          await tester.tap(find.text('Cancel'));
          await flush();
          expect(find.text('Selected: 3'), findsOneWidget);
          expect(find.text('Done'), findsOneWidget);
          expect(
            tester
                .widgetList<Checkbox>(find.byType(Checkbox))
                .where((checkbox) => checkbox.value == true),
            hasLength(3),
          );
          await tester.runAsync(() async {
            expect(
              (await LocalWorkspaceTableRepository(
                database,
                'one',
              ).table(_required(tableId))).parentId,
              isNull,
            );
            expect(
              (await LocalWorkspaceViewRepository(
                database,
                'one',
              ).read(_required(viewId))).revision,
              1,
            );
            expect(
              (await LocalWorkspaceFolderRepository(
                database,
                'one',
              ).list()).map((folder) => folder.name),
              contains('Source folder'),
            );
          });
          await tester.pumpWidget(const SizedBox.shrink());

          return;
        }
        expect(
          tester
              .widgetList<WorkspaceItemFailure>(
                find.byType(WorkspaceItemFailure),
              )
              .map((failure) => failure.error.toString()),
          isEmpty,
        );
        expect(find.text('Overview'), findsNothing);
        expect(find.text('Source folder'), findsNothing);
        expect(find.text('Items'), findsNothing);
        expect(find.text('Done'), findsNothing);
        await tester.tap(find.text('Destination'));
        await flush();
        expect(find.text('Source folder'), findsOneWidget);
        expect(find.text('Items'), findsOneWidget);
        expect(find.text('Overview'), findsOneWidget);
        await tester.runAsync(() async {
          expect(
            (await LocalWorkspaceTableRepository(
              database,
              'one',
            ).table(_required(tableId))).parentId,
            destinationId,
          );
          expect(
            (await LocalWorkspaceViewRepository(
              database,
              'one',
            ).read(_required(viewId))).parentId,
            destinationId,
          );
        });
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}

String _required(String? value) {
  if (value == null) throw StateError('Missing fixture ID');

  return value;
}
