import 'dart:convert';

import 'package:auravibes_app/data/repositories/cloud_workspace_history_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_history_blocked_exception.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_history_policy.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
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
  test(
    'cloud reports verify receipts and map metadata-only queue rows',
    () async {
      final fixture = _Fixture();
      when(() => fixture.reportEndpoint.submit(42, any(), any()))
          .thenAnswer((invocation) async {
            final id = invocation.positionalArguments[2] as String;

            return jsonEncode({'receiptId': id, 'status': 'submitted'});
          });
      final reportId = await fixture.repository.submitReport(_target);
      expect(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
          caseSensitive: false,
        ).hasMatch(reportId),
        isTrue,
      );
      final targetJson =
          verify(() => fixture.reportEndpoint.submit(42, captureAny(), any()))
                  .captured
                  .single
              as String;
      expect(jsonDecode(targetJson), _target.toJson());

      when(() => fixture.reportEndpoint.list(42)).thenAnswer(
        (_) async => [
          jsonEncode({
            'reportId': reportId,
            'kind': 'record',
            'resourceId': _target.id,
            'tableId': _target.tableId,
            'revision': _target.revision,
            'conversationId': 'conversation-1',
            'status': 'submitted',
            'submittedAt': '2026-10-26T05:00:00.000Z',
            'reviewerUserId': null,
            'reviewedAt': null,
          }),
        ],
      );
      final reports = await fixture.repository.reports();
      expect(reports, hasLength(1));
      expect(reports.single.reportId, reportId);
      expect(reports.single.target.id, _target.id);
      expect(reports.single.conversationId, 'conversation-1');
      expect(reports.single.status, 'submitted');
      expect(reports.single.reviewedAt, isNull);

      when(() => fixture.reportEndpoint.resolve(42, reportId, 'dismiss'))
          .thenAnswer(
            (_) async => jsonEncode({
              'reportId': reportId,
              'kind': 'record',
              'resourceId': _target.id,
              'tableId': _target.tableId,
              'revision': _target.revision,
              'conversationId': 'conversation-1',
              'status': 'dismissed',
              'submittedAt': '2026-10-26T05:00:00.000Z',
              'reviewerUserId': 'owner-1',
              'reviewedAt': '2026-10-26T05:01:00.000Z',
            }),
          );
      final resolved = await fixture.repository.resolveReport(
        reportId,
        .dismiss,
      );
      expect(resolved.status, 'dismissed');
      expect(resolved.reviewerUserId, 'owner-1');
      expect(resolved.reviewedAt, DateTime.parse('2026-10-26T05:01:00.000Z'));
    },
  );

  test('cloud report submit rejects an unverifiable receipt', () async {
    final fixture = _Fixture();
    when(() => fixture.reportEndpoint.submit(42, any(), any())).thenAnswer(
      (_) async =>
          jsonEncode({'receiptId': 'different-id', 'status': 'submitted'}),
    );

    await expectLater(
      fixture.repository.submitReport(_target),
      throwsA(isA<WorkspaceTableException>()),
    );
  });
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
    when(() => client.workspaceContentReport).thenReturn(reportEndpoint);
  }
  final store = _Store();
  final client = _Client();
  final endpoint = _Endpoint();
  final reportEndpoint = _ReportEndpoint();
  CloudWorkspaceHistoryRepository get repository => .new(store);
}

class _Store extends Mock implements CloudWorkspaceResourceStore;
class _Client extends Mock implements cloud.Client;
class _Endpoint extends Mock implements cloud.EndpointWorkspaceHistory;
class _ReportEndpoint extends Mock
    implements cloud.EndpointWorkspaceContentReport;
