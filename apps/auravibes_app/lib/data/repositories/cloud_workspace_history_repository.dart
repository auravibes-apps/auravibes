import 'dart:convert';

import 'package:auravibes_app/features/workspaces/models/workspace_revision.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_trash_target.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_resource_store.dart';
import 'package:uuid/v7.dart';

class const CloudWorkspaceHistoryRepository(
  final CloudWorkspaceResourceStore store,
) implements WorkspaceHistoryRepository {
  @override
  Future<List<WorkspaceRevision>> history(WorkspaceTrashTarget target) async {
    final client = await store.client;
    final workspaceId = await store.cloudWorkspaceId;
    if (client == null || workspaceId == null) {
      throw const WorkspaceTableException(denied: true);
    }
    final rows = await CloudAppErrors.guardCall(
      .state,
      () => client.workspaceHistory.history(
        workspaceId,
        jsonEncode(target.toJson()),
      ),
    );
    return rows.map((encoded) {
      final row = jsonDecode(encoded) as Map<String, dynamic>;
      return WorkspaceRevision(
        target: .new(
          kind: target.kind,
          id: target.id,
          tableId: target.tableId,
          revision: row['revision'] as int,
        ),
        data: row['data'] as Map<String, dynamic>,
      );
    }).toList();
  }

  @override
  Future<void> restore(WorkspaceTrashTarget target, int revision) async {
    final client = await store.client;
    final workspaceId = await store.cloudWorkspaceId;
    if (client == null || workspaceId == null) {
      throw const WorkspaceTableException(denied: true);
    }
    await CloudAppErrors.guardCall(
      .state,
      () => client.workspaceHistory.restore(
        workspaceId,
        jsonEncode(target.toJson()),
        revision,
        const UuidV7().generate(),
      ),
    );
  }

  @override
  Future<void> permanentlyDelete(WorkspaceTrashTarget target) async {
    final client = await store.client;
    final workspaceId = await store.cloudWorkspaceId;
    if (client == null || workspaceId == null) {
      throw const WorkspaceTableException(denied: true);
    }
    await CloudAppErrors.guardCall(
      .state,
      () => client.workspaceHistory.permanentlyDelete(
        workspaceId,
        jsonEncode(target.toJson()),
      ),
    );
  }
}
