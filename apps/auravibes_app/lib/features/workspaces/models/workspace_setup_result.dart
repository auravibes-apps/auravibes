import 'package:auravibes_app/domain/entities/workspace_entity.dart';

class const WorkspaceSetupResult({
  required final WorkspaceEntity workspace,
  required final WorkspaceSetupOutcome outcome,
});

enum WorkspaceSetupOutcome { created, connected, joined }

enum WorkspaceSetupStage { chooser, local, cloud, authentication, discovery }
