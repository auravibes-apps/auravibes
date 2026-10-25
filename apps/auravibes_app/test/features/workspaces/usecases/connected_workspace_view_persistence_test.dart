import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/local_workspace_record_query_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_reference_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_table_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_view_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_connected_binding.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_view.dart';
import 'package:auravibes_app/features/workspaces/usecases/manage_workspace_views_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_tables_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/project_connected_workspace_view_usecase.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Connector-only View persists and restores without owned table',
    () async {
      final database = AppDatabase(connection: NativeDatabase.memory());
      addTearDown(database.close);
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
        OrganizeWorkspaceTablesUsecase(
          LocalWorkspaceTableRepository(database, 'workspace'),
        ),
        .new(LocalWorkspaceRecordQueryRepository(database, 'workspace')),
        .new(LocalWorkspaceReferenceRepository(database, 'workspace')),
        validateConnected: (_) async {},
      );
      final connector = connectorDefinitions.firstWhere(
        (item) => item.identifier == 'brave',
      );
      final tool = connector.tools.firstWhere(
        (item) => item.slug == 'web_search',
      );
      final draft = WorkspaceView.connectedDraft(name: 'Live').withConnected(
        WorkspaceConnectedBinding(
          toolId: connectorToolId(connector, tool),
          revision: connectorToolRevision(connector, tool),
          connectionId: 'service:chosen',
          inputs: const {'query': 'records'},
        ),
      );
      final saved = await views.save(draft);
      expect(saved.isConnectedOnly, true);
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
    },
  );
  test('response pointers bind bounded data without expressions', () {
    expect(ProjectConnectedWorkspaceViewUsecase.call('9007199254740993', {'source': ''}), {'source': '9007199254740993'});
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
