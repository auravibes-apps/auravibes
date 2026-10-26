import 'package:auravibes_app/features/workspaces/models/workspace_trash_target.dart';

class const WorkspaceContentReport({
  required final String reportId,
  required final WorkspaceTrashTarget target,
  required final String status,
  required final DateTime submittedAt,
  final String? conversationId,
  final String? reviewerUserId,
  final DateTime? reviewedAt,
});
