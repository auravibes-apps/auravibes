import 'dart:io';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/local_workspace_directory_move_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_item_duplication_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_record_query_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_reference_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_table_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_trash_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_view_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_directory_move_item.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_view.dart';
import 'package:auravibes_app/features/workspaces/usecases/duplicate_workspace_item_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/manage_workspace_trash_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/manage_workspace_views_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/move_workspace_directory_items_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/project_connected_workspace_view_usecase.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Connector-only View persists and restores without owned table',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'auravibes-connected-1686-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final file = File.fromUri(directory.uri.resolve('workspace.sqlite'));
      var database = AppDatabase(connection: NativeDatabase(file));
      addTearDown(() => database.close());
      final _ = await database
          .into(database.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              id: const Value('workspace'),
              name: 'Local',
              type: .local,
            ),
          );
      final views = ManageWorkspaceViewsUsecase(
        LocalWorkspaceViewRepository(database, 'workspace'),
        .new(LocalWorkspaceTableRepository(database, 'workspace')),
        .new(LocalWorkspaceRecordQueryRepository(database, 'workspace')),
        .new(LocalWorkspaceReferenceRepository(database, 'workspace')),
        validateConnected: (_) => Future<void>.value(),
      );
      final connector = connectorDefinitions.firstWhere(
        (item) => item.identifier == 'brave',
      );
      final tool = connector.tools.firstWhere(
        (item) => item.slug == 'web_search',
      );
      final draft = WorkspaceView.connectedDraft(name: 'Live').withConnected(
        .new(
          toolId: connectorToolId(connector, tool),
          revision: connectorToolRevision(connector, tool),
          inputs: const {'query': 'records'},
          connectionId: 'service:chosen',
        ),
      );
      final saved = await views.save(draft);
      expect(saved.isConnectedOnly, true);
      await expectLater(
        views.save(
          saved.withConnected(
            .new(
              toolId: connectorToolId(connector, tool),
              revision: connectorToolRevision(connector, tool),
              connectionId: 'service:chosen',
              inputs: {'query': 'x'.padRight(131073, 'x')},
            ),
          ),
        ),
        throwsA(isA<WorkspaceTableException>()),
      );

      expect((await views.open(saved.id)).view.connected?.inputs, {
        'query': 'records',
      });
      expect((await views.list()).single.id, saved.id);
      final renamed = await views.save(
        saved.edited(
          name: 'Renamed',
          definition: saved.definition,
          bindings: saved.bindings,
          columnTypes: saved.columnTypes,
        ),
      );
      expect(renamed.connected?.connectionId, 'service:chosen');
      final restored = await views.restore(
        renamed,
        saved,
        requestId: 'restore',
      );
      expect(restored.revision, 3);
      expect(restored.connected?.toolId, draft.connected?.toolId);
      await database.close();
      database = AppDatabase(connection: NativeDatabase(file));
      final reopened = await LocalWorkspaceViewRepository(
        database,
        'workspace',
      ).read(saved.id);
      expect(reopened.connected?.toJson(), restored.connected?.toJson());
      expect(reopened.isConnectedOnly, true);
      final move = MoveWorkspaceDirectoryItemsUsecase(
        LocalWorkspaceDirectoryMoveRepository(database, 'workspace'),
      );
      final items = <WorkspaceDirectoryMoveItem>[
        .new(
          key: (kind: .view, id: reopened.id),
          name: reopened.name,
          revision: reopened.revision,
          canManage: true,
          metadataName: 'Organized source',
        ),
      ];
      await move(items, null);
      final moved = await LocalWorkspaceViewRepository(
        database,
        'workspace',
      ).read(reopened.id);
      expect(moved.name, 'Organized source');
      final copied =
          await DuplicateWorkspaceItemUsecase(
            LocalWorkspaceItemDuplicationRepository(database, 'workspace'),
          )(
            .new(
              kind: .view,
              sourceId: moved.id,
              expectedRevision: moved.revision,
              targetId: 'source-copy',
              requestId: 'copy-source',
              name: 'Copied source',
            ),
            approve: () async => true,
          );
      expect(copied, true);
      final copy = await LocalWorkspaceViewRepository(
        database,
        'workspace',
      ).read('source-copy');
      expect(copy.connected?.toJson(), moved.connected?.toJson());
      final trash = ManageWorkspaceTrashUsecase(
        LocalWorkspaceTrashRepository(database, 'workspace'),
      );
      final batch = await trash.apply(
        .new(kind: .view, id: copy.id, revision: copy.revision),
        approve: (_) async => true,
      );
      if (batch == null) fail('Explicit Trash approval should apply');
      final recovery = await trash.restore(batch.id);
      expect(recovery.unresolvedDependencies, false);
      final recovered = await LocalWorkspaceViewRepository(
        database,
        'workspace',
      ).read(copy.id);
      expect(recovered.connected?.toJson(), copy.connected?.toJson());
    },
  );
  test('response pointers bind bounded data without expressions', () {
    expect(
      ProjectConnectedWorkspaceViewUsecase.call('9007199254740993', {
        'source': '',
      }),
      {'source': '9007199254740993'},
    );
    expect(
      ProjectConnectedWorkspaceViewUsecase.call(
        '{"results":[{"name":"Current"}]}',
        {'title': '/results/0/name'},
      ),
      {'title': 'Current'},
    );
    expect(
      () => ProjectConnectedWorkspaceViewUsecase.call(
        {'results': <Object?>[]},
        {'title': '/results/0/name'},
      ),
      throwsA(isA<Exception>()),
    );
    expect(
      () => ProjectConnectedWorkspaceViewUsecase.validate({
        'title': 'javascript:read()',
      }),
      throwsA(isA<Exception>()),
    );
  });
}
