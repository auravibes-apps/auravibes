import 'dart:async';

import 'package:auravibes_app/features/workspaces/models/workspace_revision.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_trash_target.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_history_provider.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_content_reports_panel.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_history_approval.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_history_policy_button.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_history_policy_summary.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_failure.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_table_actions.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_trash_actions.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

typedef WorkspaceHistoryPanelOptions = ({
  String workspaceId,
  WorkspaceTrashTarget target,
  bool canRestore,
});

const _historyDialogWidth = 600.0;
const _historyDialogHeightFactor = 0.85;
const _compactHistoryHeaderWidth = 480.0;
const _historyHeaderActionSpacing = 8.0;

class const WorkspaceHistoryPanel({
  required final String workspaceId,
  required final WorkspaceTrashTarget target,
  final bool canRestore = true,
  super.key,
}) extends HookConsumerWidget {
  static Future<bool?> open(
    BuildContext context,
    WorkspaceHistoryPanelOptions options,
  ) => showDialog<bool>(
    context: context,
    builder: (context) => _HistoryPanelDialog(options: options),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = _useHistory(ref, workspaceId, target);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          _HistoryHeader(workspaceId: workspaceId),
          Flexible(
            child: _HistoryResult(
              workspaceId: workspaceId,
              target: target,
              canRestore: canRestore,
              snapshot: snapshot,
            ),
          ),
          const _CloseHistory(),
        ],
      ),
    );
  }
}

class const _HistoryPanelDialog({
  required final WorkspaceHistoryPanelOptions options,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Dialog(
    child: SizedBox(
      width: _historyDialogWidth,
      height: MediaQuery.sizeOf(context).height * _historyDialogHeightFactor,
      child: WorkspaceHistoryPanel(
        workspaceId: options.workspaceId,
        target: options.target,
        canRestore: options.canRestore,
      ),
    ),
  );
}

AsyncSnapshot<List<WorkspaceRevision>> _useHistory(
  WidgetRef ref,
  String workspaceId,
  WorkspaceTrashTarget target,
) {
  final policyRevision = ref
      .watch(workspaceHistoryPolicyProvider(workspaceId))
      .value
      ?.revision;
  final future = useMemoized(() => _loadHistory(ref, workspaceId, target), [
    workspaceId,
    target.id,
    target.revision,
    policyRevision,
  ]);

  return useFuture(future);
}

class const _HistoryHeader({required final String workspaceId})
    extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canManage = ref
        .watch(workspaceHistoryPolicyProvider(workspaceId))
        .value
        ?.canManage;

    return _HistoryHeaderLayout(
      workspaceId: workspaceId,
      canManage: canManage == true,
    );
  }
}

class const _HistoryHeaderLayout({
  required final String workspaceId,
  required final bool canManage,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) =>
        constraints.maxWidth < _compactHistoryHeaderWidth
        ? _CompactHistoryHeader(workspaceId: workspaceId, canManage: canManage)
        : _WideHistoryHeader(workspaceId: workspaceId, canManage: canManage),
  );
}

class const _CompactHistoryHeader({
  required final String workspaceId,
  required final bool canManage,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .stretch,
    children: [
      const TextLocale(LocaleKeys.workspace_items_history_title),
      Align(
        alignment: AlignmentDirectional.centerEnd,
        child: _HistoryHeaderActions(
          workspaceId: workspaceId,
          canManage: canManage,
        ),
      ),
    ],
  );
}

class const _WideHistoryHeader({
  required final String workspaceId,
  required final bool canManage,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Expanded(
        child: TextLocale(LocaleKeys.workspace_items_history_title),
      ),
      _HistoryHeaderActions(workspaceId: workspaceId, canManage: canManage),
    ],
  );
}

class const _HistoryHeaderActions({
  required final String workspaceId,
  required final bool canManage,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Wrap(
    alignment: .end,
    spacing: _historyHeaderActionSpacing,
    crossAxisAlignment: .center,
    children: [
      if (canManage)
        AuraButton(
          onPressed: () => unawaited(
            WorkspaceContentReportsPanel.open(context, workspaceId),
          ),
          child: const TextLocale(LocaleKeys.workspace_items_history_reports),
          variant: .ghost,
          identifier: 'workspace_content_reports',
        ),
      WorkspaceHistoryPolicyButton(workspaceId: workspaceId),
    ],
  );
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
  required final bool canRestore,
  required final AsyncSnapshot<List<WorkspaceRevision>> snapshot,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (snapshot.error case final error?) {
      return WorkspaceItemFailure(error: error);
    }
    if (snapshot.data case final rows?) {
      return _HistoryRows(
        workspaceId: workspaceId,
        target: target,
        canRestore: canRestore,
        rows: rows,
      );
    }

    return const Center(child: CircularProgressIndicator());
  }
}

class const _HistoryRows({
  required final String workspaceId,
  required final WorkspaceTrashTarget target,
  required final bool canRestore,
  required final List<WorkspaceRevision> rows,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView(
    children: [
      if (rows.isEmpty)
        const TextLocale(LocaleKeys.workspace_items_history_empty),
      for (final row in rows)
        _RevisionRow(
          workspaceId: workspaceId,
          target: target,
          canRestore: canRestore,
          revision: row,
        ),
      WorkspaceHistoryPolicySummary(workspaceId: workspaceId),
    ],
  );
}

class const _RevisionRow({
  required final String workspaceId,
  required final WorkspaceTrashTarget target,
  required final bool canRestore,
  required final WorkspaceRevision revision,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final action = WorkspaceTableActions.use(context);

    return _RevisionRowContent(
      workspaceId: workspaceId,
      revision: revision,
      action: action,
      target: target,
      canRestore: canRestore,
      onRestore: () => unawaited(action.run(() => _restore(context, ref))),
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
      approve: () => _approveRestore(context),
    );
    if (context.mounted) _complete(context, ref, restored);
  }

  void _complete(BuildContext context, WidgetRef ref, bool restored) {
    if (!context.mounted || !restored) return;
    WorkspaceTrashActions.refresh(ref);
    Navigator.of(context).pop(true);
  }
}

class const _RevisionRowContent({
  required final String workspaceId,
  required final WorkspaceRevision revision,
  required final WorkspaceTableAction action,
  required final WorkspaceTrashTarget target,
  required final bool canRestore,
  required final VoidCallback onRestore,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .stretch,
    children: [
      _RevisionContent(
        revision: revision,
        action: action,
        target: target,
        canRestore: canRestore,
        onPressed: onRestore,
      ),
      if (revision.aiInvolved == true)
        _RevisionReportButton(workspaceId: workspaceId, revision: revision),
    ],
  );
}

class const _RevisionReportButton({
  required final String workspaceId,
  required final WorkspaceRevision revision,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final action = WorkspaceTableActions.use(context);
    final receipt = useState<String?>(null);

    return _RevisionReportButtonContent(
      revision: revision,
      action: action,
      receipt: receipt.value,
      onPressed: _revisionReportCallback((
        action: action,
        submit: () => _submit(context, ref, receipt),
      )),
    );
  }

  Future<void> _submit(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<String?> receipt,
  ) async {
    final usecase = await ref.read(
      workspaceHistoryUsecaseProvider(workspaceId).future,
    );
    final reportId = await usecase.submitReport(revision.target);
    if (context.mounted) receipt.value = reportId;
  }
}

typedef _RevisionReportSubmission = ({
  WorkspaceTableAction action,
  Future<void> Function() submit,
});

VoidCallback _revisionReportCallback(_RevisionReportSubmission request) =>
    () => unawaited(request.action.run(request.submit));

class const _RevisionReportButtonContent({
  required final WorkspaceRevision revision,
  required final WorkspaceTableAction action,
  required final String? receipt,
  required final VoidCallback onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .stretch,
    children: [
      AuraButton(
        onPressed: onPressed,
        child: const TextLocale(LocaleKeys.workspace_items_history_report),
        variant: .ghost,
        disabled: action.pending,
        identifier: 'workspace_history_report_${revision.target.revision}',
      ),
      _RevisionReportState(receipt: receipt, error: action.error),
    ],
  );
}

class const _RevisionReportState({
  required final String? receipt,
  required final Object? error,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .stretch,
    children: [
      if (receipt case final String reportId)
        TextLocale(
          LocaleKeys.workspace_items_history_report_receipt,
          args: [reportId],
        ),
      if (error case final Object failure) WorkspaceItemFailure(error: failure),
    ],
  );
}

class const _RevisionContent({
  required final WorkspaceRevision revision,
  required final WorkspaceTableAction action,
  required final WorkspaceTrashTarget target,
  required final bool canRestore,
  required final VoidCallback onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: _RevisionBody(
      revision: revision,
      action: action,
      target: target,
      canRestore: canRestore,
      onPressed: onPressed,
    ),
  );
}

class const _RevisionBody({
  required final WorkspaceRevision revision,
  required final WorkspaceTableAction action,
  required final WorkspaceTrashTarget target,
  required final bool canRestore,
  required final VoidCallback onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: .min,
    crossAxisAlignment: .stretch,
    children: [
      _RevisionDetails(revision: revision),
      if (canRestore && revision.target.revision != target.revision)
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
    children: [
      Text('${revision.target.revision}'),
      _RevisionActorAndOperation(revision: revision),
      _RevisionConversation(revision: revision),
      _RevisionCaptureTime(revision: revision),
      TextLocale(_summary(revision)),
    ],
  );
}

class const _RevisionActorAndOperation({
  required final WorkspaceRevision revision,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .stretch,
    children: [
      if (revision.actorUserId case final String actor)
        TextLocale(LocaleKeys.workspace_items_history_actor, args: [actor]),
      if (revision.actorUserId == null)
        const TextLocale(LocaleKeys.workspace_items_history_actor_unknown),
      if (revision.operation case final String operation)
        TextLocale(
          LocaleKeys.workspace_items_history_operation,
          args: [_operationLabel(operation)],
        ),
    ],
  );
}

class const _RevisionConversation({required final WorkspaceRevision revision})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .stretch,
    children: [
      if (revision.aiInvolved == true)
        const TextLocale(LocaleKeys.workspace_items_history_ai_involved),
      if (revision.conversationId case final String conversationId)
        TextLocale(
          LocaleKeys.workspace_items_history_conversation,
          args: [conversationId],
        ),
    ],
  );
}

class const _RevisionCaptureTime({required final WorkspaceRevision revision})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (revision.capturedAt) {
    final capturedAt? => TextLocale(
      LocaleKeys.workspace_items_history_captured_at,
      args: [capturedAt.toLocal().toString()],
    ),
    null => const SizedBox.shrink(),
  };
}

String _operationLabel(String operation) => switch (operation) {
  'create' ||
  'created' => LocaleKeys.workspace_items_history_report_action_created,
  'update' ||
  'updated' => LocaleKeys.workspace_items_history_report_action_updated,
  'delete' ||
  'deleted' => LocaleKeys.workspace_items_history_report_action_deleted,
  _ => LocaleKeys.workspace_items_history_report_action_unknown,
};

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

String _summary(WorkspaceRevision revision) => revision.target.kind == .table
    ? LocaleKeys.workspace_items_history_table_revision
    : LocaleKeys.workspace_items_history_record_revision;

Future<List<WorkspaceRevision>> _loadHistory(
  WidgetRef ref,
  String workspaceId,
  WorkspaceTrashTarget target,
) async =>
    await (await ref.read(workspaceHistoryUsecaseProvider(workspaceId).future))
        .history(target);

Future<bool> _approveRestore(BuildContext context) =>
    WorkspaceHistoryApproval.ask(context, purge: false);
