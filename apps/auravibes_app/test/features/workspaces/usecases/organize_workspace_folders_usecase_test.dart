import 'dart:convert';
import 'dart:io';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/cloud_workspace_folder_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_folder_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_folder.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_resource_store.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_folders_usecase.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'create and browse nested folders without crossing workspaces',
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
      final _ = await database
          .into(database.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              id: const Value('two'),
              name: 'Two',
              type: .local,
            ),
          );
      final folders = OrganizeWorkspaceFoldersUsecase(
        LocalWorkspaceFolderRepository(database, 'one'),
      );
      final other = OrganizeWorkspaceFoldersUsecase(
        LocalWorkspaceFolderRepository(database, 'two'),
      );
      expect(await folders.list(), isEmpty);
      final parent = await folders.create(name: '  Documents  ');
      final child = await folders.create(name: 'Personal', parentId: parent.id);
      expect((await folders.list()).single.name, 'Documents');
      expect((await folders.list(parentId: parent.id)).single.id, child.id);
      expect(await other.list(), isEmpty);
      await expectLater(
        other.create(name: 'Invalid', parentId: parent.id),
        throwsA(isA<WorkspaceFolderException>()),
      );
      await expectLater(
        Future.sync(() => folders.create(name: '   ')),
        throwsA(isA<WorkspaceFolderException>()),
      );
    },
  );

  test(
    'cloud folders create through patches and browse paginated state',
    () async {
      final rows = <WorkspaceResource>[];
      final store = CloudWorkspaceResourceStore.forTesting(
        watch: (_) => const Stream.empty(),
        patch: ({required requestId, required operations}) async {
          final operation = operations.single;
          expect(operation.resourceKind, WorkspaceResourceKind.folder);
          expect(operation.operation, WorkspacePatchOperationKind.create);
          final now = DateTime.now().toUtc();
          rows.add(
            WorkspaceResource(
              workspaceId: 1,
              resourceKind: .folder,
              resourceId: operation.resourceId,
              data: operation.data ?? (throw StateError('Missing payload')),
              revision: 1,
              createdAt: now,
              updatedAt: now,
            ),
          );

          return PatchWorkspaceStateResponse(
            resources: [rows.last],
            sequence: rows.length,
          );
        },
        putSecret: (_) => throw StateError('Unexpected secret write'),
        mutateCredential: (_) =>
            throw StateError('Unexpected credential mutation'),
        read: ({required pages, required eventLimit, afterSequence}) async {
          final request = pages.single;
          final index = request.afterResourceId == null ? 0 : 1;
          final page = rows.skip(index).take(1).toList();

          return ReadWorkspaceStateResponse(
            pages: [
              WorkspaceResourcePage(
                resourceKind: .folder,
                resources: page,
                nextResourceId: rows.length > index + 1
                    ? page.single.resourceId
                    : null,
              ),
            ],
            currentSequence: rows.length,
            events: [],
            requiresSnapshot: false,
          );
        },
      );
      final folders = OrganizeWorkspaceFoldersUsecase(
        CloudWorkspaceFolderRepository(store),
      );
      expect(await folders.list(), isEmpty);
      final parent = await folders.create(name: '  Documents  ');
      final child = await folders.create(name: 'Personal', parentId: parent.id);
      expect((await folders.list()).single.name, 'Documents');
      expect((await folders.list(parentId: parent.id)).single.id, child.id);
      expect(
        (jsonDecode(rows.last.data) as Map<String, dynamic>)['parentId'],
        parent.id,
      );
    },
  );

  test('local folders remain available after database reopen', () async {
    final directory = await Directory.systemTemp.createTemp(
      'workspace-folders-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/folders.sqlite');
    final database = AppDatabase(connection: NativeDatabase(file));
    final _ = await database
        .into(database.workspaces)
        .insert(
          WorkspacesCompanion.insert(
            id: const Value('one'),
            name: 'One',
            type: .local,
          ),
        );
    final first = OrganizeWorkspaceFoldersUsecase(
      LocalWorkspaceFolderRepository(database, 'one'),
    );
    final created = await first.create(name: 'Documents');
    await database.close();
    final reopened = AppDatabase(connection: NativeDatabase(file));
    addTearDown(reopened.close);
    final folders = OrganizeWorkspaceFoldersUsecase(
      LocalWorkspaceFolderRepository(reopened, 'one'),
    );
    expect((await folders.list()).single.id, created.id);
    expect((await folders.list()).single.name, 'Documents');
  });
}
