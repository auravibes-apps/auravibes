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

class const WorkspaceContentReportsPanel({
  required final String workspaceId,
  super.key,
}) extends HookConsumerWidget {
  static Future<void> open(BuildContext context, String workspaceId) async {
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: 600,
          height: MediaQuery.sizeOf(context).height * 0.85,
          child: WorkspaceContentReportsPanel(workspaceId: workspaceId),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final refresh = useState(0);
    final future = useMemoized(() => _load(ref, workspaceId), [
      workspaceId,
      refresh.value,
    ]);
    final snapshot = useFuture(future);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          const TextLocale(LocaleKeys.workspace_items_history_reports_title),
          Flexible(
            child: _ReportResult(
              workspaceId: workspaceId,
              snapshot: snapshot,
              onResolved: () => refresh.value++,
            ),
          ),
          AuraButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const TextLocale(LocaleKeys.common_cancel),
            variant: .ghost,
          ),
        ],
      ),
    );
  }
}

class const _ReportResult({
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
      if (reports.isEmpty) {
        return const Center(
          child: TextLocale(LocaleKeys.workspace_items_history_reports_empty),
        );
      }

      return ListView(
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

    return const Center(child: CircularProgressIndicator());
  }
}

class const _ReportRow({
  required final String workspaceId,
  required final WorkspaceContentReport report,
  required final VoidCallback onResolved,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final action = WorkspaceTableActions.use(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
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
          TextLocale(_status(report.status)),
          if (report.status == 'submitted')
            Wrap(
              spacing: 8,
              children: [
                AuraButton(
                  onPressed: () => unawaited(
                    action.run(
                      () => _resolve(context, ref, .dismiss, onResolved),
                    ),
                  ),
                  child: const TextLocale(
                    LocaleKeys.workspace_items_history_report_dismiss,
                  ),
                  variant: .ghost,
                  disabled: action.pending,
                  identifier: 'workspace_report_dismiss_${report.reportId}',
                ),
                AuraButton(
                  onPressed: () => unawaited(
                    action.run(
                      () => _resolve(context, ref, .remove, onResolved),
                    ),
                  ),
                  child: const TextLocale(
                    LocaleKeys.workspace_items_history_report_remove,
                  ),
                  disabled: action.pending,
                  identifier: 'workspace_report_remove_${report.reportId}',
                ),
              ],
            ),
          if (action.error case final Object error)
            WorkspaceItemFailure(error: error),
        ],
      ),
    );
  }

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
