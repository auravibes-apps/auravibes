import 'package:auravibes_app/features/workspaces/models/workspace_content_report.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_content_report_action.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_history_policy.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_revision.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_trash_target.dart';
import 'package:auravibes_engine/auravibes_engine.dart';

class const ManageWorkspaceHistoryUsecase(
  final WorkspaceHistoryRepository repository,
) {
  Future<WorkspaceHistoryPolicy> policy() => repository.policy();

  Future<bool> configurePolicy(
    WorkspaceHistoryPolicy current,
    int? days, {
    required Future<bool> Function() approve,
    ConversationToolAccessMode mode = .defaultMode,
  }) async {
    WorkspaceHistoryPolicy.validate(days);
    if (!current.canManage) throw const WorkspaceTableException(denied: true);
    if (mode == .defaultMode && !await approve()) return false;
    await repository.configure(current, days);

    return true;
  }

  Future<List<WorkspaceRevision>> history(WorkspaceTrashTarget target) =>
      repository.history(target);

  Future<String> submitReport(WorkspaceTrashTarget target) =>
      repository.submitReport(target);

  Future<List<WorkspaceContentReport>> reports() => repository.reports();

  Future<WorkspaceContentReport?> resolveReport(
    String reportId,
    WorkspaceContentReportAction action, {
    required Future<bool> Function() approveRemoval,
    ConversationToolAccessMode mode = .defaultMode,
  }) async {
    if (action == .remove && mode == .defaultMode && !await approveRemoval()) {
      return null;
    }

    return await repository.resolveReport(reportId, action);
  }

  Future<bool> restore(
    WorkspaceTrashTarget target,
    int revision, {
    required Future<bool> Function() approve,
    ConversationToolAccessMode mode = .defaultMode,
  }) async {
    if (mode == .defaultMode && !await approve()) return false;
    await repository.restore(target, revision);

    return true;
  }

  Future<bool> permanentlyDelete(
    WorkspaceTrashTarget target, {
    required Future<bool> Function() approve,
    ConversationToolAccessMode mode = .defaultMode,
  }) async {
    if (mode == .defaultMode && !await approve()) return false;
    await repository.permanentlyDelete(target);

    return true;
  }
}
