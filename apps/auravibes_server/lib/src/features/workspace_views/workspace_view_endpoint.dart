import 'dart:convert';

import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_server/src/features/accounts/authenticated_account_resolver.dart';
import 'package:auravibes_server/src/features/conversations/engine/server_tool_executor.dart';
import 'package:auravibes_server/src/features/workspace_views/workspace_connected_validation.dart';
import 'package:auravibes_server/src/features/workspace_views/workspace_view_store.dart';
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';

class WorkspaceViewEndpoint extends Endpoint {
  WorkspaceViewEndpoint({ServerToolExecutorService? connectorExecutor})
    : _connectorExecutor =
          connectorExecutor ?? const ServerToolExecutorService();
  final ServerToolExecutorService _connectorExecutor;
  Future<String> readConnected(
    Session session,
    int workspaceId,
    String id,
  ) async {
    try {
      return await _readConnected(session, workspaceId, id);
    } on AgentToolExecutionFailure catch (failure) {
      final data = jsonDecode(failure.responseRaw) as Map<String, dynamic>;
      final code = (data['error'] as Map?)?['code'];
      throw WorkspaceConnectedReadException(
        code: switch (code) {
          'stale_contract' || 'invalid_tool_arguments' => 'repair',
          final String value when value.startsWith('connection_') =>
            'disconnected',
          'tool_access_denied' => 'denied',
          _ => 'failed',
        },
      );
    }
  }

  Future<String> _readConnected(
    Session session,
    int workspaceId,
    String id,
  ) async {
    final account = await const AuthenticatedAccountResolver()(session);
    final view = await read(session, workspaceId, id);
    final data = jsonDecode(view.data) as Map<String, dynamic>;
    final arguments = WorkspaceConnectedValidation.arguments(data['connected']);
    final result = await _connectorExecutor.readConnector(
      session,
      workspaceId: workspaceId,
      userId: account.userId,
      arguments: arguments,
    );
    final current = await read(session, workspaceId, id);
    if (current.revision != view.revision) {
      throw CloudWorkspaceException(
        code: CloudWorkspaceErrorCode.staleRevision,
      );
    }
    await _connectorExecutor.readConnectorAccess(
      session,
      workspaceId: workspaceId,
      userId: account.userId,
      arguments: arguments,
    );

    return jsonEncode(result);
  }

  Future<WorkspaceView> duplicate(
    Session session,
    DuplicateWorkspaceItemRequest request,
  ) => _access(
    session,
    request.workspaceId,
    (store) => store.duplicate(request),
  );
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
