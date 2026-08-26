import 'package:auravibes_app/domain/entities/workspace_entity.dart';

class WorkspaceSelection {
  const WorkspaceSelection({
    required this.workspaces,
    required this.savedWorkspaceId,
  });

  final List<WorkspaceEntity> workspaces;
  final String? savedWorkspaceId;
}
