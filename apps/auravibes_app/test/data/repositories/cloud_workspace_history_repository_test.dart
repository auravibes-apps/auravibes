import 'dart:convert';

import 'package:auravibes_app/data/repositories/cloud_workspace_history_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_history_blocked_exception.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_history_policy.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_trash_target.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_resource_store.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart' as cloud;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  test(
    'cloud history maps authorized blockers without weakening generic denials',
    () async {
      final fixture = _Fixture();
      when(() => fixture.endpoint.permanentlyDelete(42, any())).thenThrow(
        cloud.CloudWorkspaceException(
          code: .validationFailed,
          blockingResourcesJson: jsonEncode([
            {'id': 'source', 'name': 'Source record'},
          ]),
        ),
      );
      await expectLater(
        fixture.repository.permanentlyDelete(_target),
        throwsA(
          isA<WorkspaceHistoryBlockedException>().having(
            (error) => error.resources,
            'authorized source',
            ['Source record'],
          ),
        ),
      );
      when(() => fixture.endpoint.permanentlyDelete(42, any()))
          .thenThrow(cloud.CloudWorkspaceException(code: .permissionDenied));
      await expectLater(
        fixture.repository.permanentlyDelete(_target),
        throwsA(
          isA<CloudAppException>().having(
            (error) => error.code,
            'generic denied code',
            'permissionDenied',
          ),
        ),
      );
    },
  );
  test(
    'cloud history sends stored snapshot identity and current policy revision',
    () async {
      final fixture = _Fixture();
      registerFallbackValue(
        cloud.WorkspaceHistoryRestoreRequest(
          workspaceId: 42,
          targetJson: '{}',
          revision: 1,
          requestId: 'fallback',
        ),
      );
      registerFallbackValue(
        cloud.WorkspaceHistoryPolicyRequest(
          workspaceId: 42,
          expectedRevision: 2,
          requestId: 'fallback',
        ),
      );
      when(() => fixture.endpoint.restore(any()))
          .thenAnswer((_) => Future<void>.value());
      when(() => fixture.endpoint.configurePolicy(any()))
          .thenAnswer((_) => Future<void>.value());
      await fixture.repository.restore(_target, 1);
      final restored =
          verify(() => fixture.endpoint.restore(captureAny())).captured.single
              as cloud.WorkspaceHistoryRestoreRequest;
      expect(restored.revision, 1);
      expect(jsonDecode(restored.targetJson), _target.toJson());
      expect(restored.requestId, isNotEmpty);
      await fixture.repository.configure(
        const WorkspaceHistoryPolicy(days: 5, revision: 2),
        null,
      );
      final configured =
          verify(() => fixture.endpoint.configurePolicy(captureAny()))
                  .captured
                  .single
              as cloud.WorkspaceHistoryPolicyRequest;
      expect(configured.days, isNull);
      expect(configured.expectedRevision, 2);
      expect(configured.workspaceId, 42);
      expect(configured.requestId, isNotEmpty);
    },
  );
}

const _target = WorkspaceTrashTarget(
  kind: .record,
  id: 'record',
  revision: 3,
  tableId: 'table',
);

class _Fixture {
  new() {
    when(() => store.client).thenAnswer((_) async => client);
    when(() => store.cloudWorkspaceId).thenAnswer((_) async => 42);
    when(() => client.workspaceHistory).thenReturn(endpoint);
  }
  final store = _Store();
  final client = _Client();
  final endpoint = _Endpoint();
  CloudWorkspaceHistoryRepository get repository => .new(store);
}

class _Store extends Mock implements CloudWorkspaceResourceStore;
class _Client extends Mock implements cloud.Client;
class _Endpoint extends Mock implements cloud.EndpointWorkspaceHistory;
