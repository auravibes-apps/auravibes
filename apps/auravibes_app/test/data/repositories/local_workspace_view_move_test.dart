import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/local_workspace_folder_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_table_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_view_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_view.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_tables_usecase.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'View move shares outer rollback and advances metadata revision only',
    () async {
      final database = AppDatabase(connection: NativeDatabase.memory());
      addTearDown(database.close);
      final _ = await database
          .into(database.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              id: const Value('one'),
              name: 'One',
              type: .local,
            ),
          );
      final folder = await LocalWorkspaceFolderRepository(
        database,
        'one',
      ).create(name: 'Destination');
      final table = await OrganizeWorkspaceTablesUsecase(
        LocalWorkspaceTableRepository(database, 'one'),
      ).create(name: 'Items', labelName: 'Title');
      final views = LocalWorkspaceViewRepository(database, 'one');
      final first = await views.save(
        WorkspaceView.create(
          name: 'Overview',
          table: table,
          columnIds: [table.labelColumnId],
        ),
        requestId: 'create',
      );
      await expectLater(
        database.transaction(() async {
          final _ = await views.move(
            first.id,
            expectedRevision: 1,
            parentId: folder.id,
          );
          final _ = await views.move(
            first.id,
            expectedRevision: 0,
            parentId: null,
          );
        }),
        throwsA(isA<WorkspaceTableException>()),
      );
      expect((await views.read(first.id)).revision, 1);
      expect((await views.read(first.id)).parentId, isNull);
      expect(await views.history(first.id), hasLength(1));
      final moved = await views.move(
        first.id,
        expectedRevision: 1,
        parentId: folder.id,
      );
      expect(moved.parentId, folder.id);
      expect(moved.revision, 2);
      expect(moved.definition.toJson(), first.definition.toJson());
      expect(moved.bindings, first.bindings);
      expect(await views.history(first.id), hasLength(2));
      await expectLater(
        views.move(first.id, expectedRevision: 2, parentId: 'missing'),
        throwsA(isA<WorkspaceTableException>()),
      );
      expect((await views.read(first.id)).revision, 2);
    },
  );
}
