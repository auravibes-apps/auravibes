import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'repositories/workspace_state_repository.dart';
import 'usecases/workspace_state_usecases.dart';
import 'workspace_history_retention.dart';
import 'workspace_trash_access.dart';

class const WorkspaceHistoryPolicyService(
  final Session session,
  final int workspaceId,
  final String userId,
) {
  Future<String> read() => session.db.transaction((transaction) async {
    final canManage = await _canManage(transaction);
    final row = await WorkspaceHistoryRetention(
      session,
      workspaceId,
      transaction,
    ).policy();

    return _policy(row, canManage);
  });

  Future<void> configure(WorkspaceHistoryPolicyRequest request) async {
    WorkspaceHistoryRetention.validate(request.days);
    final patch = _request(workspaceId, request);
    final _ = await WorkspaceStateUseCases(WorkspaceStateRepository()).patch(
      session,
      userId: userId,
      request: patch,
      guard: (transaction) => WorkspaceHistoryRetention(
        session,
        workspaceId,
        transaction,
      ).apply(request.days),
    );
  }

  Future<bool> _canManage(Transaction transaction) async {
    final locked = await WorkspaceTrashAccess(
      session,
      workspaceId,
      userId,
      transaction,
    ).lock();

    return const {'owner', 'admin'}.contains(locked.member.role);
  }
}

String _policy(WorkspaceResource? row, bool canManage) => jsonEncode({
  'days': row == null || row.deletedAt != null
      ? null
      : (jsonDecode(row.data) as Map<String, dynamic>)['days'],
  'revision': row?.revision ?? 0,
  'canManage': canManage,
});
WorkspacePatchOperation _operation(WorkspaceHistoryPolicyRequest request) =>
    WorkspacePatchOperation(
      operation: request.expectedRevision == 0 ? .create : .update,
      resourceKind: .workspaceSetting,
      resourceId: WorkspaceHistoryRetention.resourceId,
      data: jsonEncode({'days': request.days}),
      expectedRevision: request.expectedRevision == 0
          ? null
          : request.expectedRevision,
      fieldMask: const [],
    );

PatchWorkspaceStateRequest _request(
  int workspaceId,
  WorkspaceHistoryPolicyRequest request,
) => PatchWorkspaceStateRequest(
  workspaceId: workspaceId,
  requestId: request.requestId,
  operations: [_operation(request)],
);
