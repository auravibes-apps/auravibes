import 'dart:convert';

import 'package:auravibes_server/src/features/workspace_state/repositories/workspace_state_repository.dart';
import 'package:auravibes_server/src/features/workspace_state/usecases/workspace_state_usecases.dart';
import 'package:auravibes_server/src/features/workspaces/repositories/cloud_workspace_repository.dart'
    as workspaces;
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import '../../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Workspace content reports', (builder, endpoints) {
    test('authorized metadata reports can be reviewed and removed', () async {
      final ownerId = const Uuid().v4().toString();
      final memberId = const Uuid().v4().toString();
      final owner = _authenticated(builder, ownerId);
      final member = _authenticated(builder, memberId);
      final session = owner.build();
      await _createAccount(session, ownerId);
      await _createAccount(session, memberId);

      final workspace = await workspaces.CloudWorkspaceRepository()
          .createWorkspace(
            session,
            name: 'Reports',
            ownerUserId: ownerId,
            now: DateTime.now().toUtc(),
          );
      final workspaceId = workspace.id!;
      final now = DateTime.now().toUtc();
      final _ = await WorkspaceMember.db.insertRow(
        session,
        WorkspaceMember(
          workspaceId: workspaceId,
          userId: memberId,
          role: 'member',
          revision: 1,
          createdAt: now,
          updatedAt: now,
        ),
      );

      Future<PatchWorkspaceStateResponse> patch(
        List<WorkspacePatchOperation> operations,
        String requestId,
      ) => endpoints.workspaceState.patch(
        owner,
        PatchWorkspaceStateRequest(
          workspaceId: workspaceId,
          requestId: requestId,
          operations: operations,
        ),
      );
      WorkspacePatchOperation create(
        WorkspaceResourceKind kind,
        String id,
        Map<String, Object?> data,
      ) => WorkspacePatchOperation(
        operation: .create,
        resourceKind: kind,
        resourceId: id,
        data: jsonEncode(data),
        fieldMask: const [],
      );
      WorkspacePatchOperation updateRecord(int revision, String value) =>
          WorkspacePatchOperation(
            operation: .update,
            resourceKind: .tableRecord,
            resourceId: 'record',
            expectedRevision: revision,
            data: jsonEncode({
              'tableId': 'table',
              'schemaRevision': 1,
              'values': {'label': value},
            }),
            fieldMask: const [],
          );

      await patch([
        create(.table, 'table', {
          'name': 'Data',
          'labelColumnId': 'label',
          'schemaRevision': 1,
          'memberAccess': {memberId: 'read'},
          'columns': [
            {'id': 'label', 'name': 'Name', 'type': 'text'},
          ],
        }),
        create(.tableRecord, 'record', {
          'tableId': 'table',
          'schemaRevision': 1,
          'values': {'label': 'Private value'},
        }),
      ], 'create-record');

      var snapshot = (await WorkspaceRevision.db.find(
        session,
        where: (row) =>
            row.workspaceId.equals(workspaceId) &
            row.resourceKind.equals(.tableRecord) &
            row.revision.equals(1),
      )).single;
      expect(snapshot.actorUserId, ownerId);
      expect(snapshot.aiInvolved, isFalse);
      expect(snapshot.operation, 'create');
      expect(snapshot.conversationId, isNull);

      await patch([updateRecord(1, 'Manual edit')], 'manual-edit');
      snapshot = (await WorkspaceRevision.db.find(
        session,
        where: (row) =>
            row.workspaceId.equals(workspaceId) &
            row.resourceKind.equals(.tableRecord) &
            row.revision.equals(2),
      )).single;
      expect(snapshot.actorUserId, ownerId);
      expect(snapshot.aiInvolved, isFalse);
      expect(snapshot.operation, 'update');

      final state = WorkspaceStateUseCases(WorkspaceStateRepository());
      await state.patch(
        session,
        userId: ownerId,
        request: PatchWorkspaceStateRequest(
          workspaceId: workspaceId,
          requestId: 'host-ai-edit',
          operations: [updateRecord(2, 'AI edited value')],
        ),
        aiInvolved: true,
        conversationId: 'conversation-report-1',
      );
      snapshot = (await WorkspaceRevision.db.find(
        session,
        where: (row) =>
            row.workspaceId.equals(workspaceId) &
            row.resourceKind.equals(.tableRecord) &
            row.revision.equals(3),
      )).single;
      expect(snapshot.actorUserId, ownerId);
      expect(snapshot.aiInvolved, isTrue);
      expect(snapshot.operation, 'update');
      expect(snapshot.conversationId, 'conversation-report-1');

      final target = jsonEncode({
        'kind': 'record',
        'id': 'record',
        'tableId': 'table',
        'revision': 3,
      });
      final visibleHistory = await endpoints.workspaceHistory.history(
        member,
        workspaceId,
        target,
      );
      final aiHistory = (jsonDecode(visibleHistory.first) as Map);
      expect(aiHistory['actorUserId'], ownerId);
      expect(aiHistory['aiInvolved'], isTrue);
      expect(aiHistory['operation'], 'update');
      expect(aiHistory['conversationId'], 'conversation-report-1');

      const firstReportId = '123e4567-e89b-12d3-a456-426614174000';
      const secondReportId = '223e4567-e89b-12d3-a456-426614174000';
      const deniedReportId = '323e4567-e89b-12d3-a456-426614174000';
      final firstReceipt = jsonDecode(
        await endpoints.workspaceContentReport.submit(
          member,
          workspaceId,
          target,
          firstReportId,
        ),
      ) as Map<String, dynamic>;
      expect(firstReceipt, {'receiptId': firstReportId, 'status': 'submitted'});
      final secondReceipt = jsonDecode(
        await endpoints.workspaceContentReport.submit(
          member,
          workspaceId,
          target,
          secondReportId,
        ),
      ) as Map<String, dynamic>;
      expect(secondReceipt['receiptId'], secondReportId);
      await expectLater(
        endpoints.workspaceContentReport.submit(
          member,
          workspaceId,
          jsonEncode({
            'kind': 'record',
            'id': 'record',
            'tableId': 'table',
            'revision': 2,
          }),
          deniedReportId,
        ),
        throwsA(isA<CloudWorkspaceException>()),
      );
      await expectLater(
        endpoints.workspaceContentReport.list(member, workspaceId),
        throwsA(isA<CloudWorkspaceException>()),
      );

      final reports = await endpoints.workspaceContentReport.list(
        owner,
        workspaceId,
      );
      expect(reports, hasLength(2));
      expect(reports.join(), isNot(contains('AI edited value')));
      expect(reports.join(), isNot(contains('Private value')));
      expect(reports.join(), contains('conversation-report-1'));

      final dismissed = jsonDecode(
        await endpoints.workspaceContentReport.resolve(
          owner,
          workspaceId,
          firstReportId,
          'dismiss',
        ),
      ) as Map<String, dynamic>;
      expect(dismissed['status'], 'dismissed');
      expect(dismissed['reviewerUserId'], ownerId);
      final removed = jsonDecode(
        await endpoints.workspaceContentReport.resolve(
          owner,
          workspaceId,
          secondReportId,
          'remove',
        ),
      ) as Map<String, dynamic>;
      expect(removed['status'], 'removed');
      expect(removed['reviewerUserId'], ownerId);
      expect(
        await endpoints.workspaceTrash.list(owner, workspaceId),
        isNotEmpty,
      );

      final memberRow = (await WorkspaceMember.db.findFirstRow(
        session,
        where: (row) =>
            row.workspaceId.equals(workspaceId) & row.userId.equals(memberId),
      ))!;
      final _ = await WorkspaceMember.db.deleteRow(session, memberRow);
      await expectLater(
        endpoints.workspaceHistory.history(member, workspaceId, target),
        throwsA(isA<CloudWorkspaceException>()),
      );
      await expectLater(
        endpoints.workspaceContentReport.submit(
          member,
          workspaceId,
          target,
          deniedReportId,
        ),
        throwsA(isA<CloudWorkspaceException>()),
      );
    });
  });
}

TestSessionBuilder _authenticated(
  TestSessionBuilder builder,
  String userId,
) => builder.copyWith(
  authentication: AuthenticationOverride.authenticationInfo(userId, const {}),
);

Future<void> _createAccount(Session session, String userId) async {
  final _ = await AuthUser.db.insertRow(
    session,
    AuthUser(id: UuidValue.fromString(userId), scopeNames: const {}),
  );
  final _ = await EmailAccount.db.insertRow(
    session,
    EmailAccount(
      authUserId: UuidValue.fromString(userId),
      email: '$userId@example.com',
      passwordHash: 'unused',
    ),
  );
}
