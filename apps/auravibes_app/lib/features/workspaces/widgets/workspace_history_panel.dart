import 'dart:async';

import 'package:auravibes_app/features/workspaces/models/workspace_revision.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_trash_target.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_history_provider.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_failure.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_table_actions.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_trash_actions.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspaceHistoryPanel({
  required final String workspaceId,
  required final WorkspaceTrashTarget target,
  super.key,
}) extends HookConsumerWidget {
  static Future<void> open(
    BuildContext context,
    String workspaceId,
    WorkspaceTrashTarget target,
  ) => showDialog<void>(
    context: context,
    builder: (_) => Dialog(
      child: SizedBox(
        width: 600,
        child: WorkspaceHistoryPanel(workspaceId: workspaceId, target: target),
      ),
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final future = useMemoized(() async {
      final usecase = await ref.read(
        workspaceHistoryUsecaseProvider(workspaceId).future,
      );
      return await usecase.history(target);
    }, [workspaceId, target.id, target.revision]);
    final rows = useFuture(future);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .stretch,
        children: [
          const TextLocale(LocaleKeys.workspace_items_history_title),
          const TextLocale(LocaleKeys.workspace_items_history_retention),
          Flexible(
            child: rows.hasError
                ? WorkspaceItemFailure(error: rows.error!)
                : rows.data == null
                ? const Center(child: CircularProgressIndicator())
                : _HistoryRows(
                    workspaceId: workspaceId,
                    target: target,
                    rows: rows.data!,
                  ),
          ),
          AuraButton(
            onPressed: () => Navigator.of(context).pop(),
            variant: .ghost,
            child: const TextLocale(LocaleKeys.common_cancel),
          ),
        ],
      ),
    );
  }
}

class const _HistoryRows({
  required final String workspaceId,
  required final WorkspaceTrashTarget target,
  required final List<WorkspaceRevision> rows,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => rows.isEmpty
      ? const TextLocale(LocaleKeys.workspace_items_history_empty)
      : ListView(
          shrinkWrap: true,
          children: [
            for (final row in rows)
              _RevisionRow(
                workspaceId: workspaceId,
                target: target,
                revision: row,
              ),
          ],
        );
}

class const _RevisionRow({
  required final String workspaceId,
  required final WorkspaceTrashTarget target,
  required final WorkspaceRevision revision,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final action = WorkspaceTableActions.use(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: .stretch,
        mainAxisSize: .min,
        children: [
          Text('${revision.target.revision}'),
          Text(_summary(revision)),
          if (revision.target.revision != target.revision)
            AuraButton(
              identifier:
                  'workspace_history_restore_${revision.target.revision}',
              isLoading: action.pending,
              disabled: action.pending,
              onPressed: () =>
                  unawaited(action.run(() => _restore(context, ref))),
              child: const TextLocale(
                LocaleKeys.workspace_items_history_restore,
              ),
            ),
          if (action.error case final Object error)
            WorkspaceItemFailure(error: error),
        ],
      ),
    );
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final usecase = await ref.read(
      workspaceHistoryUsecaseProvider(workspaceId).future,
    );
    if (!context.mounted) return;
    final restored = await usecase.restore(
      target,
      revision.target.revision,
      approve: () => approveWorkspaceHistory(context, purge: false),
    );
    if (!context.mounted || !restored) return;
    WorkspaceTrashActions.refresh(ref);
    Navigator.of(context).pop();
  }
}

String _summary(WorkspaceRevision revision) {
  final columns = revision.data['columns'];
  if (columns is List)
    return columns
        .cast<Map<String, dynamic>>()
        .map((column) => column['name'])
        .join(', ');
  final values = revision.data['values'];
  return values is Map ? values.values.map((value) => '$value').join(', ') : '';
}

Future<bool> approveWorkspaceHistory(
  BuildContext context, {
  required bool purge,
}) async {
  final approved = await showDialog<bool>(
    context: context,
    builder: (_) => _HistoryApproval(purge: purge),
  );
  return approved ?? false;
}

class const _HistoryApproval({required final bool purge})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Dialog(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: .min,
            crossAxisAlignment: .stretch,
            children: [
              TextLocale(
                purge
                    ? LocaleKeys.workspace_items_history_purge_notice
                    : LocaleKeys.workspace_items_history_restore_notice,
              ),
              AuraButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: TextLocale(
                  purge
                      ? LocaleKeys.workspace_items_history_purge
                      : LocaleKeys.workspace_items_history_restore,
                ),
              ),
              AuraButton(
                onPressed: () => Navigator.of(context).pop(false),
                variant: .ghost,
                child: const TextLocale(LocaleKeys.common_cancel),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
