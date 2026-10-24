import 'package:auravibes_app/data/repositories/cloud_workspace_item_duplication_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_item_duplication.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_app/features/workspaces/usecases/duplicate_workspace_item_usecase.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart' as cloud;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  test(
    'cloud duplication uses the authenticated adapter without local storage',
    () async {
      final client = _Client();
      final state = _State();
      final views = _Views();
      when(() => client.workspaceState).thenReturn(state);
      when(() => client.workspaceView).thenReturn(views);
      registerFallbackValue(
        cloud.DuplicateWorkspaceItemRequest(
          workspaceId: 42,
          requestId: 'fallback',
          sourceId: 'source',
          expectedRevision: 1,
          targetId: 'target',
          name: 'Copy',
        ),
      );
      when(() => state.duplicateTable(any())).thenAnswer(
        (_) async =>
            cloud.PatchWorkspaceStateResponse(resources: [], sequence: 1),
      );
      when(() => views.duplicate(any())).thenAnswer(
        (_) async => cloud.WorkspaceView(
          workspaceId: 42,
          stableId: 'target',
          data: '{}',
          revision: 1,
          history: '[]',
        ),
      );
      final usecase = DuplicateWorkspaceItemUsecase(
        CloudWorkspaceItemDuplicationRepository(client, 42),
      );
      const table = WorkspaceItemDuplication(
        kind: .table,
        sourceId: 'source',
        expectedRevision: 7,
        targetId: 'table-copy',
        requestId: 'table-operation',
        name: 'Copy',
        parentId: 'folder',
        copyRecords: true,
      );
      expect(await usecase(table, approve: () async => false), isFalse);
      final _ = verifyNever(() => state.duplicateTable(any()));
      expect(
        await usecase(
          table,
          approve: () async => fail('Allow-all skips only approval'),
          mode: .allowAll,
        ),
        isTrue,
      );
      final request =
          verify(() => state.duplicateTable(captureAny())).captured.single
              as cloud.DuplicateWorkspaceItemRequest;
      expect(request.workspaceId, 42);
      expect(request.sourceId, 'source');
      expect(request.expectedRevision, 7);
      expect(request.targetId, 'table-copy');
      expect(request.requestId, 'table-operation');
      expect(request.parentId, 'folder');
      expect(request.copyRecords, isTrue);
      const view = WorkspaceItemDuplication(
        kind: .view,
        sourceId: 'view',
        expectedRevision: 3,
        targetId: 'view-copy',
        requestId: 'view-operation',
        name: 'View copy',
      );
      expect(await usecase(view, approve: () async => true), isTrue);
      verify(() => views.duplicate(any())).called(1);
      when(() => state.duplicateTable(any()))
          .thenThrow(cloud.CloudWorkspaceException(code: .permissionDenied));
      await expectLater(
        usecase(table, approve: () async => true),
        throwsA(
          isA<CloudAppException>().having(
            (error) => error.code,
            'code',
            'permissionDenied',
          ),
        ),
      );
      when(() => state.duplicateTable(any()))
          .thenThrow(cloud.CloudWorkspaceException(code: .validationFailed));
      await expectLater(
        usecase(table, approve: () async => true),
        throwsA(
          isA<WorkspaceTableException>().having(
            (error) => error.unsupportedCopy,
            'unsupported copy',
            true,
          ),
        ),
      );
    },
  );
}

class _Client extends Mock implements cloud.Client;
class _State extends Mock implements cloud.EndpointWorkspaceState;
class _Views extends Mock implements cloud.EndpointWorkspaceView;
