import 'dart:convert';

import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';
import '../../workspaces/domain/workspace_roles.dart';

class const WorkspaceConnectorAccessUsecases() {
  Future<void> requireEnabled(
    Session session, {
    required int workspaceId,
    required String userId,
    required String toolId,
    required ConnectorToolDefinition tool,
  }) => _require(
    session,
    workspaceId: workspaceId,
    userId: userId,
    resourceId: toolId,
    method: tool.urlTemplate?.template.method.value,
  );

  Future<void> requireMcp(
    Session session, {
    required int workspaceId,
    required String userId,
    required String resourceId,
  }) => _require(
    session,
    workspaceId: workspaceId,
    userId: userId,
    resourceId: resourceId,
    method: null,
  );

  Future<void> _require(
    Session session, {
    required int workspaceId,
    required String userId,
    required String resourceId,
    required String? method,
  }) async {
    final member = await WorkspaceMember.db.findFirstRow(
      session,
      where: (table) =>
          table.workspaceId.equals(workspaceId) &
          table.userId.equals(userId) &
          table.removedAt.equals(null),
    );
    if (member == null) _deny();
    final resources = await WorkspaceResource.db.find(
      session,
      where: (table) =>
          table.workspaceId.equals(workspaceId) &
          table.resourceKind.inSet({
            WorkspaceResourceKind.tool,
            WorkspaceResourceKind.toolPermission,
            WorkspaceResourceKind.toolGroup,
          }) &
          table.deletedAt.equals(null),
    );
    final target = resources
        .where(
          (resource) =>
              resource.resourceKind == WorkspaceResourceKind.tool &&
              resource.resourceId == resourceId,
        )
        .firstOrNull;
    if (target == null) _deny();
    final data = _data(target);
    final groupId = data['toolGroupId'];
    if (groupId != null) {
      final group = resources
          .where(
            (resource) =>
                resource.resourceKind == WorkspaceResourceKind.toolGroup &&
                resource.resourceId == groupId,
          )
          .firstOrNull;
      if (group == null ||
          _data(group)['isEnabled'] == false ||
          _data(group)['permissionMode'] == 'alwaysDeny') {
        _deny();
      }
    }
    if (data['isEnabled'] != true || data['permissionMode'] == 'alwaysDeny') {
      _deny();
    }
    final denied = resources
        .where(
          (resource) =>
              resource.resourceKind == WorkspaceResourceKind.toolPermission,
        )
        .map(_data)
        .any(
          (permission) =>
              permission['toolId'] == target.resourceId &&
              (permission['isEnabled'] == false ||
                  permission['permissionMode'] == 'alwaysDeny'),
        );
    if (denied) _deny();
    if (member.role == WorkspaceRoles.owner ||
        member.role == WorkspaceRoles.admin) {
      return;
    }
    final rawConfig = data['config'];
    final config = rawConfig is String ? jsonDecode(rawConfig) : null;
    final access = config is Map ? config['memberAccess'] : null;
    if (access == 'readWrite') return;
    if (access == 'read' && (method == 'GET' || method == 'HEAD')) return;
    _deny();
  }

  Map<String, dynamic> _data(WorkspaceResource resource) =>
      jsonDecode(resource.data) as Map<String, dynamic>;

  Never _deny() => throw CloudWorkspaceException(
    code: CloudWorkspaceErrorCode.permissionDenied,
  );
}
