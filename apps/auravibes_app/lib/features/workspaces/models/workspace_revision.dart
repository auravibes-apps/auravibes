import 'package:auravibes_app/features/workspaces/models/workspace_content_report.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_content_report_action.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_history_policy.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_trash_target.dart';

class const WorkspaceRevision({
  required final WorkspaceTrashTarget target,
  required final Map<String, dynamic> data,
  final String? actorUserId,
  final bool? aiInvolved,
  final String? operation,
  final String? conversationId,
  final DateTime? capturedAt,
});

abstract interface class WorkspaceHistoryRepository
    implements WorkspaceHistoryPolicyRepository {
  Future<List<WorkspaceRevision>> history(WorkspaceTrashTarget target);
  Future<String> submitReport(WorkspaceTrashTarget target);
  Future<List<WorkspaceContentReport>> reports();
  Future<WorkspaceContentReport> resolveReport(
    String reportId,
    WorkspaceContentReportAction action,
  );
  Future<void> restore(WorkspaceTrashTarget target, int revision);
  Future<void> permanentlyDelete(WorkspaceTrashTarget target);
}
