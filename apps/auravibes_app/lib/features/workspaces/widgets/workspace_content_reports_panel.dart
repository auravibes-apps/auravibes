import 'dart:async';

import 'package:auravibes_app/features/workspaces/models/workspace_content_report.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_content_report_action.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_history_provider.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_history_approval.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_failure.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_table_actions.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

const _reportDialogWidth = 600.0;
const _reportDialogHeightFactor = 0.85;
const _reportRowVerticalInset = 8.0;
const _reportActionSpacing = 8.0;

typedef _ReportActionInvocation = ({
  WorkspaceTableAction action,
  BuildContext context,
  WidgetRef ref,
  WorkspaceContentReportAction reportAction,
});

class const WorkspaceContentReportsPanel({
  required final String workspaceId,
  super.key,
}) extends HookConsumerWidget {
  static Future<void> open(BuildContext context, String workspaceId) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _ReportPanelDialog(workspaceId: workspaceId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
    padding: const EdgeInsets.all(16),
    child: _ReportPanelContents(workspaceId: workspaceId),
  );
}

class const _ReportPanelDialog({required final String workspaceId})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Dialog(
    child: SizedBox(
      width: _reportDialogWidth,
      height: MediaQuery.sizeOf(context).height * _reportDialogHeightFactor,
      child: WorkspaceContentReportsPanel(workspaceId: workspaceId),
    ),
  );
}

class const _ReportPanelContents({required final String workspaceId})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .stretch,
    children: [
      const TextLocale(LocaleKeys.workspace_items_history_reports_title),
      Flexible(child: _ReportResult(workspaceId: workspaceId)),
      AuraButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const TextLocale(LocaleKeys.common_cancel),
        variant: .ghost,
      ),
    ],
  );
}

class const _ReportResult({required final String workspaceId})
    extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final refresh = useState(0);
    final future = useMemoized(() => _load(ref, workspaceId), [
      workspaceId,
      refresh.value,
    ]);
    final snapshot = useFuture(future);

    return _ReportSnapshot(
      workspaceId: workspaceId,
      snapshot: snapshot,
      onResolved: () => refresh.value++,
    );
  }
}

class const _ReportSnapshot({
  required final String workspaceId,
  required final AsyncSnapshot<List<WorkspaceContentReport>> snapshot,
  required final VoidCallback onResolved,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (snapshot.error case final error?) {
      return WorkspaceItemFailure(error: error);
    }
    if (snapshot.data case final reports?) {
      return _ReportRows(
        workspaceId: workspaceId,
        reports: reports,
        onResolved: onResolved,
      );
    }

    return const Center(child: CircularProgressIndicator());
  }
}

class const _ReportRows({
  required final String workspaceId,
  required final List<WorkspaceContentReport> reports,
  required final VoidCallback onResolved,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => reports.isEmpty
      ? const Center(
          child: TextLocale(LocaleKeys.workspace_items_history_reports_empty),
        )
      : ListView(
          children: [
            for (final report in reports)
              _ReportRow(
                workspaceId: workspaceId,
                report: report,
                onResolved: onResolved,
              ),
          ],
        );
}

class const _ReportRow({
  required final String workspaceId,
  required final WorkspaceContentReport report,
  required final VoidCallback onResolved,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final action = WorkspaceTableActions.use(context);

    return _ReportRowCard(
      report: report,
      pending: action.pending,
      error: action.error,
      onDismiss: _run((
        action: action,
        context: context,
        ref: ref,
        reportAction: WorkspaceContentReportAction.dismiss,
      )),
      onRemove: _run((
        action: action,
        context: context,
        ref: ref,
        reportAction: WorkspaceContentReportAction.remove,
      )),
    );
  }

  VoidCallback _run(_ReportActionInvocation invocation) =>
      () => unawaited(
        invocation.action.run(
          () => _resolve(
            invocation.context,
            invocation.ref,
            invocation.reportAction,
            onResolved,
          ),
        ),
      );

  Future<void> _resolve(
    BuildContext context,
    WidgetRef ref,
    WorkspaceContentReportAction action,
    VoidCallback onResolved,
  ) async {
    final usecase = await ref.read(
      workspaceHistoryUsecaseProvider(workspaceId).future,
    );
    final result = await usecase.resolveReport(
      report.reportId,
      action,
      approveRemoval: () =>
          WorkspaceHistoryApproval.removeReportedContent(context),
    );
    if (context.mounted && result != null) onResolved();
  }
}

class const _ReportRowCard({
  required final WorkspaceContentReport report,
  required final bool pending,
  required final Object? error,
  required final VoidCallback onDismiss,
  required final VoidCallback onRemove,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: _reportRowVerticalInset),
    child: Column(
      crossAxisAlignment: .stretch,
      children: [
        _ReportTargetDetails(report: report),
        _ReportRowStatus(
          report: report,
          pending: pending,
          error: error,
          onDismiss: onDismiss,
          onRemove: onRemove,
        ),
      ],
    ),
  );
}

class const _ReportRowStatus({
  required final WorkspaceContentReport report,
  required final bool pending,
  required final Object? error,
  required final VoidCallback onDismiss,
  required final VoidCallback onRemove,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .stretch,
    children: [
      TextLocale(_status(report.status)),
      if (report.status == 'submitted')
        _ReportReviewActions(
          reportId: report.reportId,
          pending: pending,
          onDismiss: onDismiss,
          onRemove: onRemove,
        ),
      if (error case final Object failure) WorkspaceItemFailure(error: failure),
    ],
  );
}

class const _ReportTargetDetails({required final WorkspaceContentReport report})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .stretch,
    children: [
      TextLocale(
        LocaleKeys.workspace_items_history_report_target,
        args: [
          report.target.kind.name,
          report.target.id,
          '${report.target.revision}',
        ],
      ),
      if (report.conversationId case final String conversationId)
        TextLocale(
          LocaleKeys.workspace_items_history_conversation,
          args: [conversationId],
        ),
    ],
  );
}

class const _ReportReviewActions({
  required final String reportId,
  required final bool pending,
  required final VoidCallback onDismiss,
  required final VoidCallback onRemove,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: _reportActionSpacing,
    children: [
      _ReportActionButton(
        reportId: reportId,
        action: .dismiss,
        pending: pending,
        onPressed: onDismiss,
      ),
      _ReportActionButton(
        reportId: reportId,
        action: .remove,
        pending: pending,
        onPressed: onRemove,
      ),
    ],
  );
}

class const _ReportActionButton({
  required final String reportId,
  required final WorkspaceContentReportAction action,
  required final bool pending,
  required final VoidCallback onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: onPressed,
    child: TextLocale(_actionLabel(action)),
    variant: action == .dismiss ? .ghost : .primary,
    disabled: pending,
    identifier: 'workspace_report_${action.name}_$reportId',
  );
}

Future<List<WorkspaceContentReport>> _load(
  WidgetRef ref,
  String workspaceId,
) async {
  final usecase = await ref.read(
    workspaceHistoryUsecaseProvider(workspaceId).future,
  );

  return await usecase.reports();
}

String _status(String status) => switch (status) {
  'submitted' => LocaleKeys.workspace_items_history_report_submitted,
  'dismissed' => LocaleKeys.workspace_items_history_report_dismissed,
  'removed' => LocaleKeys.workspace_items_history_report_removed,
  _ => LocaleKeys.workspace_items_history_report_submitted,
};

String _actionLabel(WorkspaceContentReportAction action) => switch (action) {
  .dismiss => LocaleKeys.workspace_items_history_report_dismiss,
  .remove => LocaleKeys.workspace_items_history_report_remove,
};
