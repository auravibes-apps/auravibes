import 'package:auravibes_app/features/workspaces/models/workspace_folder.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_view.dart';

typedef WorkspaceDirectoryItemKey = ({
  WorkspaceDirectoryItemKind kind,
  String id,
});

/// A selected item's expected revision is captured when selection begins.
class const WorkspaceDirectoryMoveItem({
  required final WorkspaceDirectoryItemKey key,
  required final String name,
  required final int revision,
  required final bool canManage,
  final String? metadataName,
}) {
  bool get _validName {
    final value = metadataName;
    if (value == null) return true;

    return key.kind == .view && value.trim().isNotEmpty && value.length <= 200;
  }

  static WorkspaceDirectoryMoveItem folder(WorkspaceFolder folder) => .new(
    key: (kind: .folder, id: folder.id),
    name: folder.name,
    revision: folder.revision,
    canManage: folder.canManage,
  );
  static WorkspaceDirectoryMoveItem table(WorkspaceTable table) => .new(
    key: (kind: .table, id: table.id),
    name: table.name,
    revision: table.revision,
    canManage: table.canManage,
  );
  static WorkspaceDirectoryMoveItem view(WorkspaceView view) => .new(
    key: (kind: .view, id: view.id),
    name: view.name,
    revision: view.revision,
    canManage: view.canManage,
  );

  bool canMoveTo(String? parentId) =>
      canManage &&
      revision > 0 &&
      key.id.isNotEmpty &&
      !(key.kind == .folder && key.id == parentId) &&
      _validName;
}

enum WorkspaceDirectoryItemKind { folder, table, view }

abstract interface class WorkspaceDirectoryMoveRepository {
  Future<void> move(List<WorkspaceDirectoryMoveItem> items, String? parentId);
}
