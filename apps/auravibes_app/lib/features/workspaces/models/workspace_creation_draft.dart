/// Non-secret state retained while a workspace task authenticates.
class const WorkspaceCreationDraft({
  final String name = '',
  final String target = '',
  final WorkspaceCreationIntent intent = .local,
});

enum WorkspaceCreationIntent { local, cloud, connect }
