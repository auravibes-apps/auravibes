import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../workspaces/domain/workspace_roles.dart';
import 'workspace_reference_visibility.dart';

/// Resolves table grants against current membership on every request.
class const WorkspaceTableAccess({final Transaction? transaction}) {
  Future<WorkspaceResource?> visible(
    Session session,
    WorkspaceMember member,
    WorkspaceResource resource,
  ) => _TableReader(session, member, transaction).visible(resource);

  Future<WorkspaceEvent> visibleEvent(
    Session session,
    WorkspaceMember member,
    WorkspaceEvent event,
  ) async {
    final visible = event.resourceKind == 'view'
        ? await _ViewEventReader(session, member, transaction).visible(event)
        : await _TableReader(session, member, transaction).canSeeEvent(event);

    return visible ? event : _hiddenEvent(event);
  }

  Future<bool> canReadTable(
    Session session,
    WorkspaceMember member,
    WorkspaceResource table, {
    bool includeDeleted = false,
  }) async {
    if (table.resourceKind != .table ||
        table.workspaceId != member.workspaceId ||
        (!includeDeleted && table.deletedAt != null)) {
      return false;
    }

    return await _TableReader(session, member, transaction).level(table) !=
        null;
  }

  Future<void> requireWrite(
    Session session,
    WorkspaceMember member,
    WorkspacePatchOperation operation,
  ) =>
      _TableWriter(_TableReader(session, member, transaction))
          .require(operation);
}

class const _ResourceKey(
  final int workspaceId,
  final WorkspaceResourceKind kind,
  final String id,
) {
  Expression matches(WorkspaceResourceTable row) =>
      row.workspaceId.equals(workspaceId) &
      row.resourceKind.equals(kind) &
      row.resourceId.equals(id);
}

class const _TableReader(
  final Session session,
  final WorkspaceMember member,
  final Transaction? transaction,
) {
  Future<WorkspaceResource?> resource(_ResourceKey key) =>
      WorkspaceResource.db.findFirstRow(
        session,
        where: key.matches,
        transaction: transaction,
      );

  Future<WorkspaceResource?> table(String id) async {
    final row = await resource(_ResourceKey(member.workspaceId, .table, id));

    return row?.deletedAt == null ? row : null;
  }

  Future<String?> level(WorkspaceResource resource) async {
    if (member.role == WorkspaceRoles.owner) return 'owner';
    final target = resource.resourceKind == WorkspaceResourceKind.table
        ? resource
        : await table(_data(resource)['tableId'] as String);
    if (target == null) return null;

    return _grant(target, member.userId);
  }

  Future<WorkspaceResource?> visible(WorkspaceResource resource) async {
    return switch (resource.resourceKind) {
      .folder => _visibleFolder(resource, member.role),
      .file => await _file(resource),
      .workflow => _workflow(resource, member.role),
      _ => await _tableResource(resource),
    };
  }

  WorkspaceResource _workflow(WorkspaceResource resource, String role) {
    final data = _data(resource);
    data['canManageWorkflow'] =
        role == WorkspaceRoles.owner || role == WorkspaceRoles.admin;

    return resource.copyWith(data: jsonEncode(data));
  }

  Future<bool> canSeeEvent(WorkspaceEvent event) =>
      _TableEventReader(this).visible(event);

  Future<WorkspaceResource?> _file(WorkspaceResource resource) async {
    if (resource.deletedAt != null) return null;

    return await _FileProjection(
      session,
      resource,
      member.role,
      transaction,
    ).visible();
  }

  Future<WorkspaceResource?> _tableResource(WorkspaceResource resource) async {
    if (!_isTableResource(resource.resourceKind)) return resource;
    final access = await level(resource);
    if (access == null) return null;

    return await _project(resource, access);
  }

  Future<WorkspaceResource> _project(
    WorkspaceResource resource,
    String access,
  ) async {
    if (resource.resourceKind == WorkspaceResourceKind.table) {
      return await WorkspaceReferenceVisibility(
        session,
        member,
        transaction,
      ).table(_visibleTable(resource, access));
    }

    return await WorkspaceReferenceVisibility(
      session,
      member,
      transaction,
    ).record(resource);
  }
}

class const _TableEventReader(final _TableReader reader) {
  Future<bool> visible(WorkspaceEvent event) async {
    final kind = _eventKind(event);
    if (kind == .file) return await _file(event);
    if (kind == null || !_isTableResource(kind)) return true;

    return await _table(event, kind);
  }

  Future<bool> _table(WorkspaceEvent event, WorkspaceResourceKind kind) async {
    final id = event.resourceId;
    if (id == null) return false;
    final row = await reader.resource(
      _ResourceKey(event.workspaceId, kind, id),
    );

    return row != null && await reader.level(row) != null;
  }

  Future<bool> _file(WorkspaceEvent event) async {
    final id = event.resourceId;
    if (id == null) return false;
    final row = await reader.resource(
      _ResourceKey(event.workspaceId, .file, id),
    );

    return row != null && row.deletedAt == null;
  }
}

class const _TableWriter(final _TableReader reader) {
  Future<void> require(WorkspacePatchOperation operation) async {
    if (!_isTableResource(operation.resourceKind)) return;
    final data = _patchData(operation.data);
    if (reader.member.role == WorkspaceRoles.owner) {
      await _requireOwnerGrant(operation, data);

      return;
    }
    if (await _canEditRecord(operation, data)) return;
    throw CloudWorkspaceException(
      code: CloudWorkspaceErrorCode.permissionDenied,
    );
  }

  Future<void> _requireOwnerGrant(
    WorkspacePatchOperation operation,
    Map<String, dynamic>? data,
  ) async {
    if (operation.resourceKind != WorkspaceResourceKind.table) return;
    final grants = data?['memberAccess'];
    if (grants == null) return;
    _validateGrants(grants);
    for (final userId in (grants as Map<String, dynamic>).keys) {
      await _requireMember(userId);
    }
  }

  Future<void> _requireMember(String userId) async {
    final member = await WorkspaceMember.db.findFirstRow(
      reader.session,
      where: (row) => _activeMember(row, reader.member.workspaceId, userId),
      transaction: reader.transaction,
    );
    if (member == null) _invalid();
  }

  Future<bool> _canEditRecord(
    WorkspacePatchOperation operation,
    Map<String, dynamic>? data,
  ) async {
    if (operation.resourceKind != WorkspaceResourceKind.tableRecord) {
      return false;
    }
    final existing = await reader.resource(
      _ResourceKey(
        reader.member.workspaceId,
        .tableRecord,
        operation.resourceId,
      ),
    );
    final target = existing ?? await _targetTable(data);

    return target != null && await reader.level(target) == 'edit';
  }

  Future<WorkspaceResource?> _targetTable(Map<String, dynamic>? data) async {
    final id = data?['tableId'];

    return id is String ? await reader.table(id) : null;
  }
}

Expression _activeMember(
  WorkspaceMemberTable row,
  int workspaceId,
  String userId,
) =>
    row.workspaceId.equals(workspaceId) &
    row.userId.equals(userId) &
    row.removedAt.equals(null);

bool _isTableResource(WorkspaceResourceKind kind) =>
    kind == WorkspaceResourceKind.table ||
    kind == WorkspaceResourceKind.tableRecord;

Map<String, dynamic> _data(WorkspaceResource resource) =>
    jsonDecode(resource.data) as Map<String, dynamic>;

String? _grant(WorkspaceResource table, String userId) {
  final grants = _data(table)['memberAccess'];

  return grants is Map ? grants[userId] as String? : null;
}

WorkspaceResource _visibleTable(WorkspaceResource resource, String access) {
  final data = _data(resource);
  if (access != 'owner') data.remove('memberAccess');
  data['canManageTable'] = access == 'owner';
  data['canEditRecords'] = access == 'owner' || access == 'edit';

  return resource.copyWith(data: jsonEncode(data));
}

WorkspaceResourceKind? _eventKind(WorkspaceEvent event) => WorkspaceResourceKind
    .values
    .where((kind) => kind.name == event.resourceKind)
    .firstOrNull;

Map<String, dynamic>? _patchData(String? payload) {
  if (payload == null) return null;
  try {
    final Object? decoded = jsonDecode(payload);
    if (decoded is Map<String, dynamic>) return decoded;
  } on FormatException {
    _invalid();
  }
  _invalid();
}

void _validateGrants(Object grants) {
  if (grants is! Map<String, dynamic> ||
      grants.values.any((value) => value != 'read' && value != 'edit')) {
    _invalid();
  }
}

Never _invalid() => throw CloudWorkspaceException(
  code: CloudWorkspaceErrorCode.validationFailed,
);

WorkspaceResource _visibleFolder(WorkspaceResource resource, String role) =>
    resource.copyWith(
      data: jsonEncode({
        ..._data(resource),
        'canManageFolder':
            role == WorkspaceRoles.owner || role == WorkspaceRoles.admin,
      }),
    );

class const _FileProjection(
  final Session session,
  final WorkspaceResource resource,
  final String role,
  final Transaction? transaction,
) {
  Future<WorkspaceResource> visible() async =>
      resource.copyWith(data: jsonEncode(_content(await _object())));

  Future<WorkspaceObject?> _object() {
    final objectId = int.tryParse(_data(resource)['assetId'] as String? ?? '');

    return WorkspaceObject.db.findFirstRow(
      session,
      where: (row) => _matches(row, objectId),
      transaction: transaction,
    );
  }

  Expression _matches(WorkspaceObjectTable row, int? objectId) =>
      row.workspaceId.equals(resource.workspaceId) &
      row.id.equals(objectId) &
      row.status.equals('active') &
      row.deletedAt.equals(null);

  Map<String, Object?> _content(WorkspaceObject? object) => {
    ..._data(resource),
    'canManageFile':
        role == WorkspaceRoles.owner || role == WorkspaceRoles.admin,
    if (object != null) 'asset': _asset(object),
  };

  Map<String, Object?> _asset(WorkspaceObject object) => {
    'id': '${object.id}',
    'name': object.displayName,
    'mimeType': object.mimeType,
    'sizeBytes': object.sizeBytes,
    'checksum': object.checksumSha256,
  };
}

WorkspaceEvent _hiddenEvent(WorkspaceEvent event) => event.copyWith(
  id: null,
  actorUserId: '',
  kind: 'workspace.changed',
  resourceKind: 'workspace',
  resourceId: null,
  payloadJson: null,
  publishedAt: null,
);

class const _ViewEventReader(
  final Session session,
  final WorkspaceMember member,
  final Transaction? transaction,
) {
  Future<bool> visible(WorkspaceEvent event) async {
    final view = await _view(event.resourceId);
    if (view == null) return false;
    final table = await _table(_viewSource(view));
    if (table == null) return false;

    return await WorkspaceTableAccess(transaction: transaction)
        .canReadTable(session, member, table);
  }

  Future<WorkspaceView?> _view(String? id) => WorkspaceView.db.findFirstRow(
    session,
    where: (row) =>
        row.workspaceId.equals(member.workspaceId) & row.stableId.equals(id),
    transaction: transaction,
  );

  Future<WorkspaceResource?> _table(String id) =>
      WorkspaceResource.db.findFirstRow(
        session,
        where: (row) =>
            row.workspaceId.equals(member.workspaceId) &
            row.resourceKind.equals(.table) &
            row.resourceId.equals(id),
        transaction: transaction,
      );
}

String _viewSource(WorkspaceView view) =>
    (jsonDecode(view.data) as Map<String, dynamic>)['tableId'] as String;
