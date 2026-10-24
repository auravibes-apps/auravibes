import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../accounts/authenticated_account_resolver.dart';
import 'workspace_view_store.dart';

class WorkspaceViewEndpoint extends Endpoint {
  Future<List<WorkspaceView>> list(
    Session session,
    WorkspaceViewListRequest request,
  ) => _access(
    session,
    request.workspaceId,
    (store) => store.list(request.parentId, request.allFolders),
  );
  Future<WorkspaceView> read(Session session, int workspaceId, String id) =>
      _access(session, workspaceId, (store) => store.read(id));
  Future<List<String>> history(Session session, int workspaceId, String id) =>
      _access(session, workspaceId, (store) => store.history(id));
  Future<WorkspaceView> save(
    Session session,
    WorkspaceViewSaveRequest request,
  ) => _access(session, request.workspaceId, (store) => store.save(request));
}

Future<T> _access<T>(
  Session session,
  int workspaceId,
  Future<T> Function(WorkspaceViewStore) operation,
) async {
  final account = await const AuthenticatedAccountResolver()(session);

  return session.db.transaction((transaction) async {
    final store = await _locked(
      session,
      workspaceId,
      account.userId,
      transaction,
    );

    return await operation(store);
  });
}

Future<WorkspaceViewStore> _locked(
  Session session,
  int workspaceId,
  String userId,
  Transaction transaction,
) async {
  await _lockWorkspace(session, workspaceId, transaction);
  final member = await WorkspaceMember.db.findFirstRow(
    session,
    where: (row) => _memberMatches(row, workspaceId, userId),
    transaction: transaction,
  );
  if (member == null) _denied();

  return WorkspaceViewStore(session, member, transaction);
}

Future<void> _lockWorkspace(
  Session session,
  int id,
  Transaction transaction,
) async {
  final row = await CloudWorkspace.db.findById(
    session,
    id,
    transaction: transaction,
    lockMode: LockMode.forUpdate,
  );
  if (row == null) _denied();
}

Expression _memberMatches(
  WorkspaceMemberTable row,
  int workspaceId,
  String userId,
) =>
    row.workspaceId.equals(workspaceId) &
    row.userId.equals(userId) &
    row.removedAt.equals(null);
Never _denied() => throw CloudWorkspaceException(
  code: CloudWorkspaceErrorCode.permissionDenied,
);
