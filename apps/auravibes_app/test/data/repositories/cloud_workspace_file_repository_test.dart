import 'package:auravibes_app/data/repositories/cloud_workspace_file_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_asset.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_resource_store.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart' as cloud;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  for (final listing in [true, false]) {
    test('File pagination rejects repeated cursors: list=$listing', () async {
      final store = _Store();
      var calls = 0;
      when(() => store.read(pages: any(named: 'pages'))).thenAnswer((_) async {
        calls++;
        if (calls > 3) throw StateError('Unbounded pagination');
        return cloud.ReadWorkspaceStateResponse(
          pages: [
            cloud.WorkspaceResourcePage(
              resourceKind: .file,
              resources: [],
              nextResourceId: 'same',
            ),
          ],
          currentSequence: 0,
          events: [],
          requiresSnapshot: false,
        );
      });
      final repository = CloudWorkspaceFileRepository(store);
      await expectLater(
        listing ? repository.list() : repository.file('missing'),
        throwsA(
          isA<WorkspaceAssetException>().having(
            (error) => error.failure,
            'recoverable pagination failure',
            WorkspaceAssetFailure.unavailable,
          ),
        ),
      );
      expect(calls, 2);
    });
  }
}

class _Store extends Mock implements CloudWorkspaceResourceStore {}
