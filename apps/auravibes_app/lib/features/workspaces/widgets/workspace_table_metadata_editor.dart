import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_tables_provider.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_editor.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspaceTableMetadataEditor({
  required final String workspaceId,
  required final WorkspaceTable table,
  required final String? parentName,
  required final VoidCallback onBack,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => WorkspaceItemEditor(
    workspaceId: workspaceId,
    name: table.name,
    parentId: table.parentId,
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
      workspaceTableUsecaseProvider(workspaceId).future,
    );
    final _ = await usecase.updateMetadata(
      table: table,
      name: input.name,
      parentId: input.parentId,
    );
    if (!context.mounted) return;
    ref.invalidate(workspaceTablesProvider);
  }
}
