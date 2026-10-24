import 'dart:async';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/local_workspace_history_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_table_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_trash_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_trash_target.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_history_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_trash_provider.dart';
import 'package:auravibes_app/features/workspaces/usecases/manage_workspace_history_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/manage_workspace_trash_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_tables_usecase.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_history_panel.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_trash_panel.dart';
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
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'history restore stays usable at width $width and text $scale',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          tester.view.physicalSize = .new(width, 800);
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final database = AppDatabase(connection: NativeDatabase.memory());
          addTearDown(database.close);
          final _ = await database
              .into(database.workspaces)
              .insert(
                WorkspacesCompanion.insert(
                  id: const .new('local'),
                  name: 'Local',
                  type: .local,
                ),
              );
          final tables = OrganizeWorkspaceTablesUsecase(
            LocalWorkspaceTableRepository(database, 'local'),
          );
          final table = await tables.create(name: 'Data', labelName: 'Name');
          final first = await tables.createRecord(
            table: table,
            values: {table.labelColumnId: 'Original value'},
          );
          final second = await tables.updateRecord(
            table: table,
            record: first,
            values: {table.labelColumnId: 'Current value'},
          );
          final history = ManageWorkspaceHistoryUsecase(
            LocalWorkspaceHistoryRepository(database, 'local'),
          );
          final target = WorkspaceTrashTarget(
            kind: .record,
            id: first.id,
            tableId: table.id,
            revision: second.revision,
          );
          await tester.runAsync(
            () => tester.pumpWidget(
              TestableApp(
                workspaceId: 'local',
                overrides: [
                  workspaceHistoryUsecaseProvider('local')
                      .overrideWith((ref) async => history),
                ],
                child: Builder(
                  builder: (context) => MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(textScaler: TextScaler.linear(scale)),
                    child: Builder(
                      builder: (context) => AuraButton(
                        identifier: 'open_history',
                        onPressed: () => unawaited(
                          WorkspaceHistoryPanel.open(context, 'local', target),
                        ),
                        child: const Text('History fixture'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await _settle(tester);
          Finder button(String id) => find.byWidgetPredicate(
            (widget) => widget is AuraButton && widget.identifier == id,
          );
          await tester.tap(button('open_history'));
          await _settle(tester);
          expect(find.text('Current value'), findsOneWidget);
          await tester.scrollUntilVisible(
            button('workspace_history_restore_1'),
            200,
          );
          expect(find.text('Original value'), findsOneWidget);
          await tester.ensureVisible(button('workspace_history_restore_1'));
          await tester.tap(button('workspace_history_restore_1'));
          final _ = await tester.pump();
          final _ = await tester.pump(const Duration(milliseconds: 400));
          await tester.ensureVisible(button('workspace_history_cancel'));
          await tester.tap(button('workspace_history_cancel'));
          await _settle(tester);
          expect((await tables.record(table.id, first.id)).revision, 2);
          await tester.tap(button('workspace_history_restore_1'));
          final _ = await tester.pump();
          final _ = await tester.pump(const Duration(milliseconds: 400));
          await tester.ensureVisible(button('workspace_history_confirm'));
          await tester.tap(button('workspace_history_confirm'));
          await _settle(tester);
          expect((await tables.record(table.id, first.id)).revision, 3);
          expect(
            (await tables.record(
              table.id,
              first.id,
            )).values[table.labelColumnId],
            'Original value',
          );
          expect(tester.takeException(), isNull);
        },
      );
      testWidgets(
        'permanent deletion confirms explicit batch at width $width and text $scale',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = .new(width, 800);
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final database = AppDatabase(connection: NativeDatabase.memory());
          addTearDown(database.close);
          final _ = await database
              .into(database.workspaces)
              .insert(
                WorkspacesCompanion.insert(
                  id: const .new('local'),
                  name: 'Local',
                  type: .local,
                ),
              );
          final tables = OrganizeWorkspaceTablesUsecase(
            LocalWorkspaceTableRepository(database, 'local'),
          );
          final table = await tables.create(name: 'Data', labelName: 'Name');
          final record = await tables.createRecord(
            table: table,
            values: {table.labelColumnId: 'Delete me'},
          );
          final trash = ManageWorkspaceTrashUsecase(
            LocalWorkspaceTrashRepository(database, 'local'),
          );
          final history = ManageWorkspaceHistoryUsecase(
            LocalWorkspaceHistoryRepository(database, 'local'),
          );
          final batch = await trash.apply(
            .new(
              kind: .record,
              id: record.id,
              tableId: table.id,
              revision: record.revision,
            ),
            approve: (_) async => true,
          );
          await tester.runAsync(
            () => tester.pumpWidget(
              TestableApp(
                workspaceId: 'local',
                overrides: [
                  workspaceHistoryUsecaseProvider('local')
                      .overrideWith((ref) async => history),
                  workspaceTrashUsecaseProvider('local')
                      .overrideWith((ref) async => trash),
                ],
                child: Builder(
                  builder: (context) => AuraButton(
                    identifier: 'open_trash',
                    onPressed: () =>
                        unawaited(WorkspaceTrashPanel.open(context, 'local')),
                    child: const Text('Trash fixture'),
                  ),
                ),
              ),
            ),
          );
          Finder button(String id) => find.byWidgetPredicate(
            (widget) => widget is AuraButton && widget.identifier == id,
          );
          await _settle(tester);
          await tester.tap(button('open_trash'));
          await _settle(tester);
          final purge = button('workspace_permanent_delete_${record.id}');
          await tester.scrollUntilVisible(purge, 200);
          await tester.tap(purge);
          final _ = await tester.pump();
          final _ = await tester.pump(const Duration(milliseconds: 400));
          await tester.ensureVisible(button('workspace_history_cancel'));
          await tester.tap(button('workspace_history_cancel'));
          await _settle(tester);
          expect((await trash.list()).single.id, batch!.id);
          await tester.tap(purge);
          final _ = await tester.pump();
          final _ = await tester.pump(const Duration(milliseconds: 400));
          await tester.ensureVisible(button('workspace_history_confirm'));
          await tester.tap(button('workspace_history_confirm'));
          await _settle(tester);
          expect(await trash.list(), isEmpty);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  final _ = await tester.pumpAndSettle();
}
