import 'dart:async';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/local_workspace_folder_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_trash_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_revision.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_trash_target.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_history_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_trash_provider.dart';
import 'package:auravibes_app/features/workspaces/usecases/manage_workspace_history_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/manage_workspace_trash_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_folders_usecase.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_trash_actions.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_trash_panel.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:drift/native.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/test_app.dart';

class _DelayedHistory extends Mock implements WorkspaceHistoryRepository;

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });
  testWidgets('delete all survives rows disappearing during confirmation', (
    tester,
  ) async {
    const target = WorkspaceTrashTarget(
      kind: .folder,
      id: 'folder',
      revision: 1,
    );
    const batch = WorkspaceTrashBatch(
      id: 'batch',
      target: target,
      name: 'Deleted folder',
      affectedCount: 1,
    );
    var rows = <WorkspaceTrashBatch>[batch];
    final history = _DelayedHistory();
    final delete = Completer<void>();
    when(() => history.permanentlyDelete(target))
        .thenAnswer((_) => delete.future);
    await tester.runAsync(
      () => tester.pumpWidget(
        TestableApp(
          child: const Scaffold(
            body: WorkspaceTrashPanel(workspaceId: 'local'),
          ),
          overrides: [
            workspaceTrashProvider('local').overrideWith((ref) async => rows),
            workspaceHistoryUsecaseProvider('local').overrideWith(
              (ref) async => ManageWorkspaceHistoryUsecase(history),
            ),
          ],
          workspaceId: 'local',
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();
    final deleteAll = find.byWidgetPredicate(
      (widget) =>
          widget is AuraIconButton &&
          widget.identifier == 'workspace_trash_delete_all',
    );
    await tester.tap(deleteAll);
    final _ = await tester.pumpAndSettle();
    rows = [];
    ProviderScope.containerOf(tester.element(find.byType(WorkspaceTrashPanel)))
        .invalidate(workspaceTrashProvider('local'));
    await tester.pump();
    final _ = await tester.pumpAndSettle();
    expect(deleteAll, findsNothing);
    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is AuraButton &&
            widget.identifier == 'workspace_history_confirm',
      ),
    );
    await tester.pump();
    verify(() => history.permanentlyDelete(target)).called(1);
    delete.complete();
    final _ = await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  for (final width in [400.0, 1200.0]) {
    testWidgets(
      'trash confirmation and recovery keep stable identities at $width',
      (tester) async {
        tester.view.devicePixelRatio = 1;
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
        final folders = OrganizeWorkspaceFoldersUsecase(
          LocalWorkspaceFolderRepository(database, 'local'),
        );
        final folder = await folders.create(name: 'Recover me');
        final trash = ManageWorkspaceTrashUsecase(
          LocalWorkspaceTrashRepository(database, 'local'),
        );
        await tester.runAsync(
          () => tester.pumpWidget(
            TestableApp(
              child: Consumer(
                builder: (context, ref, _) => Column(
                  children: [
                    AuraButton(
                      onPressed: () => unawaited(
                        WorkspaceTrashActions.trash(
                          context,
                          ref,
                          'local',
                          .new(
                            kind: .folder,
                            id: folder.id,
                            revision: folder.revision,
                          ),
                        ),
                      ),
                      child: const Text('Trash fixture'),
                      identifier: 'start_trash',
                    ),
                    AuraButton(
                      onPressed: () =>
                          unawaited(WorkspaceTrashPanel.open(context, 'local')),
                      child: const Text('Recovery fixture'),
                      identifier: 'open_trash',
                    ),
                  ],
                ),
              ),
              overrides: [
                workspaceTrashUsecaseProvider('local')
                    .overrideWith((ref) async => trash),
              ],
              workspaceId: 'local',
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();
        Finder button(String id) => find.byWidgetPredicate(
          (widget) => widget is AuraButton && widget.identifier == id,
        );
        await tester.tap(button('start_trash'));
        final _ = await tester.pumpAndSettle();
        expect(button('workspace_trash_confirm'), findsOneWidget);
        await tester.tap(button('workspace_trash_cancel'));
        final _ = await tester.pumpAndSettle();
        expect((await folders.list()).single.id, folder.id);
        await tester.tap(button('start_trash'));
        final _ = await tester.pumpAndSettle();
        await tester.tap(button('workspace_trash_confirm'));
        final _ = await tester.pumpAndSettle();
        expect(await folders.list(), isEmpty);
        final batch = (await trash.list()).single;
        await tester.tap(button('open_trash'));
        final _ = await tester.pumpAndSettle();
        final before = tester.getSize(find.byType(WorkspaceTrashPanel));
        await tester.tap(
          find.byWidgetPredicate(
            (widget) =>
                widget is AuraPopupMenuButton &&
                widget.identifier == 'workspace_trash_menu_${batch.id}',
          ),
        );
        final _ = await tester.pumpAndSettle();
        await tester.tap(find.text('Restore').last);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(await folders.list(), isEmpty);
        await tester.tap(button('workspace_history_confirm'));
        final _ = await tester.pumpAndSettle();
        expect(tester.getSize(find.byType(WorkspaceTrashPanel)), before);
        expect((await folders.list()).single.id, folder.id);
        expect(await trash.list(), isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
