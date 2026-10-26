import 'dart:convert';

import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_server/src/features/accounts/authenticated_account_resolver.dart';
import 'package:auravibes_server/src/features/accounts/auth_user_lock.dart';
import 'package:auravibes_server/src/features/conversations/engine/server_tool_executor.dart';
import 'package:auravibes_server/src/features/workspace_views/workspace_connected_validation.dart';
import 'package:auravibes_server/src/features/workspace_views/workspace_view_store.dart';
import 'package:auravibes_server/src/features/workspace_views/workspace_view_validation.dart';
import 'package:auravibes_server/src/features/workspace_state/usecases/workspace_connector_access_usecases.dart';
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
      throw WorkspaceConnectedReadException(code: _failureCode(failure));
    }
  }

  Future<String> submitAction(
    Session session,
    int workspaceId,
    String id,
    int expectedRevision,
    String formValuesJson,
    String operationId,
  ) async {
    WorkspaceViewValidation.requestId(operationId);
    final account = await const AuthenticatedAccountResolver()(session);
    final view = await read(session, workspaceId, id);
    if (view.revision != expectedRevision) {
      throw CloudWorkspaceException(
        code: CloudWorkspaceErrorCode.staleRevision,
      );
    }
    if (utf8.encode(formValuesJson).length > 131072) {
      throw CloudWorkspaceException(
        code: CloudWorkspaceErrorCode.validationFailed,
      );
    }
    final data = jsonDecode(view.data) as Map<String, Object?>;
    final _ = WorkspaceViewValidation.parse(view.data, id);
    if (data['action'] is! Map || data['definition'] is! Map) {
      throw CloudWorkspaceException(
        code: CloudWorkspaceErrorCode.validationFailed,
      );
    }
    final action = WorkspaceViewValidation.action(data['action']);
    if (action.type != A2uiSavedActionType.connectorWrite) {
      throw CloudWorkspaceException(
        code: CloudWorkspaceErrorCode.validationFailed,
      );
    }
    final decodedValues = _decodeFormValues(formValuesJson);
    if (decodedValues == null) {
      throw CloudWorkspaceException(
        code: CloudWorkspaceErrorCode.validationFailed,
      );
    }
    final definition = Map<String, Object?>.from(data['definition'] as Map);
    final components = (definition['components'] as List)
        .cast<Map<String, Object?>>();
    final formValues = normalizeA2uiFormValues(
      components: components,
      values: decodedValues,
    );
    final validation = validateA2uiFormValues(
      components: components,
      values: formValues,
    );
    if (!validation.isValid) {
      return jsonEncode({
        'status': 'validationFailed',
        'errorsByPath': validation.errorsByPath,
      });
    }
    Map<String, Object?> arguments;
    try {
      arguments = a2uiSavedActionInputs(action, formValues);
    } on FormatException {
      return jsonEncode({
        'status': 'validationFailed',
        'errorsByPath': {
          for (final path in action.inputs.values) path: 'required',
        },
      });
    }
    try {
      final result = await _connectorExecutor.executeWorkspaceViewConnector(
        session,
        workspaceId: workspaceId,
        userId: account.userId,
        toolId: action.toolId!,
        revision: action.revision!,
        arguments: arguments,
        connectionId: action.connectionId,
        operationId: operationId,
      );
      try {
        final current = await _access(
          session,
          workspaceId,
          (store) async {
            final current = await store.read(id);
            final resolved = resolveCloudConnectorTool(
              toolId: action.toolId!,
              revision: action.revision!,
              arguments: arguments,
            );
            await const WorkspaceConnectorAccessUsecases().requireEnabled(
              session,
              workspaceId: workspaceId,
              userId: account.userId,
              toolId: action.toolId!,
              tool: resolved.tool,
              transaction: store.transaction,
            );
            return current;
          },
        );
        return jsonEncode({
          'status': 'completed',
          'result': result,
          'viewChangedDuringExecution': current.revision != expectedRevision,
        });
      } on Object {
        // Preserve the completed action without exposing its provider response.
        return jsonEncode({
          'status': 'completed',
          'viewChangedDuringExecution': true,
        });
      }
    } on AgentToolExecutionFailure catch (failure) {
      return jsonEncode(_actionFailure(failure));
    }
  }

  Future<String> _readConnected(
    Session session,
    int workspaceId,
    String id,
  ) async {
    final source = await _readSource(session, workspaceId, id);
    final result = await _connectorExecutor.readConnector(
      session,
      workspaceId: source.workspaceId,
      userId: source.userId,
      arguments: source.arguments,
    );
    await _checkSource(session, source);

    return jsonEncode(result);
  }

  Future<_ConnectedRead> _readSource(
    Session session,
    int workspaceId,
    String id,
  ) async {
    final account = await const AuthenticatedAccountResolver()(session);
    final view = await read(session, workspaceId, id);

    return (
      workspaceId: workspaceId,
      userId: account.userId,
      view: view,
      arguments: _savedArguments(view),
    );
  }

  Future<void> _checkSource(Session session, _ConnectedRead source) async {
    await _access(
      session,
      source.workspaceId,
      (store) async {
        final current = await store.read(source.view.stableId);
        _requireRevision(source.view, current);
        await _connectorExecutor.readConnectorAccess(
          session,
          workspaceId: source.workspaceId,
          userId: source.userId,
          arguments: source.arguments,
          transaction: store.transaction,
        );
      },
    );
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
  ) => _access(
    session,
    request.workspaceId,
    (store) => store.save(request),
  );
}

Map<String, Object?> _actionFailure(AgentToolExecutionFailure failure) {
  final decoded = _decodeFailure(failure.responseRaw);
  final error = decoded['error'];
  final code = error is Map ? error['code'] : null;
  final partial = decoded['statusCode'] == 207;
  final status = code == 'tool_access_denied'
      ? 'denied'
      : partial
      ? 'partial'
      : failure.resultStatus == AgentToolResultStatus.uncertain
      ? 'uncertain'
      : 'failed';

  return {
    'status': status,
    if (partial) 'retryBlocked': true,
    if (code is String) 'code': code,
    if (decoded['outcome'] is String) 'outcome': decoded['outcome'],
  };
}

Map<String, Object?>? _decodeFormValues(String source) {
  try {
    final decoded = jsonDecode(source);
    if (decoded is! Map || decoded.keys.any((key) => key is! String)) {
      return null;
    }

    return Map<String, Object?>.from(decoded);
  } on FormatException {
    return null;
  }
}

Map<String, Object?> _decodeFailure(String source) {
  try {
    return Map<String, Object?>.from(jsonDecode(source) as Map);
  } on Object {
    return const {};
  }
}

typedef _ConnectedRead = ({
  int workspaceId,
  String userId,
  WorkspaceView view,
  Map<String, dynamic> arguments,
});

Map<String, dynamic> _savedArguments(WorkspaceView view) {
  final data = jsonDecode(view.data) as Map<String, dynamic>;

  return WorkspaceConnectedValidation.arguments(data['connected']);
}

void _requireRevision(WorkspaceView saved, WorkspaceView current) {
  if (current.revision != saved.revision) {
    throw CloudWorkspaceException(code: CloudWorkspaceErrorCode.staleRevision);
  }
}

String _failureCode(AgentToolExecutionFailure failure) {
  final data = jsonDecode(failure.responseRaw) as Map<String, dynamic>;
  final code = (data['error'] as Map?)?['code'];

  return switch (code) {
    'stale_contract' || 'invalid_tool_arguments' => 'repair',
    final String value when value.startsWith('connection_') => 'disconnected',
    'tool_access_denied' => 'denied',
    _ => 'failed',
  };
}

Future<T> _access<T>(
  Session session,
  int workspaceId,
  Future<T> Function(WorkspaceViewStore) operation,
) async {
  final account = await const AuthenticatedAccountResolver()(session);

  return session.db.transaction((transaction) async {
    final authUser = await const AuthUserLock().lock(
      session,
      userId: account.userId,
      transaction: transaction,
    );
    if (authUser == null) _denied();
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
    lockMode: LockMode.forUpdate,
  );
  if (member == null) _denied();

  return WorkspaceViewStore(session, member, transaction);
}

Future<void> _lockWorkspace(
  Session session,
  int id,
  Transaction transaction,
) async {
  final row = await CloudWorkspace.db.findFirstRow(
    session,
    where: (workspace) =>
        workspace.id.equals(id) &
        workspace.deletedAt.equals(null) &
        workspace.erasureRequestedAt.equals(null),
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
