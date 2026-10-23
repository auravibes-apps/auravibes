import 'package:auravibes_app/features/workspaces/models/workspace_folder.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_folders_provider.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_editor.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspaceFolderMetadataEditor({
  required final String workspaceId,
  required final WorkspaceFolder folder,
  required final String? parentName,
  required final VoidCallback onBack,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => WorkspaceItemEditor(
    workspaceId: workspaceId,
    name: folder.name,
    parentId: folder.parentId,
    parentName: parentName,
    onBack: onBack,
    onSave: (name, parentId) =>
        _save(ref, context, (name: name, parentId: parentId)),
    excludedFolderId: folder.id,
  );

  Future<void> _save(
    WidgetRef ref,
    BuildContext context,
    ({String name, String? parentId}) input,
  ) async {
    final usecase = await ref.read(
      workspaceFolderUsecaseProvider(workspaceId).future,
    );
    final _ = await usecase.updateMetadata(
      folder: folder,
      name: input.name,
      parentId: input.parentId,
    );
    if (!context.mounted) return;
    ref.invalidate(workspaceFoldersProvider);
  }
}
