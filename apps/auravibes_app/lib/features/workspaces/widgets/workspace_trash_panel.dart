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
    final action = WorkspaceTableActions.use(context);

    return _TrashLayout(
      panel: this,
      trash: trash,
      action: action,
      parentContext: context,
      ref: ref,
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

class const _TrashLayout({
  required final WorkspaceTrashPanel panel,
  required final AsyncValue<List<WorkspaceTrashBatch>> trash,
  required final WorkspaceTableAction action,
  required final BuildContext parentContext,
  required final WidgetRef ref,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        _TrashHeader(
          panel: panel,
          trash: trash,
          action: action,
          parentContext: parentContext,
          ref: ref,
        ),
        if (action.error case final Object error)
          WorkspaceItemFailure(error: error),
        Expanded(
          child: _TrashBody(workspaceId: panel.workspaceId, trash: trash),
        ),
      ],
    ),
  );
}

class const _TrashHeader({
  required final WorkspaceTrashPanel panel,
  required final AsyncValue<List<WorkspaceTrashBatch>> trash,
  required final WorkspaceTableAction action,
  required final BuildContext parentContext,
  required final WidgetRef ref,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: TextLocale(
          LocaleKeys.workspace_items_trash,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      _TrashDeleteAll(
        panel: panel,
        rows: trash.value,
        action: action,
        parentContext: parentContext,
        ref: ref,
      ),
      _TrashRefresh(workspaceId: panel.workspaceId),
      const _TrashClose(),
    ],
  );
}

class const _TrashDeleteAll({
  required final WorkspaceTrashPanel panel,
  required final List<WorkspaceTrashBatch>? rows,
  required final WorkspaceTableAction action,
  required final BuildContext parentContext,
  required final WidgetRef ref,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = rows;
    if (!_canDelete(items)) {
      return const SizedBox.shrink();
    }

    return AuraIconButton(
      icon: Icons.delete_sweep_outlined,
      onPressed: _deleteAll,
      disabled: action.pending,
      identifier: 'workspace_trash_delete_all',
      tooltip: LocaleKeys.workspace_items_trash_delete_all.tr(),
    );
  }

  bool _canDelete(List<WorkspaceTrashBatch>? items) =>
      items != null && items.isNotEmpty && items.every((row) => row.canRestore);

  void _deleteAll() {
    final items = rows;
    if (items == null) return;
    unawaited(action.run(() => panel._deleteAll(parentContext, ref, items)));
  }
}

class const _TrashRefresh({required final String workspaceId})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => AuraIconButton(
    icon: Icons.refresh,
    onPressed: () => ref.invalidate(workspaceTrashProvider(workspaceId)),
    identifier: 'workspace_trash_refresh',
    tooltip: LocaleKeys.workspace_items_trash_refresh.tr(),
  );
}

class const _TrashClose() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraIconButton(
    icon: Icons.close,
    onPressed: () => Navigator.of(context).pop(),
    identifier: 'workspace_trash_close',
    tooltip: LocaleKeys.workspace_items_trash_close.tr(),
  );
}

class const _TrashBody({
  required final String workspaceId,
  required final AsyncValue<List<WorkspaceTrashBatch>> trash,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (trash) {
    AsyncData(:final value) =>
      value.isEmpty
          ? const Center(
              child: TextLocale(LocaleKeys.workspace_items_trash_empty),
            )
          : ListView(
              children: [
                for (final row in value)
                  _TrashRow(workspaceId: workspaceId, batch: row),
              ],
            ),
    AsyncError(:final error) => WorkspaceItemFailure(error: error),
    AsyncLoading() => const Center(child: CircularProgressIndicator()),
  };
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
        _TrashRowContent(row: this, action: action, context: context, ref: ref),
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
      approve: () => _confirmPurge(context),
    );
    if (context.mounted && deleted) WorkspaceTrashActions.refresh(ref);
  }
}

class const _TrashRowContent({
  required final _TrashRow row,
  required final WorkspaceTableAction action,
  required final BuildContext context,
  required final WidgetRef ref,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: _TrashName(batch: row.batch)),
      if (row.batch.canRestore && !action.pending)
        _TrashRowMenu(
          row: row,
          action: action,
          parentContext: this.context,
          ref: ref,
        ),
      if (action.pending) const CircularProgressIndicator(),
    ],
  );
}

Future<bool> _confirmPurge(BuildContext context) =>
    WorkspaceHistoryApproval.ask(context, purge: true);

class const _TrashName({required final WorkspaceTrashBatch batch})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .start,
    children: [
      if (batch.name.isEmpty)
        const TextLocale(LocaleKeys.workspace_items_reference_deleted)
      else
        Text(batch.name),
      Text(
        '${batch.affectedCount}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );
}

class const _TrashRowMenu({
  required final _TrashRow row,
  required final WorkspaceTableAction action,
  required final BuildContext parentContext,
  required final WidgetRef ref,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraPopupMenuButton(
    items: [_restore(), _delete()],
    identifier: 'workspace_trash_menu_${row.batch.id}',
    tooltip: LocaleKeys.common_show_more.tr(),
  );

  AuraPopupMenuItem _restore() => AuraPopupMenuItem(
    title: const TextLocale(LocaleKeys.workspace_items_trash_restore),
    onTap: () => unawaited(action.run(() => row._restore(parentContext, ref))),
    identifier: 'workspace_trash_restore_${row.batch.id}',
  );

  AuraPopupMenuItem _delete() => AuraPopupMenuItem(
    title: const TextLocale(LocaleKeys.workspace_items_history_purge),
    onTap: () => unawaited(action.run(() => row._delete(parentContext, ref))),
    variant: .error,
    identifier: 'workspace_permanent_delete_${row.batch.target.id}',
  );
}
