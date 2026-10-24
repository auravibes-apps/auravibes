import 'package:auravibes_app/features/workspaces/models/workspace_history_policy.dart';
import 'dart:convert';

import 'package:auravibes_app/features/workspaces/models/workspace_revision.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_trash_target.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_resource_store.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart' as cloud;
import 'package:uuid/v7.dart';

typedef _Connection = ({cloud.Client client, int workspaceId});

class const CloudWorkspaceHistoryRepository(
  final CloudWorkspaceResourceStore store,
) implements WorkspaceHistoryRepository {
  @override
  Future<WorkspaceHistoryPolicy> policy() async {
    final connection = await _connection();
    final encoded = await CloudAppErrors.guardCall(.state, () => connection.client.workspaceHistory.policy(connection.workspaceId));
    return _policy(encoded);
  }

  @override
  Future<void> configure(WorkspaceHistoryPolicy current, int? days) async {
    final connection = await _connection();
    final request = cloud.WorkspaceHistoryPolicyRequest(workspaceId: connection.workspaceId, days: days, expectedRevision: current.revision, requestId: const UuidV7().generate());
    await CloudAppErrors.guardCall(.state, () => connection.client.workspaceHistory.configurePolicy(request));
  }

  @override
  Future<List<WorkspaceRevision>> history(WorkspaceTrashTarget target) async {
    final connection = await _connection();
    final rows = await _read(connection, target);

    return rows.map((encoded) => _snapshot(encoded, target)).toList();
  }

  @override
  Future<void> restore(WorkspaceTrashTarget target, int revision) async {
    final connection = await _connection();
    await _restore(connection, target, revision);
  }

  @override
  Future<void> permanentlyDelete(WorkspaceTrashTarget target) async {
    final connection = await _connection();
    await CloudAppErrors.guardCall(
      .state,
      () => connection.client.workspaceHistory.permanentlyDelete(
        connection.workspaceId,
        jsonEncode(target.toJson()),
      ),
    );
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

Future<List<String>> _read(
  _Connection connection,
  WorkspaceTrashTarget target,
) => CloudAppErrors.guardCall(
  .state,
  () => connection.client.workspaceHistory.history(
    connection.workspaceId,
    jsonEncode(target.toJson()),
  ),
);
Future<void> _restore(
  _Connection connection,
  WorkspaceTrashTarget target,
  int revision,
) => CloudAppErrors.guardCall(
  .state,
  () => connection.client.workspaceHistory.restore(
    _request(connection, target, revision),
  ),
);
WorkspaceRevision _snapshot(String encoded, WorkspaceTrashTarget target) {
  final row = jsonDecode(encoded) as Map<String, dynamic>;

  return WorkspaceRevision(
    target: _target(target, row['revision'] as int),
    data: row['data'] as Map<String, dynamic>,
  );
}

WorkspaceTrashTarget _target(WorkspaceTrashTarget target, int revision) => .new(
  kind: target.kind,
  id: target.id,
  tableId: target.tableId,
  revision: revision,
);

cloud.WorkspaceHistoryRestoreRequest _request(
  _Connection connection,
  WorkspaceTrashTarget target,
  int revision,
) => cloud.WorkspaceHistoryRestoreRequest(
  workspaceId: connection.workspaceId,
  targetJson: jsonEncode(target.toJson()),
  revision: revision,
  requestId: const UuidV7().generate(),
);

WorkspaceHistoryPolicy _policy(String encoded) {
  final data = jsonDecode(encoded) as Map<String, dynamic>;
  return WorkspaceHistoryPolicy(days: data['days'] as int?, revision: data['revision'] as int, canManage: data['canManage'] as bool);
}
