import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/local_workspace_folder_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_record_query_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_reference_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_table_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_trash_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_view_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_trash_target.dart';
import 'package:auravibes_app/features/workspaces/usecases/manage_workspace_trash_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/manage_workspace_views_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_folders_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_tables_usecase.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('View tombstones block read/history/save replay and restore only their batch', () async {
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
    final tables = OrganizeWorkspaceTablesUsecase(
      LocalWorkspaceTableRepository(database, 'local'),
    );
    final trash = ManageWorkspaceTrashUsecase(
      LocalWorkspaceTrashRepository(database, 'local'),
    );
    final views = ManageWorkspaceViewsUsecase(
      LocalWorkspaceViewRepository(database, 'local'),
      tables,
      .new(LocalWorkspaceRecordQueryRepository(database, 'local')),
      .new(LocalWorkspaceReferenceRepository(database, 'local')),
    );
    final folder = await folders.create(name: 'Folder');
    final table = await tables.create(name: 'Data', labelName: 'Name');
    final first = await views.create(
      name: 'Earlier',
      table: table,
      columnIds: [table.labelColumnId],
      parentId: folder.id,
    );
    final saved = await views.save(first, requestId: 'once');
    final earlier = await _trash(
      trash,
      .new(kind: .view, id: saved.id, revision: saved.revision),
    );
    await expectLater(
      views.open(first.id),
      throwsA(isA<WorkspaceTableException>()),
    );
    await expectLater(
      views.history(first.id),
      throwsA(isA<WorkspaceTableException>()),
    );
    await expectLater(
      views.save(first, requestId: 'once'),
      throwsA(isA<WorkspaceTableException>()),
    );
    final second = await views.create(
      name: 'Current',
      table: table,
      columnIds: [table.labelColumnId],
      parentId: folder.id,
    );
    final batch = await _trash(
      trash,
      .new(kind: .folder, id: folder.id, revision: folder.revision),
    );
    expect(batch.affectedCount, 2);
    expect(await views.list(allFolders: true), isEmpty);
    final _ = await trash.restore(batch.id);
    expect((await views.list(allFolders: true)).single.id, second.id);
    final _ = await trash.restore(earlier.id);
    expect((await views.open(first.id)).view.revision, 4);
    expect((await views.history(first.id)).length, 3);
    final current = (await views.open(first.id)).view;
    final missingSource = await _trash(
      trash,
      .new(kind: .view, id: current.id, revision: current.revision),
    );
    final _ = await _trash(
      trash,
      .new(kind: .table, id: table.id, revision: table.revision),
    );
    final restored = await trash.restore(missingSource.id);
    expect(restored.unresolvedDependencies, isTrue);
  });
}

Future<WorkspaceTrashBatch> _trash(
  ManageWorkspaceTrashUsecase usecase,
  WorkspaceTrashTarget target,
) async =>
    await usecase.apply(target, approve: (_) async => true) ??
    (throw StateError('Expected approved trash'));
