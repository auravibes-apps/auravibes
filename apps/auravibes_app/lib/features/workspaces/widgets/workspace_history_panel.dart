import 'dart:async';

import 'package:auravibes_app/features/workspaces/models/workspace_revision.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_trash_target.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_history_provider.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_history_approval.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_history_policy_settings.dart';
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
    final snapshot = _useHistory(ref, workspaceId, target);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .stretch,
        children: [
          _HistoryHeader(workspaceId: workspaceId),
          Flexible(
            child: _HistoryResult(
              workspaceId: workspaceId,
              target: target,
              snapshot: snapshot,
            ),
          ),
          const _CloseHistory(),
        ],
      ),
    );
  }
}

AsyncSnapshot<List<WorkspaceRevision>> _useHistory(
  WidgetRef ref,
  String workspaceId,
  WorkspaceTrashTarget target,
) {
  final policyRevision = ref.watch(workspaceHistoryPolicyProvider(workspaceId)).value?.revision;
  final future = useMemoized(() async {
    final usecase = await ref.read(
      workspaceHistoryUsecaseProvider(workspaceId).future,
    );

    return await usecase.history(target);
  }, [workspaceId, target.id, target.revision, policyRevision]);

  return useFuture(future);
}

class const _HistoryHeader({required final String workspaceId}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(children: [const Expanded(child: TextLocale(LocaleKeys.workspace_items_history_title)), WorkspaceHistoryPolicyButton(workspaceId: workspaceId)]);
}

class const _CloseHistory() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: () => Navigator.of(context).pop(),
    child: const TextLocale(LocaleKeys.common_cancel),
    variant: .ghost,
  );
}

class const _HistoryResult({
  required final String workspaceId,
  required final WorkspaceTrashTarget target,
  required final AsyncSnapshot<List<WorkspaceRevision>> snapshot,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (snapshot.error case final error?) {
      return WorkspaceItemFailure(error: error);
    }
    if (snapshot.data case final rows?) {
      return _HistoryRows(workspaceId: workspaceId, target: target, rows: rows);
    }

    return const Center(child: CircularProgressIndicator());
  }
}

class const _HistoryRows({
  required final String workspaceId,
  required final WorkspaceTrashTarget target,
  required final List<WorkspaceRevision> rows,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView(
    shrinkWrap: true,
    children: [
      if (rows.isEmpty)
        const TextLocale(LocaleKeys.workspace_items_history_empty),
      for (final row in rows)
        _RevisionRow(workspaceId: workspaceId, target: target, revision: row),
      WorkspaceHistoryPolicySummary(workspaceId: workspaceId),
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

    return _RevisionContent(
      revision: revision,
      action: action,
      target: target,
      onPressed: () => unawaited(action.run(() => _restore(context, ref))),
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
      approve: () => WorkspaceHistoryApproval.ask(context, purge: false),
    );
    if (context.mounted) _complete(context, ref, restored);
  }

  void _complete(BuildContext context, WidgetRef ref, bool restored) {
    if (!context.mounted || !restored) return;
    WorkspaceTrashActions.refresh(ref);
    Navigator.of(context).pop();
  }
}

class const _RevisionContent({
  required final WorkspaceRevision revision,
  required final WorkspaceTableAction action,
  required final WorkspaceTrashTarget target,
  required final VoidCallback onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: _RevisionBody(
      revision: revision,
      action: action,
      target: target,
      onPressed: onPressed,
    ),
  );
}

class const _RevisionBody({
  required final WorkspaceRevision revision,
  required final WorkspaceTableAction action,
  required final WorkspaceTrashTarget target,
  required final VoidCallback onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: .min,
    crossAxisAlignment: .stretch,
    children: [
      _RevisionDetails(revision: revision),
      if (revision.target.revision != target.revision)
        _RestoreRevision(
          action: action,
          revision: revision.target.revision,
          onPressed: onPressed,
        ),
      if (action.error case final Object error)
        WorkspaceItemFailure(error: error),
    ],
  );
}

class const _RevisionDetails({required final WorkspaceRevision revision})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: .min,
    crossAxisAlignment: .stretch,
    children: [Text('${revision.target.revision}'), Text(_summary(revision))],
  );
}

class const _RestoreRevision({
  required final WorkspaceTableAction action,
  required final int revision,
  required final VoidCallback onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: onPressed,
    child: const TextLocale(LocaleKeys.workspace_items_history_restore),
    isLoading: action.pending,
    disabled: action.pending,
    identifier: 'workspace_history_restore_$revision',
  );
}

String _summary(WorkspaceRevision revision) {
  final columns = revision.data['columns'];
  if (columns is List) {
    return columns
        .cast<Map<String, dynamic>>()
        .map((column) => column['name'])
        .join(', ');
  }
  final values = revision.data['values'];

  return values is Map ? values.values.map((value) => '$value').join(', ') : '';
}
