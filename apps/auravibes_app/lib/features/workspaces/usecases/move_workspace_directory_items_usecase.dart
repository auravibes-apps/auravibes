import 'package:auravibes_app/features/workspaces/models/workspace_directory_move_item.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';

class const MoveWorkspaceDirectoryItemsUsecase(
  final WorkspaceDirectoryMoveRepository repository,
) {
  static const maxItems = 50;
  Future<void> call(
    List<WorkspaceDirectoryMoveItem> items,
    String? parentId,
  ) async {
    if (items.isEmpty ||
        items.length > maxItems ||
        !_distinct(items) ||
        items.any((item) => !item.canMoveTo(parentId))) {
      throw const WorkspaceTableException();
    }
    await repository.move(items, parentId);
  }
}

bool _distinct(List<WorkspaceDirectoryMoveItem> items) =>
    items.map((item) => item.key).toSet().length == items.length;
