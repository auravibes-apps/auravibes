import 'dart:convert';

import 'package:auravibes_app/features/workspaces/models/workspace_directory_move_item.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_resource_mapper.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_resource_store.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_state_gateway.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:uuid/v7.dart';

class CloudWorkspaceDirectoryMoveRepository
    implements WorkspaceDirectoryMoveRepository {
  new(CloudWorkspaceStateGateway gateway)
    : _read = gateway.read,
      _patch = gateway.patch;
  new forTesting(this._read, this._patch);
  final WorkspaceResourceRead _read;
  final WorkspaceDirectoryPatch _patch;

  @override
  Future<void> move(
    List<WorkspaceDirectoryMoveItem> items,
    String? parentId,
  ) async {
    final resources = await _DirectoryResources(_read).read(items);
    final _ = await _patch(
      requestId: const UuidV7().generate(),
      operations: _operations(items, resources, parentId),
      viewMoves: _views(items, parentId),
    );
  }

  List<WorkspacePatchOperation> _operations(
    List<WorkspaceDirectoryMoveItem> items,
    Map<WorkspaceDirectoryItemKey, WorkspaceResource> resources,
    String? parentId,
  ) => [
    for (final item in items.where((item) => item.key.kind != .view))
      _operation(item, resources[item.key], parentId),
  ];
  List<WorkspaceViewMove> _views(
    List<WorkspaceDirectoryMoveItem> items,
    String? parentId,
  ) => [
    for (final item in items.where((item) => item.key.kind == .view))
      WorkspaceViewMove(
        id: item.key.id,
        expectedRevision: item.revision,
        parentId: parentId,
        name: item.metadataName,
      ),
  ];
}

typedef WorkspaceDirectoryPatch = Future<PatchWorkspaceStateResponse> Function({
  required String requestId,
  required List<WorkspacePatchOperation> operations,
  List<WorkspaceViewMove>? viewMoves,
});

class const _DirectoryResources(final WorkspaceResourceRead readState) {
  Future<Map<WorkspaceDirectoryItemKey, WorkspaceResource>> read(
    List<WorkspaceDirectoryMoveItem> items,
  ) async {
    final resources = <WorkspaceDirectoryItemKey, WorkspaceResource>{};
    for (final kind in [
      WorkspaceDirectoryItemKind.folder,
      WorkspaceDirectoryItemKind.table,
    ]) {
      final ids = _ids(items, kind);
      if (ids.isNotEmpty) resources.addAll(await _kind(kind, ids));
    }

    return resources;
  }

  Future<Map<WorkspaceDirectoryItemKey, WorkspaceResource>> _kind(
    WorkspaceDirectoryItemKind kind,
    Set<String> ids,
  ) async {
    final scan = _DirectoryScan(kind, ids);
    do {
      scan.requireCursor();
      final page = await _page(kind, scan.cursor);
      if (scan.accept(page)) return scan.result;
    } while (scan.cursor != null);
    throw const WorkspaceTableException(denied: true);
  }

  Future<WorkspaceResourcePage> _page(
    WorkspaceDirectoryItemKind kind,
    String? cursor,
  ) async {
    final response = await readState(
      pages: [
        WorkspaceResourcePageRequest(
          resourceKind: kind == .folder ? .folder : .table,
          afterResourceId: cursor,
          limit: 100,
        ),
      ],
      eventLimit: 0,
    );

    return response.pages.single;
  }
}

WorkspacePatchOperation _operation(
  WorkspaceDirectoryMoveItem item,
  WorkspaceResource? resource,
  String? parentId,
) {
  if (resource == null) throw const WorkspaceTableException(denied: true);
  if (resource.revision != item.revision) {
    throw const WorkspaceTableException(conflict: true);
  }
  final data = _permittedData(item, resource);

  return WorkspacePatchOperation(
    operation: .update,
    resourceKind: resource.resourceKind,
    resourceId: resource.resourceId,
    data: jsonEncode({...data, 'parentId': parentId}),
    fieldMask: const [],
    expectedRevision: item.revision,
  );
}

Set<String> _ids(
  List<WorkspaceDirectoryMoveItem> items,
  WorkspaceDirectoryItemKind kind,
) => items
    .where((item) => item.key.kind == kind)
    .map((item) => item.key.id)
    .toSet();
Map<String, dynamic> _permittedData(
  WorkspaceDirectoryMoveItem item,
  WorkspaceResource resource,
) {
  final data = CloudResourceMapper.decode(resource);
  final permission = item.key.kind == .folder
      ? 'canManageFolder'
      : 'canManageTable';
  if (data[permission] != true) {
    throw const WorkspaceTableException(denied: true);
  }

  data.removeWhere((key, _) => _projectionFields.contains(key));

  return data;
}

const _projectionFields = {
  'canManageFolder',
  'canManageTable',
  'canEditRecords',
};

void _requireNewCursor(Set<String?> cursors, String? cursor) {
  if (!cursors.add(cursor)) throw const WorkspaceTableException();
}

class _DirectoryScan {
  new(this.kind, this.ids);
  final WorkspaceDirectoryItemKind kind;
  final Set<String> ids;
  final result = <WorkspaceDirectoryItemKey, WorkspaceResource>{};
  String? cursor;
  final _cursors = <String?>{};
  void requireCursor() => _requireNewCursor(_cursors, cursor);
  bool accept(WorkspaceResourcePage page) {
    _add(page);
    cursor = page.nextResourceId;

    return result.length == ids.length;
  }

  void _add(WorkspaceResourcePage page) {
    for (final row in page.resources.where(
      (row) => ids.contains(row.resourceId),
    )) {
      result[(kind: kind, id: row.resourceId)] = row;
    }
  }
}
