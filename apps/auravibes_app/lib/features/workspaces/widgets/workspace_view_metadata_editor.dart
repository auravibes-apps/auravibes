import 'package:auravibes_app/features/workspaces/models/workspace_directory_move_item.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_view.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_directory_move_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_views_provider.dart';
import 'package:auravibes_app/features/workspaces/usecases/move_workspace_directory_items_usecase.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_editor.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspaceViewMetadataEditor({
  required final String workspaceId,
  required final WorkspaceView view,
  required final String? parentName,
  required final VoidCallback onBack,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usecase = ref.watch(
      workspaceDirectoryMoveUsecaseProvider(workspaceId).future,
    );

    return WorkspaceItemEditor(
      workspaceId: workspaceId,
      name: view.name,
      parentId: view.parentId,
      parentName: parentName,
      onBack: onBack,
      onSave: (name, parentId) =>
          _save(ref, usecase, (name: name, parentId: parentId)),
    );
  }

  Future<void> _save(
    WidgetRef ref,
    Future<MoveWorkspaceDirectoryItemsUsecase> ready,
    ({String name, String? parentId}) metadata,
  ) async {
    final usecase = await ready;
    if (!ref.context.mounted) return;
    await usecase([_item(metadata.name)], metadata.parentId);
    if (!ref.context.mounted) return;
    _refresh(ref, metadata.parentId);
  }

  void _refresh(WidgetRef ref, String? parentId) {
    ref
      ..invalidate(workspaceViewsProvider(workspaceId, view.parentId))
      ..invalidate(workspaceViewsProvider(workspaceId, parentId))
      ..invalidate(workspaceViewDataProvider(workspaceId, view.id));
  }

  WorkspaceDirectoryMoveItem _item(String name) => WorkspaceDirectoryMoveItem(
    key: (kind: .view, id: view.id),
    name: view.name,
    revision: view.revision,
    canManage: view.canManage,
    metadataName: name,
  );
}
