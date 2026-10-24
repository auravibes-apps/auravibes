import 'dart:convert';

import 'package:auravibes_app/data/repositories/cloud_workspace_view_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_view_mapper.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_view.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart' as cloud;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  test(
    'cloud View adapter preserves stable bindings, revision and retry identity',
    () async {
      final client = _Client();
      final endpoint = _Endpoint();
      final view = WorkspaceView.create(
        name: 'Overview',
        table: const WorkspaceTable(
          id: 'source',
          name: 'Items',
          labelColumnId: 'label',
          columns: [WorkspaceColumn(id: 'label', name: 'Title')],
          revision: 1,
          schemaRevision: 1,
        ),
        columnIds: ['label'],
        parentId: 'folder',
      );
      final saved = view.withRevision(1);
      final encoded = jsonEncode(WorkspaceViewMapper.toJson(saved));
      final response = cloud.WorkspaceView(
        workspaceId: 42,
        stableId: view.id,
        data: encoded,
        revision: 1,
        history: '[]',
      );
      registerFallbackValue(
        cloud.WorkspaceViewSaveRequest(
          workspaceId: 42,
          requestId: 'fallback',
          viewId: view.id,
          expectedRevision: 0,
          definition: '{}',
        ),
      );
      when(() => client.workspaceView).thenReturn(endpoint);
      when(() => endpoint.save(any())).thenAnswer((_) async => response);
      when(() => endpoint.read(42, view.id)).thenAnswer((_) async => response);
      when(() => endpoint.history(42, view.id))
          .thenAnswer((_) async => [encoded]);
      final repository = CloudWorkspaceViewRepository(client, 42);
      final result = await repository.save(view, requestId: 'retry-operation');
      expect(result.revision, 1);
      expect((await repository.read(view.id)).bindings, view.bindings);
      expect((await repository.history(view.id)).single.parentId, 'folder');
      final request =
          verify(() => endpoint.save(captureAny())).captured.single
              as cloud.WorkspaceViewSaveRequest;
      expect(request.workspaceId, 42);
      expect(request.requestId, 'retry-operation');
      expect(request.expectedRevision, 0);
      expect(jsonDecode(request.definition), WorkspaceViewMapper.toJson(view));
    },
  );
}

class _Client extends Mock implements cloud.Client;
class _Endpoint extends Mock implements cloud.EndpointWorkspaceView;
