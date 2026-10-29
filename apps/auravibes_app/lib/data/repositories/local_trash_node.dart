import 'package:auravibes_app/features/workspaces/models/workspace_trash_target.dart';

class const LocalTrashNode({
  required final WorkspaceTrashKind kind,
  required final String id,
  required final String name,
  required final int revision,
  final String? parentId,
  final String? tableId,
  final bool deleted = false,
}) {
  factory fromJson(Map<String, dynamic> data) => .new(
    kind: _kind(data),
    id: data['id'] as String,
    name: data['name'] as String,
    revision: data['revision'] as int,
    parentId: data['parentId'] as String?,
    tableId: data['tableId'] as String?,
    deleted: data['deleted'] as bool? ?? false,
  );

  Map<String, Object?> toJson() => {
    'kind': kind.name,
    'id': id,
    'name': name,
    'revision': revision,
    'parentId': parentId,
    'tableId': tableId,
  };
}

WorkspaceTrashKind _kind(Map<String, dynamic> data) =>
    WorkspaceTrashKind.values.byName(data['kind'] as String);
