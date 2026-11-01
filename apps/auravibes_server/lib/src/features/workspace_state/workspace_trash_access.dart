import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../accounts/auth_user_lock.dart';
import '../workspaces/domain/workspace_roles.dart';
import 'repositories/workspace_state_repository.dart';

class const WorkspaceTrashAccess(
  final Session session,
  final int workspaceId,
  final String userId,
  final Transaction transaction,
) {
  Future<({WorkspaceMember member, CloudWorkspace workspace})> lock() async {
    final authUser = await const AuthUserLock().lock(
      session,
      userId: userId,
      transaction: transaction,
    );
    if (authUser == null) trashDenied();
    final repository = WorkspaceStateRepository();
    final workspace = await repository.findWorkspace(
      session,
      workspaceId,
      transaction: transaction,
      lock: true,
    );
    final member = await repository.findMember(
      session,
      workspaceId: workspaceId,
      userId: userId,
      transaction: transaction,
    );
    if (workspace == null || member == null) trashDenied();

    return (member: member, workspace: workspace);
  }

  Future<void> require(
    WorkspaceMember member,
    WorkspaceResource resource,
  ) async {
    if (!await writable(member, resource)) trashDenied();
  }

  Future<bool> writable(
    WorkspaceMember member,
    WorkspaceResource resource,
  ) async {
    if (member.role == WorkspaceRoles.owner) return true;
    if (member.role == WorkspaceRoles.admin &&
        {WorkspaceResourceKind.file, WorkspaceResourceKind.workflow}.contains(
          resource.resourceKind,
        )) {
      return true;
    }
    if (resource.resourceKind != .tableRecord) return false;

    return await _grant(resource) == 'edit';
  }

  Future<bool> readable(
    WorkspaceMember member,
    WorkspaceResource resource,
  ) async {
    if (member.role == WorkspaceRoles.owner) return true;
    if (member.role == WorkspaceRoles.admin &&
        {WorkspaceResourceKind.file, WorkspaceResourceKind.workflow}.contains(
          resource.resourceKind,
        )) {
      return true;
    }
    if (resource.resourceKind != .tableRecord &&
        resource.resourceKind != .table) {
      return false;
    }
    final grant = await _grant(resource);

    return grant == 'read' || grant == 'edit';
  }

  Future<Object?> _grant(WorkspaceResource resource) async {
    final table = resource.resourceKind == .table
        ? resource
        : await _table(resource);
    final grants = table == null ? null : trashData(table)['memberAccess'];

    return grants is Map ? grants[userId] : null;
  }

  Future<WorkspaceResource?> _table(WorkspaceResource resource) =>
      WorkspaceStateRepository().findResource(
        session,
        workspaceId: workspaceId,
        kind: .table,
        resourceId: trashData(resource)['tableId'] as String,
        transaction: transaction,
      );
}

Map<String, dynamic> trashData(WorkspaceResource resource) =>
    jsonDecode(resource.data) as Map<String, dynamic>;
Never trashDenied() => throw CloudWorkspaceException(code: .permissionDenied);
Never trashInvalid() => throw CloudWorkspaceException(code: .validationFailed);
Never trashConflict() => throw CloudWorkspaceException(code: .conflict);
