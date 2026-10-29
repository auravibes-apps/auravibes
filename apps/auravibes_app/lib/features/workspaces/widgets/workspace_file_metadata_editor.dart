import 'package:auravibes_app/features/workspaces/models/workspace_asset.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_assets_provider.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_editor.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspaceFileMetadataEditor({
  required final String workspaceId,
  required final WorkspaceFile file,
  required final String? parentName,
  required final VoidCallback onBack,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => WorkspaceItemEditor(
    workspaceId: workspaceId,
    name: file.name,
    parentId: file.parentId,
    parentName: parentName,
    onBack: onBack,
    onSave: (name, parentId) =>
        _save(ref, context, (name: name, parentId: parentId)),
  );

  Future<void> _save(
    WidgetRef ref,
    BuildContext context,
    ({String name, String? parentId}) input,
  ) async {
    final usecase = await ref.read(
      workspaceFilesUsecaseProvider(workspaceId).future,
    );
    final _ = await usecase.updateMetadata(
      file: file,
      name: input.name,
      parentId: input.parentId,
    );
    if (!context.mounted) return;
    ref.invalidate(workspaceFilesProvider);
  }
}
