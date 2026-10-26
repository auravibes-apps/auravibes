import 'dart:async';

import 'package:auravibes_app/features/workspaces/models/workspace_trash_target.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_history_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_trash_provider.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_history_approval.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_failure.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_table_actions.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_trash_actions.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_trash_restore_button.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspaceTrashPanel({required final String workspaceId, super.key})
    extends HookConsumerWidget {
  static Future<void> open(BuildContext context, String workspaceId) =>
      showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          child: SizedBox(
            width: 600,
            height: 560,
            child: WorkspaceTrashPanel(workspaceId: workspaceId),
          ),
        ),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trash = ref.watch(workspaceTrashProvider(workspaceId));
    final rows = trash.value;
    final action = WorkspaceTableActions.use(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextLocale(
                  LocaleKeys.workspace_items_trash,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (rows != null &&
                  rows.isNotEmpty &&
                  rows.every((row) => row.canRestore))
                AuraIconButton(
                  icon: Icons.delete_sweep_outlined,
                  onPressed: () => unawaited(
                    action.run(() => _deleteAll(context, ref, rows)),
                  ),
                  disabled: action.pending,
                  identifier: 'workspace_trash_delete_all',
                  tooltip: LocaleKeys.workspace_items_trash_delete_all.tr(),
                ),
              AuraIconButton(
                icon: Icons.refresh,
                onPressed: () =>
                    ref.invalidate(workspaceTrashProvider(workspaceId)),
                identifier: 'workspace_trash_refresh',
                tooltip: LocaleKeys.workspace_items_trash_refresh.tr(),
              ),
              AuraIconButton(
                icon: Icons.close,
                onPressed: () => Navigator.of(context).pop(),
                identifier: 'workspace_trash_close',
                tooltip: LocaleKeys.workspace_items_trash_close.tr(),
              ),
            ],
          ),
          if (action.error case final Object error)
            WorkspaceItemFailure(error: error),
          Expanded(
            child: switch (trash) {
              AsyncData(:final value) =>
                value.isEmpty
                    ? const Center(
                        child: TextLocale(
                          LocaleKeys.workspace_items_trash_empty,
                        ),
                      )
                    : ListView(
                        children: [
                          for (final row in value)
                            _TrashRow(workspaceId: workspaceId, batch: row),
                        ],
                      ),
              AsyncError(:final error) => WorkspaceItemFailure(error: error),
              AsyncLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
            },
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAll(
    BuildContext context,
    WidgetRef ref,
    List<WorkspaceTrashBatch> rows,
  ) async {
    if (!await WorkspaceHistoryApproval.trashAction(context, all: true)) return;
    if (!context.mounted) return;
    final usecase = await ref.read(
      workspaceHistoryUsecaseProvider(workspaceId).future,
    );
    try {
      for (final row in rows) {
        final _ = await usecase.permanentlyDelete(
          row.target,
          approve: () async => true,
        );
      }
    } finally {
      if (context.mounted) WorkspaceTrashActions.refresh(ref);
    }
  }
}

class const _TrashRow({
  required final String workspaceId,
  required final WorkspaceTrashBatch batch,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final action = WorkspaceTableActions.use(context);

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  if (batch.name.isEmpty)
                    const TextLocale(
                      LocaleKeys.workspace_items_reference_deleted,
                    )
                  else
                    Text(batch.name),
                  Text(
                    '${batch.affectedCount}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (batch.canRestore && !action.pending)
              AuraPopupMenuButton(
                items: [
                  AuraPopupMenuItem(
                    title: const TextLocale(
                      LocaleKeys.workspace_items_trash_restore,
                    ),
                    onTap: () =>
                        unawaited(action.run(() => _restore(context, ref))),
                    identifier: 'workspace_trash_restore_${batch.id}',
                  ),
                  AuraPopupMenuItem(
                    title: const TextLocale(
                      LocaleKeys.workspace_items_history_purge,
                    ),
                    onTap: () =>
                        unawaited(action.run(() => _delete(context, ref))),
                    variant: .error,
                    identifier: 'workspace_permanent_delete_${batch.target.id}',
                  ),
                ],
                identifier: 'workspace_trash_menu_${batch.id}',
                tooltip: LocaleKeys.common_show_more.tr(),
              ),
            if (action.pending) const CircularProgressIndicator(),
          ],
        ),
        if (action.error case final Object error)
          WorkspaceItemFailure(error: error),
      ],
    );
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    if (!await WorkspaceHistoryApproval.trashAction(context, all: false)) {
      return;
    }
    if (context.mounted) {
      await restoreTrashBatch(context, ref, workspaceId, batch.id);
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final usecase = await ref.read(
      workspaceHistoryUsecaseProvider(workspaceId).future,
    );
    if (!context.mounted) return;
    final deleted = await usecase.permanentlyDelete(
      batch.target,
      approve: () => WorkspaceHistoryApproval.ask(context, purge: true),
    );
    if (context.mounted && deleted) WorkspaceTrashActions.refresh(ref);
  }
}
