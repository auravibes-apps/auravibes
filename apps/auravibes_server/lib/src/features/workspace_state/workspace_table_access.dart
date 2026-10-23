import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../workspaces/domain/workspace_roles.dart';

/// Resolves table grants against current membership on every request.
class const WorkspaceTableAccess() {
  Future<WorkspaceResource?> table(
    Session session,
    int workspaceId,
    String id, {
    Transaction? transaction,
  }) => WorkspaceResource.db.findFirstRow(
    session,
    where: (row) =>
        row.workspaceId.equals(workspaceId) &
        row.resourceKind.equals(WorkspaceResourceKind.table) &
        row.resourceId.equals(id) &
        row.deletedAt.equals(null),
    transaction: transaction,
  );

  Future<String?> level(
    Session session,
    WorkspaceMember member,
    WorkspaceResource resource, {
    Transaction? transaction,
  }) async {
    if (member.role == WorkspaceRoles.owner) return 'owner';
    final data = jsonDecode(resource.data) as Map<String, dynamic>;
    final target = resource.resourceKind == WorkspaceResourceKind.table
        ? resource
        : await table(
            session,
            resource.workspaceId,
            data['tableId'] as String,
            transaction: transaction,
          );
    if (target == null) return null;
    final grants =
        (jsonDecode(target.data) as Map<String, dynamic>)['memberAccess'];
    return grants is Map ? grants[member.userId] as String? : null;
  }

  Future<WorkspaceResource?> visible(
    Session session,
    WorkspaceMember member,
    WorkspaceResource resource,
  ) async {
    if (resource.resourceKind != WorkspaceResourceKind.table &&
        resource.resourceKind != WorkspaceResourceKind.tableRecord) {
      return resource;
    }
    final access = await level(session, member, resource);
    if (access == null) return null;
    if (resource.resourceKind != WorkspaceResourceKind.table) return resource;
    final data = jsonDecode(resource.data) as Map<String, dynamic>;
    if (access != 'owner') data.remove('memberAccess');
    data['canManageTable'] = access == 'owner';
    data['canEditRecords'] = access == 'owner' || access == 'edit';
    return resource.copyWith(data: jsonEncode(data));
  }

  Future<bool> canSeeEvent(
    Session session,
    WorkspaceMember member,
    WorkspaceEvent event,
  ) async {
    final kind = WorkspaceResourceKind.values
        .where((kind) => kind.name == event.resourceKind)
        .firstOrNull;
    if (kind != WorkspaceResourceKind.table &&
        kind != WorkspaceResourceKind.tableRecord) {
      return true;
    }
    final resource = await WorkspaceResource.db.findFirstRow(
      session,
      where: (row) =>
          row.workspaceId.equals(event.workspaceId) &
          row.resourceKind.equals(kind!) &
          row.resourceId.equals(event.resourceId),
    );
    return resource != null && await level(session, member, resource) != null;
  }

  Future<void> requireWrite(
    Session session,
    WorkspaceMember member,
    WorkspacePatchOperation operation, {
    required Transaction transaction,
  }) async {
    if (operation.resourceKind != WorkspaceResourceKind.table &&
        operation.resourceKind != WorkspaceResourceKind.tableRecord) {
      return;
    }
    Map<String, dynamic>? data;
    final payload = operation.data;
    if (payload != null) {
      try {
        final Object? decoded = jsonDecode(payload);
        if (decoded is! Map<String, dynamic>) {
          throw const FormatException();
        }
        data = decoded;
      } on FormatException {
        throw CloudWorkspaceException(
          code: CloudWorkspaceErrorCode.validationFailed,
        );
      }
    }
    if (member.role == WorkspaceRoles.owner) {
      if (operation.resourceKind == WorkspaceResourceKind.table &&
          operation.data != null) {
        final grants = data?['memberAccess'];
        if (grants != null) {
          if (grants is! Map ||
              grants.values.any(
                (value) => value != 'read' && value != 'edit',
              )) {
            throw CloudWorkspaceException(
              code: CloudWorkspaceErrorCode.validationFailed,
            );
          }
          for (final userId in grants.keys) {
            final target = await WorkspaceMember.db.findFirstRow(
              session,
              where: (row) =>
                  row.workspaceId.equals(member.workspaceId) &
                  row.userId.equals(userId as String) &
                  row.removedAt.equals(null),
              transaction: transaction,
            );
            if (target == null) {
              throw CloudWorkspaceException(
                code: CloudWorkspaceErrorCode.validationFailed,
              );
            }
          }
        }
      }
      return;
    }
    if (operation.resourceKind == WorkspaceResourceKind.tableRecord) {
      final existing = await WorkspaceResource.db.findFirstRow(
        session,
        where: (row) =>
            row.workspaceId.equals(member.workspaceId) &
            row.resourceKind.equals(WorkspaceResourceKind.tableRecord) &
            row.resourceId.equals(operation.resourceId),
        transaction: transaction,
      );
      final target =
          existing ??
          (data?['tableId'] is String
              ? await table(
                  session,
                  member.workspaceId,
                  data!['tableId'] as String,
                  transaction: transaction,
                )
              : null);
      if (target != null &&
          await level(session, member, target, transaction: transaction) ==
              'edit') {
        return;
      }
    }
    throw CloudWorkspaceException(
      code: CloudWorkspaceErrorCode.permissionDenied,
    );
  }
}
