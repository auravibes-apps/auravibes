import 'dart:convert';

import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_trash_target.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_resource_store.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart' as cloud;

class const CloudWorkspaceTrashRepository(
  final CloudWorkspaceResourceStore store,
) implements WorkspaceTrashRepository {
  @override
  Future<WorkspaceDeletedReference?> deletedReference(
    String tableId,
    String recordId,
  ) async {
    final connection = await _connection();
    final encoded = await CloudAppErrors.guardCall(
      .state,
      () => connection.client.workspaceTrash.deletedReference(
        connection.workspaceId,
        tableId,
        recordId,
      ),
    );

    return _deleted(encoded);
  }

  @override
  Future<List<WorkspaceTrashBatch>> list() async {
    final connection = await _connection();
    final rows = await CloudAppErrors.guardCall(
      .state,
      () => connection.client.workspaceTrash.list(connection.workspaceId),
    );

    return rows.map(_batch).toList();
  }

  @override
  Future<WorkspaceTrashBatch> preview(WorkspaceTrashTarget target) async {
    final connection = await _connection();

    return _batch(
      await CloudAppErrors.guardCall(
        .state,
        () => connection.client.workspaceTrash.preview(
          connection.workspaceId,
          jsonEncode(target.toJson()),
        ),
      ),
    );
  }

  @override
  Future<WorkspaceTrashBatch> trash(
    WorkspaceTrashTarget target, {
    required String planToken,
  }) async {
    final connection = await _connection();

    return _batch(await _trash(connection, target, planToken));
  }

  @override
  Future<WorkspaceTrashRestoration> restore(String batchId) async {
    final connection = await _connection();
    final encoded = await CloudAppErrors.guardCall(
      .state,
      () => connection.client.workspaceTrash.restore(
        connection.workspaceId,
        batchId,
      ),
    );

    return _restored(encoded);
  }

  Future<_Connection> _connection() async {
    final client = await store.client;
    final workspaceId = await store.cloudWorkspaceId;
    if (client == null || workspaceId == null) {
      throw const WorkspaceTableException(denied: true);
    }

    return (client: client, workspaceId: workspaceId);
  }
}

typedef _Connection = ({cloud.Client client, int workspaceId});
typedef _Identity = ({
  String id,
  String name,
  WorkspaceTrashTarget target,
  int count,
});
typedef _Flags = ({String token, bool canRestore});
Future<String> _trash(
  _Connection connection,
  WorkspaceTrashTarget target,
  String token,
) => CloudAppErrors.guardCall(
  .state,
  () => connection.client.workspaceTrash.trash(
    _trashRequest(connection.workspaceId, target, token),
  ),
);
cloud.WorkspaceTrashRequest _trashRequest(
  int workspaceId,
  WorkspaceTrashTarget target,
  String token,
) => .new(
  workspaceId: workspaceId,
  requestId: _requestId(target),
  targetJson: jsonEncode(target.toJson()),
  planToken: token,
);
String _requestId(WorkspaceTrashTarget target) =>
    'trash-${target.kind.name}-${target.id}-${target.revision}';
WorkspaceDeletedReference? _deleted(String encoded) {
  final data = jsonDecode(encoded) as Map<String, dynamic>?;

  return data == null
      ? null
      : .new(
          batchId: data['batchId'] as String,
          canRestore: data['canRestore'] as bool,
        );
}

WorkspaceTrashRestoration _restored(String encoded) {
  final data = jsonDecode(encoded) as Map<String, dynamic>;

  return .new(
    movedToRoot: data['movedToRoot'] as bool,
    unresolvedDependencies: data['unresolvedDependencies'] as bool,
  );
}

WorkspaceTrashBatch _batch(String encoded) {
  final data = jsonDecode(encoded) as Map<String, dynamic>;

  return _build(_identity(data), _flags(data));
}

_Identity _identity(Map<String, dynamic> data) => (
  id: data['id'] as String,
  name: data['name'] as String,
  target: .fromJson(data['target'] as Map<String, dynamic>),
  count: data['affectedCount'] as int,
);
_Flags _flags(Map<String, dynamic> data) => (
  token: data['planToken'] as String? ?? '',
  canRestore: data['canRestore'] as bool? ?? true,
);
WorkspaceTrashBatch _build(_Identity identity, _Flags flags) => .new(
  id: identity.id,
  name: identity.name,
  target: identity.target,
  affectedCount: identity.count,
  planToken: flags.token,
  canRestore: flags.canRestore,
);
