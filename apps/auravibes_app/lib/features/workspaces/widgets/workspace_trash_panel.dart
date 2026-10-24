import 'package:auravibes_app/features/workspaces/models/workspace_trash_target.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_trash_provider.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_failure.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_trash_restore_button.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspaceTrashPanel({required final String workspaceId, super.key})
    extends StatelessWidget {
  static Future<void> open(BuildContext context, String workspaceId) =>
      showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          child: SizedBox(
            width: 600,
            child: WorkspaceTrashPanel(workspaceId: workspaceId),
          ),
        ),
      );
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      mainAxisSize: .min,
      children: [
        const TextLocale(LocaleKeys.workspace_items_trash),
        Flexible(child: _TrashContent(workspaceId: workspaceId)),
        _TrashRefresh(workspaceId: workspaceId),
        const _TrashClose(),
      ],
    ),
  );
}

class const _TrashContent({required final String workspaceId})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      switch (ref.watch(workspaceTrashProvider(workspaceId))) {
        AsyncData(:final value) => _TrashRows(
          workspaceId: workspaceId,
          rows: value,
        ),
        AsyncError(:final error) => WorkspaceItemFailure(error: error),
        AsyncLoading() => const CircularProgressIndicator(),
      };
}

class const _TrashRows({
  required final String workspaceId,
  required final List<WorkspaceTrashBatch> rows,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => rows.isEmpty
      ? const TextLocale(LocaleKeys.workspace_items_trash_empty)
      : ListView(
          children: [
            for (final row in rows)
              _TrashRow(workspaceId: workspaceId, batch: row),
          ],
        );
}

class const _TrashRow({
  required final String workspaceId,
  required final WorkspaceTrashBatch batch,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: .min,
    crossAxisAlignment: .stretch,
    children: [
      if (batch.name.isEmpty)
        const TextLocale(LocaleKeys.workspace_items_reference_deleted)
      else
        Text(batch.name),
      Text('${batch.affectedCount}'),
      if (batch.canRestore)
        WorkspaceTrashRestoreButton(
          workspaceId: workspaceId,
          batchId: batch.id,
        ),
    ],
  );
}

class const _TrashRefresh({required final String workspaceId})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => AuraButton(
    onPressed: () => ref.invalidate(workspaceTrashProvider(workspaceId)),
    child: const TextLocale(LocaleKeys.workspace_items_trash_refresh),
  );
}

class const _TrashClose() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: () => Navigator.of(context).pop(),
    child: const TextLocale(LocaleKeys.workspace_items_trash_close),
    variant: .ghost,
  );
}
