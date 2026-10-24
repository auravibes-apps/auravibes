import 'package:auravibes_app/features/workspaces/models/workspace_trash_target.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_trash_provider.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_trash_restore_button.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspaceDeletedReferenceNotice({
  required final String workspaceId,
  required final String tableId,
  required final String recordId,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => _DeletedState(
    workspaceId: workspaceId,
    state: ref.watch(
      workspaceDeletedReferenceProvider(workspaceId, tableId, recordId),
    ),
  );
}

class const _DeletedState({
  required final String workspaceId,
  required final AsyncValue<WorkspaceDeletedReference?> state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (state) {
    AsyncData(value: final WorkspaceDeletedReference deleted) =>
      _DeletedActions(workspaceId: workspaceId, deleted: deleted),
    AsyncLoading() || AsyncData(value: null) || AsyncError() =>
      const TextLocale(LocaleKeys.workspace_items_reference_unavailable),
  };
}

class const _DeletedActions({
  required final String workspaceId,
  required final WorkspaceDeletedReference deleted,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: .min,
    children: [
      const TextLocale(LocaleKeys.workspace_items_reference_deleted),
      if (deleted.canRestore)
        WorkspaceTrashRestoreButton(
          workspaceId: workspaceId,
          batchId: deleted.batchId,
        ),
    ],
  );
}
