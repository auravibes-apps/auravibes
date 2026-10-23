import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_resource_mapper.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_resource_store.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';

class const CloudWorkspaceTableAccessRepository(
  final CloudWorkspaceResourceStore _store,
) implements WorkspaceTableAccessRepository {
  @override
  Future<List<WorkspaceTableMember>> members(String tableId) async {
    final data = _ownerData(await _table(tableId));
    final grants = data['memberAccess'] as Map? ?? const {};
    final roster = await _roster();

    return [
      for (final member in roster)
        if (member.role != 'owner') _member(member, grants),
    ];
  }

  @override
  Future<void> setMemberAccess({
    required WorkspaceTable table,
    required String userId,
    required String? access,
  }) async {
    final data = _ownerData(await _table(table.id));
    await _store.update(
      kind: .table,
      id: table.id,
      revision: table.revision,
      data: _grantData(data, userId, access),
    );
  }

  Future<WorkspaceResource> _table(String id) async {
    String? cursor;
    do {
      final page = await _page(cursor);
      final resource = page.resources
          .where((row) => row.resourceId == id)
          .firstOrNull;
      if (resource != null) return resource;
      cursor = page.nextResourceId;
    } while (cursor != null);
    throw const WorkspaceTableException(denied: true);
  }

  Future<WorkspaceResourcePage> _page(String? cursor) async {
    final response = await _store.read(
      pages: [
        WorkspaceResourcePageRequest(
          resourceKind: .table,
          afterResourceId: cursor,
          limit: 100,
        ),
      ],
    );

    return response.pages.single;
  }

  Future<List<CloudWorkspaceMemberSummary>> _roster() async {
    final client = await _store.client;
    final workspaceId = await _store.cloudWorkspaceId;
    if (client == null || workspaceId == null) {
      throw const WorkspaceTableException();
    }

    return await CloudAppErrors.guardCall(
      .state,
      () => client.cloudWorkspace.listMembers(.new(workspaceId: workspaceId)),
    );
  }
}

Map<String, dynamic> _ownerData(WorkspaceResource resource) {
  final data = CloudResourceMapper.decode(resource);
  if (data['canManageTable'] != true) {
    throw const WorkspaceTableException(denied: true);
  }

  return data;
}

WorkspaceTableMember _member(
  CloudWorkspaceMemberSummary member,
  Map<dynamic, dynamic> grants,
) => WorkspaceTableMember(
  userId: member.userId,
  label: member.email ?? member.userId,
  access: grants[member.userId] as String?,
);

Map<String, Object?> _grantData(
  Map<String, dynamic> data,
  String userId,
  String? access,
) {
  final grants = Map<String, Object?>.from(
    data['memberAccess'] as Map? ?? const {},
  );
  if (access == null) {
    final _ = grants.remove(userId);
  } else {
    grants[userId] = access;
  }

  return {...data}
    ..remove('canManageTable')
    ..remove('canEditRecords')
    ..['memberAccess'] = grants;
}
